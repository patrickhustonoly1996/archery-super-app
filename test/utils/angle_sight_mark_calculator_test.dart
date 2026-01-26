import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/angle_sight_mark_calculator.dart';
import 'package:archery_super_app/utils/angle_correction_constants.dart';
import 'package:archery_super_app/models/user_profile.dart';

void main() {
  group('AngleSightMarkCalculator', () {
    group('Speed estimation', () {
      test('compound bow at 60# estimates around 280fps', () {
        final speed = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.compound,
          poundage: 60,
        );
        expect(speed, closeTo(280, 20)); // 260-300 fps range
      });

      test('recurve at 40# estimates around 195fps', () {
        final speed = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.recurve,
          poundage: 40,
        );
        expect(speed, closeTo(195, 20)); // 175-215 fps range
      });

      test('barebow at 35# estimates around 165fps', () {
        final speed = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.barebow,
          poundage: 35,
        );
        expect(speed, closeTo(165, 20)); // 145-185 fps range
      });

      test('longbow at 35# estimates around 138fps', () {
        final speed = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.longbow,
          poundage: 35,
        );
        expect(speed, closeTo(138, 20)); // 118-158 fps range
      });

      test('draw length affects speed', () {
        final shortDraw = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.recurve,
          poundage: 40,
          drawLength: 26,
        );
        final longDraw = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.recurve,
          poundage: 40,
          drawLength: 30,
        );
        expect(longDraw, greaterThan(shortDraw));
      });

      test('arrow weight affects speed', () {
        final lightArrow = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.recurve,
          poundage: 40,
          arrowWeightGrains: 350,
        );
        final heavyArrow = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.recurve,
          poundage: 40,
          arrowWeightGrains: 500,
        );
        expect(lightArrow, greaterThan(heavyArrow));
      });

      test('speed is clamped to valid range', () {
        final veryLow = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.longbow,
          poundage: 20,
          drawLength: 24,
          arrowWeightGrains: 600,
        );
        final veryHigh = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.compound,
          poundage: 80,
          drawLength: 32,
          arrowWeightGrains: 300,
        );
        expect(veryLow, greaterThanOrEqualTo(AngleCorrectionConstants.minSpeed));
        expect(veryHigh, lessThanOrEqualTo(AngleCorrectionConstants.maxSpeed));
      });
    });

    group('Speed-based factors', () {
      test('fast arrows (290fps) have nearly equal up/down factors', () {
        final factors = AngleSightMarkCalculator.getFactorsForSpeed(290);
        expect(factors.ratio, closeTo(1.0, 0.1));
      });

      test('slow arrows (180fps) have ~2x downhill factor', () {
        final factors = AngleSightMarkCalculator.getFactorsForSpeed(180);
        expect(factors.ratio, closeTo(2.0, 0.1));
      });

      test('medium speed (235fps) has intermediate ratio', () {
        final factors = AngleSightMarkCalculator.getFactorsForSpeed(235);
        expect(factors.ratio, greaterThan(1.0));
        expect(factors.ratio, lessThan(2.0));
      });

      test('factors scale linearly with speed', () {
        final factors200 = AngleSightMarkCalculator.getFactorsForSpeed(200);
        final factors250 = AngleSightMarkCalculator.getFactorsForSpeed(250);
        final factors270 = AngleSightMarkCalculator.getFactorsForSpeed(270);

        // Uphill factors should decrease as speed increases
        expect(factors250.uphill, lessThan(factors200.uphill));
        expect(factors270.uphill, lessThan(factors250.uphill));

        // Ratio should decrease as speed increases
        expect(factors250.ratio, lessThan(factors200.ratio));
        expect(factors270.ratio, lessThan(factors250.ratio));
      });
    });

    group('Angle calculations', () {
      test('flat angle (0) returns flat sight mark unchanged', () {
        final mark = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: 4.15,
          angleDegrees: 0,
          arrowSpeedFps: 220,
        );
        expect(mark, equals(4.15));
      });

      test('uphill (negative angle) decreases sight mark', () {
        final flat = 4.15;
        final uphill = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: -15,
          arrowSpeedFps: 220,
        );
        expect(uphill, lessThan(flat));
      });

      test('downhill (positive angle) decreases sight mark', () {
        final flat = 4.15;
        final downhill = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: 15,
          arrowSpeedFps: 220,
        );
        expect(downhill, lessThan(flat));
      });

      test('downhill decreases more than uphill for slow arrows', () {
        const flat = 4.15;
        const angle = 15.0;
        const slowSpeed = 180.0;

        final uphill = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: -angle,
          arrowSpeedFps: slowSpeed,
        );
        final downhill = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: angle,
          arrowSpeedFps: slowSpeed,
        );

        // Both should be less than flat
        expect(uphill, lessThan(flat));
        expect(downhill, lessThan(flat));

        // Downhill should be lower (more correction) than uphill for slow arrows
        expect(downhill, lessThan(uphill));
      });

      test('uphill and downhill nearly equal for fast arrows', () {
        const flat = 4.15;
        const angle = 15.0;
        const fastSpeed = 290.0;

        final uphill = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: -angle,
          arrowSpeedFps: fastSpeed,
        );
        final downhill = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: angle,
          arrowSpeedFps: fastSpeed,
        );

        // Difference should be very small for fast arrows
        expect((uphill - downhill).abs(), lessThan(0.1));
      });

      test('larger angles produce larger corrections', () {
        const flat = 4.15;
        const speed = 220.0;

        final angle5 = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: 5,
          arrowSpeedFps: speed,
        );
        final angle15 = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: 15,
          arrowSpeedFps: speed,
        );
        final angle25 = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: 25,
          arrowSpeedFps: speed,
        );

        // Larger angles should produce lower marks (more correction)
        expect(angle15, lessThan(angle5));
        expect(angle25, lessThan(angle15));
      });
    });

    group('Percentage calculation', () {
      test('flat mark is 100%', () {
        final pct = AngleSightMarkCalculator.getSightMarkAsPercentage(
          flatSightMark: 4.15,
          angleDegrees: 0,
          arrowSpeedFps: 220,
        );
        expect(pct, equals(100.0));
      });

      test('angled shots are less than 100%', () {
        final pctUp = AngleSightMarkCalculator.getSightMarkAsPercentage(
          flatSightMark: 4.15,
          angleDegrees: -15,
          arrowSpeedFps: 220,
        );
        final pctDown = AngleSightMarkCalculator.getSightMarkAsPercentage(
          flatSightMark: 4.15,
          angleDegrees: 15,
          arrowSpeedFps: 220,
        );
        expect(pctUp, lessThan(100.0));
        expect(pctDown, lessThan(100.0));
      });

      test('percentage matches calculated sight mark', () {
        const flat = 4.15;
        const angle = 15.0;
        const speed = 220.0;

        final mark = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: angle,
          arrowSpeedFps: speed,
        );
        final pct = AngleSightMarkCalculator.getSightMarkAsPercentage(
          flatSightMark: flat,
          angleDegrees: angle,
          arrowSpeedFps: speed,
        );

        expect(pct, closeTo((mark / flat) * 100, 0.01));
      });
    });

    group('Angle table generation', () {
      test('generates entries for all standard angles', () {
        final table = AngleSightMarkCalculator.generateAngleTable(
          flatSightMark: 4.15,
          arrowSpeedFps: 220,
        );

        // Should have entries for -25, -20, -15, -10, -5, 0, 5, 10, 15, 20, 25
        expect(table.length, equals(11));
      });

      test('table includes flat entry at index 5', () {
        final table = AngleSightMarkCalculator.generateAngleTable(
          flatSightMark: 4.15,
          arrowSpeedFps: 220,
        );

        final flatEntry = table.firstWhere((e) => e.angle == 0);
        expect(flatEntry.sightMark, equals(4.15));
        expect(flatEntry.percentage, equals(100.0));
        expect(flatEntry.isFlat, isTrue);
      });

      test('uphill entries have negative angles', () {
        final table = AngleSightMarkCalculator.generateAngleTable(
          flatSightMark: 4.15,
          arrowSpeedFps: 220,
        );

        final uphillEntries = table.where((e) => e.isUphill);
        expect(uphillEntries.length, equals(5));
        for (final entry in uphillEntries) {
          expect(entry.angle, isNegative);
        }
      });

      test('downhill entries have positive angles', () {
        final table = AngleSightMarkCalculator.generateAngleTable(
          flatSightMark: 4.15,
          arrowSpeedFps: 220,
        );

        final downhillEntries = table.where((e) => e.isDownhill);
        expect(downhillEntries.length, equals(5));
        for (final entry in downhillEntries) {
          expect(entry.angle, isPositive);
        }
      });

      test('compact table has correct structure', () {
        final table = AngleSightMarkCalculator.generateCompactTable(
          flatSightMark: 4.15,
          arrowSpeedFps: 220,
        );

        expect(table.uphill.length, equals(5));
        expect(table.downhill.length, equals(5));
        expect(table.flat.angle, equals(0));
        expect(table.flat.sightMark, equals(4.15));
      });

      test('custom angles are respected', () {
        final customAngles = [3.0, 7.0, 12.0];
        final table = AngleSightMarkCalculator.generateAngleTable(
          flatSightMark: 4.15,
          arrowSpeedFps: 220,
          angles: customAngles,
        );

        // Should have -12, -7, -3, 0, 3, 7, 12 = 7 entries
        expect(table.length, equals(7));
      });
    });

    group('Speed description', () {
      test('returns appropriate descriptions', () {
        expect(
          AngleSightMarkCalculator.getSpeedDescription(300),
          equals('Fast'),
        );
        expect(
          AngleSightMarkCalculator.getSpeedDescription(260),
          equals('Medium-Fast'),
        );
        expect(
          AngleSightMarkCalculator.getSpeedDescription(220),
          equals('Medium'),
        );
        expect(
          AngleSightMarkCalculator.getSpeedDescription(185),
          equals('Medium-Slow'),
        );
        expect(
          AngleSightMarkCalculator.getSpeedDescription(150),
          equals('Slow'),
        );
      });
    });

    group('Real-world examples from plan', () {
      test('fast setup (280fps): up and down nearly equal', () {
        const flat = 4.15;
        const angle = 5.0;
        const speed = 280.0;

        final upMark = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: -angle,
          arrowSpeedFps: speed,
        );
        final downMark = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: angle,
          arrowSpeedFps: speed,
        );

        // Both should be close to 4.13-4.14
        expect(upMark, closeTo(4.13, 0.02));
        expect(downMark, closeTo(4.13, 0.02));
        expect((upMark - downMark).abs(), lessThan(0.02));
      });

      test('medium setup (250fps): slight difference', () {
        const flat = 4.15;
        const angle = 5.0;
        const speed = 250.0;

        final upMark = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: -angle,
          arrowSpeedFps: speed,
        );
        final downMark = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: angle,
          arrowSpeedFps: speed,
        );

        // Up ~4.13, down ~4.12
        expect(upMark, greaterThan(downMark));
        expect((upMark - downMark).abs(), lessThan(0.05));
      });

      test('slow setup (210fps): clear difference', () {
        const flat = 4.15;
        const angle = 5.0;
        const speed = 210.0;

        final upMark = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: -angle,
          arrowSpeedFps: speed,
        );
        final downMark = AngleSightMarkCalculator.getSightMarkForAngle(
          flatSightMark: flat,
          angleDegrees: angle,
          arrowSpeedFps: speed,
        );

        // Up ~4.13, down ~4.11 - clear difference
        expect(upMark, greaterThan(downMark));
        expect((upMark - downMark).abs(), greaterThan(0.01));
      });
    });
  });
}
