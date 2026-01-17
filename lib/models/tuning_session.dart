import 'dart:convert';

/// Model for tuning session data
class TuningSessionModel {
  final String id;
  final String? bowId;
  final DateTime date;
  final String bowType; // 'recurve', 'compound'
  final String tuningType; // 'paper', 'bare_shaft', 'walk_back', 'french', etc.
  final Map<String, dynamic>? results; // Tuning results as structured data
  final String? notes;
  final DateTime createdAt;

  TuningSessionModel({
    required this.id,
    this.bowId,
    required this.date,
    required this.bowType,
    required this.tuningType,
    this.results,
    this.notes,
    required this.createdAt,
  });

  factory TuningSessionModel.fromJson(Map<String, dynamic> json) {
    return TuningSessionModel(
      id: json['id'] as String,
      bowId: json['bowId'] as String?,
      date: DateTime.parse(json['date'] as String),
      bowType: json['bowType'] as String,
      tuningType: json['tuningType'] as String,
      results: json['results'] != null
          ? (json['results'] is String
              ? jsonDecode(json['results'] as String) as Map<String, dynamic>
              : json['results'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bowId': bowId,
      'date': date.toIso8601String(),
      'bowType': bowType,
      'tuningType': tuningType,
      'results': results,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String? get resultsJson => results != null ? jsonEncode(results) : null;

  TuningSessionModel copyWith({
    String? id,
    String? bowId,
    DateTime? date,
    String? bowType,
    String? tuningType,
    Map<String, dynamic>? results,
    String? notes,
    DateTime? createdAt,
  }) {
    return TuningSessionModel(
      id: id ?? this.id,
      bowId: bowId ?? this.bowId,
      date: date ?? this.date,
      bowType: bowType ?? this.bowType,
      tuningType: tuningType ?? this.tuningType,
      results: results ?? this.results,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Bow types
class BowType {
  static const String recurve = 'recurve';
  static const String compound = 'compound';

  static String displayName(String type) {
    switch (type) {
      case recurve:
        return 'Recurve';
      case compound:
        return 'Compound';
      default:
        return type;
    }
  }
}

/// Tuning types
class TuningType {
  // Common to both
  static const String paperTune = 'paper';
  static const String bareShaft = 'bare_shaft';

  // Recurve-specific
  static const String walkBack = 'walk_back';
  static const String braceHeight = 'brace_height';
  static const String nockPoint = 'nock_point';
  static const String tiller = 'tiller';
  static const String centershot = 'centershot';
  static const String plungerTension = 'plunger_tension';

  // Compound-specific
  static const String frenchTune = 'french';
  static const String camTiming = 'cam_timing';
  static const String yokeTuning = 'yoke_tuning';
  static const String restPosition = 'rest_position';
  static const String peepHeight = 'peep_height';

  static String displayName(String type) {
    switch (type) {
      case paperTune:
        return 'Paper Tune';
      case bareShaft:
        return 'Bare Shaft';
      case walkBack:
        return 'Walk-Back';
      case braceHeight:
        return 'Brace Height';
      case nockPoint:
        return 'Nock Point';
      case tiller:
        return 'Tiller';
      case centershot:
        return 'Centershot';
      case plungerTension:
        return 'Plunger Tension';
      case frenchTune:
        return 'French Tune';
      case camTiming:
        return 'Cam Timing';
      case yokeTuning:
        return 'Yoke Tuning';
      case restPosition:
        return 'Rest Position';
      case peepHeight:
        return 'Peep Height';
      default:
        return type;
    }
  }

  static List<String> getTypesForBow(String bowType) {
    if (bowType == BowType.recurve) {
      return [
        braceHeight,
        nockPoint,
        tiller,
        centershot,
        plungerTension,
        paperTune,
        bareShaft,
        walkBack,
      ];
    } else {
      return [
        camTiming,
        yokeTuning,
        restPosition,
        peepHeight,
        paperTune,
        bareShaft,
        frenchTune,
      ];
    }
  }
}

/// Paper tune tear directions
class TearDirection {
  static const String up = 'up';
  static const String down = 'down';
  static const String left = 'left';
  static const String right = 'right';
  static const String clean = 'clean';
  static const String upLeft = 'up_left';
  static const String upRight = 'up_right';
  static const String downLeft = 'down_left';
  static const String downRight = 'down_right';

  static String displayName(String direction) {
    switch (direction) {
      case up:
        return 'Up';
      case down:
        return 'Down';
      case left:
        return 'Left';
      case right:
        return 'Right';
      case clean:
        return 'Clean';
      case upLeft:
        return 'Up-Left';
      case upRight:
        return 'Up-Right';
      case downLeft:
        return 'Down-Left';
      case downRight:
        return 'Down-Right';
      default:
        return direction;
    }
  }
}

/// Paper tune tear sizes
class TearSize {
  static const String small = 'small';
  static const String medium = 'medium';
  static const String large = 'large';

  static String displayName(String size) {
    switch (size) {
      case small:
        return 'Small';
      case medium:
        return 'Medium';
      case large:
        return 'Large';
      default:
        return size;
    }
  }
}

/// Paper tune results structure
class PaperTuneResults {
  final String direction;
  final String size;

  PaperTuneResults({
    required this.direction,
    required this.size,
  });

  factory PaperTuneResults.fromJson(Map<String, dynamic> json) {
    return PaperTuneResults(
      direction: json['direction'] as String? ?? TearDirection.clean,
      size: json['size'] as String? ?? TearSize.small,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'direction': direction,
      'size': size,
    };
  }
}
