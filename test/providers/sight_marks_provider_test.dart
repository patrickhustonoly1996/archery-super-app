/// Tests for SightMarksProvider
///
/// These tests verify the sight marks management functionality including:
/// - DistanceUnit enum (meters/yards conversion)
/// - SightNotationStyle enum (decimal/whole notation)
/// - SightMarkPreferences class
/// - SightMark model class (parsing, validation, conversions)
/// - PredictedSightMark model class
/// - SightMarkConfidence enum
/// - SightMarkCalculator (interpolation, extrapolation, curve fitting)
/// - Provider state logic (caching, predictions)
///
/// Note: Tests that require database interaction use simulated state logic
/// since SightMarksProvider has hard dependencies on AppDatabase. The key
/// testable components are:
/// 1. DistanceUnit enum behavior
/// 2. SightNotationStyle enum behavior
/// 3. SightMark model class behavior
/// 4. SightMarkPreferences class behavior
/// 5. PredictedSightMark class behavior
/// 6. SightMarkCalculator math
/// 7. Provider caching and prediction logic
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/models/sight_mark.dart';
import 'package:archery_super_app/models/weather_conditions.dart';
import 'package:archery_super_app/utils/sight_mark_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // DISTANCE UNIT ENUM TESTS
  // ===========================================================================
  group('DistanceUnit enum', () {
    group('abbreviation values', () {
      test('meters has abbreviation m', () {
        expect(DistanceUnit.meters.abbreviation, equals('m'));
      });

      test('yards has abbreviation yd', () {
        expect(DistanceUnit.yards.abbreviation, equals('yd'));
      });

      test('all units have non-empty abbreviations', () {
        for (final unit in DistanceUnit.values) {
          expect(unit.abbreviation, isNotEmpty);
        }
      });

      test('abbreviations are unique', () {
        final abbreviations =
            DistanceUnit.values.map((u) => u.abbreviation).toSet();
        expect(abbreviations.length, equals(DistanceUnit.values.length));
      });
    });

    group('fromString', () {
      test('parses "meters" to meters', () {
        expect(DistanceUnit.fromString('meters'), equals(DistanceUnit.meters));
      });

      test('parses "yards" to yards', () {
        expect(DistanceUnit.fromString('yards'), equals(DistanceUnit.yards));
      });

      test('parses "yd" to yards', () {
        expect(DistanceUnit.fromString('yd'), equals(DistanceUnit.yards));
      });

      test('defaults to meters for null', () {
        expect(DistanceUnit.fromString(null), equals(DistanceUnit.meters));
      });

      test('defaults to meters for empty string', () {
        expect(DistanceUnit.fromString(''), equals(DistanceUnit.meters));
      });

      test('defaults to meters for unknown value', () {
        expect(DistanceUnit.fromString('feet'), equals(DistanceUnit.meters));
      });

      test('defaults to meters for "m"', () {
        expect(DistanceUnit.fromString('m'), equals(DistanceUnit.meters));
      });
    });

    group('toDbString', () {
      test('meters returns "meters"', () {
        expect(DistanceUnit.meters.toDbString(), equals('meters'));
      });

      test('yards returns "yards"', () {
        expect(DistanceUnit.yards.toDbString(), equals('yards'));
      });

      test('roundtrip meters through fromString/toDbString', () {
        final original = DistanceUnit.meters;
        final dbString = original.toDbString();
        final parsed = DistanceUnit.fromString(dbString);
        expect(parsed, equals(original));
      });

      test('roundtrip yards through fromString/toDbString', () {
        final original = DistanceUnit.yards;
        final dbString = original.toDbString();
        final parsed = DistanceUnit.fromString(dbString);
        expect(parsed, equals(original));
      });
    });
  });

  // ===========================================================================
  // SIGHT NOTATION STYLE ENUM TESTS
  // ===========================================================================
  group('SightNotationStyle enum', () {
    group('values', () {
      test('has decimal style', () {
        expect(SightNotationStyle.values, contains(SightNotationStyle.decimal));
      });

      test('has whole style', () {
        expect(SightNotationStyle.values, contains(SightNotationStyle.whole));
      });

      test('has exactly 2 values', () {
        expect(SightNotationStyle.values.length, equals(2));
      });
    });

    group('fromString', () {
      test('parses "decimal" to decimal', () {
        expect(SightNotationStyle.fromString('decimal'),
            equals(SightNotationStyle.decimal));
      });

      test('parses "whole" to whole', () {
        expect(SightNotationStyle.fromString('whole'),
            equals(SightNotationStyle.whole));
      });

      test('defaults to decimal for null', () {
        expect(
            SightNotationStyle.fromString(null), equals(SightNotationStyle.decimal));
      });

      test('defaults to decimal for empty string', () {
        expect(
            SightNotationStyle.fromString(''), equals(SightNotationStyle.decimal));
      });

      test('defaults to decimal for unknown value', () {
        expect(SightNotationStyle.fromString('fractional'),
            equals(SightNotationStyle.decimal));
      });
    });

    group('toDbString', () {
      test('decimal returns "decimal"', () {
        expect(SightNotationStyle.decimal.toDbString(), equals('decimal'));
      });

      test('whole returns "whole"', () {
        expect(SightNotationStyle.whole.toDbString(), equals('whole'));
      });

      test('roundtrip decimal through fromString/toDbString', () {
        final original = SightNotationStyle.decimal;
        final dbString = original.toDbString();
        final parsed = SightNotationStyle.fromString(dbString);
        expect(parsed, equals(original));
      });

      test('roundtrip whole through fromString/toDbString', () {
        final original = SightNotationStyle.whole;
        final dbString = original.toDbString();
        final parsed = SightNotationStyle.fromString(dbString);
        expect(parsed, equals(original));
      });
    });
  });

  // ===========================================================================
  // SIGHT MARK PREFERENCES TESTS
  // ===========================================================================
  group('SightMarkPreferences', () {
    group('constructor', () {
      test('creates with required bowId', () {
        final prefs = SightMarkPreferences(bowId: 'bow-123');
        expect(prefs.bowId, equals('bow-123'));
      });

      test('defaults notationStyle to decimal', () {
        final prefs = SightMarkPreferences(bowId: 'bow-123');
        expect(prefs.notationStyle, equals(SightNotationStyle.decimal));
      });

      test('defaults decimalPlaces to 2', () {
        final prefs = SightMarkPreferences(bowId: 'bow-123');
        expect(prefs.decimalPlaces, equals(2));
      });

      test('accepts custom notationStyle', () {
        final prefs = SightMarkPreferences(
          bowId: 'bow-123',
          notationStyle: SightNotationStyle.whole,
        );
        expect(prefs.notationStyle, equals(SightNotationStyle.whole));
      });

      test('accepts custom decimalPlaces', () {
        final prefs = SightMarkPreferences(
          bowId: 'bow-123',
          decimalPlaces: 3,
        );
        expect(prefs.decimalPlaces, equals(3));
      });

      test('accepts all custom values', () {
        final prefs = SightMarkPreferences(
          bowId: 'bow-456',
          notationStyle: SightNotationStyle.whole,
          decimalPlaces: 1,
        );
        expect(prefs.bowId, equals('bow-456'));
        expect(prefs.notationStyle, equals(SightNotationStyle.whole));
        expect(prefs.decimalPlaces, equals(1));
      });
    });

    group('copyWith', () {
      test('copies with new notationStyle', () {
        final original = SightMarkPreferences(
          bowId: 'bow-123',
          notationStyle: SightNotationStyle.decimal,
          decimalPlaces: 2,
        );
        final copied = original.copyWith(notationStyle: SightNotationStyle.whole);
        expect(copied.bowId, equals('bow-123'));
        expect(copied.notationStyle, equals(SightNotationStyle.whole));
        expect(copied.decimalPlaces, equals(2));
      });

      test('copies with new decimalPlaces', () {
        final original = SightMarkPreferences(
          bowId: 'bow-123',
          notationStyle: SightNotationStyle.decimal,
          decimalPlaces: 2,
        );
        final copied = original.copyWith(decimalPlaces: 4);
        expect(copied.bowId, equals('bow-123'));
        expect(copied.notationStyle, equals(SightNotationStyle.decimal));
        expect(copied.decimalPlaces, equals(4));
      });

      test('copies with no changes when called with no arguments', () {
        final original = SightMarkPreferences(
          bowId: 'bow-123',
          notationStyle: SightNotationStyle.whole,
          decimalPlaces: 3,
        );
        final copied = original.copyWith();
        expect(copied.bowId, equals(original.bowId));
        expect(copied.notationStyle, equals(original.notationStyle));
        expect(copied.decimalPlaces, equals(original.decimalPlaces));
      });

      test('copies with all new values', () {
        final original = SightMarkPreferences(
          bowId: 'bow-123',
          notationStyle: SightNotationStyle.decimal,
          decimalPlaces: 2,
        );
        final copied = original.copyWith(
          notationStyle: SightNotationStyle.whole,
          decimalPlaces: 0,
        );
        expect(copied.bowId, equals('bow-123')); // bowId cannot be changed
        expect(copied.notationStyle, equals(SightNotationStyle.whole));
        expect(copied.decimalPlaces, equals(0));
      });
    });
  });

  // ===========================================================================
  // SIGHT MARK CONFIDENCE ENUM TESTS
  // ===========================================================================
  group('SightMarkConfidence enum', () {
    group('values', () {
      test('has high confidence', () {
        expect(SightMarkConfidence.values, contains(SightMarkConfidence.high));
      });

      test('has medium confidence', () {
        expect(SightMarkConfidence.values, contains(SightMarkConfidence.medium));
      });

      test('has low confidence', () {
        expect(SightMarkConfidence.values, contains(SightMarkConfidence.low));
      });

      test('has unknown confidence', () {
        expect(SightMarkConfidence.values, contains(SightMarkConfidence.unknown));
      });

      test('has exactly 4 values', () {
        expect(SightMarkConfidence.values.length, equals(4));
      });
    });

    group('isHigh', () {
      test('returns true for high', () {
        expect(SightMarkConfidence.high.isHigh, isTrue);
      });

      test('returns false for medium', () {
        expect(SightMarkConfidence.medium.isHigh, isFalse);
      });

      test('returns false for low', () {
        expect(SightMarkConfidence.low.isHigh, isFalse);
      });

      test('returns false for unknown', () {
        expect(SightMarkConfidence.unknown.isHigh, isFalse);
      });
    });

    group('isMedium', () {
      test('returns true for medium', () {
        expect(SightMarkConfidence.medium.isMedium, isTrue);
      });

      test('returns false for high', () {
        expect(SightMarkConfidence.high.isMedium, isFalse);
      });

      test('returns false for low', () {
        expect(SightMarkConfidence.low.isMedium, isFalse);
      });

      test('returns false for unknown', () {
        expect(SightMarkConfidence.unknown.isMedium, isFalse);
      });
    });

    group('isLow', () {
      test('returns true for low', () {
        expect(SightMarkConfidence.low.isLow, isTrue);
      });

      test('returns true for unknown', () {
        expect(SightMarkConfidence.unknown.isLow, isTrue);
      });

      test('returns false for high', () {
        expect(SightMarkConfidence.high.isLow, isFalse);
      });

      test('returns false for medium', () {
        expect(SightMarkConfidence.medium.isLow, isFalse);
      });
    });
  });

  // ===========================================================================
  // SIGHT MARK MODEL TESTS
  // ===========================================================================
  group('SightMark model', () {
    late SightMark sightMark;

    setUp(() {
      sightMark = SightMark(
        id: 'sm-123',
        bowId: 'bow-456',
        distance: 70.0,
        unit: DistanceUnit.meters,
        sightValue: '5.14',
        recordedAt: DateTime(2026, 1, 15, 10, 30),
      );
    });

    group('constructor', () {
      test('creates with required fields', () {
        expect(sightMark.id, equals('sm-123'));
        expect(sightMark.bowId, equals('bow-456'));
        expect(sightMark.distance, equals(70.0));
        expect(sightMark.unit, equals(DistanceUnit.meters));
        expect(sightMark.sightValue, equals('5.14'));
        expect(sightMark.recordedAt, equals(DateTime(2026, 1, 15, 10, 30)));
      });

      test('optional fields default to null', () {
        expect(sightMark.weather, isNull);
        expect(sightMark.elevationDelta, isNull);
        expect(sightMark.slopeAngle, isNull);
        expect(sightMark.sessionId, isNull);
        expect(sightMark.endNumber, isNull);
        expect(sightMark.shotCount, isNull);
        expect(sightMark.confidenceScore, isNull);
        expect(sightMark.updatedAt, isNull);
        expect(sightMark.deletedAt, isNull);
      });

      test('accepts all optional fields', () {
        final weather = WeatherConditions(
          temperature: 20.0,
          sky: 'sunny',
          wind: 'light',
        );
        final fullMark = SightMark(
          id: 'sm-789',
          bowId: 'bow-123',
          distance: 50.0,
          unit: DistanceUnit.yards,
          sightValue: '4.25',
          weather: weather,
          elevationDelta: 10.0,
          slopeAngle: 5.0,
          sessionId: 'session-1',
          endNumber: 3,
          shotCount: 36,
          confidenceScore: 0.9,
          recordedAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 1, 16),
          deletedAt: DateTime(2026, 1, 17),
        );
        expect(fullMark.weather, equals(weather));
        expect(fullMark.elevationDelta, equals(10.0));
        expect(fullMark.slopeAngle, equals(5.0));
        expect(fullMark.sessionId, equals('session-1'));
        expect(fullMark.endNumber, equals(3));
        expect(fullMark.shotCount, equals(36));
        expect(fullMark.confidenceScore, equals(0.9));
        expect(fullMark.updatedAt, equals(DateTime(2026, 1, 16)));
        expect(fullMark.deletedAt, equals(DateTime(2026, 1, 17)));
      });
    });

    group('numericValue', () {
      test('parses simple decimal value', () {
        expect(sightMark.numericValue, equals(5.14));
      });

      test('parses whole number', () {
        final mark = SightMark(
          id: 'sm-1',
          bowId: 'bow-1',
          distance: 50.0,
          unit: DistanceUnit.meters,
          sightValue: '514',
          recordedAt: DateTime.now(),
        );
        expect(mark.numericValue, equals(514.0));
      });

      test('parses value with non-numeric characters', () {
        final mark = SightMark(
          id: 'sm-1',
          bowId: 'bow-1',
          distance: 50.0,
          unit: DistanceUnit.meters,
          sightValue: '5.14mm',
          recordedAt: DateTime.now(),
        );
        expect(mark.numericValue, equals(5.14));
      });

      test('parses value with spaces', () {
        final mark = SightMark(
          id: 'sm-1',
          bowId: 'bow-1',
          distance: 50.0,
          unit: DistanceUnit.meters,
          sightValue: ' 5.14 ',
          recordedAt: DateTime.now(),
        );
        expect(mark.numericValue, equals(5.14));
      });

      test('returns 0.0 for empty string', () {
        final mark = SightMark(
          id: 'sm-1',
          bowId: 'bow-1',
          distance: 50.0,
          unit: DistanceUnit.meters,
          sightValue: '',
          recordedAt: DateTime.now(),
        );
        expect(mark.numericValue, equals(0.0));
      });

      test('returns 0.0 for non-numeric string', () {
        final mark = SightMark(
          id: 'sm-1',
          bowId: 'bow-1',
          distance: 50.0,
          unit: DistanceUnit.meters,
          sightValue: 'abc',
          recordedAt: DateTime.now(),
        );
        expect(mark.numericValue, equals(0.0));
      });

      test('parses negative values (removes non-numeric chars)', () {
        final mark = SightMark(
          id: 'sm-1',
          bowId: 'bow-1',
          distance: 50.0,
          unit: DistanceUnit.meters,
          sightValue: '-5.14',
          recordedAt: DateTime.now(),
        );
        // Regex removes the minus sign, so it becomes 5.14
        expect(mark.numericValue, equals(5.14));
      });
    });

    group('isValid', () {
      test('returns true for valid sight mark', () {
        expect(sightMark.isValid, isTrue);
      });

      test('returns false for zero distance', () {
        final mark = sightMark.copyWith(distance: 0.0);
        expect(mark.isValid, isFalse);
      });

      test('returns false for negative distance', () {
        final mark = sightMark.copyWith(distance: -10.0);
        expect(mark.isValid, isFalse);
      });

      test('returns false for zero sight value', () {
        final mark = sightMark.copyWith(sightValue: '0');
        expect(mark.isValid, isFalse);
      });

      test('returns false for empty sight value', () {
        final mark = sightMark.copyWith(sightValue: '');
        expect(mark.isValid, isFalse);
      });

      test('returns false for non-numeric sight value', () {
        final mark = sightMark.copyWith(sightValue: 'abc');
        expect(mark.isValid, isFalse);
      });
    });

    group('distanceInMeters', () {
      test('returns distance unchanged for meters', () {
        expect(sightMark.distanceInMeters, equals(70.0));
      });

      test('converts yards to meters', () {
        final mark = sightMark.copyWith(
          distance: 100.0,
          unit: DistanceUnit.yards,
        );
        // 100 yards * 0.9144 = 91.44 meters
        expect(mark.distanceInMeters, closeTo(91.44, 0.001));
      });

      test('converts 70 yards to meters correctly', () {
        final mark = sightMark.copyWith(
          distance: 70.0,
          unit: DistanceUnit.yards,
        );
        // 70 yards * 0.9144 = 64.008 meters
        expect(mark.distanceInMeters, closeTo(64.008, 0.001));
      });

      test('converts 1 yard to meters correctly', () {
        final mark = sightMark.copyWith(
          distance: 1.0,
          unit: DistanceUnit.yards,
        );
        expect(mark.distanceInMeters, closeTo(0.9144, 0.0001));
      });
    });

    group('confidenceLevel', () {
      test('returns unknown for null confidence score', () {
        expect(sightMark.confidenceLevel, equals(SightMarkConfidence.unknown));
      });

      test('returns high for score >= 0.8', () {
        final mark = sightMark.copyWith(confidenceScore: 0.8);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.high));
      });

      test('returns high for score = 1.0', () {
        final mark = sightMark.copyWith(confidenceScore: 1.0);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.high));
      });

      test('returns high for score = 0.95', () {
        final mark = sightMark.copyWith(confidenceScore: 0.95);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.high));
      });

      test('returns medium for score >= 0.5 and < 0.8', () {
        final mark = sightMark.copyWith(confidenceScore: 0.5);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.medium));
      });

      test('returns medium for score = 0.79', () {
        final mark = sightMark.copyWith(confidenceScore: 0.79);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.medium));
      });

      test('returns medium for score = 0.65', () {
        final mark = sightMark.copyWith(confidenceScore: 0.65);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.medium));
      });

      test('returns low for score < 0.5', () {
        final mark = sightMark.copyWith(confidenceScore: 0.49);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.low));
      });

      test('returns low for score = 0.0', () {
        final mark = sightMark.copyWith(confidenceScore: 0.0);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.low));
      });

      test('returns low for score = 0.25', () {
        final mark = sightMark.copyWith(confidenceScore: 0.25);
        expect(mark.confidenceLevel, equals(SightMarkConfidence.low));
      });
    });

    group('displayValue', () {
      test('returns sight value as-is', () {
        expect(sightMark.displayValue, equals('5.14'));
      });

      test('returns whole number sight value', () {
        final mark = sightMark.copyWith(sightValue: '514');
        expect(mark.displayValue, equals('514'));
      });

      test('returns sight value with units', () {
        final mark = sightMark.copyWith(sightValue: '5.14mm');
        expect(mark.displayValue, equals('5.14mm'));
      });
    });

    group('distanceDisplay', () {
      test('formats meters with abbreviation', () {
        expect(sightMark.distanceDisplay, equals('70m'));
      });

      test('formats yards with abbreviation', () {
        final mark = sightMark.copyWith(unit: DistanceUnit.yards);
        expect(mark.distanceDisplay, equals('70yd'));
      });

      test('rounds 70.5 to 71 (standard rounding)', () {
        // Dart's toStringAsFixed(0) uses standard rounding (0.5 rounds up)
        final mark = sightMark.copyWith(distance: 70.5);
        expect(mark.distanceDisplay, equals('71m'));
      });

      test('rounds 70.4 to 70', () {
        final mark = sightMark.copyWith(distance: 70.4);
        expect(mark.distanceDisplay, equals('70m'));
      });

      test('rounds 70.9 to 71', () {
        final mark = sightMark.copyWith(distance: 70.9);
        expect(mark.distanceDisplay, equals('71m'));
      });
    });

    group('copyWith', () {
      test('copies with new id', () {
        final copied = sightMark.copyWith(id: 'new-id');
        expect(copied.id, equals('new-id'));
        expect(copied.bowId, equals(sightMark.bowId));
      });

      test('copies with new bowId', () {
        final copied = sightMark.copyWith(bowId: 'new-bow');
        expect(copied.bowId, equals('new-bow'));
        expect(copied.id, equals(sightMark.id));
      });

      test('copies with new distance', () {
        final copied = sightMark.copyWith(distance: 50.0);
        expect(copied.distance, equals(50.0));
      });

      test('copies with new unit', () {
        final copied = sightMark.copyWith(unit: DistanceUnit.yards);
        expect(copied.unit, equals(DistanceUnit.yards));
      });

      test('copies with new sightValue', () {
        final copied = sightMark.copyWith(sightValue: '6.00');
        expect(copied.sightValue, equals('6.00'));
      });

      test('copies with new weather', () {
        final weather = WeatherConditions(temperature: 25.0);
        final copied = sightMark.copyWith(weather: weather);
        expect(copied.weather, equals(weather));
      });

      test('copies with no changes when called with no arguments', () {
        final copied = sightMark.copyWith();
        expect(copied.id, equals(sightMark.id));
        expect(copied.bowId, equals(sightMark.bowId));
        expect(copied.distance, equals(sightMark.distance));
        expect(copied.unit, equals(sightMark.unit));
        expect(copied.sightValue, equals(sightMark.sightValue));
        expect(copied.recordedAt, equals(sightMark.recordedAt));
      });

      test('copies preserving optional null values', () {
        final copied = sightMark.copyWith(elevationDelta: 5.0);
        expect(copied.elevationDelta, equals(5.0));
        expect(copied.slopeAngle, isNull);
        expect(copied.weather, isNull);
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        expect(sightMark.toString(), equals('SightMark(70m: 5.14)'));
      });

      test('includes yards for yard units', () {
        final mark = sightMark.copyWith(unit: DistanceUnit.yards);
        expect(mark.toString(), equals('SightMark(70yd: 5.14)'));
      });
    });
  });

  // ===========================================================================
  // PREDICTED SIGHT MARK MODEL TESTS
  // ===========================================================================
  group('PredictedSightMark model', () {
    late PredictedSightMark prediction;

    setUp(() {
      prediction = PredictedSightMark(
        distance: 50.0,
        unit: DistanceUnit.meters,
        predictedValue: 4.25,
        confidence: SightMarkConfidence.high,
        source: 'exact',
      );
    });

    group('constructor', () {
      test('creates with required fields', () {
        expect(prediction.distance, equals(50.0));
        expect(prediction.unit, equals(DistanceUnit.meters));
        expect(prediction.predictedValue, equals(4.25));
        expect(prediction.confidence, equals(SightMarkConfidence.high));
        expect(prediction.source, equals('exact'));
      });

      test('basedOn defaults to null', () {
        expect(prediction.basedOn, isNull);
      });

      test('interpolatedFrom defaults to null', () {
        expect(prediction.interpolatedFrom, isNull);
      });

      test('accepts basedOn', () {
        final baseMark = SightMark(
          id: 'sm-1',
          bowId: 'bow-1',
          distance: 50.0,
          unit: DistanceUnit.meters,
          sightValue: '4.25',
          recordedAt: DateTime.now(),
        );
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.25,
          confidence: SightMarkConfidence.high,
          source: 'exact',
          basedOn: baseMark,
        );
        expect(pred.basedOn, equals(baseMark));
      });

      test('accepts interpolatedFrom', () {
        final marks = [
          SightMark(
            id: 'sm-1',
            bowId: 'bow-1',
            distance: 30.0,
            unit: DistanceUnit.meters,
            sightValue: '3.50',
            recordedAt: DateTime.now(),
          ),
          SightMark(
            id: 'sm-2',
            bowId: 'bow-1',
            distance: 70.0,
            unit: DistanceUnit.meters,
            sightValue: '5.50',
            recordedAt: DateTime.now(),
          ),
        ];
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.50,
          confidence: SightMarkConfidence.medium,
          source: 'interpolated',
          interpolatedFrom: marks,
        );
        expect(pred.interpolatedFrom, equals(marks));
      });
    });

    group('displayValue', () {
      test('formats to 2 decimal places', () {
        expect(prediction.displayValue, equals('4.25'));
      });

      test('pads with zeros', () {
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.0,
          confidence: SightMarkConfidence.medium,
          source: 'interpolated',
        );
        expect(pred.displayValue, equals('4.00'));
      });

      test('rounds appropriately', () {
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.256,
          confidence: SightMarkConfidence.medium,
          source: 'interpolated',
        );
        expect(pred.displayValue, equals('4.26'));
      });
    });

    group('distanceDisplay', () {
      test('formats meters with abbreviation', () {
        expect(prediction.distanceDisplay, equals('50m'));
      });

      test('formats yards with abbreviation', () {
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.yards,
          predictedValue: 4.25,
          confidence: SightMarkConfidence.medium,
          source: 'interpolated',
        );
        expect(pred.distanceDisplay, equals('50yd'));
      });
    });

    group('source type checks', () {
      test('isExact returns true for exact source', () {
        expect(prediction.isExact, isTrue);
      });

      test('isExact returns false for interpolated source', () {
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.25,
          confidence: SightMarkConfidence.medium,
          source: 'interpolated',
        );
        expect(pred.isExact, isFalse);
      });

      test('isInterpolated returns true for interpolated source', () {
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.25,
          confidence: SightMarkConfidence.medium,
          source: 'interpolated',
        );
        expect(pred.isInterpolated, isTrue);
      });

      test('isInterpolated returns false for exact source', () {
        expect(prediction.isInterpolated, isFalse);
      });

      test('isExtrapolated returns true for extrapolated source', () {
        final pred = PredictedSightMark(
          distance: 90.0,
          unit: DistanceUnit.meters,
          predictedValue: 6.00,
          confidence: SightMarkConfidence.low,
          source: 'extrapolated',
        );
        expect(pred.isExtrapolated, isTrue);
      });

      test('isExtrapolated returns false for interpolated source', () {
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.25,
          confidence: SightMarkConfidence.medium,
          source: 'interpolated',
        );
        expect(pred.isExtrapolated, isFalse);
      });

      test('isFromSimilarBow returns true for similar_bow source', () {
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.25,
          confidence: SightMarkConfidence.low,
          source: 'similar_bow',
        );
        expect(pred.isFromSimilarBow, isTrue);
      });

      test('isFromSimilarBow returns false for exact source', () {
        expect(prediction.isFromSimilarBow, isFalse);
      });
    });

    group('toString', () {
      test('returns formatted string with source', () {
        expect(prediction.toString(),
            equals('PredictedSightMark(50m: 4.25 [exact])'));
      });

      test('includes interpolated in string', () {
        final pred = PredictedSightMark(
          distance: 50.0,
          unit: DistanceUnit.meters,
          predictedValue: 4.25,
          confidence: SightMarkConfidence.medium,
          source: 'interpolated',
        );
        expect(pred.toString(),
            equals('PredictedSightMark(50m: 4.25 [interpolated])'));
      });
    });
  });

  // ===========================================================================
  // SIGHT MARK CALCULATOR TESTS
  // ===========================================================================
  group('SightMarkCalculator', () {
    SightMark createMark({
      required double distance,
      required String sightValue,
      DistanceUnit unit = DistanceUnit.meters,
      DateTime? recordedAt,
    }) {
      return SightMark(
        id: 'sm-${distance.toInt()}',
        bowId: 'bow-1',
        distance: distance,
        unit: unit,
        sightValue: sightValue,
        recordedAt: recordedAt ?? DateTime(2026, 1, 15),
      );
    }

    group('predict with empty marks', () {
      test('returns null for empty list', () {
        final result = SightMarkCalculator.predict(
          marks: [],
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNull);
      });
    });

    group('predict with single mark', () {
      test('returns null when no exact match', () {
        final marks = [createMark(distance: 30.0, sightValue: '3.50')];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNull);
      });

      test('returns exact match when distance matches', () {
        final marks = [createMark(distance: 50.0, sightValue: '4.50')];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, equals(4.50));
        expect(result.source, equals('exact'));
        expect(result.confidence, equals(SightMarkConfidence.high));
      });
    });

    group('predict exact match', () {
      test('returns exact match from multiple marks', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.50'),
          createMark(distance: 50.0, sightValue: '4.50'),
          createMark(distance: 70.0, sightValue: '5.50'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, equals(4.50));
        expect(result.source, equals('exact'));
        expect(result.confidence, equals(SightMarkConfidence.high));
        expect(result.basedOn, isNotNull);
      });

      test('returns most recent mark when multiple exact matches', () {
        final marks = [
          createMark(
            distance: 50.0,
            sightValue: '4.40',
            recordedAt: DateTime(2026, 1, 10),
          ),
          createMark(
            distance: 50.0,
            sightValue: '4.50',
            recordedAt: DateTime(2026, 1, 15),
          ),
          createMark(
            distance: 50.0,
            sightValue: '4.45',
            recordedAt: DateTime(2026, 1, 12),
          ),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, equals(4.50)); // Most recent
      });
    });

    group('predict with two marks (linear interpolation)', () {
      test('interpolates between two marks', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 70.0, sightValue: '5.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // (50-30)/(70-30) = 0.5, so 3.0 + 0.5*(5.0-3.0) = 4.0
        expect(result!.predictedValue, closeTo(4.0, 0.01));
        expect(result.source, equals('interpolated'));
        expect(result.confidence, equals(SightMarkConfidence.medium));
      });

      test('interpolates at 1/4 point', () {
        final marks = [
          createMark(distance: 20.0, sightValue: '2.00'),
          createMark(distance: 60.0, sightValue: '6.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 30.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // (30-20)/(60-20) = 0.25, so 2.0 + 0.25*(6.0-2.0) = 3.0
        expect(result!.predictedValue, closeTo(3.0, 0.01));
      });

      test('interpolates at 3/4 point', () {
        final marks = [
          createMark(distance: 20.0, sightValue: '2.00'),
          createMark(distance: 60.0, sightValue: '6.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // (50-20)/(60-20) = 0.75, so 2.0 + 0.75*(6.0-2.0) = 5.0
        expect(result!.predictedValue, closeTo(5.0, 0.01));
      });

      test('returns null when extrapolating below range with only 2 marks', () {
        // The algorithm finds bracketing points, and when extrapolating below
        // the range with only 2 marks, both points end up being the same
        // (the lowest mark), which causes it to return null
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 20.0,
          unit: DistanceUnit.meters,
        );
        // With only 2 marks and target below range, algorithm cannot bracket properly
        expect(result, isNull);
      });

      test('returns null when extrapolating above range with only 2 marks', () {
        // The algorithm finds bracketing points. With target above range:
        // lower ends up being the highest mark, upper stays null and defaults
        // to the same highest mark, causing lower==upper which returns null
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 70.0,
          unit: DistanceUnit.meters,
        );
        // With only 2 marks and target above range, algorithm cannot bracket properly
        expect(result, isNull);
      });
    });

    group('predict with three or more marks (quadratic)', () {
      test('interpolates using quadratic fit', () {
        // Create marks that follow a quadratic curve: y = 0.001x² + 0.01x + 1
        // At x=30: y = 0.001*900 + 0.3 + 1 = 2.2
        // At x=50: y = 0.001*2500 + 0.5 + 1 = 4.0
        // At x=70: y = 0.001*4900 + 0.7 + 1 = 6.6
        final marks = [
          createMark(distance: 30.0, sightValue: '2.2'),
          createMark(distance: 50.0, sightValue: '4.0'),
          createMark(distance: 70.0, sightValue: '6.6'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // Should be close to 0.001*1600 + 0.4 + 1 = 3.0
        expect(result!.predictedValue, closeTo(3.0, 0.2));
        expect(result.source, equals('interpolated'));
      });

      test('returns interpolated source within range', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 70.0, sightValue: '5.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.source, equals('interpolated'));
      });

      test('returns extrapolated source below range', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 70.0, sightValue: '5.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 20.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.source, equals('extrapolated'));
      });

      test('returns extrapolated source above range', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 70.0, sightValue: '5.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 90.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.source, equals('extrapolated'));
      });

      test('includes interpolatedFrom in result', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 70.0, sightValue: '5.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.interpolatedFrom, isNotNull);
        expect(result.interpolatedFrom!.length, equals(3));
      });
    });

    group('predict filters by unit', () {
      test('only uses marks with matching unit', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00', unit: DistanceUnit.meters),
          createMark(distance: 50.0, sightValue: '4.00', unit: DistanceUnit.meters),
          createMark(distance: 70.0, sightValue: '5.00', unit: DistanceUnit.yards),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // Should use linear interpolation since only 2 meters marks
        expect(result!.interpolatedFrom!.length, equals(2));
      });

      test('returns null when no marks match unit', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00', unit: DistanceUnit.yards),
          createMark(distance: 50.0, sightValue: '4.00', unit: DistanceUnit.yards),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNull);
      });
    });

    group('predict filters invalid marks', () {
      test('ignores marks with zero distance', () {
        final marks = [
          createMark(distance: 0.0, sightValue: '1.00'),
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // Should use linear interpolation since only 2 valid marks
        expect(result!.interpolatedFrom!.length, equals(2));
      });

      test('ignores marks with zero sight value', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '0'),
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 70.0, sightValue: '5.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 60.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // Should use linear interpolation since only 2 valid marks
        expect(result!.interpolatedFrom!.length, equals(2));
      });
    });

    group('getCurveCoefficients', () {
      test('returns null for empty list', () {
        final result =
            SightMarkCalculator.getCurveCoefficients([], DistanceUnit.meters);
        expect(result, isNull);
      });

      test('returns null for less than 3 marks', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
        ];
        final result = SightMarkCalculator.getCurveCoefficients(
            marks, DistanceUnit.meters);
        expect(result, isNull);
      });

      test('returns coefficients for 3 marks', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 70.0, sightValue: '5.00'),
        ];
        final result = SightMarkCalculator.getCurveCoefficients(
            marks, DistanceUnit.meters);
        expect(result, isNotNull);
        expect(result!.length, equals(3));
      });

      test('returns coefficients [a, b, c] in correct order', () {
        // For a linear relationship y = 0.05x + 1.5
        // The quadratic coefficient a should be close to 0
        final marks = [
          createMark(distance: 30.0, sightValue: '3.0'), // 0.05*30 + 1.5 = 3.0
          createMark(distance: 50.0, sightValue: '4.0'), // 0.05*50 + 1.5 = 4.0
          createMark(distance: 70.0, sightValue: '5.0'), // 0.05*70 + 1.5 = 5.0
        ];
        final result = SightMarkCalculator.getCurveCoefficients(
            marks, DistanceUnit.meters);
        expect(result, isNotNull);
        final a = result![0];
        final b = result[1];
        final c = result[2];
        // a should be close to 0 (linear)
        expect(a.abs(), lessThan(0.001));
        // b should be close to 0.05
        expect(b, closeTo(0.05, 0.01));
        // c should be close to 1.5
        expect(c, closeTo(1.5, 0.1));
      });

      test('filters by unit', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.00', unit: DistanceUnit.meters),
          createMark(distance: 50.0, sightValue: '4.00', unit: DistanceUnit.meters),
          createMark(distance: 70.0, sightValue: '5.00', unit: DistanceUnit.yards),
        ];
        final result = SightMarkCalculator.getCurveCoefficients(
            marks, DistanceUnit.meters);
        // Only 2 meters marks, so should return null
        expect(result, isNull);
      });

      test('filters invalid marks', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '0'),
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 70.0, sightValue: '5.00'),
        ];
        final result = SightMarkCalculator.getCurveCoefficients(
            marks, DistanceUnit.meters);
        // Only 2 valid marks, so should return null
        expect(result, isNull);
      });
    });
  });

  // ===========================================================================
  // PROVIDER STATE SIMULATION TESTS
  // ===========================================================================
  group('Provider state simulation', () {
    // Simulates provider caching behavior
    Map<String, List<SightMark>> simulateCache() {
      return <String, List<SightMark>>{};
    }

    List<SightMark> getMarksForBow(
        Map<String, List<SightMark>> cache, String bowId) {
      return cache[bowId] ?? [];
    }

    void setMarksForBow(
        Map<String, List<SightMark>> cache, String bowId, List<SightMark> marks) {
      cache[bowId] = marks;
    }

    SightMark createMark({
      required String bowId,
      required double distance,
      required String sightValue,
      DistanceUnit unit = DistanceUnit.meters,
    }) {
      return SightMark(
        id: 'sm-${bowId}-${distance.toInt()}',
        bowId: bowId,
        distance: distance,
        unit: unit,
        sightValue: sightValue,
        recordedAt: DateTime(2026, 1, 15),
      );
    }

    group('cache management', () {
      test('returns empty list for unknown bow', () {
        final cache = simulateCache();
        final marks = getMarksForBow(cache, 'unknown-bow');
        expect(marks, isEmpty);
      });

      test('stores marks for bow', () {
        final cache = simulateCache();
        final marks = [
          createMark(bowId: 'bow-1', distance: 50.0, sightValue: '4.00'),
        ];
        setMarksForBow(cache, 'bow-1', marks);
        expect(getMarksForBow(cache, 'bow-1'), equals(marks));
      });

      test('keeps bows separate', () {
        final cache = simulateCache();
        final marks1 = [
          createMark(bowId: 'bow-1', distance: 50.0, sightValue: '4.00'),
        ];
        final marks2 = [
          createMark(bowId: 'bow-2', distance: 50.0, sightValue: '5.00'),
        ];
        setMarksForBow(cache, 'bow-1', marks1);
        setMarksForBow(cache, 'bow-2', marks2);
        expect(getMarksForBow(cache, 'bow-1'), equals(marks1));
        expect(getMarksForBow(cache, 'bow-2'), equals(marks2));
      });

      test('clear cache removes marks', () {
        final cache = simulateCache();
        final marks = [
          createMark(bowId: 'bow-1', distance: 50.0, sightValue: '4.00'),
        ];
        setMarksForBow(cache, 'bow-1', marks);
        cache.remove('bow-1');
        expect(getMarksForBow(cache, 'bow-1'), isEmpty);
      });
    });

    group('prediction with cache', () {
      test('getPredictedMark returns prediction from cached marks', () {
        final cache = simulateCache();
        final marks = [
          createMark(bowId: 'bow-1', distance: 30.0, sightValue: '3.00'),
          createMark(bowId: 'bow-1', distance: 70.0, sightValue: '5.00'),
        ];
        setMarksForBow(cache, 'bow-1', marks);

        final cachedMarks = getMarksForBow(cache, 'bow-1');
        final result = SightMarkCalculator.predict(
          marks: cachedMarks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );

        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(4.0, 0.01));
      });

      test('getPredictedMark returns null for empty cache', () {
        final cache = simulateCache();
        final cachedMarks = getMarksForBow(cache, 'bow-1');
        final result = SightMarkCalculator.predict(
          marks: cachedMarks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );

        expect(result, isNull);
      });
    });

    group('common distances', () {
      test('meters common distances are correct', () {
        final metersDistances = [18.0, 25.0, 30.0, 40.0, 50.0, 60.0, 70.0, 90.0];
        expect(metersDistances.length, equals(8));
        expect(metersDistances, contains(18.0)); // Indoor
        expect(metersDistances, contains(70.0)); // Olympic
        expect(metersDistances, contains(90.0)); // Long
      });

      test('yards common distances are correct', () {
        final yardsDistances = [20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 100.0];
        expect(yardsDistances.length, equals(8));
        expect(yardsDistances, contains(20.0)); // Short
        expect(yardsDistances, contains(100.0)); // York
      });

      test('predictions for common distances use cache', () {
        final cache = simulateCache();
        final marks = [
          createMark(bowId: 'bow-1', distance: 30.0, sightValue: '3.00'),
          createMark(bowId: 'bow-1', distance: 50.0, sightValue: '4.00'),
          createMark(bowId: 'bow-1', distance: 70.0, sightValue: '5.00'),
        ];
        setMarksForBow(cache, 'bow-1', marks);

        final cachedMarks = getMarksForBow(cache, 'bow-1');
        final distances = [18.0, 25.0, 30.0, 40.0, 50.0, 60.0, 70.0, 90.0];

        final predictions = distances
            .map((d) => SightMarkCalculator.predict(
                  marks: cachedMarks,
                  targetDistance: d,
                  unit: DistanceUnit.meters,
                ))
            .whereType<PredictedSightMark>()
            .toList();

        // All distances should get predictions (interpolated or extrapolated)
        expect(predictions.length, equals(8));
      });
    });

    group('format sight value', () {
      test('formats with default 2 decimal places', () {
        final value = 4.1234;
        final formatted = value.toStringAsFixed(2);
        expect(formatted, equals('4.12'));
      });

      test('formats with 0 decimal places', () {
        final value = 4.56;
        final formatted = value.toStringAsFixed(0);
        expect(formatted, equals('5'));
      });

      test('formats with 3 decimal places', () {
        final value = 4.1234;
        final formatted = value.toStringAsFixed(3);
        expect(formatted, equals('4.123'));
      });

      test('pads with zeros', () {
        final value = 4.1;
        final formatted = value.toStringAsFixed(2);
        expect(formatted, equals('4.10'));
      });
    });
  });

  // ===========================================================================
  // REAL-WORLD SCENARIO TESTS
  // ===========================================================================
  group('Real-world scenarios', () {
    SightMark createMark({
      required double distance,
      required String sightValue,
      DistanceUnit unit = DistanceUnit.meters,
      DateTime? recordedAt,
    }) {
      return SightMark(
        id: 'sm-${distance.toInt()}',
        bowId: 'bow-1',
        distance: distance,
        unit: unit,
        sightValue: sightValue,
        recordedAt: recordedAt ?? DateTime(2026, 1, 15),
      );
    }

    group('Olympic recurve archer', () {
      // Typical sight marks for 70m Olympic round setup
      // Using realistic values that increase with distance
      late List<SightMark> olympicMarks;

      setUp(() {
        olympicMarks = [
          createMark(distance: 18.0, sightValue: '2.80'), // Indoor
          createMark(distance: 30.0, sightValue: '3.50'),
          createMark(distance: 50.0, sightValue: '4.30'),
          createMark(distance: 70.0, sightValue: '5.14'), // Olympic
          createMark(distance: 90.0, sightValue: '6.10'), // Long distance
        ];
      });

      test('predicts 40m from existing marks', () {
        final result = SightMarkCalculator.predict(
          marks: olympicMarks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(3.9, 0.3));
        expect(result.source, equals('interpolated'));
      });

      test('predicts 60m from existing marks', () {
        final result = SightMarkCalculator.predict(
          marks: olympicMarks,
          targetDistance: 60.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(4.7, 0.3));
        expect(result.source, equals('interpolated'));
      });

      test('returns exact mark for 70m', () {
        final result = SightMarkCalculator.predict(
          marks: olympicMarks,
          targetDistance: 70.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, equals(5.14));
        expect(result.source, equals('exact'));
        expect(result.confidence, equals(SightMarkConfidence.high));
      });

      test('extrapolates beyond known range with lower confidence', () {
        final result = SightMarkCalculator.predict(
          marks: olympicMarks,
          targetDistance: 100.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.source, equals('extrapolated'));
        // Extrapolated predictions have lower confidence
        expect(result.confidence, isNot(equals(SightMarkConfidence.high)));
      });
    });

    group('Beginner archer with limited marks', () {
      late List<SightMark> beginnerMarks;

      setUp(() {
        beginnerMarks = [
          createMark(distance: 18.0, sightValue: '3.00'),
          createMark(distance: 30.0, sightValue: '4.00'),
        ];
      });

      test('uses linear interpolation with 2 marks', () {
        final result = SightMarkCalculator.predict(
          marks: beginnerMarks,
          targetDistance: 24.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.source, equals('interpolated'));
        // (24-18)/(30-18) = 0.5, so 3.0 + 0.5 = 3.5
        expect(result.predictedValue, closeTo(3.5, 0.1));
      });

      test('cannot extrapolate beyond range with only 2 marks', () {
        // The linear predict algorithm requires bracketing points
        // With only 2 marks, extrapolation beyond the range returns null
        final result = SightMarkCalculator.predict(
          marks: beginnerMarks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        // Algorithm cannot bracket properly with 2 marks outside range
        expect(result, isNull);
      });
    });

    group('UK imperial (yards) archer', () {
      late List<SightMark> yardsMarks;

      setUp(() {
        yardsMarks = [
          createMark(distance: 20.0, sightValue: '2.50', unit: DistanceUnit.yards),
          createMark(distance: 40.0, sightValue: '3.50', unit: DistanceUnit.yards),
          createMark(distance: 60.0, sightValue: '4.50', unit: DistanceUnit.yards),
          createMark(distance: 80.0, sightValue: '5.50', unit: DistanceUnit.yards),
          createMark(distance: 100.0, sightValue: '6.50', unit: DistanceUnit.yards),
        ];
      });

      test('predicts 50 yards', () {
        final result = SightMarkCalculator.predict(
          marks: yardsMarks,
          targetDistance: 50.0,
          unit: DistanceUnit.yards,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(4.0, 0.2));
      });

      test('returns exact for 60 yards', () {
        final result = SightMarkCalculator.predict(
          marks: yardsMarks,
          targetDistance: 60.0,
          unit: DistanceUnit.yards,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, equals(4.50));
        expect(result.source, equals('exact'));
      });

      test('does not mix with meters marks', () {
        final mixedMarks = [
          ...yardsMarks,
          createMark(distance: 50.0, sightValue: '99.99', unit: DistanceUnit.meters),
        ];
        final result = SightMarkCalculator.predict(
          marks: mixedMarks,
          targetDistance: 50.0,
          unit: DistanceUnit.yards,
        );
        expect(result, isNotNull);
        // Should NOT use the 99.99 meters mark
        expect(result!.predictedValue, lessThan(10.0));
      });
    });

    group('Compound archer with different sight settings', () {
      late List<SightMark> compoundMarks;

      setUp(() {
        // Compound bows typically have smaller sight mark ranges
        // due to higher arrow speeds
        compoundMarks = [
          createMark(distance: 18.0, sightValue: '1.20'),
          createMark(distance: 30.0, sightValue: '1.50'),
          createMark(distance: 50.0, sightValue: '1.90'),
          createMark(distance: 70.0, sightValue: '2.40'),
        ];
      });

      test('handles smaller value ranges', () {
        final result = SightMarkCalculator.predict(
          marks: compoundMarks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // Value should be between 1.50 and 1.90
        expect(result!.predictedValue, greaterThan(1.5));
        expect(result.predictedValue, lessThan(1.9));
      });
    });

    group('Field archer with mixed distances', () {
      test('handles non-standard distances', () {
        final fieldMarks = [
          createMark(distance: 15.0, sightValue: '2.50'),
          createMark(distance: 25.0, sightValue: '3.20'),
          createMark(distance: 35.0, sightValue: '3.90'),
          createMark(distance: 45.0, sightValue: '4.60'),
          createMark(distance: 55.0, sightValue: '5.30'),
        ];

        final result = SightMarkCalculator.predict(
          marks: fieldMarks,
          targetDistance: 22.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.source, equals('interpolated'));
        expect(result.predictedValue, greaterThan(2.8));
        expect(result.predictedValue, lessThan(3.2));
      });
    });
  });

  // ===========================================================================
  // EDGE CASES AND ERROR HANDLING
  // ===========================================================================
  group('Edge cases', () {
    SightMark createMark({
      required double distance,
      required String sightValue,
      DistanceUnit unit = DistanceUnit.meters,
    }) {
      return SightMark(
        id: 'sm-${distance.toInt()}',
        bowId: 'bow-1',
        distance: distance,
        unit: unit,
        sightValue: sightValue,
        recordedAt: DateTime(2026, 1, 15),
      );
    }

    group('boundary values', () {
      test('handles very small distances', () {
        final marks = [
          createMark(distance: 5.0, sightValue: '1.00'),
          createMark(distance: 10.0, sightValue: '1.50'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 7.5,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(1.25, 0.01));
      });

      test('handles very large distances', () {
        final marks = [
          createMark(distance: 150.0, sightValue: '8.00'),
          createMark(distance: 180.0, sightValue: '9.50'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 165.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(8.75, 0.01));
      });

      test('handles very small sight values', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '0.5'),
          createMark(distance: 50.0, sightValue: '0.8'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(0.65, 0.01));
      });

      test('handles large sight values', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '150'),
          createMark(distance: 50.0, sightValue: '250'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(200.0, 1.0));
      });
    });

    group('special cases', () {
      test('handles marks at same distance', () {
        final marks = [
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 50.0, sightValue: '4.05'),
          createMark(distance: 50.0, sightValue: '3.95'),
        ];
        // This would trigger exact match logic
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 50.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.source, equals('exact'));
      });

      test('handles marks with same sight value', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '4.00'),
          createMark(distance: 50.0, sightValue: '4.00'),
          createMark(distance: 70.0, sightValue: '4.00'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        expect(result!.predictedValue, closeTo(4.0, 0.1));
      });
    });

    group('decimal precision', () {
      test('maintains precision in calculations', () {
        final marks = [
          createMark(distance: 30.0, sightValue: '3.333'),
          createMark(distance: 50.0, sightValue: '4.444'),
        ];
        final result = SightMarkCalculator.predict(
          marks: marks,
          targetDistance: 40.0,
          unit: DistanceUnit.meters,
        );
        expect(result, isNotNull);
        // Midpoint should be (3.333 + 4.444) / 2 = 3.8885
        expect(result!.predictedValue, closeTo(3.8885, 0.001));
      });
    });
  });

  // ===========================================================================
  // DATA INTEGRITY TESTS
  // ===========================================================================
  group('Data integrity', () {
    test('SightMark copyWith creates independent copy', () {
      final original = SightMark(
        id: 'sm-1',
        bowId: 'bow-1',
        distance: 50.0,
        unit: DistanceUnit.meters,
        sightValue: '4.00',
        recordedAt: DateTime(2026, 1, 15),
      );

      final copied = original.copyWith(sightValue: '5.00');

      // Original unchanged
      expect(original.sightValue, equals('4.00'));
      // Copy has new value
      expect(copied.sightValue, equals('5.00'));
    });

    test('SightMarkPreferences copyWith creates independent copy', () {
      final original = SightMarkPreferences(
        bowId: 'bow-1',
        notationStyle: SightNotationStyle.decimal,
        decimalPlaces: 2,
      );

      final copied = original.copyWith(decimalPlaces: 3);

      // Original unchanged
      expect(original.decimalPlaces, equals(2));
      // Copy has new value
      expect(copied.decimalPlaces, equals(3));
    });

    test('prediction does not modify input marks list', () {
      final marks = [
        SightMark(
          id: 'sm-1',
          bowId: 'bow-1',
          distance: 30.0,
          unit: DistanceUnit.meters,
          sightValue: '3.00',
          recordedAt: DateTime(2026, 1, 15),
        ),
        SightMark(
          id: 'sm-2',
          bowId: 'bow-1',
          distance: 50.0,
          unit: DistanceUnit.meters,
          sightValue: '4.00',
          recordedAt: DateTime(2026, 1, 15),
        ),
      ];

      final originalLength = marks.length;
      final originalFirst = marks[0].sightValue;

      SightMarkCalculator.predict(
        marks: marks,
        targetDistance: 40.0,
        unit: DistanceUnit.meters,
      );

      expect(marks.length, equals(originalLength));
      expect(marks[0].sightValue, equals(originalFirst));
    });
  });
}
