import 'field_course_target.dart';

/// Round types for IFAA field archery
enum FieldRoundType {
  /// Standard field round - 28 targets, 4 arrows each, 5-4-3 scoring
  field('Field', 28, 4, 560),

  /// Hunter round - 28 targets, 4 arrows each, 5-4-3 scoring (unmarked distances)
  hunter('Hunter', 28, 4, 560),

  /// Expert round - 28 targets, 4 arrows each, 5-4-3-2-1 scoring
  expert('Expert', 28, 4, 560),

  /// Animal round - 28 targets, 1-3 arrows (walk-up), variable scoring
  animal('Animal', 28, 3, 588),

  /// 3D Standard - 28 targets, 2 arrows each, 11-10-8-5 scoring
  marked3dStandard('3D Standard', 28, 2, 616),

  /// 3D Hunting - 28 targets, 1 arrow each, 20 kill scoring
  marked3dHunting('3D Hunting', 28, 1, 560);

  final String displayName;
  final int targetCount;
  final int maxArrowsPerTarget;
  final int maxScore;

  const FieldRoundType(
      this.displayName, this.targetCount, this.maxArrowsPerTarget, this.maxScore);

  /// Get scoring description
  String get scoringDescription {
    switch (this) {
      case FieldRoundType.field:
      case FieldRoundType.hunter:
        return '5-4-3 scoring';
      case FieldRoundType.expert:
        return '5-4-3-2-1 scoring';
      case FieldRoundType.animal:
        return '21-20-18 (1st), 17-16-14 (2nd), 13-12-10 (3rd)';
      case FieldRoundType.marked3dStandard:
        return '11-10-8-5 scoring';
      case FieldRoundType.marked3dHunting:
        return '20 kill, 18 wound';
    }
  }

  /// Whether this round uses walk-up/walk-down mechanics
  bool get hasWalkMechanics => this == FieldRoundType.animal;

  /// Whether distances are marked (visible to archer)
  bool get hasMarkedDistances {
    switch (this) {
      case FieldRoundType.field:
      case FieldRoundType.expert:
      case FieldRoundType.marked3dStandard:
        return true;
      case FieldRoundType.hunter:
      case FieldRoundType.animal:
      case FieldRoundType.marked3dHunting:
        return false;
    }
  }

  static FieldRoundType fromString(String value) {
    return FieldRoundType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => FieldRoundType.field,
    );
  }
}

/// A field archery course definition (like a golf course)
/// Persists between sessions for reuse
class FieldCourse {
  final String id;
  final String name;
  final String? venueId;
  final FieldRoundType roundType;
  final int targetCount; // 14 or 28
  final String? notes;
  final List<FieldCourseTarget> targets;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const FieldCourse({
    required this.id,
    required this.name,
    this.venueId,
    required this.roundType,
    required this.targetCount,
    this.notes,
    this.targets = const [],
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Whether this is a half course (14 targets)
  bool get isHalfCourse => targetCount == 14;

  /// Whether the course is fully defined
  bool get isComplete => targets.length == targetCount;

  /// Get the next target number to define (1-indexed)
  int get nextTargetToDefine => targets.length + 1;

  /// Calculate max possible score for this course
  int get maxScore {
    if (!isComplete) {
      // Estimate based on round type
      return (roundType.maxScore * targetCount) ~/ 28;
    }
    return targets.fold(0, (sum, t) => sum + t.maxScore);
  }

  /// Get target by number (1-indexed)
  FieldCourseTarget? getTarget(int number) {
    return targets.cast<FieldCourseTarget?>().firstWhere(
          (t) => t?.targetNumber == number,
          orElse: () => null,
        );
  }

  FieldCourse copyWith({
    String? id,
    String? name,
    String? venueId,
    FieldRoundType? roundType,
    int? targetCount,
    String? notes,
    List<FieldCourseTarget>? targets,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return FieldCourse(
      id: id ?? this.id,
      name: name ?? this.name,
      venueId: venueId ?? this.venueId,
      roundType: roundType ?? this.roundType,
      targetCount: targetCount ?? this.targetCount,
      notes: notes ?? this.notes,
      targets: targets ?? this.targets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'FieldCourse($name, ${roundType.displayName}, $targetCount targets)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldCourse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
