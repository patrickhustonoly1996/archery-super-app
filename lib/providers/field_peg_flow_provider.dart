import 'package:flutter/foundation.dart';
import '../models/field_peg_state.dart';
import '../models/field_course_target.dart';
import '../models/field_scoring.dart';
import '../models/arrow_coordinate.dart';
import '../models/sight_mark.dart';
import '../utils/field_correction_calculator.dart';

/// Scoring mode for field targets
enum FieldScoringMode { plotting, buttons }

/// Manages per-peg scoring flow for IFAA field targets.
///
/// Handles:
/// - Walk-down targets (1 arrow per peg, 4 pegs at different distances)
/// - Single-peg targets (4 arrows from same position)
/// - Angle input and sightmark recommendations per peg
/// - Poor shot marking
/// - Mode toggle between plotting and button scoring
class FieldPegFlowProvider extends ChangeNotifier {
  // Target configuration
  FieldTargetPegFlow? _pegFlow;
  FieldTargetPegFlow? get pegFlow => _pegFlow;

  // Correction calculator inputs
  double _arrowSpeedFps = 195.0;
  double? _baseFlatMark;
  double? _courseDifferential;
  int _courseDataPoints = 0;
  SightMarkConfidence _baseConfidence = SightMarkConfidence.medium;

  // Scoring mode
  FieldScoringMode _scoringMode = FieldScoringMode.buttons;
  FieldScoringMode get scoringMode => _scoringMode;

  // Current recommendation (cached to avoid recalculation)
  FieldSightMarkRecommendation? _currentRecommendation;
  FieldSightMarkRecommendation? get currentRecommendation => _currentRecommendation;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Initialize the peg flow for a target.
  void initializeForTarget({
    required FieldCourseTarget target,
    required double arrowSpeedFps,
    double? baseFlatMark,
    double? courseDifferential,
    int courseDataPoints = 0,
    SightMarkConfidence baseConfidence = SightMarkConfidence.medium,
    Map<int, double>? prefilledAngles,
  }) {
    _arrowSpeedFps = arrowSpeedFps;
    _baseFlatMark = baseFlatMark;
    _courseDifferential = courseDifferential;
    _courseDataPoints = courseDataPoints;
    _baseConfidence = baseConfidence;

    // Build peg states from target configuration
    final pegs = <FieldPegState>[];
    final config = target.pegConfig;

    if (config.type == PegType.walkDown || config.type == PegType.walkUp) {
      // Walk-down/walk-up: one peg per position
      for (int i = 0; i < config.positions.length; i++) {
        final pos = config.positions[i];
        pegs.add(FieldPegState(
          pegIndex: i,
          distance: pos.distance,
          unit: pos.unit,
          angleDegrees: prefilledAngles?[i],
          angleSource: prefilledAngles?[i] != null ? 'prefilled' : null,
        ));
      }
    } else {
      // Single peg or fan: all arrows from same position
      // Create 4 pegs at the same distance (each represents one arrow)
      for (int i = 0; i < target.arrowsRequired; i++) {
        pegs.add(FieldPegState(
          pegIndex: i,
          distance: target.primaryDistance,
          unit: target.unit,
          angleDegrees: prefilledAngles?[0],
          angleSource: prefilledAngles?[0] != null ? 'prefilled' : null,
        ));
      }
    }

    _pegFlow = FieldTargetPegFlow(
      courseTargetId: target.id,
      targetNumber: target.targetNumber,
      faceSize: target.faceSize,
      pegType: config.type,
      pegs: pegs,
      currentPegIndex: 0,
    );

    _currentRecommendation = null;
    notifyListeners();
  }

  // ===========================================================================
  // ANGLE MANAGEMENT
  // ===========================================================================

  /// Set angle for the current peg
  void setAngle(double degrees, String source) {
    if (_pegFlow == null) return;

    final pegs = List<FieldPegState>.from(_pegFlow!.pegs);
    pegs[_pegFlow!.currentPegIndex] = pegs[_pegFlow!.currentPegIndex].copyWith(
      angleDegrees: degrees,
      angleSource: source,
    );

    _pegFlow = _pegFlow!.copyWith(pegs: pegs);

    // If this is the first peg and consistent angle is enabled,
    // propagate to subsequent unscored pegs
    if (_pegFlow!.currentPegIndex == 0 && _pegFlow!.consistentAngleEnabled) {
      _propagateAngle(degrees, source);
    }

    // Update initial angle if this is peg 0
    if (_pegFlow!.currentPegIndex == 0) {
      _pegFlow = _pegFlow!.copyWith(initialAngle: degrees);
    }

    _recalculateRecommendation();
    notifyListeners();
  }

  /// Toggle consistent angle mode (carry angle from peg 0 to subsequent pegs)
  void toggleConsistentAngle() {
    if (_pegFlow == null) return;

    final newEnabled = !_pegFlow!.consistentAngleEnabled;
    _pegFlow = _pegFlow!.copyWith(consistentAngleEnabled: newEnabled);

    if (newEnabled && _pegFlow!.initialAngle != null) {
      _propagateAngle(_pegFlow!.initialAngle!, 'consistent');
    }

    notifyListeners();
  }

  void _propagateAngle(double degrees, String source) {
    if (_pegFlow == null) return;

    final pegs = List<FieldPegState>.from(_pegFlow!.pegs);
    for (int i = 1; i < pegs.length; i++) {
      if (!pegs[i].isScored) {
        pegs[i] = pegs[i].copyWith(
          angleDegrees: degrees,
          angleSource: source,
        );
      }
    }
    _pegFlow = _pegFlow!.copyWith(pegs: pegs);
  }

  // ===========================================================================
  // SIGHTMARK RECOMMENDATION
  // ===========================================================================

  /// Get the current recommendation (recalculates if needed)
  FieldSightMarkRecommendation? getRecommendation() {
    if (_currentRecommendation != null) return _currentRecommendation;
    _recalculateRecommendation();
    return _currentRecommendation;
  }

  void _recalculateRecommendation() {
    if (_pegFlow == null || _baseFlatMark == null) {
      _currentRecommendation = null;
      return;
    }

    final peg = _pegFlow!.currentPeg;

    // For walk-down with different distances per peg, we need per-peg flat marks.
    // For now, scale the base flat mark by the distance ratio.
    double pegFlatMark = _baseFlatMark!;
    if (_pegFlow!.isWalkDown) {
      // The baseFlatMark is for the primary (first peg) distance.
      // Scale for current peg distance.
      final primaryDist = _pegFlow!.pegs.first.distance;
      if (primaryDist > 0 && peg.distance != primaryDist) {
        // Rough linear scaling — proper prediction would use the full sight mark curve
        pegFlatMark = _baseFlatMark! * (peg.distance / primaryDist);
      }
    }

    // Build previous peg result for walk-down
    PreviousPegResult? previousResult;
    if (_pegFlow!.isWalkDown && _pegFlow!.currentPegIndex > 0) {
      final prevPeg = _pegFlow!.pegs[_pegFlow!.currentPegIndex - 1];
      if (prevPeg.isScored) {
        previousResult = PreviousPegResult(
          coordinate: prevPeg.arrowScore?.coordinate,
          isPoorShot: prevPeg.isPoorShot,
          poorShotDirection: prevPeg.poorShotDirection,
          previousDistance: prevPeg.distance,
          previousAngle: prevPeg.angleDegrees,
          previousSightMark: double.tryParse(prevPeg.sightMarkUsed ?? ''),
        );
      }
    }

    _currentRecommendation = FieldCorrectionCalculator.calculateForPeg(
      distance: peg.distance,
      unit: peg.unit,
      angleDegrees: peg.angleDegrees,
      arrowSpeedFps: _arrowSpeedFps,
      baseFlatMark: pegFlatMark,
      courseDifferential: _courseDifferential,
      courseDataPoints: _courseDataPoints,
      previousPegResult: previousResult,
      baseConfidence: _baseConfidence,
    );
  }

  // ===========================================================================
  // SCORING
  // ===========================================================================

  /// Score the current arrow via button press (zone selection)
  void scoreArrowByButton(FieldScoringZone zone) {
    if (_pegFlow == null) return;
    final idx = _pegFlow!.currentPegIndex;
    final peg = _pegFlow!.pegs[idx];

    final arrowScore = FieldArrowScore(
      arrowNumber: idx + 1,
      zone: zone,
      pegPosition: _pegFlow!.isWalkDown ? idx + 1 : null,
      slopeAngleDeg: peg.angleDegrees,
      sightMarkUsed: _currentRecommendation?.displayValue,
    );

    _applyArrowScore(idx, arrowScore);
  }

  /// Score the current arrow via plot (coordinate on target face)
  void scoreArrowByPlot(ArrowCoordinate coordinate, FieldScoringZone zone) {
    if (_pegFlow == null) return;
    final idx = _pegFlow!.currentPegIndex;
    final peg = _pegFlow!.pegs[idx];

    final arrowScore = FieldArrowScore(
      arrowNumber: idx + 1,
      zone: zone,
      pegPosition: _pegFlow!.isWalkDown ? idx + 1 : null,
      coordinate: coordinate,
      slopeAngleDeg: peg.angleDegrees,
      sightMarkUsed: _currentRecommendation?.displayValue,
    );

    _applyArrowScore(idx, arrowScore);
  }

  void _applyArrowScore(int pegIndex, FieldArrowScore score) {
    final pegs = List<FieldPegState>.from(_pegFlow!.pegs);
    pegs[pegIndex] = pegs[pegIndex].copyWith(
      arrowScore: score,
      sightMarkUsed: _currentRecommendation?.displayValue,
    );
    _pegFlow = _pegFlow!.copyWith(pegs: pegs);
    _currentRecommendation = null; // Force recalc for next peg
    notifyListeners();
  }

  /// Toggle poor shot on current (or last scored) peg
  void togglePoorShot({String? direction}) {
    if (_pegFlow == null) return;

    // Find the peg to toggle (current if scored, otherwise previous)
    int targetIdx = _pegFlow!.currentPegIndex;
    if (!_pegFlow!.pegs[targetIdx].isScored && targetIdx > 0) {
      targetIdx = targetIdx - 1;
    }

    final peg = _pegFlow!.pegs[targetIdx];
    if (!peg.isScored) return;

    final newIsPoor = !peg.isPoorShot;
    final pegs = List<FieldPegState>.from(_pegFlow!.pegs);
    pegs[targetIdx] = pegs[targetIdx].copyWith(
      isPoorShot: newIsPoor,
      poorShotDirection: newIsPoor ? direction : null,
    );

    // Also update the arrow score
    final updatedScore = peg.arrowScore!.copyWith(
      isPoorShot: newIsPoor,
      poorShotDirection: newIsPoor ? direction : null,
    );
    pegs[targetIdx] = pegs[targetIdx].copyWith(arrowScore: updatedScore);

    _pegFlow = _pegFlow!.copyWith(pegs: pegs);
    _currentRecommendation = null; // Force recalc since poor shot affects walk-down
    notifyListeners();
  }

  // ===========================================================================
  // PEG NAVIGATION
  // ===========================================================================

  /// Advance to the next peg (for walk-downs)
  void nextPeg() {
    if (_pegFlow == null || !_pegFlow!.canAdvance) return;

    _pegFlow = _pegFlow!.copyWith(
      currentPegIndex: _pegFlow!.currentPegIndex + 1,
    );
    _currentRecommendation = null;
    _recalculateRecommendation();
    notifyListeners();
  }

  // ===========================================================================
  // MODE & STATE
  // ===========================================================================

  /// Toggle scoring mode between plotting and buttons
  void setScoringMode(FieldScoringMode mode) {
    _scoringMode = mode;
    notifyListeners();
  }

  /// Whether the target is fully scored
  bool get isTargetComplete => _pegFlow?.isComplete ?? false;

  /// Get the current peg state
  FieldPegState? get currentPeg => _pegFlow?.currentPeg;

  /// Get all final arrow scores for submission
  List<FieldArrowScore> getFinalScores() {
    return _pegFlow?.allArrowScores ?? [];
  }

  /// Get per-peg sight marks as JSON (for storage)
  Map<int, String>? getPegSightMarks() {
    if (_pegFlow == null) return null;
    final marks = <int, String>{};
    for (final peg in _pegFlow!.pegs) {
      if (peg.sightMarkUsed != null) {
        marks[peg.pegIndex] = peg.sightMarkUsed!;
      }
    }
    return marks.isEmpty ? null : marks;
  }

  /// Reset for a new target
  void reset() {
    _pegFlow = null;
    _currentRecommendation = null;
    _baseFlatMark = null;
    _courseDifferential = null;
    _courseDataPoints = 0;
    notifyListeners();
  }
}
