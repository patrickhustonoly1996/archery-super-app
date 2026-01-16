import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../models/arrow_coordinate.dart';
import '../services/firestore_sync_service.dart';
import '../utils/unique_id.dart';
import '../utils/error_handler.dart';

/// Manages the active scoring session state
class SessionProvider extends ChangeNotifier {
  final AppDatabase _db;

  SessionProvider(this._db);

  // Current session state
  Session? _currentSession;
  RoundType? _currentRoundType;
  List<End> _ends = [];
  List<Arrow> _currentEndArrows = [];
  End? _activeEnd;

  // Cached arrows from completed ends (for synchronous access)
  List<Arrow> _completedEndArrows = [];

  // Equipment state
  String? _selectedBowId;
  String? _selectedQuiverId;
  bool _shaftTaggingEnabled = false;

  // Getters
  Session? get currentSession => _currentSession;
  RoundType? get roundType => _currentRoundType;
  List<End> get ends => _ends;
  List<Arrow> get currentEndArrows => _currentEndArrows;
  End? get activeEnd => _activeEnd;
  bool get hasActiveSession => _currentSession != null;
  bool get isSessionComplete => _currentSession?.completedAt != null;

  String? get selectedBowId => _selectedBowId;
  String? get selectedQuiverId => _selectedQuiverId;
  bool get shaftTaggingEnabled => _shaftTaggingEnabled;

  int get currentEndNumber => _activeEnd?.endNumber ?? 1;
  int get arrowsPerEnd => _currentRoundType?.arrowsPerEnd ?? 3;
  int get totalEnds => _currentRoundType?.totalEnds ?? 10;
  int get faceCount => _currentRoundType?.faceCount ?? 1;
  bool get isTriSpot => faceCount == 3;

  /// Face size in cm (40 for indoor, 80/122 for outdoor)
  int get faceSizeCm => _currentRoundType?.faceSize ?? 40;

  /// Whether this is an indoor round
  bool get isIndoor => _currentRoundType?.isIndoor ?? true;

  /// Scoring type for the round (10-zone or 5-zone)
  String get scoringType => _currentRoundType?.scoringType ?? '10-zone';

  int get arrowsInCurrentEnd => _currentEndArrows.length;
  bool get isEndComplete => arrowsInCurrentEnd >= arrowsPerEnd;

  /// Calculate total score for the session
  int get totalScore {
    int total = 0;
    for (final end in _ends) {
      total += end.endScore;
    }
    // Add current end arrows
    for (final arrow in _currentEndArrows) {
      total += arrow.score;
    }
    return total;
  }

  /// Calculate total Xs for the session
  int get totalXs {
    int xs = 0;
    for (final end in _ends) {
      xs += end.endXs;
    }
    for (final arrow in _currentEndArrows) {
      if (arrow.isX) xs++;
    }
    return xs;
  }

  /// Current end score
  int get currentEndScore {
    int score = 0;
    for (final arrow in _currentEndArrows) {
      score += arrow.score;
    }
    return score;
  }

  /// Current end Xs
  int get currentEndXs {
    int xs = 0;
    for (final arrow in _currentEndArrows) {
      if (arrow.isX) xs++;
    }
    return xs;
  }

  /// Check for and resume any incomplete session
  Future<bool> checkForIncompleteSession() async {
    final incomplete = await _db.getIncompleteSession();
    if (incomplete != null) {
      await _loadSession(incomplete);
      return true;
    }
    return false;
  }

  /// Load an existing session
  Future<void> _loadSession(Session session) async {
    _currentSession = session;
    _currentRoundType = await _db.getRoundType(session.roundTypeId);
    _ends = await _db.getEndsForSession(session.id);

    // Load equipment state
    _selectedBowId = session.bowId;
    _selectedQuiverId = session.quiverId;
    _shaftTaggingEnabled = session.shaftTaggingEnabled;

    // Cache completed end arrows for synchronous access
    await _refreshCompletedEndArrowsCache();

    // Find or create active end
    final activeEnd = await _db.getCurrentEnd(session.id);
    if (activeEnd != null) {
      _activeEnd = activeEnd;
      _currentEndArrows = await _db.getArrowsForEnd(activeEnd.id);
    } else if (_ends.length < totalEnds) {
      // Create new end
      await _createNewEnd();
    }

    notifyListeners();
  }

  /// Start a new session
  Future<void> startSession({
    required String roundTypeId,
    String? location,
    String sessionType = 'practice',
    String? bowId,
    String? quiverId,
    bool shaftTaggingEnabled = false,
  }) async {
    final roundType = await _db.getRoundType(roundTypeId);
    if (roundType == null) {
      throw Exception('Invalid round type');
    }

    final sessionId = UniqueId.generate();

    await _db.insertSession(SessionsCompanion.insert(
      id: sessionId,
      roundTypeId: roundTypeId,
      sessionType: Value(sessionType),
      location: Value(location),
      bowId: Value(bowId),
      quiverId: Value(quiverId),
      shaftTaggingEnabled: Value(shaftTaggingEnabled),
    ));

    final session = await _db.getSession(sessionId);
    if (session != null) {
      _currentSession = session;
      _currentRoundType = roundType;
      _ends = [];
      _currentEndArrows = [];
      _completedEndArrows = []; // Clear cache for new session

      // Store equipment state
      _selectedBowId = bowId;
      _selectedQuiverId = quiverId;
      _shaftTaggingEnabled = shaftTaggingEnabled;

      await _createNewEnd();
      notifyListeners();
    }
  }

  /// Create a new end
  Future<void> _createNewEnd() async {
    if (_currentSession == null) return;

    final endNumber = _ends.length + 1;
    final endId = '${_currentSession!.id}_end_$endNumber';

    await _db.insertEnd(EndsCompanion.insert(
      id: endId,
      sessionId: _currentSession!.id,
      endNumber: endNumber,
    ));

    _activeEnd = await _db.getEnd(endId);
    _currentEndArrows = [];
    notifyListeners();
  }

  /// Plot an arrow using mm coordinates (preferred method)
  /// This is the primary plotting method with sub-millimeter precision.
  Future<void> plotArrowMm({
    required ArrowCoordinate coord,
    int faceIndex = 0,
    int? shaftNumber,
  }) async {
    if (_activeEnd == null || isEndComplete) return;

    // Use mm-based scoring with epsilon tolerance
    // Pass scoringType to use correct scoring system (10-zone or 5-zone)
    final result = TargetRingsMm.scoreAndX(
      coord.distanceMm,
      faceSizeCm,
      scoringType: scoringType,
    );

    final arrowId =
        '${_activeEnd!.id}_arrow_${_currentEndArrows.length + 1}';

    await _db.insertArrow(ArrowsCompanion.insert(
      id: arrowId,
      endId: _activeEnd!.id,
      faceIndex: Value(faceIndex),
      xMm: Value(coord.xMm),
      yMm: Value(coord.yMm),
      x: coord.normalizedX, // Legacy: keep normalized for backward compat
      y: coord.normalizedY,
      score: result.score,
      isX: Value(result.isX),
      sequence: _currentEndArrows.length + 1,
      shaftNumber: Value(shaftNumber),
    ));

    // Reload current end arrows
    _currentEndArrows = await _db.getArrowsForEnd(_activeEnd!.id);
    notifyListeners();

    // Auto-commit when end is complete
    if (_currentEndArrows.length >= arrowsPerEnd) {
      await commitEnd();
    }
  }

  /// Plot an arrow at the given normalized position (-1 to +1)
  /// @deprecated Use plotArrowMm for new code - provides sub-mm precision
  Future<void> plotArrow({
    required double x,
    required double y,
    int faceIndex = 0,
    int? shaftNumber,
  }) async {
    // Convert normalized to ArrowCoordinate and use the mm method
    final coord = ArrowCoordinate.fromNormalized(
      x: x,
      y: y,
      faceSizeCm: faceSizeCm,
    );
    await plotArrowMm(
      coord: coord,
      faceIndex: faceIndex,
      shaftNumber: shaftNumber,
    );
  }

  /// Remove the last plotted arrow (undo)
  Future<void> undoLastArrow() async {
    if (_activeEnd == null || _currentEndArrows.isEmpty) return;

    await _db.deleteLastArrowInEnd(_activeEnd!.id);
    _currentEndArrows = await _db.getArrowsForEnd(_activeEnd!.id);
    notifyListeners();
  }

  /// Commit the current end and move to the next
  Future<void> commitEnd() async {
    if (_activeEnd == null || _currentEndArrows.isEmpty) return;

    // Calculate end score
    final endScore = currentEndScore;
    final endXs = currentEndXs;

    // Add current end arrows to completed cache before clearing
    _completedEndArrows = [..._completedEndArrows, ..._currentEndArrows];

    // Commit the end
    await _db.commitEnd(_activeEnd!.id, endScore, endXs);

    // Reload ends list
    _ends = await _db.getEndsForSession(_currentSession!.id);

    // Check if session is complete
    if (_ends.length >= totalEnds) {
      await _completeSession();
    } else {
      // Create next end
      await _createNewEnd();
    }

    notifyListeners();
  }

  /// Complete the current session
  Future<void> _completeSession() async {
    if (_currentSession == null) return;

    await _db.completeSession(_currentSession!.id, totalScore, totalXs);
    _currentSession = await _db.getSession(_currentSession!.id);

    // Trigger cloud backup in background
    _triggerCloudBackup();

    notifyListeners();
  }

  /// Trigger cloud backup in background (non-blocking)
  void _triggerCloudBackup() {
    Future.microtask(() async {
      try {
        final syncService = FirestoreSyncService();
        if (syncService.isAuthenticated) {
          await ErrorHandler.runBackground(
            () => syncService.backupAllData(_db),
            errorMessage: 'Cloud backup failed',
            onRetry: _triggerCloudBackup,
          );
        }
      } catch (e) {
        // Firebase not initialized (tests) or other initialization error
        debugPrint('Cloud backup skipped: $e');
      }
    });
  }

  /// Abandon current session
  Future<void> abandonSession() async {
    if (_currentSession == null) return;

    await _db.deleteSession(_currentSession!.id);
    _currentSession = null;
    _currentRoundType = null;
    _ends = [];
    _currentEndArrows = [];
    _completedEndArrows = [];
    _activeEnd = null;
    notifyListeners();
  }

  /// Get all arrows for display on the target face (all ends + current)
  /// This is the synchronous version for immediate UI updates.
  List<Arrow> get allSessionArrows {
    return [..._completedEndArrows, ..._currentEndArrows];
  }

  /// Async version that fetches from database (for initial load/refresh)
  Future<List<Arrow>> getAllSessionArrows() async {
    final allArrows = <Arrow>[];

    // Get all arrows from completed ends
    for (final end in _ends) {
      final endArrows = await _db.getArrowsForEnd(end.id);
      allArrows.addAll(endArrows);
    }

    // Add current end arrows
    allArrows.addAll(_currentEndArrows);

    return allArrows;
  }

  /// Refresh the completed end arrows cache from database
  Future<void> _refreshCompletedEndArrowsCache() async {
    final allArrows = <Arrow>[];
    for (final end in _ends) {
      final endArrows = await _db.getArrowsForEnd(end.id);
      allArrows.addAll(endArrows);
    }
    _completedEndArrows = allArrows;
  }

  /// Get last N arrows from completed ends + current end for rolling average
  Future<List<Arrow>> getLastNArrows(int count) async {
    if (_currentSession == null) return [];

    final allArrows = <Arrow>[];

    // Get arrows from completed ends (newest first)
    for (int i = _ends.length - 1; i >= 0 && allArrows.length < count; i--) {
      final endArrows = await _db.getArrowsForEnd(_ends[i].id);
      // Add arrows in reverse (most recent first)
      for (int j = endArrows.length - 1; j >= 0 && allArrows.length < count; j--) {
        allArrows.add(endArrows[j]);
      }
    }

    // Add current end arrows if needed
    for (int i = _currentEndArrows.length - 1; i >= 0 && allArrows.length < count; i--) {
      allArrows.add(_currentEndArrows[i]);
    }

    return allArrows.reversed.toList(); // Return in chronological order
  }

  /// Get all arrows for all completed ends (for scorecard display)
  Future<List<List<Arrow>>> getAllCompletedEndArrows() async {
    final endArrows = <List<Arrow>>[];
    for (final end in _ends) {
      final arrows = await _db.getArrowsForEnd(end.id);
      endArrows.add(arrows);
    }
    return endArrows;
  }

  /// Get arrows for a specific face index (tri-spot mode)
  List<Arrow> getArrowsForFace(int faceIndex) {
    return _currentEndArrows.where((a) => a.faceIndex == faceIndex).toList();
  }

  /// Get arrows for the current half of the round
  /// First half = ends 1 to totalEnds/2, Second half = remaining ends
  Future<List<Arrow>> getCurrentHalfArrows() async {
    if (_currentSession == null) return [];

    final halfPoint = (totalEnds / 2).ceil();
    final isSecondHalf = currentEndNumber > halfPoint;

    final allArrows = <Arrow>[];

    if (isSecondHalf) {
      // Get arrows from second half ends
      for (int i = halfPoint; i < _ends.length; i++) {
        final endArrows = await _db.getArrowsForEnd(_ends[i].id);
        allArrows.addAll(endArrows);
      }
    } else {
      // Get arrows from first half ends
      for (int i = 0; i < _ends.length && i < halfPoint; i++) {
        final endArrows = await _db.getArrowsForEnd(_ends[i].id);
        allArrows.addAll(endArrows);
      }
    }

    // Add current end arrows
    allArrows.addAll(_currentEndArrows);

    return allArrows;
  }

  /// Clear session state (for logout or reset)
  void clearSession() {
    _currentSession = null;
    _currentRoundType = null;
    _ends = [];
    _currentEndArrows = [];
    _completedEndArrows = [];
    _activeEnd = null;
    notifyListeners();
  }

  // ============================================================================
  // COORDINATE HELPERS
  // ============================================================================

  /// Convert an Arrow to ArrowCoordinate using session's face size
  ArrowCoordinate arrowToCoordinate(Arrow arrow) {
    // Prefer mm coordinates if available (non-zero), fall back to normalized
    if (arrow.xMm != 0 || arrow.yMm != 0) {
      return ArrowCoordinate(
        xMm: arrow.xMm,
        yMm: arrow.yMm,
        faceSizeCm: faceSizeCm,
      );
    }
    // Legacy fallback: convert from normalized
    return ArrowCoordinate.fromNormalized(
      x: arrow.x,
      y: arrow.y,
      faceSizeCm: faceSizeCm,
    );
  }

  /// Convert list of Arrows to ArrowCoordinates
  List<ArrowCoordinate> arrowsToCoordinates(List<Arrow> arrows) {
    return arrows.map(arrowToCoordinate).toList();
  }

  /// Get all session arrows as ArrowCoordinates
  Future<List<ArrowCoordinate>> getAllSessionArrowCoordinates() async {
    final arrows = await getAllSessionArrows();
    return arrowsToCoordinates(arrows);
  }

  /// Get last N arrows as ArrowCoordinates (for rolling average)
  Future<List<ArrowCoordinate>> getLastNArrowCoordinates(int count) async {
    final arrows = await getLastNArrows(count);
    return arrowsToCoordinates(arrows);
  }
}
