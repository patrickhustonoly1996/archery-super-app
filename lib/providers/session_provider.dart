import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';

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

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

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

  /// Plot an arrow at the given position
  Future<void> plotArrow({
    required double x,
    required double y,
    int faceIndex = 0,
    int? shaftNumber,
  }) async {
    if (_activeEnd == null || isEndComplete) return;

    // Calculate distance from center for scoring (need sqrt, not squared distance)
    final distanceFraction = math.sqrt(x * x + y * y).clamp(0.0, 1.0);

    // Get score from ring boundaries
    final score = TargetRings.getScore(distanceFraction.clamp(0.0, 1.0));
    final isX = TargetRings.isX(distanceFraction);

    final arrowId =
        '${_activeEnd!.id}_arrow_${_currentEndArrows.length + 1}';

    await _db.insertArrow(ArrowsCompanion.insert(
      id: arrowId,
      endId: _activeEnd!.id,
      faceIndex: Value(faceIndex),
      x: x,
      y: y,
      score: score,
      isX: Value(isX),
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
    notifyListeners();
  }

  /// Abandon current session
  Future<void> abandonSession() async {
    if (_currentSession == null) return;

    await _db.deleteSession(_currentSession!.id);
    _currentSession = null;
    _currentRoundType = null;
    _ends = [];
    _currentEndArrows = [];
    _activeEnd = null;
    notifyListeners();
  }

  /// Get all arrows for display on the target face (all ends + current)
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

  /// Clear session state (for logout or reset)
  void clearSession() {
    _currentSession = null;
    _currentRoundType = null;
    _ends = [];
    _currentEndArrows = [];
    _activeEnd = null;
    notifyListeners();
  }
}
