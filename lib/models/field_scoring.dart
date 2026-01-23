import 'dart:convert';
import 'field_course.dart';

/// Scoring zone for field archery targets
enum FieldScoringZone {
  /// X-ring (inner 5) - counts as 5 but tracked separately
  x(5, 'X'),
  /// 5-ring (center)
  five(5, '5'),
  /// 4-ring
  four(4, '4'),
  /// 3-ring (outer scoring zone)
  three(3, '3'),
  /// 2-ring (expert round only)
  two(2, '2'),
  /// 1-ring (expert round only)
  one(1, '1'),
  /// Miss
  miss(0, 'M');

  final int score;
  final String display;

  const FieldScoringZone(this.score, this.display);

  static FieldScoringZone fromScore(int score, {bool isX = false}) {
    if (isX) return FieldScoringZone.x;
    switch (score) {
      case 5:
        return FieldScoringZone.five;
      case 4:
        return FieldScoringZone.four;
      case 3:
        return FieldScoringZone.three;
      case 2:
        return FieldScoringZone.two;
      case 1:
        return FieldScoringZone.one;
      default:
        return FieldScoringZone.miss;
    }
  }

  static FieldScoringZone fromString(String value) {
    return FieldScoringZone.values.firstWhere(
      (z) => z.name == value || z.display == value,
      orElse: () => FieldScoringZone.miss,
    );
  }
}

/// Animal round hit zones
enum AnimalHitZone {
  /// Vital area (kill zone) - highest score
  vital('Vital', 'V'),
  /// Wound area - reduced score
  wound('Wound', 'W'),
  /// Miss - no score
  miss('Miss', 'M');

  final String displayName;
  final String abbreviation;

  const AnimalHitZone(this.displayName, this.abbreviation);

  static AnimalHitZone fromString(String value) {
    return AnimalHitZone.values.firstWhere(
      (z) => z.name == value || z.abbreviation == value,
      orElse: () => AnimalHitZone.miss,
    );
  }
}

/// Score for a single arrow in field/hunter/expert rounds
class FieldArrowScore {
  final int arrowNumber; // 1-4
  final FieldScoringZone zone;
  final int? pegPosition; // For walk-down: which peg (1-4)

  const FieldArrowScore({
    required this.arrowNumber,
    required this.zone,
    this.pegPosition,
  });

  int get score => zone.score;
  bool get isX => zone == FieldScoringZone.x;

  Map<String, dynamic> toJson() => {
        'arrowNumber': arrowNumber,
        'zone': zone.name,
        'pegPosition': pegPosition,
      };

  factory FieldArrowScore.fromJson(Map<String, dynamic> json) {
    return FieldArrowScore(
      arrowNumber: json['arrowNumber'] as int,
      zone: FieldScoringZone.fromString(json['zone'] as String),
      pegPosition: json['pegPosition'] as int?,
    );
  }

  @override
  String toString() => 'Arrow $arrowNumber: ${zone.display}';
}

/// Score for a single arrow in animal rounds
class AnimalArrowScore {
  final int station; // 1, 2, or 3 (walk-up station)
  final AnimalHitZone zone;

  const AnimalArrowScore({
    required this.station,
    required this.zone,
  });

  /// Calculate score based on station and zone
  /// Station 1 (furthest): Vital=21, Wound=20, Miss=0
  /// Station 2 (middle): Vital=17, Wound=16, Miss=0 (or 18 first-arrow rule)
  /// Station 3 (closest): Vital=13, Wound=12, Miss=0 (or 14 first-arrow rule)
  int getScore({bool isFirstScoringArrow = true}) {
    if (zone == AnimalHitZone.miss) return 0;

    // IFAA first-scoring-arrow rule
    if (isFirstScoringArrow) {
      switch (station) {
        case 1:
          return zone == AnimalHitZone.vital ? 21 : 20;
        case 2:
          return zone == AnimalHitZone.vital ? 18 : 16;
        case 3:
          return zone == AnimalHitZone.vital ? 14 : 12;
        default:
          return 0;
      }
    } else {
      // Subsequent arrows (practice tracking only, not official)
      switch (station) {
        case 1:
          return zone == AnimalHitZone.vital ? 21 : 20;
        case 2:
          return zone == AnimalHitZone.vital ? 17 : 16;
        case 3:
          return zone == AnimalHitZone.vital ? 13 : 12;
        default:
          return 0;
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'station': station,
        'zone': zone.name,
      };

  factory AnimalArrowScore.fromJson(Map<String, dynamic> json) {
    return AnimalArrowScore(
      station: json['station'] as int,
      zone: AnimalHitZone.fromString(json['zone'] as String),
    );
  }

  @override
  String toString() => 'Station $station: ${zone.displayName}';
}

/// 3D target scoring zones
enum Scoring3DZone {
  /// Center kill zone (11 for standard, 20 for hunting)
  centerKill(11, '11'),
  /// Kill zone (10 for standard, 18 for hunting wound)
  kill(10, '10'),
  /// Vital (8 for standard)
  vital(8, '8'),
  /// Wound (5 for standard)
  wound(5, '5'),
  /// Miss
  miss(0, 'M');

  final int standardScore;
  final String display;

  const Scoring3DZone(this.standardScore, this.display);

  /// Get score for standard 3D round (11-10-8-5)
  int get standardRoundScore => standardScore;

  /// Get score for hunting 3D round (20-18)
  int get huntingRoundScore {
    switch (this) {
      case Scoring3DZone.centerKill:
        return 20;
      case Scoring3DZone.kill:
      case Scoring3DZone.vital:
        return 18;
      default:
        return 0;
    }
  }

  static Scoring3DZone fromString(String value) {
    return Scoring3DZone.values.firstWhere(
      (z) => z.name == value || z.display == value,
      orElse: () => Scoring3DZone.miss,
    );
  }
}

/// Score for a single arrow in 3D rounds
class Score3DArrowScore {
  final int arrowNumber;
  final Scoring3DZone zone;

  const Score3DArrowScore({
    required this.arrowNumber,
    required this.zone,
  });

  Map<String, dynamic> toJson() => {
        'arrowNumber': arrowNumber,
        'zone': zone.name,
      };

  factory Score3DArrowScore.fromJson(Map<String, dynamic> json) {
    return Score3DArrowScore(
      arrowNumber: json['arrowNumber'] as int,
      zone: Scoring3DZone.fromString(json['zone'] as String),
    );
  }
}

/// Complete score for a single target in a field session
class FieldTargetScore {
  final String id;
  final String sessionId;
  final String courseTargetId;
  final int targetNumber;
  final int totalScore;
  final int xCount;
  final List<FieldArrowScore> arrowScores;
  final String? sightMarkUsed;
  final DateTime? completedAt;

  const FieldTargetScore({
    required this.id,
    required this.sessionId,
    required this.courseTargetId,
    required this.targetNumber,
    required this.totalScore,
    this.xCount = 0,
    required this.arrowScores,
    this.sightMarkUsed,
    this.completedAt,
  });

  /// Calculate total from arrow scores
  static int calculateTotal(List<FieldArrowScore> arrows) {
    return arrows.fold(0, (sum, a) => sum + a.score);
  }

  /// Count X's from arrow scores
  static int calculateXCount(List<FieldArrowScore> arrows) {
    return arrows.where((a) => a.isX).length;
  }

  /// Create arrow scores JSON
  static String arrowScoresToJson(List<FieldArrowScore> arrows) {
    return jsonEncode(arrows.map((a) => a.toJson()).toList());
  }

  /// Parse arrow scores from JSON
  static List<FieldArrowScore> arrowScoresFromJson(String json) {
    final list = jsonDecode(json) as List;
    return list.map((a) => FieldArrowScore.fromJson(a as Map<String, dynamic>)).toList();
  }

  FieldTargetScore copyWith({
    String? id,
    String? sessionId,
    String? courseTargetId,
    int? targetNumber,
    int? totalScore,
    int? xCount,
    List<FieldArrowScore>? arrowScores,
    String? sightMarkUsed,
    DateTime? completedAt,
  }) {
    return FieldTargetScore(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      courseTargetId: courseTargetId ?? this.courseTargetId,
      targetNumber: targetNumber ?? this.targetNumber,
      totalScore: totalScore ?? this.totalScore,
      xCount: xCount ?? this.xCount,
      arrowScores: arrowScores ?? this.arrowScores,
      sightMarkUsed: sightMarkUsed ?? this.sightMarkUsed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Complete score for an animal round target
class AnimalTargetScore {
  final String id;
  final String sessionId;
  final String courseTargetId;
  final int targetNumber;
  final int totalScore;
  final List<AnimalArrowScore> arrowScores;
  final int? firstScoringStation; // Which station got the first hit
  final String? sightMarkUsed;
  final DateTime? completedAt;

  const AnimalTargetScore({
    required this.id,
    required this.sessionId,
    required this.courseTargetId,
    required this.targetNumber,
    required this.totalScore,
    required this.arrowScores,
    this.firstScoringStation,
    this.sightMarkUsed,
    this.completedAt,
  });

  /// Whether the target was hit (any scoring arrow)
  bool get wasHit => arrowScores.any((a) => a.zone != AnimalHitZone.miss);

  /// Number of arrows shot (1-3)
  int get arrowsShot => arrowScores.length;

  /// Create arrow scores JSON
  static String arrowScoresToJson(List<AnimalArrowScore> arrows) {
    return jsonEncode(arrows.map((a) => a.toJson()).toList());
  }

  /// Parse arrow scores from JSON
  static List<AnimalArrowScore> arrowScoresFromJson(String json) {
    final list = jsonDecode(json) as List;
    return list.map((a) => AnimalArrowScore.fromJson(a as Map<String, dynamic>)).toList();
  }
}

/// Scoring utilities for field archery
class FieldScoringUtils {
  /// Get available scoring zones for a round type
  static List<FieldScoringZone> getZonesForRoundType(FieldRoundType type) {
    switch (type) {
      case FieldRoundType.field:
      case FieldRoundType.hunter:
        return [
          FieldScoringZone.x,
          FieldScoringZone.five,
          FieldScoringZone.four,
          FieldScoringZone.three,
          FieldScoringZone.miss,
        ];
      case FieldRoundType.expert:
        return [
          FieldScoringZone.x,
          FieldScoringZone.five,
          FieldScoringZone.four,
          FieldScoringZone.three,
          FieldScoringZone.two,
          FieldScoringZone.one,
          FieldScoringZone.miss,
        ];
      case FieldRoundType.animal:
        // Animal uses different scoring - return empty
        return [];
      case FieldRoundType.marked3dStandard:
      case FieldRoundType.marked3dHunting:
        // 3D uses different scoring - return empty
        return [];
    }
  }

  /// Calculate max possible score for a target
  static int getMaxTargetScore(FieldRoundType type, int arrowCount) {
    switch (type) {
      case FieldRoundType.field:
      case FieldRoundType.hunter:
      case FieldRoundType.expert:
        return arrowCount * 5;
      case FieldRoundType.animal:
        return 21; // First arrow vital hit
      case FieldRoundType.marked3dStandard:
        return arrowCount * 11;
      case FieldRoundType.marked3dHunting:
        return 20;
    }
  }
}
