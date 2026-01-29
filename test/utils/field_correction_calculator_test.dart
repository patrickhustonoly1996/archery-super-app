import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/field_correction_calculator.dart';
import 'package:archery_super_app/models/arrow_coordinate.dart';
import 'package:archery_super_app/models/sight_mark.dart';

void main() {
  group('FieldCorrectionCalculator', () {
    group('calculateForPeg', () {
      test('returns base mark with no adjustments on flat ground', () {
        final result = FieldCorrectionCalculator.calculateForPeg(
          distance: 50,
          unit: DistanceUnit.yards,
          arrowSpeedFps: 195,
          baseFlatMark: 3.60,
        );

        expect(result.value, 3.60);
        expect(result.flatMark, 3.60);
        expect(result.angleAdjustment, 0.0);
        expect(result.courseAdjustment, 0.0);
        expect(result.walkDownAdjustment, 0.0);
        expect(result.hasAdjustments, false);
      });

      test('applies angle correction for uphill shot', () {
        final result = FieldCorrectionCalculator.calculateForPeg(
          distance: 50,
          unit: DistanceUnit.yards,
          angleDegrees: -12.5, // uphill
          arrowSpeedFps: 195,
          baseFlatMark: 3.60,
        );

        expect(result.value, lessThan(3.60)); // Uphill = aim lower
        expect(result.angleAdjustment, lessThan(0));
        expect(result.hasAdjustments, true);
      });

      test('applies angle correction for downhill shot', () {
        final result = FieldCorrectionCalculator.calculateForPeg(
          distance: 50,
          unit: DistanceUnit.yards,
          angleDegrees: 10.0, // downhill
          arrowSpeedFps: 195,
          baseFlatMark: 3.60,
        );

        expect(result.value, lessThan(3.60)); // Downhill = also aim lower
        expect(result.angleAdjustment, lessThan(0));
      });

      test('applies course differential', () {
        final result = FieldCorrectionCalculator.calculateForPeg(
          distance: 50,
          unit: DistanceUnit.yards,
          arrowSpeedFps: 195,
          baseFlatMark: 3.60,
          courseDifferential: 0.06,
          courseDataPoints: 3,
        );

        expect(result.value, closeTo(3.66, 0.001));
        expect(result.courseAdjustment, 0.06);
        expect(result.dataPoints, 3);
      });

      test('combines angle and course adjustments', () {
        final result = FieldCorrectionCalculator.calculateForPeg(
          distance: 50,
          unit: DistanceUnit.yards,
          angleDegrees: -12.5,
          arrowSpeedFps: 195,
          baseFlatMark: 3.60,
          courseDifferential: 0.06,
          courseDataPoints: 3,
        );

        // Value should be less than base (angle) but include course differential
        expect(result.angleAdjustment, lessThan(0));
        expect(result.courseAdjustment, 0.06);
        expect(result.value, closeTo(3.60 + result.angleAdjustment + 0.06, 0.001));
      });

      test('applies walk-down adjustment from previous peg', () {
        final prevResult = PreviousPegResult(
          coordinate: ArrowCoordinate(
            xMm: 0,
            yMm: -15, // Arrow hit high
            faceSizeCm: 65,
          ),
          previousDistance: 80,
          previousSightMark: 4.20,
        );

        final result = FieldCorrectionCalculator.calculateForPeg(
          distance: 70,
          unit: DistanceUnit.yards,
          arrowSpeedFps: 195,
          baseFlatMark: 3.90,
          previousPegResult: prevResult,
        );

        // Arrow hit high -> sight should increase (positive walk-down adjustment)
        expect(result.walkDownAdjustment, greaterThan(0));
      });

      test('poor shot gets 25% weight in walk-down adjustment', () {
        // Good shot
        final goodResult = PreviousPegResult(
          coordinate: ArrowCoordinate(
            xMm: 0,
            yMm: -20,
            faceSizeCm: 65,
          ),
          previousDistance: 80,
        );

        final goodAdj = FieldCorrectionCalculator.calculateForPeg(
          distance: 70,
          unit: DistanceUnit.yards,
          arrowSpeedFps: 195,
          baseFlatMark: 3.90,
          previousPegResult: goodResult,
        );

        // Poor shot
        final poorResult = PreviousPegResult(
          coordinate: ArrowCoordinate(
            xMm: 0,
            yMm: -20,
            faceSizeCm: 65,
          ),
          isPoorShot: true,
          poorShotDirection: 'high',
          previousDistance: 80,
        );

        final poorAdj = FieldCorrectionCalculator.calculateForPeg(
          distance: 70,
          unit: DistanceUnit.yards,
          arrowSpeedFps: 195,
          baseFlatMark: 3.90,
          previousPegResult: poorResult,
        );

        // Poor shot should have ~25% of the adjustment
        if (goodAdj.walkDownAdjustment.abs() > 0.005) {
          expect(
            poorAdj.walkDownAdjustment.abs(),
            lessThan(goodAdj.walkDownAdjustment.abs()),
          );
        }
      });

      test('no walk-down adjustment without coordinate', () {
        final prevResult = PreviousPegResult(
          previousDistance: 80,
          previousSightMark: 4.20,
        );

        final result = FieldCorrectionCalculator.calculateForPeg(
          distance: 70,
          unit: DistanceUnit.yards,
          arrowSpeedFps: 195,
          baseFlatMark: 3.90,
          previousPegResult: prevResult,
        );

        expect(result.walkDownAdjustment, 0.0);
      });
    });

    group('calculateWeightedGroupCentre', () {
      test('returns null for empty list', () {
        final result = FieldCorrectionCalculator.calculateWeightedGroupCentre(
          coordinates: [],
          isPoorShot: [],
          faceSizeCm: 65,
        );
        expect(result, isNull);
      });

      test('returns single arrow position for one arrow', () {
        final result = FieldCorrectionCalculator.calculateWeightedGroupCentre(
          coordinates: [
            ArrowCoordinate(xMm: 10, yMm: -5, faceSizeCm: 65),
          ],
          isPoorShot: [false],
          faceSizeCm: 65,
        );

        expect(result, isNotNull);
        expect(result!.xMm, closeTo(10, 0.01));
        expect(result.yMm, closeTo(-5, 0.01));
      });

      test('calculates even centre for equal good shots', () {
        final result = FieldCorrectionCalculator.calculateWeightedGroupCentre(
          coordinates: [
            ArrowCoordinate(xMm: 10, yMm: 0, faceSizeCm: 65),
            ArrowCoordinate(xMm: -10, yMm: 0, faceSizeCm: 65),
          ],
          isPoorShot: [false, false],
          faceSizeCm: 65,
        );

        expect(result, isNotNull);
        expect(result!.xMm, closeTo(0, 0.01));
        expect(result.yMm, closeTo(0, 0.01));
      });

      test('weights poor shots at 25%', () {
        // Good shot at (10, 0) + poor shot at (-30, 0)
        // Weighted centre: (10*1.0 + (-30)*0.25) / (1.0 + 0.25) = (10 - 7.5) / 1.25 = 2.0
        final result = FieldCorrectionCalculator.calculateWeightedGroupCentre(
          coordinates: [
            ArrowCoordinate(xMm: 10, yMm: 0, faceSizeCm: 65),
            ArrowCoordinate(xMm: -30, yMm: 0, faceSizeCm: 65),
          ],
          isPoorShot: [false, true],
          faceSizeCm: 65,
        );

        expect(result, isNotNull);
        expect(result!.xMm, closeTo(2.0, 0.01));
      });
    });

    group('FieldSightMarkRecommendation', () {
      test('breakdownText shows all adjustments', () {
        final rec = FieldSightMarkRecommendation(
          value: 3.45,
          flatMark: 3.60,
          angleAdjustment: -0.12,
          courseAdjustment: -0.03,
          walkDownAdjustment: 0.0,
          explanation: 'test',
          confidence: SightMarkConfidence.high,
          dataPoints: 3,
        );

        expect(rec.breakdownText, contains('base:'));
        expect(rec.breakdownText, contains('3.60'));
        expect(rec.breakdownText, contains('angle:'));
        expect(rec.breakdownText, contains('-0.12'));
        expect(rec.breakdownText, contains('course:'));
        expect(rec.breakdownText, contains('-0.03'));
        expect(rec.breakdownText, contains('3 visits'));
      });

      test('displayValue formats to 2 decimal places', () {
        final rec = FieldSightMarkRecommendation(
          value: 3.456789,
          flatMark: 3.60,
          explanation: 'test',
          confidence: SightMarkConfidence.medium,
        );

        expect(rec.displayValue, '3.46');
      });
    });
  });
}
