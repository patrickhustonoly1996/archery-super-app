import 'dart:convert';

/// Unit for brace height measurements
enum BraceHeightUnit {
  millimeters('mm'),
  inches('in');

  final String abbreviation;
  const BraceHeightUnit(this.abbreviation);

  static BraceHeightUnit fromString(String? value) {
    if (value == 'inches' || value == 'in') return BraceHeightUnit.inches;
    return BraceHeightUnit.millimeters;
  }

  String toDbString() => this == BraceHeightUnit.inches ? 'inches' : 'millimeters';

  /// Get the opposite unit
  BraceHeightUnit get other => this == millimeters ? inches : millimeters;

  /// Convert a brace height to the other unit
  double convert(double value) {
    if (this == millimeters) {
      // mm to inches
      return value / 25.4;
    } else {
      // inches to mm
      return value * 25.4;
    }
  }

  /// Convert to millimeters (for consistent storage)
  double toMillimeters(double value) {
    if (this == inches) return value * 25.4;
    return value;
  }

  /// Convert from millimeters to this unit
  double fromMillimeters(double mm) {
    if (this == inches) return mm / 25.4;
    return mm;
  }

  /// Typical brace height ranges for this unit
  String get typicalRange {
    if (this == millimeters) {
      return '210-240 mm (recurve)';
    } else {
      return '8.25-9.5" (recurve)';
    }
  }
}

/// Comprehensive bow specifications for recurve and compound bows
class BowSpecifications {
  // === PRIMARY SETTINGS (Most Important) ===
  final double? braceHeight; // stored in mm internally
  final BraceHeightUnit braceHeightUnit; // user's preferred display unit
  final double? nockingPoint; // mm above square (positive = above)
  final double? tillerTop; // mm
  final double? tillerBottom; // mm

  // === RISER ===
  final String? riserModel;
  final String? riserLength; // "23", "25", "27" inches

  // === LIMBS ===
  final String? limbModel;
  final String? limbLength; // "short", "medium", "long"
  final double? markedLimbWeight; // weight printed on limbs (at 28")
  final double? drawWeightOnFingers; // actual draw weight at your draw length (recurve)
  final double? peakWeight; // peak weight on cams (compound)

  // === STRING ===
  final String? stringMaterial; // "8125", "BCY-X", "Fast Flight", etc.
  final int? stringStrands; // typically 14-20

  // === BUTTON/PLUNGER ===
  final String? buttonModel;
  final String? buttonSpringTension; // "soft", "medium", "stiff" or number
  final String? centreShot; // "straight", "half_point_out", "full_point_out", "1.5_points_out"

  // === CLICKER ===
  final String? clickerModel;
  final double? clickerPosition; // mm from button center

  // === SIGHT ===
  final String? sightModel;
  final String? sightExtensionLength; // inches

  // === STABILIZERS ===
  final double? longRodLength; // inches
  final double? sideRodLength; // inches
  final double? vBarAngle; // degrees
  final String? stabilizerWeights; // description of weights

  // === ARROW SPECS (linked to quiver but often recorded with bow) ===
  final String? arrowModel;
  final String? arrowSpine; // e.g., "600", "700", "800"
  final double? arrowLength; // inches

  // === NOTES ===
  final String? notes;

  BowSpecifications({
    this.braceHeight,
    this.braceHeightUnit = BraceHeightUnit.millimeters,
    this.nockingPoint,
    this.tillerTop,
    this.tillerBottom,
    this.riserModel,
    this.riserLength,
    this.limbModel,
    this.limbLength,
    this.markedLimbWeight,
    this.drawWeightOnFingers,
    this.peakWeight,
    this.stringMaterial,
    this.stringStrands,
    this.buttonModel,
    this.buttonSpringTension,
    this.centreShot,
    this.clickerModel,
    this.clickerPosition,
    this.sightModel,
    this.sightExtensionLength,
    this.longRodLength,
    this.sideRodLength,
    this.vBarAngle,
    this.stabilizerWeights,
    this.arrowModel,
    this.arrowSpine,
    this.arrowLength,
    this.notes,
  });

  factory BowSpecifications.fromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return BowSpecifications();
    }
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return BowSpecifications.fromMap(map);
    } catch (e) {
      return BowSpecifications();
    }
  }

  /// Create from a Bow object, reading from both dedicated columns and JSON settings.
  /// Dedicated columns take precedence over JSON settings.
  factory BowSpecifications.fromBow(dynamic bow) {
    // First load from JSON settings as base
    final base = BowSpecifications.fromJson(bow.settings as String?);

    // Override with dedicated columns if present
    return BowSpecifications(
      // Primary tuning - prefer dedicated columns
      braceHeight: bow.braceHeight as double? ?? base.braceHeight,
      braceHeightUnit: base.braceHeightUnit,
      nockingPoint: bow.nockingPointHeight as double? ?? base.nockingPoint,
      tillerTop: bow.tillerTop as double? ?? base.tillerTop,
      tillerBottom: bow.tillerBottom as double? ?? base.tillerBottom,
      // Equipment - prefer dedicated columns
      riserModel: bow.riserModel as String? ?? base.riserModel,
      limbModel: bow.limbModel as String? ?? base.limbModel,
      markedLimbWeight: bow.poundage as double? ?? base.markedLimbWeight,
      drawWeightOnFingers: base.drawWeightOnFingers,
      peakWeight: base.peakWeight,
      // Button/clicker - prefer dedicated columns
      buttonSpringTension: bow.buttonTension as String? ?? base.buttonSpringTension,
      clickerPosition: bow.clickerPosition as double? ?? base.clickerPosition,
      // Carry over fields only in JSON
      riserLength: base.riserLength,
      limbLength: base.limbLength,
      stringMaterial: base.stringMaterial,
      stringStrands: base.stringStrands,
      buttonModel: base.buttonModel,
      centreShot: base.centreShot,
      clickerModel: base.clickerModel,
      sightModel: base.sightModel,
      sightExtensionLength: base.sightExtensionLength,
      longRodLength: base.longRodLength,
      sideRodLength: base.sideRodLength,
      vBarAngle: base.vBarAngle,
      stabilizerWeights: base.stabilizerWeights,
      arrowModel: base.arrowModel,
      arrowSpine: base.arrowSpine,
      arrowLength: base.arrowLength,
      notes: base.notes,
    );
  }

  factory BowSpecifications.fromMap(Map<String, dynamic> map) {
    return BowSpecifications(
      braceHeight: _parseDouble(map['braceHeight']),
      braceHeightUnit: BraceHeightUnit.fromString(map['braceHeightUnit'] as String?),
      nockingPoint: _parseDouble(map['nockingPoint']),
      tillerTop: _parseDouble(map['tillerTop']),
      tillerBottom: _parseDouble(map['tillerBottom']),
      riserModel: map['riserModel'] as String?,
      riserLength: map['riserLength'] as String?,
      limbModel: map['limbModel'] as String?,
      limbLength: map['limbLength'] as String?,
      // Support both old 'limbPoundage' and new field names
      markedLimbWeight: _parseDouble(map['markedLimbWeight'] ?? map['limbPoundage']),
      drawWeightOnFingers: _parseDouble(map['drawWeightOnFingers']),
      peakWeight: _parseDouble(map['peakWeight']),
      stringMaterial: map['stringMaterial'] as String?,
      stringStrands: _parseInt(map['stringStrands']),
      buttonModel: map['buttonModel'] as String?,
      buttonSpringTension: map['buttonSpringTension'] as String?,
      centreShot: map['centreShot'] as String?,
      clickerModel: map['clickerModel'] as String?,
      clickerPosition: _parseDouble(map['clickerPosition']),
      sightModel: map['sightModel'] as String?,
      sightExtensionLength: map['sightExtensionLength'] as String?,
      longRodLength: _parseDouble(map['longRodLength']),
      sideRodLength: _parseDouble(map['sideRodLength']),
      vBarAngle: _parseDouble(map['vBarAngle']),
      stabilizerWeights: map['stabilizerWeights'] as String?,
      arrowModel: map['arrowModel'] as String?,
      arrowSpine: map['arrowSpine'] as String?,
      arrowLength: _parseDouble(map['arrowLength']),
      notes: map['notes'] as String?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (braceHeight != null) 'braceHeight': braceHeight,
      'braceHeightUnit': braceHeightUnit.toDbString(),
      if (nockingPoint != null) 'nockingPoint': nockingPoint,
      if (tillerTop != null) 'tillerTop': tillerTop,
      if (tillerBottom != null) 'tillerBottom': tillerBottom,
      if (riserModel != null) 'riserModel': riserModel,
      if (riserLength != null) 'riserLength': riserLength,
      if (limbModel != null) 'limbModel': limbModel,
      if (limbLength != null) 'limbLength': limbLength,
      if (markedLimbWeight != null) 'markedLimbWeight': markedLimbWeight,
      if (drawWeightOnFingers != null) 'drawWeightOnFingers': drawWeightOnFingers,
      if (peakWeight != null) 'peakWeight': peakWeight,
      if (stringMaterial != null) 'stringMaterial': stringMaterial,
      if (stringStrands != null) 'stringStrands': stringStrands,
      if (buttonModel != null) 'buttonModel': buttonModel,
      if (buttonSpringTension != null) 'buttonSpringTension': buttonSpringTension,
      if (centreShot != null) 'centreShot': centreShot,
      if (clickerModel != null) 'clickerModel': clickerModel,
      if (clickerPosition != null) 'clickerPosition': clickerPosition,
      if (sightModel != null) 'sightModel': sightModel,
      if (sightExtensionLength != null) 'sightExtensionLength': sightExtensionLength,
      if (longRodLength != null) 'longRodLength': longRodLength,
      if (sideRodLength != null) 'sideRodLength': sideRodLength,
      if (vBarAngle != null) 'vBarAngle': vBarAngle,
      if (stabilizerWeights != null) 'stabilizerWeights': stabilizerWeights,
      if (arrowModel != null) 'arrowModel': arrowModel,
      if (arrowSpine != null) 'arrowSpine': arrowSpine,
      if (arrowLength != null) 'arrowLength': arrowLength,
      if (notes != null) 'notes': notes,
    };
  }

  String toJson() {
    final map = toMap();
    if (map.isEmpty) return '';
    return json.encode(map);
  }

  BowSpecifications copyWith({
    double? braceHeight,
    BraceHeightUnit? braceHeightUnit,
    double? nockingPoint,
    double? tillerTop,
    double? tillerBottom,
    String? riserModel,
    String? riserLength,
    String? limbModel,
    String? limbLength,
    double? markedLimbWeight,
    double? drawWeightOnFingers,
    double? peakWeight,
    String? stringMaterial,
    int? stringStrands,
    String? buttonModel,
    String? buttonSpringTension,
    String? centreShot,
    String? clickerModel,
    double? clickerPosition,
    String? sightModel,
    String? sightExtensionLength,
    double? longRodLength,
    double? sideRodLength,
    double? vBarAngle,
    String? stabilizerWeights,
    String? arrowModel,
    String? arrowSpine,
    double? arrowLength,
    String? notes,
    bool clearBraceHeight = false,
    bool clearNockingPoint = false,
    bool clearTillerTop = false,
    bool clearTillerBottom = false,
  }) {
    return BowSpecifications(
      braceHeight: clearBraceHeight ? null : (braceHeight ?? this.braceHeight),
      braceHeightUnit: braceHeightUnit ?? this.braceHeightUnit,
      nockingPoint: clearNockingPoint ? null : (nockingPoint ?? this.nockingPoint),
      tillerTop: clearTillerTop ? null : (tillerTop ?? this.tillerTop),
      tillerBottom: clearTillerBottom ? null : (tillerBottom ?? this.tillerBottom),
      riserModel: riserModel ?? this.riserModel,
      riserLength: riserLength ?? this.riserLength,
      limbModel: limbModel ?? this.limbModel,
      limbLength: limbLength ?? this.limbLength,
      markedLimbWeight: markedLimbWeight ?? this.markedLimbWeight,
      drawWeightOnFingers: drawWeightOnFingers ?? this.drawWeightOnFingers,
      peakWeight: peakWeight ?? this.peakWeight,
      stringMaterial: stringMaterial ?? this.stringMaterial,
      stringStrands: stringStrands ?? this.stringStrands,
      buttonModel: buttonModel ?? this.buttonModel,
      buttonSpringTension: buttonSpringTension ?? this.buttonSpringTension,
      centreShot: centreShot ?? this.centreShot,
      clickerModel: clickerModel ?? this.clickerModel,
      clickerPosition: clickerPosition ?? this.clickerPosition,
      sightModel: sightModel ?? this.sightModel,
      sightExtensionLength: sightExtensionLength ?? this.sightExtensionLength,
      longRodLength: longRodLength ?? this.longRodLength,
      sideRodLength: sideRodLength ?? this.sideRodLength,
      vBarAngle: vBarAngle ?? this.vBarAngle,
      stabilizerWeights: stabilizerWeights ?? this.stabilizerWeights,
      arrowModel: arrowModel ?? this.arrowModel,
      arrowSpine: arrowSpine ?? this.arrowSpine,
      arrowLength: arrowLength ?? this.arrowLength,
      notes: notes ?? this.notes,
    );
  }

  /// Calculate tiller difference (top - bottom)
  double? get tillerDifference {
    if (tillerTop == null || tillerBottom == null) return null;
    return tillerTop! - tillerBottom!;
  }

  /// Calculate total bow length based on riser and limb length
  String? get totalBowLength {
    if (riserLength == null || limbLength == null) return null;

    final riserInches = double.tryParse(riserLength!);
    if (riserInches == null) return null;

    int limbAddition;
    switch (limbLength!.toLowerCase()) {
      case 'short':
        limbAddition = 66 - 25; // 66" bow with 25" riser
        break;
      case 'medium':
        limbAddition = 68 - 25; // 68" bow with 25" riser
        break;
      case 'long':
        limbAddition = 70 - 25; // 70" bow with 25" riser
        break;
      default:
        return null;
    }

    final totalLength = riserInches + limbAddition;
    return '${totalLength.toStringAsFixed(0)}"';
  }

  /// Check if has any primary specs set
  bool get hasPrimarySpecs =>
      braceHeight != null ||
      nockingPoint != null ||
      tillerTop != null ||
      tillerBottom != null;

  /// Check if has any specs at all
  bool get hasAnySpecs => toMap().isNotEmpty;

  /// Get a summary string for display
  String get summaryText {
    final parts = <String>[];

    if (braceHeight != null) {
      final displayValue = braceHeightUnit.fromMillimeters(braceHeight!);
      final decimals = braceHeightUnit == BraceHeightUnit.inches ? 2 : 1;
      parts.add('BH: ${displayValue.toStringAsFixed(decimals)}${braceHeightUnit.abbreviation}');
    }
    if (tillerTop != null && tillerBottom != null) {
      final diff = tillerDifference!;
      parts.add('Tiller: ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}mm');
    }
    // Show whichever poundage is available
    if (drawWeightOnFingers != null) {
      parts.add('${drawWeightOnFingers!.toStringAsFixed(0)}# OTF');
    } else if (markedLimbWeight != null) {
      parts.add('${markedLimbWeight!.toStringAsFixed(0)}#');
    } else if (peakWeight != null) {
      parts.add('${peakWeight!.toStringAsFixed(0)}# peak');
    }

    return parts.isEmpty ? 'No specs recorded' : parts.join(' | ');
  }

  /// Get brace height in the user's preferred unit
  double? get braceHeightInPreferredUnit {
    if (braceHeight == null) return null;
    return braceHeightUnit.fromMillimeters(braceHeight!);
  }

  /// Get the primary draw weight (whichever is set)
  double? get primaryDrawWeight => drawWeightOnFingers ?? markedLimbWeight ?? peakWeight;
}

/// Centre shot position options
class CentreShotOptions {
  static const String straight = 'straight';
  static const String halfPointOut = 'half_point_out';
  static const String fullPointOut = 'full_point_out';
  static const String oneAndHalfPointsOut = '1.5_points_out';

  static String displayName(String? value) {
    switch (value) {
      case straight:
        return 'Straight';
      case halfPointOut:
        return '1/2 point outside';
      case fullPointOut:
        return 'Full point outside';
      case oneAndHalfPointsOut:
        return '1.5 points outside';
      default:
        return 'Not set';
    }
  }

  static const List<String> values = [
    straight,
    halfPointOut,
    fullPointOut,
    oneAndHalfPointsOut,
  ];
}

/// Limb length options
class LimbLengthOptions {
  static const String short = 'short';
  static const String medium = 'medium';
  static const String long = 'long';

  static String displayName(String? value) {
    switch (value) {
      case short:
        return 'Short (66")';
      case medium:
        return 'Medium (68")';
      case long:
        return 'Long (70")';
      default:
        return 'Not set';
    }
  }

  static const List<String> values = [short, medium, long];
}

/// Riser length options
class RiserLengthOptions {
  static const List<String> values = ['23', '25', '27'];

  static String displayName(String? value) {
    if (value == null) return 'Not set';
    return '$value"';
  }
}
