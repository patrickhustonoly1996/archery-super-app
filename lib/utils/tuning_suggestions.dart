import '../models/tuning_session.dart';

/// Provides auto-suggestions based on paper tune tear patterns
class TuningSuggestions {
  /// Get tuning suggestions based on paper tune results
  static List<String> getSuggestionsForPaperTune({
    required String bowType,
    required String direction,
    required String size,
  }) {
    final suggestions = <String>[];

    if (direction == TearDirection.clean) {
      suggestions.add('Perfect! No adjustment needed.');
      return suggestions;
    }

    final severity = _getSeverity(size);
    final prefix = severity == 'minor' ? 'Slight' : severity == 'moderate' ? 'Moderate' : 'Significant';

    if (bowType == BowType.recurve) {
      suggestions.addAll(_getRecurveSuggestions(direction, prefix));
    } else {
      suggestions.addAll(_getCompoundSuggestions(direction, prefix));
    }

    return suggestions;
  }

  static String _getSeverity(String size) {
    switch (size) {
      case TearSize.small:
        return 'minor';
      case TearSize.medium:
        return 'moderate';
      case TearSize.large:
        return 'significant';
      default:
        return 'moderate';
    }
  }

  static List<String> _getRecurveSuggestions(String direction, String prefix) {
    final suggestions = <String>[];

    switch (direction) {
      case TearDirection.up:
        suggestions.add('$prefix high tear detected');
        suggestions.add('Lower nocking point (move down 1-2mm)');
        suggestions.add('Check tiller - may need to reduce top limb');
        break;

      case TearDirection.down:
        suggestions.add('$prefix low tear detected');
        suggestions.add('Raise nocking point (move up 1-2mm)');
        suggestions.add('Check tiller - may need to reduce bottom limb');
        break;

      case TearDirection.left:
        suggestions.add('$prefix left tear detected');
        suggestions.add('Move button/plunger OUT (away from riser)');
        suggestions.add('Reduce plunger tension slightly');
        suggestions.add('Check arrow spine - may be too weak');
        break;

      case TearDirection.right:
        suggestions.add('$prefix right tear detected');
        suggestions.add('Move button/plunger IN (toward riser)');
        suggestions.add('Increase plunger tension slightly');
        suggestions.add('Check arrow spine - may be too stiff');
        break;

      case TearDirection.upLeft:
        suggestions.add('$prefix up-left tear detected');
        suggestions.add('Lower nocking point (move down 1-2mm)');
        suggestions.add('Move button/plunger OUT (away from riser)');
        suggestions.add('Address vertical first, then horizontal');
        break;

      case TearDirection.upRight:
        suggestions.add('$prefix up-right tear detected');
        suggestions.add('Lower nocking point (move down 1-2mm)');
        suggestions.add('Move button/plunger IN (toward riser)');
        suggestions.add('Address vertical first, then horizontal');
        break;

      case TearDirection.downLeft:
        suggestions.add('$prefix down-left tear detected');
        suggestions.add('Raise nocking point (move up 1-2mm)');
        suggestions.add('Move button/plunger OUT (away from riser)');
        suggestions.add('Address vertical first, then horizontal');
        break;

      case TearDirection.downRight:
        suggestions.add('$prefix down-right tear detected');
        suggestions.add('Raise nocking point (move up 1-2mm)');
        suggestions.add('Move button/plunger IN (toward riser)');
        suggestions.add('Address vertical first, then horizontal');
        break;
    }

    return suggestions;
  }

  static List<String> _getCompoundSuggestions(String direction, String prefix) {
    final suggestions = <String>[];

    switch (direction) {
      case TearDirection.up:
        suggestions.add('$prefix high tear detected');
        suggestions.add('Lower nocking point on D-loop');
        suggestions.add('Check cam timing - bottom cam may be fast');
        suggestions.add('Adjust rest down slightly');
        break;

      case TearDirection.down:
        suggestions.add('$prefix low tear detected');
        suggestions.add('Raise nocking point on D-loop');
        suggestions.add('Check cam timing - top cam may be fast');
        suggestions.add('Adjust rest up slightly');
        break;

      case TearDirection.left:
        suggestions.add('$prefix left tear detected');
        suggestions.add('Move rest OUT (away from riser)');
        suggestions.add('Check arrow spine - may be too weak');
        suggestions.add('Verify cam timing is synchronized');
        break;

      case TearDirection.right:
        suggestions.add('$prefix right tear detected');
        suggestions.add('Move rest IN (toward riser)');
        suggestions.add('Check arrow spine - may be too stiff');
        suggestions.add('Verify cam timing is synchronized');
        break;

      case TearDirection.upLeft:
        suggestions.add('$prefix up-left tear detected');
        suggestions.add('Lower nocking point on D-loop');
        suggestions.add('Move rest OUT (away from riser)');
        suggestions.add('Address vertical first, then horizontal');
        break;

      case TearDirection.upRight:
        suggestions.add('$prefix up-right tear detected');
        suggestions.add('Lower nocking point on D-loop');
        suggestions.add('Move rest IN (toward riser)');
        suggestions.add('Address vertical first, then horizontal');
        break;

      case TearDirection.downLeft:
        suggestions.add('$prefix down-left tear detected');
        suggestions.add('Raise nocking point on D-loop');
        suggestions.add('Move rest OUT (away from riser)');
        suggestions.add('Address vertical first, then horizontal');
        break;

      case TearDirection.downRight:
        suggestions.add('$prefix down-right tear detected');
        suggestions.add('Raise nocking point on D-loop');
        suggestions.add('Move rest IN (toward riser)');
        suggestions.add('Address vertical first, then horizontal');
        break;
    }

    return suggestions;
  }

  /// Get general tuning tips based on tuning type
  static List<String> getGeneralTips(String tuningType, String bowType) {
    final tips = <String>[];

    switch (tuningType) {
      case TuningType.paperTune:
        tips.add('Shoot through paper from 6-8 feet');
        tips.add('Use same arrow you plan to shoot');
        tips.add('Take multiple shots to confirm pattern');
        tips.add('Make small adjustments (1-2mm at a time)');
        break;

      case TuningType.bareShaft:
        tips.add('Shoot fletched and bare shafts at 18m');
        tips.add('Bare shafts should group with fletched');
        tips.add('If bare shafts group left/right: adjust button/rest');
        tips.add('If bare shafts group high/low: adjust nocking point');
        break;

      case TuningType.walkBack:
        if (bowType == BowType.recurve) {
          tips.add('Shoot at distances: 10m, 30m, 50m, 70m');
          tips.add('Arrows should group vertically');
          tips.add('If arrows drift left: move button OUT');
          tips.add('If arrows drift right: move button IN');
        }
        break;

      case TuningType.frenchTune:
        if (bowType == BowType.compound) {
          tips.add('Shoot fletched arrow, then bare shaft at same spot');
          tips.add('Bare shaft should hit same location');
          tips.add('Adjust rest left/right for horizontal difference');
          tips.add('Adjust nocking point for vertical difference');
        }
        break;

      case TuningType.braceHeight:
        tips.add('Typical recurve: 215-230mm');
        tips.add('Higher = quieter, lower = faster');
        tips.add('Measure from pivot point to string');
        tips.add('Start at manufacturer recommendation');
        break;

      case TuningType.tiller:
        tips.add('Measure from limb pocket to string');
        tips.add('Positive tiller: top limb longer than bottom');
        tips.add('Typical recurve: +2 to +6mm');
        tips.add('Adjust by turning limb bolts equally');
        break;
    }

    return tips;
  }
}
