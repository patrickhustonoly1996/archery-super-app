import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/round_types_seed.dart';

void main() {
  group('RoundTypesSeed', () {
    late List<dynamic> roundTypes;

    setUpAll(() {
      roundTypes = getAllRoundTypesSeed();
    });

    group('Data Integrity', () {
      test('returns non-empty list', () {
        expect(roundTypes, isNotEmpty);
      });

      test('all round types have unique IDs', () {
        final ids = roundTypes.map((r) => r.id.value).toSet();
        expect(ids.length, equals(roundTypes.length));
      });

      test('all round types have non-empty names', () {
        for (final round in roundTypes) {
          expect(round.name.value, isNotEmpty);
        }
      });

      test('all round types have valid category', () {
        final validCategories = {
          'wa_indoor',
          'wa_outdoor',
          'agb_indoor',
          'agb_imperial',
          'agb_metric',
          'nfaa_indoor',
          'nfaa_field',
          'practice',
        };

        for (final round in roundTypes) {
          expect(
            validCategories.contains(round.category.value),
            isTrue,
            reason: 'Invalid category: ${round.category.value}',
          );
        }
      });
    });

    group('WA Indoor Rounds', () {
      test('WA 18m exists with correct max score', () {
        final wa18 = roundTypes.firstWhere(
          (r) => r.id.value == 'wa_18_60',
        );
        expect(wa18.maxScore.value, equals(600));
        expect(wa18.distance.value, equals(18));
        expect(wa18.isIndoor.value, isTrue);
      });

      test('WA 18m tri-spot has 3 faces', () {
        final trispot = roundTypes.firstWhere(
          (r) => r.id.value == 'wa_18_trispot',
        );
        expect(trispot.faceCount.value, equals(3));
      });

      test('indoor rounds have correct face sizes', () {
        final indoorRounds = roundTypes.where(
          (r) => r.category.value == 'wa_indoor',
        );

        for (final round in indoorRounds) {
          // WA indoor uses 40cm or 60cm faces
          expect(
            [40, 60].contains(round.faceSize.value),
            isTrue,
            reason: '${round.id.value} has invalid face size',
          );
        }
      });
    });

    group('WA Outdoor Rounds', () {
      test('WA 720 70m exists with correct max score', () {
        final wa720 = roundTypes.firstWhere(
          (r) => r.id.value == 'wa_720_70m',
        );
        expect(wa720.maxScore.value, equals(720));
        expect(wa720.distance.value, equals(70));
        expect(wa720.arrowsPerEnd.value, equals(6));
        expect(wa720.totalEnds.value, equals(12));
        expect(wa720.isIndoor.value, isFalse);
      });

      test('outdoor rounds use 122cm face', () {
        final outdoorRounds = roundTypes.where(
          (r) => r.category.value == 'wa_outdoor',
        );

        for (final round in outdoorRounds) {
          expect(
            round.faceSize.value,
            equals(122),
            reason: '${round.id.value} should use 122cm face',
          );
        }
      });

      test('outdoor rounds shoot 6 arrows per end', () {
        final outdoorRounds = roundTypes.where(
          (r) => r.category.value == 'wa_outdoor',
        );

        for (final round in outdoorRounds) {
          expect(
            round.arrowsPerEnd.value,
            equals(6),
            reason: '${round.id.value} should have 6 arrows per end',
          );
        }
      });
    });

    group('Score Calculations', () {
      test('max score is positive', () {
        for (final round in roundTypes) {
          expect(
            round.maxScore.value,
            greaterThan(0),
            reason: '${round.id.value} should have positive max score',
          );
        }
      });

      test('total arrows is arrowsPerEnd x totalEnds', () {
        for (final round in roundTypes) {
          final totalArrows =
              round.arrowsPerEnd.value * round.totalEnds.value;

          // Common totals: 30, 36, 60, 72, 90, 144
          expect(
            totalArrows,
            greaterThan(0),
            reason: '${round.id.value} should have positive total arrows',
          );
        }
      });
    });

    group('Distance Validation', () {
      test('indoor rounds have distance <= 30m', () {
        // Indoor can include some longer ranges like Stafford (27m/30 yards)
        final indoorRounds = roundTypes.where((r) => r.isIndoor.value == true);

        for (final round in indoorRounds) {
          expect(
            round.distance.value,
            lessThanOrEqualTo(30),
            reason: '${round.id.value} is indoor but > 30m',
          );
        }
      });

      test('outdoor rounds have distance > 25m', () {
        final outdoorRounds = roundTypes.where(
          (r) => r.category.value == 'wa_outdoor',
        );

        for (final round in outdoorRounds) {
          expect(
            round.distance.value,
            greaterThan(25),
            reason: '${round.id.value} is outdoor but <= 25m',
          );
        }
      });
    });
  });
}
