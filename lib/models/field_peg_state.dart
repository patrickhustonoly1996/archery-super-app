import 'field_course_target.dart';
import 'field_scoring.dart';
import 'sight_mark.dart';

/// Per-peg state during field scoring
class FieldPegState {
  final int pegIndex; // 0-3
  final double distance;
  final DistanceUnit unit;
  final double? angleDegrees;
  final String? angleSource; // 'manual' or 'gyroscope'
  final double? sightMarkRecommended;
  final String? sightMarkUsed;
  final FieldArrowScore? arrowScore;
  final bool isPoorShot;
  final String? poorShotDirection; // high/low/left/right

  const FieldPegState({
    required this.pegIndex,
    required this.distance,
    required this.unit,
    this.angleDegrees,
    this.angleSource,
    this.sightMarkRecommended,
    this.sightMarkUsed,
    this.arrowScore,
    this.isPoorShot = false,
    this.poorShotDirection,
  });

  bool get isScored => arrowScore != null;
  bool get hasAngle => angleDegrees != null;
  bool get hasSightMark => sightMarkRecommended != null;

  /// Display string for distance
  String get distanceDisplay =>
      '${distance.toStringAsFixed(0)}${unit.abbreviation}';

  FieldPegState copyWith({
    int? pegIndex,
    double? distance,
    DistanceUnit? unit,
    double? angleDegrees,
    String? angleSource,
    double? sightMarkRecommended,
    String? sightMarkUsed,
    FieldArrowScore? arrowScore,
    bool? isPoorShot,
    String? poorShotDirection,
  }) {
    return FieldPegState(
      pegIndex: pegIndex ?? this.pegIndex,
      distance: distance ?? this.distance,
      unit: unit ?? this.unit,
      angleDegrees: angleDegrees ?? this.angleDegrees,
      angleSource: angleSource ?? this.angleSource,
      sightMarkRecommended: sightMarkRecommended ?? this.sightMarkRecommended,
      sightMarkUsed: sightMarkUsed ?? this.sightMarkUsed,
      arrowScore: arrowScore ?? this.arrowScore,
      isPoorShot: isPoorShot ?? this.isPoorShot,
      poorShotDirection: poorShotDirection ?? this.poorShotDirection,
    );
  }

  @override
  String toString() =>
      'Peg $pegIndex: $distanceDisplay${angleDegrees != null ? " @ ${angleDegrees!.toStringAsFixed(1)}°" : ""}${isScored ? " = ${arrowScore!.score}" : ""}';
}

/// Aggregate state for a target's peg flow
class FieldTargetPegFlow {
  final String courseTargetId;
  final int targetNumber;
  final int faceSize; // cm
  final PegType pegType;
  final List<FieldPegState> pegs;
  final int currentPegIndex;
  final bool consistentAngleEnabled;
  final double? initialAngle; // angle from first peg when consistent mode is on

  const FieldTargetPegFlow({
    required this.courseTargetId,
    required this.targetNumber,
    required this.faceSize,
    required this.pegType,
    required this.pegs,
    this.currentPegIndex = 0,
    this.consistentAngleEnabled = false,
    this.initialAngle,
  });

  /// Current peg state
  FieldPegState get currentPeg => pegs[currentPegIndex];

  /// Whether this is a walk-down target with multiple pegs
  bool get isWalkDown => pegType == PegType.walkDown;

  /// Whether this is a single-peg target (4 arrows from same spot)
  bool get isSinglePeg => pegType == PegType.single || pegType == PegType.fan;

  /// Total number of pegs
  int get pegCount => pegs.length;

  /// Whether all pegs have been scored
  bool get isComplete => pegs.every((p) => p.isScored);

  /// Number of pegs scored so far
  int get scoredPegCount => pegs.where((p) => p.isScored).length;

  /// Total score across all pegs
  int get totalScore =>
      pegs.where((p) => p.isScored).fold(0, (sum, p) => sum + p.arrowScore!.score);

  /// Total X count across all pegs
  int get totalXCount =>
      pegs.where((p) => p.isScored && p.arrowScore!.isX).length;

  /// Get all arrow scores (for submission)
  List<FieldArrowScore> get allArrowScores =>
      pegs.where((p) => p.isScored).map((p) => p.arrowScore!).toList();

  /// Whether we can advance to next peg
  bool get canAdvance => currentPegIndex < pegs.length - 1 && currentPeg.isScored;

  /// Whether we're on the last peg
  bool get isLastPeg => currentPegIndex == pegs.length - 1;

  FieldTargetPegFlow copyWith({
    String? courseTargetId,
    int? targetNumber,
    int? faceSize,
    PegType? pegType,
    List<FieldPegState>? pegs,
    int? currentPegIndex,
    bool? consistentAngleEnabled,
    double? initialAngle,
  }) {
    return FieldTargetPegFlow(
      courseTargetId: courseTargetId ?? this.courseTargetId,
      targetNumber: targetNumber ?? this.targetNumber,
      faceSize: faceSize ?? this.faceSize,
      pegType: pegType ?? this.pegType,
      pegs: pegs ?? this.pegs,
      currentPegIndex: currentPegIndex ?? this.currentPegIndex,
      consistentAngleEnabled: consistentAngleEnabled ?? this.consistentAngleEnabled,
      initialAngle: initialAngle ?? this.initialAngle,
    );
  }
}
