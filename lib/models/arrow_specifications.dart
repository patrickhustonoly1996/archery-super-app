import 'dart:convert';

/// Visual appearance of arrows for Auto-Plot identification
/// Used to identify "my arrows" among other archers' arrows
class ArrowAppearanceForAutoPlot {
  final String? fletchColor;
  final String? nockColor;
  final String? wrapColor;

  const ArrowAppearanceForAutoPlot({
    this.fletchColor,
    this.nockColor,
    this.wrapColor,
  });

  bool get hasAnyFeatures => fletchColor != null || nockColor != null || wrapColor != null;

  Map<String, dynamic> toJson() => {
        if (fletchColor != null) 'fletchColor': fletchColor,
        if (nockColor != null) 'nockColor': nockColor,
        if (wrapColor != null) 'wrapColor': wrapColor,
      };
}

/// Comprehensive arrow specifications for a quiver/arrow set
class ArrowSpecifications {
  // === SHAFT ===
  final String? shaftModel; // e.g., "Easton X10", "ACE", "ACG"
  final String? shaftSpine; // e.g., "600", "700", "800", "900", "1000"
  final double? shaftDiameter; // mm (e.g., 4.0, 5.0, 5.5)
  final double? cutLength; // inches - shaft end to shaft end
  final double? totalLength; // inches - total arrow length with point

  // === POINT ===
  final String? pointType; // "break_off", "glue_in", "screw_in"
  final int? pointWeight; // grains (e.g., 80, 100, 110, 120)
  final String? pointModel; // e.g., "Easton Break-Off", "TopHat"

  // === NOCK ===
  final String? nockType; // "pin", "push_in", "g_nock", "beiter"
  final String? nockModel; // e.g., "Beiter Pin Nock", "Easton G Nock"
  final String? nockSize; // e.g., "S", "M", "L" or specific size
  final String? nockColor;

  // === FLETCHING ===
  final String? fletchType; // "spin_wing", "shield", "parabolic", "blazer"
  final String? fletchModel; // e.g., "Kurly Vane", "Spin Wing", "Shield Cut"
  final double? fletchSize; // inches (e.g., 1.75, 2.0, 3.0)
  final double? fletchAngle; // degrees offset/helical
  final String? fletchColor;
  final int? fletchCount; // typically 3 or 4

  // === WRAP ===
  final bool? hasWrap;
  final String? wrapColor;
  final String? wrapModel;

  // === NOTES ===
  final String? notes;

  // === BARE SHAFTS ===
  final String? bareShafts; // e.g., "11, 12" or "11-12"

  ArrowSpecifications({
    this.shaftModel,
    this.shaftSpine,
    this.shaftDiameter,
    this.cutLength,
    this.totalLength,
    this.pointType,
    this.pointWeight,
    this.pointModel,
    this.nockType,
    this.nockModel,
    this.nockSize,
    this.nockColor,
    this.fletchType,
    this.fletchModel,
    this.fletchSize,
    this.fletchAngle,
    this.fletchColor,
    this.fletchCount,
    this.hasWrap,
    this.wrapColor,
    this.wrapModel,
    this.notes,
    this.bareShafts,
  });

  factory ArrowSpecifications.fromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return ArrowSpecifications();
    }
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return ArrowSpecifications.fromMap(map);
    } catch (e) {
      return ArrowSpecifications();
    }
  }

  factory ArrowSpecifications.fromMap(Map<String, dynamic> map) {
    return ArrowSpecifications(
      shaftModel: map['shaftModel'] as String?,
      shaftSpine: map['shaftSpine'] as String?,
      shaftDiameter: _parseDouble(map['shaftDiameter']),
      cutLength: _parseDouble(map['cutLength']),
      totalLength: _parseDouble(map['totalLength']),
      pointType: map['pointType'] as String?,
      pointWeight: _parseInt(map['pointWeight']),
      pointModel: map['pointModel'] as String?,
      nockType: map['nockType'] as String?,
      nockModel: map['nockModel'] as String?,
      nockSize: map['nockSize'] as String?,
      nockColor: map['nockColor'] as String?,
      fletchType: map['fletchType'] as String?,
      fletchModel: map['fletchModel'] as String?,
      fletchSize: _parseDouble(map['fletchSize']),
      fletchAngle: _parseDouble(map['fletchAngle']),
      fletchColor: map['fletchColor'] as String?,
      fletchCount: _parseInt(map['fletchCount']),
      hasWrap: map['hasWrap'] as bool?,
      wrapColor: map['wrapColor'] as String?,
      wrapModel: map['wrapModel'] as String?,
      notes: map['notes'] as String?,
      bareShafts: map['bareShafts'] as String?,
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
      if (shaftModel != null) 'shaftModel': shaftModel,
      if (shaftSpine != null) 'shaftSpine': shaftSpine,
      if (shaftDiameter != null) 'shaftDiameter': shaftDiameter,
      if (cutLength != null) 'cutLength': cutLength,
      if (totalLength != null) 'totalLength': totalLength,
      if (pointType != null) 'pointType': pointType,
      if (pointWeight != null) 'pointWeight': pointWeight,
      if (pointModel != null) 'pointModel': pointModel,
      if (nockType != null) 'nockType': nockType,
      if (nockModel != null) 'nockModel': nockModel,
      if (nockSize != null) 'nockSize': nockSize,
      if (nockColor != null) 'nockColor': nockColor,
      if (fletchType != null) 'fletchType': fletchType,
      if (fletchModel != null) 'fletchModel': fletchModel,
      if (fletchSize != null) 'fletchSize': fletchSize,
      if (fletchAngle != null) 'fletchAngle': fletchAngle,
      if (fletchColor != null) 'fletchColor': fletchColor,
      if (fletchCount != null) 'fletchCount': fletchCount,
      if (hasWrap != null) 'hasWrap': hasWrap,
      if (wrapColor != null) 'wrapColor': wrapColor,
      if (wrapModel != null) 'wrapModel': wrapModel,
      if (notes != null) 'notes': notes,
      if (bareShafts != null) 'bareShafts': bareShafts,
    };
  }

  String toJson() {
    final map = toMap();
    if (map.isEmpty) return '';
    return json.encode(map);
  }

  bool get hasAnySpecs => toMap().isNotEmpty;

  /// Get visual appearance for Auto-Plot arrow identification
  /// Returns colors that help identify "my arrows" among others
  ArrowAppearanceForAutoPlot get appearanceForAutoPlot {
    return ArrowAppearanceForAutoPlot(
      fletchColor: fletchColor,
      nockColor: nockColor,
      wrapColor: wrapColor,
    );
  }

  /// Get a summary string for display
  String get summaryText {
    final parts = <String>[];

    if (shaftModel != null) {
      parts.add(shaftModel!);
    }
    if (shaftSpine != null) {
      parts.add(shaftSpine!);
    }
    if (pointWeight != null) {
      parts.add('${pointWeight}gr');
    }

    return parts.isEmpty ? 'No specs recorded' : parts.join(' | ');
  }

  /// Get shaft description
  String? get shaftDescription {
    if (shaftModel == null && shaftSpine == null) return null;
    final parts = <String>[];
    if (shaftModel != null) parts.add(shaftModel!);
    if (shaftSpine != null) parts.add('Spine: $shaftSpine');
    if (shaftDiameter != null) parts.add('${shaftDiameter}mm');
    return parts.join(' • ');
  }

  /// Get length description
  String? get lengthDescription {
    if (cutLength == null && totalLength == null) return null;
    final parts = <String>[];
    if (cutLength != null) parts.add('Cut: ${cutLength!.toStringAsFixed(2)}"');
    if (totalLength != null) parts.add('Total: ${totalLength!.toStringAsFixed(2)}"');
    return parts.join(' • ');
  }
}

/// Point type options
class PointTypeOptions {
  static const String breakOff = 'break_off';
  static const String glueIn = 'glue_in';
  static const String screwIn = 'screw_in';

  static String displayName(String? value) {
    switch (value) {
      case breakOff:
        return 'Break-off';
      case glueIn:
        return 'Glue-in';
      case screwIn:
        return 'Screw-in';
      default:
        return 'Not set';
    }
  }

  static const List<String> values = [breakOff, glueIn, screwIn];
}

/// Nock type options
class NockTypeOptions {
  static const String pin = 'pin';
  static const String pushIn = 'push_in';
  static const String gNock = 'g_nock';
  static const String beiter = 'beiter';

  static String displayName(String? value) {
    switch (value) {
      case pin:
        return 'Pin Nock';
      case pushIn:
        return 'Push-in';
      case gNock:
        return 'G Nock';
      case beiter:
        return 'Beiter';
      default:
        return 'Not set';
    }
  }

  static const List<String> values = [pin, pushIn, gNock, beiter];
}

/// Fletching type options
class FletchTypeOptions {
  static const String spinWing = 'spin_wing';
  static const String shield = 'shield';
  static const String parabolic = 'parabolic';
  static const String blazer = 'blazer';
  static const String kurlyVane = 'kurly_vane';

  static String displayName(String? value) {
    switch (value) {
      case spinWing:
        return 'Spin Wing';
      case shield:
        return 'Shield';
      case parabolic:
        return 'Parabolic';
      case blazer:
        return 'Blazer';
      case kurlyVane:
        return 'Kurly Vane';
      default:
        return 'Not set';
    }
  }

  static const List<String> values = [spinWing, shield, parabolic, blazer, kurlyVane];
}

/// Common point weights
class CommonPointWeights {
  static const List<int> values = [60, 70, 80, 90, 100, 110, 120, 130, 140];
}

/// Common spine values (legacy - use EastonSpineValues for target arrows)
class CommonSpineValues {
  static const List<String> values = [
    '300', '340', '400', '450', '500', '550', '600', '650', '700', '750', '800', '850', '900', '1000', '1100', '1200'
  ];
}

/// Easton target arrow spine values (X10, ACE, ACG)
class EastonSpineValues {
  // X10 spines
  static const List<String> x10Spines = [
    '380', '400', '420', '450', '480', '520', '560', '600', '670', '750', '830', '900', '1000', '1050'
  ];

  // ACE spines
  static const List<String> aceSpines = [
    '370', '400', '430', '470', '520', '570', '620', '670', '720', '780', '850', '920', '1000', '1100'
  ];

  // Combined and sorted (unique values) - includes X10, ACE, and common AMO spines
  static const List<String> allSpines = [
    '300', '340', '370', '380', '400', '420', '430', '450', '470', '480', '500', '520', '550', '560', '570',
    '600', '620', '650', '670', '700', '720', '750', '780', '800', '830', '850', '900', '920', '1000', '1050', '1100', '1200'
  ];
}
