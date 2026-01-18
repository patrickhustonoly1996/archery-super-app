import '../models/tuning_session.dart';

/// Provides measurement guides/checklists for equipment specifications
/// Links tuning measurement sequences to equipment log entries
class MeasurementGuides {
  /// Get the checklist items for a measurement type
  static List<String> getChecklist(String measurementType) {
    switch (measurementType) {
      case TuningType.braceHeight:
        return [
          'Measure from pivot point to string',
          'Use a brace height gauge or T-square',
          'Record measurement in mm',
          'Check against manufacturer spec',
        ];
      case TuningType.nockPoint:
        return [
          'Place T-square on arrow rest',
          'Measure from rest to bottom of nocking point',
          'Check square alignment',
          'Record measurement relative to square',
        ];
      case TuningType.tiller:
        return [
          'Measure top limb (pocket to string)',
          'Measure bottom limb (pocket to string)',
          'Calculate difference (top - bottom)',
          'Record both measurements',
        ];
      case TuningType.centershot:
        return [
          'Nock arrow and align at rest',
          'View from behind string',
          'Check point alignment through rest',
          'Adjust button/plunger position as needed',
        ];
      case TuningType.plungerTension:
        return [
          'Note current spring setting',
          'Test with finger pressure',
          'Adjust spring tension if needed',
          'Record final setting (turns/number)',
        ];
      default:
        return [];
    }
  }

  /// Get tips for a measurement type
  static List<String> getTips(String measurementType, String bowType) {
    switch (measurementType) {
      case TuningType.braceHeight:
        return [
          'Typical recurve: 215-230mm',
          'Higher = quieter, lower = faster',
          'Start at manufacturer recommendation',
        ];
      case TuningType.nockPoint:
        return [
          'Typical starting: 3-6mm above square',
          'Higher for finger shooting',
          'Adjust based on paper tune results',
        ];
      case TuningType.tiller:
        return [
          'Positive tiller: top limb longer than bottom',
          'Typical recurve: +2 to +6mm',
          'Split finger: more positive tiller',
          'Tab/release: closer to even',
        ];
      case TuningType.centershot:
        return [
          'Point slightly outside string line',
          'Exact position depends on arrow spine',
          'Fine tune with walk-back test',
        ];
      case TuningType.plungerTension:
        return [
          'Softer = more forgiving',
          'Stiffer = more consistent',
          'Adjust based on bare shaft/paper tune',
        ];
      default:
        return [];
    }
  }

  /// Get display name for a measurement type
  static String getDisplayName(String measurementType) {
    return TuningType.displayName(measurementType);
  }

  /// Map equipment field labels to tuning types
  static String? getTuningTypeForField(String fieldLabel) {
    final label = fieldLabel.toLowerCase();
    if (label.contains('brace height')) return TuningType.braceHeight;
    if (label.contains('nock')) return TuningType.nockPoint;
    if (label.contains('tiller')) return TuningType.tiller;
    if (label.contains('centre shot') || label.contains('center shot')) {
      return TuningType.centershot;
    }
    if (label.contains('spring tension') || label.contains('plunger')) {
      return TuningType.plungerTension;
    }
    return null;
  }
}
