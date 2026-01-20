import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../models/arrow_coordinate.dart';
import '../models/distance_leg.dart';
import '../services/sync_service.dart';
import '../services/vibration_service.dart';
import '../utils/unique_id.dart';

/// Manages the active scoring session state
class SessionProvider extends ChangeNotifier {
  final AppDatabase _db;
  final _vibration = VibrationService();

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
  Bow? _selectedBow;
  String? _selectedQuiverId;
  bool _shaftTaggingEnabled = false;

  // Optional override for arrows per end (for quick start)
  int? _arrowsPerEndOverride;

  // Prevent concurrent end commits (race condition guard)
  bool _isCommittingEnd = false;

  // Getters
  Session? get currentSession => _currentSession;
  RoundType? get roundType => _currentRoundType;
  List<End> get ends => _ends;
  List<Arrow> get currentEndArrows => _currentEndArrows;
  End? get activeEnd => _activeEnd;
  bool get hasActiveSession => _currentSession != null;
  bool get isSessionComplete => _currentSession?.completedAt != null;

  String? get selectedBowId => _selectedBowId;
  Bow? get selectedBow => _selectedBow;
  String? get selectedQuiverId => _selectedQuiverId;
  bool get shaftTaggingEnabled => _shaftTaggingEnabled;

  /// Whether the selected bow is a compound bow (affects X ring scoring)
  bool get isCompoundBow => _selectedBow?.bowType == 'compound';

  /// Whether an end commit is in progress (for UI to disable button)
  bool get isCommittingEnd => _isCommittingEnd;

  /// Toggle shaft tagging on/off during session
  Future<void> setShaftTagging(bool enabled) async {
    if (_currentSession == null) return;
    await _db.setShaftTagging(_currentSession!.id, enabled);
    _shaftTaggingEnabled = enabled;
    notifyListeners();
  }

  int get currentEndNumber => _activeEnd?.endNumber ?? 1;
  int get arrowsPerEnd => _arrowsPerEndOverride ?? _currentRoundType?.arrowsPerEnd ?? 3;
  int get totalEnds => _currentRoundType?.totalEnds ?? 10;
  int get faceCount => _currentRoundType?.faceCount ?? 1;
  bool get isTriSpot => faceCount == 3;

  /// Face size in cm (40 for indoor, 80/122 for outdoor)
  int get faceSizeCm => _currentRoundType?.faceSize ?? 40;

  /// Whether this is an indoor round
  bool get isIndoor => _currentRoundType?.isIndoor ?? true;

  /// Scoring type for the round (10-zone, 5-zone, or worcester)
  String get scoringType => _currentRoundType?.scoringType ?? '10-zone';

  /// Maximum possible score for this round
  int? get maxScore => _currentRoundType?.maxScore;

  // ============================================================================
  // MULTI-DISTANCE ROUND SUPPORT
  // ============================================================================

  /// Parsed distance legs for the current round (null for single-distance rounds)
  List<DistanceLeg>? get distanceLegs =>
      _currentRoundType?.distanceLegs.parseDistanceLegs();

  /// Distance leg tracker for the current round (null for single-distance rounds)
  DistanceLegTracker? get distanceLegTracker {
    final legs = distanceLegs;
    if (legs == null || legs.length <= 1) return null;
    return DistanceLegTracker(legs: legs, arrowsPerEnd: arrowsPerEnd);
  }

  /// Whether this is a multi-distance round
  bool get isMultiDistance => (distanceLegs?.length ?? 0) > 1;

  /// Current distance leg index (0-based), or 0 for single-distance rounds
  int get currentLegIndex {
    final tracker = distanceLegTracker;
    if (tracker == null) return 0;
    return tracker.getLegIndexForEnd(currentEndNumber);
  }

  /// Current distance leg, or null for single-distance rounds
  DistanceLeg? get currentDistanceLeg {
    final tracker = distanceLegTracker;
    if (tracker == null) return null;
    return tracker.getLegForEnd(currentEndNumber);
  }

  /// Current distance with unit (e.g., "100yd", "70m")
  /// Falls back to round's default distance for single-distance rounds
  String get currentDistanceDisplay {
    final leg = currentDistanceLeg;
    if (leg != null) return leg.displayDistance;
    // Fallback for single-distance rounds
    final dist = _currentRoundType?.distance ?? 0;
    // Assume metric for outdoor, WA, etc. - imperial rounds will have distanceLegs
    return '${dist}m';
  }

  /// End numbers that mark distance boundaries (for scorecard display)
  /// Returns empty list for single-distance rounds
  List<int> get distanceBoundaryEnds {
    return distanceLegTracker?.legBoundaryEnds ?? [];
  }

  /// Check if a given end number is the last end of a distance leg
  bool isDistanceBoundary(int endNumber) {
    return distanceLegTracker?.isLegBoundary(endNumber) ?? false;
  }

  /// Get distance leg info for a specific end number
  /// Returns null for single-distance rounds
  DistanceLeg? getDistanceLegForEnd(int endNumber) {
    return distanceLegTracker?.getLegForEnd(endNumber);
  }

  /// Whether the current total score exceeds the round maximum
  /// This indicates a scoring bug that needs investigation
  bool get scoreExceedsMax {
    final max = maxScore;
    if (max == null) return false;
    return totalScore > max;
  }

  int get arrowsInCurrentEnd => _currentEndArrows.length;
  bool get isEndComplete => arrowsInCurrentEnd >= arrowsPerEnd;

  /// Total arrows in session (completed ends + current end)
  int get totalArrowsInSession =>
      _completedEndArrows.length + _currentEndArrows.length;

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
    _selectedBow = session.bowId != null ? await _db.getBow(session.bowId!) : null;
    _selectedQuiverId = session.quiverId;
    _shaftTaggingEnabled = session.shaftTaggingEnabled;

    // Clear arrows per end override (resumed sessions use standard rules)
    _arrowsPerEndOverride = null;

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
    int? arrowsPerEndOverride,
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
      _selectedBow = bowId != null ? await _db.getBow(bowId) : null;
      _selectedQuiverId = quiverId;
      _shaftTaggingEnabled = shaftTaggingEnabled;

      // Store arrows per end override (for quick start)
      _arrowsPerEndOverride = arrowsPerEndOverride;

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
  /// [rating] defaults to 5 (good shot), lower values (e.g. 3) exclude from analysis.
  Future<void> plotArrowMm({
    required ArrowCoordinate coord,
    int faceIndex = 0,
    int? shaftNumber,
    String? nockRotation,
    int rating = 5,
  }) async {
    if (_activeEnd == null || isEndComplete) return;

    // Use mm-based scoring with epsilon tolerance
    // Pass scoringType to use correct scoring system (10-zone or 5-zone)
    // Pass compoundScoring for correct X ring size (compound X is smaller)
    final result = TargetRingsMm.scoreAndX(
      coord.distanceMm,
      faceSizeCm,
      scoringType: scoringType,
      compoundScoring: isCompoundBow,
    );

    final arrowId =
        '${_activeEnd!.id}_arrow_${_currentEndArrows.length + 1}';

    // Resolve shaftId from shaftNumber if quiver is selected
    String? shaftId;
    if (shaftNumber != null && _selectedQuiverId != null) {
      final shafts = await _db.getShaftsForQuiver(_selectedQuiverId!);
      final shaft = shafts.where((s) => s.number == shaftNumber).firstOrNull;
      shaftId = shaft?.id;
    }

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
      shaftId: Value(shaftId),
      nockRotation: Value(nockRotation),
      rating: Value(rating),
    ));

    // Reload current end arrows
    _currentEndArrows = await _db.getArrowsForEnd(_activeEnd!.id);

    // Haptic feedback for arrow plotted
    _vibration.light();

    notifyListeners();

    // Auto-commit when end is complete
    if (_currentEndArrows.length >= arrowsPerEnd) {
      await commitEnd();
    }
  }

  /// Plot an arrow at the given normalized position (-1 to +1)
  /// [faceIndex] specifies which face (0, 1, or 2) for triple spot mode
  /// [rating] defaults to 5 (good shot), lower values (e.g. 3) exclude from analysis.
  Future<void> plotArrow({
    required double x,
    required double y,
    int faceIndex = 0,
    int? shaftNumber,
    String? nockRotation,
    int rating = 5,
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
      nockRotation: nockRotation,
      rating: rating,
    );
  }

  /// Remove the last plotted arrow (undo)
  /// Cycles through all arrows in the session, uncommitting ends as needed
  Future<void> undoLastArrow() async {
    if (_activeEnd == null) return;

    // If current end has arrows, delete the last one
    if (_currentEndArrows.isNotEmpty) {
      await _db.deleteLastArrowInEnd(_activeEnd!.id);
      _currentEndArrows = await _db.getArrowsForEnd(_activeEnd!.id);
      notifyListeners();
      return;
    }

    // Current end is empty - check if we have committed ends to undo into
    final committedEnds =
        _ends.where((e) => e.status == 'committed').toList();
    if (committedEnds.isEmpty) return;

    // Get the last committed end
    final lastCommittedEnd = committedEnds.last;

    // Delete the current empty active end
    await _db.deleteEnd(_activeEnd!.id);

    // Uncommit the last committed end and make it active
    await _db.uncommitEnd(lastCommittedEnd.id);

    // Load that end's arrows
    final endArrows = await _db.getArrowsForEnd(lastCommittedEnd.id);

    // Remove the last arrow from that end
    if (endArrows.isNotEmpty) {
      await _db.deleteLastArrowInEnd(lastCommittedEnd.id);
    }

    // Reload state
    _ends = await _db.getEndsForSession(_currentSession!.id);
    _activeEnd = await _db.getEnd(lastCommittedEnd.id);
    _currentEndArrows = await _db.getArrowsForEnd(lastCommittedEnd.id);

    // Refresh completed arrows cache
    await _refreshCompletedEndArrowsCache();

    notifyListeners();
  }

  /// Delete a specific arrow by index in the current end
  Future<void> deleteArrowAtIndex(int index) async {
    if (_activeEnd == null) return;
    if (index < 0 || index >= _currentEndArrows.length) return;

    final arrowToDelete = _currentEndArrows[index];
    await _db.deleteArrow(arrowToDelete.id);
    _currentEndArrows = await _db.getArrowsForEnd(_activeEnd!.id);
    notifyListeners();
  }

  /// Move an arrow to the end of the current end's arrow list
  Future<void> moveArrowToEnd(int fromIndex) async {
    if (_activeEnd == null) return;
    if (fromIndex < 0 || fromIndex >= _currentEndArrows.length - 1) return;

    // Reorder by updating sequence numbers
    final arrow = _currentEndArrows[fromIndex];
    final lastSequence = _currentEndArrows.last.sequence;

    // Move this arrow to the end by giving it the highest sequence
    await _db.updateArrowSequence(arrow.id, lastSequence + 1);

    // Reload arrows (they come back sorted by sequence)
    _currentEndArrows = await _db.getArrowsForEnd(_activeEnd!.id);
    notifyListeners();
  }

  /// Commit the current end and move to the next
  Future<void> commitEnd() async {
    // Guard against concurrent commits (can happen if user taps button during auto-commit)
    if (_isCommittingEnd) return;
    if (_activeEnd == null || _currentEndArrows.isEmpty) return;

    _isCommittingEnd = true;
    try {
      await _doCommitEnd();
    } finally {
      _isCommittingEnd = false;
    }
  }

  /// Internal: Actually commit the end (called by commitEnd with guard)
  Future<void> _doCommitEnd() async {
    // Calculate end score
    final endScore = currentEndScore;
    final endXs = currentEndXs;

    // Add current end arrows to completed cache before clearing
    _completedEndArrows = [..._completedEndArrows, ..._currentEndArrows];

    // Commit the end
    await _db.commitEnd(_activeEnd!.id, endScore, endXs);

    // Reload ends list
    _ends = await _db.getEndsForSession(_currentSession!.id);

    // Trigger incremental sync after each end
    // This ensures arrows are backed up even if session isn't completed
    _triggerCloudBackup();

    // Check if session is complete
    if (_ends.length >= totalEnds) {
      await _completeSession();
    } else {
      // Haptic feedback for end completed
      _vibration.medium();
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

    // Add session arrows to daily volume tracking
    await _db.addSessionArrowsToVolume(_currentSession!.id);

    // Trigger cloud backup in background
    _triggerCloudBackup();

    // Haptic feedback for round/session completed
    _vibration.double();

    notifyListeners();
  }

  /// Trigger cloud sync in background (non-blocking)
  void _triggerCloudBackup() {
    // SyncService handles its own error handling and retry logic
    SyncService().syncAll();
  }

  /// Abandon current session (soft delete for undo support)
  Future<void> abandonSession() async {
    if (_currentSession == null) return;

    await _db.softDeleteSession(_currentSession!.id);
    _currentSession = null;
    _currentRoundType = null;
    _ends = [];
    _currentEndArrows = [];
    _completedEndArrows = [];
    _activeEnd = null;
    _arrowsPerEndOverride = null;
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

  /// Get arrows for a specific end (by ID)
  Future<List<Arrow>> getArrowsForEnd(String endId) async {
    return await _db.getArrowsForEnd(endId);
  }

  /// Refresh the completed end arrows cache from database
  /// Only includes committed ends, not the active end
  Future<void> _refreshCompletedEndArrowsCache() async {
    final allArrows = <Arrow>[];
    for (final end in _ends) {
      // Only include committed ends in the cache
      if (end.status == 'committed') {
        final endArrows = await _db.getArrowsForEnd(end.id);
        allArrows.addAll(endArrows);
      }
    }
    _completedEndArrows = allArrows;
  }

  /// Get last N arrows from completed ends + current end for rolling average
  /// This is the synchronous version using cached data for immediate UI updates.
  List<Arrow> lastNArrows(int count) {
    if (_currentSession == null) return [];

    final allArrows = allSessionArrows;
    if (allArrows.length <= count) return allArrows;
    return allArrows.sublist(allArrows.length - count);
  }

  /// Get last N arrows from completed ends + current end for rolling average
  /// Async version (legacy - prefer lastNArrows for cached access)
  Future<List<Arrow>> getLastNArrows(int count) async {
    // Use synchronous cached version
    return lastNArrows(count);
  }

  /// Get all arrows for all completed ends (for scorecard display)
  /// Synchronous version using cached data.
  List<List<Arrow>> get completedEndArrowsByEnd {
    final endArrows = <List<Arrow>>[];
    for (final end in _ends) {
      final arrows = _completedEndArrows.where((a) => a.endId == end.id).toList();
      endArrows.add(arrows);
    }
    return endArrows;
  }

  /// Get all arrows for all completed ends (for scorecard display)
  /// Async version (legacy - prefer completedEndArrowsByEnd for cached access)
  Future<List<List<Arrow>>> getAllCompletedEndArrows() async {
    return completedEndArrowsByEnd;
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
    // Check if mm coordinates are valid by comparing with normalized
    // If both are close to zero OR consistent with each other, use mm
    // This handles both true bullseyes AND distinguishes from legacy default (0,0)
    final radiusMm = faceSizeCm * 5.0;
    final normalizedToMmX = arrow.x * radiusMm;
    final normalizedToMmY = arrow.y * radiusMm;

    // If mm coords are non-zero, use them directly
    if (arrow.xMm != 0 || arrow.yMm != 0) {
      return ArrowCoordinate(
        xMm: arrow.xMm,
        yMm: arrow.yMm,
        faceSizeCm: faceSizeCm,
      );
    }

    // Both mm are 0. Check if this is a true bullseye or legacy default.
    // True bullseye: normalized coords also near zero
    // Legacy default: normalized coords indicate non-center position
    const toleranceMm = 1.0; // 1mm tolerance for "near zero"
    final normalizedNearZero =
        normalizedToMmX.abs() < toleranceMm && normalizedToMmY.abs() < toleranceMm;

    if (normalizedNearZero) {
      // True bullseye - normalized also indicates center
      return ArrowCoordinate(
        xMm: arrow.xMm,
        yMm: arrow.yMm,
        faceSizeCm: faceSizeCm,
      );
    }

    // Legacy arrow: mm defaulted to 0,0 but normalized has real data
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
