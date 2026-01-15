import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/handicap_calculator.dart';

void main() {
  group('HandicapCalculator', () {
    group('calculateHandicap', () {
      group('WA 720 70m', () {
        const roundId = 'wa_720_70m';

        test('returns handicap 0 for near-perfect score', () {
          // Table shows 697 for HC 0
          final result = HandicapCalculator.calculateHandicap(roundId, 697);
          expect(result, equals(0));
        });

        test('returns correct handicap for mid-range scores', () {
          // Score of 600 should be around HC 24 (table shows 639 for HC 19, 602 for HC 30)
          final result = HandicapCalculator.calculateHandicap(roundId, 600);
          expect(result, isNotNull);
          expect(result, greaterThanOrEqualTo(20));
          expect(result, lessThanOrEqualTo(35));
        });

        test('returns correct handicap for score at table boundary', () {
          // Table shows 500 for exactly HC 54 (approximately)
          final result = HandicapCalculator.calculateHandicap(roundId, 500);
          expect(result, isNotNull);
          expect(result, greaterThanOrEqualTo(50));
          expect(result, lessThanOrEqualTo(60));
        });

        test('returns high handicap for very low scores', () {
          final result = HandicapCalculator.calculateHandicap(roundId, 100);
          expect(result, isNotNull);
          expect(result, greaterThan(100));
        });

        test('handles score at maximum (720)', () {
          final result = HandicapCalculator.calculateHandicap(roundId, 720);
          expect(result, equals(0));
        });

        test('handles score of zero', () {
          final result = HandicapCalculator.calculateHandicap(roundId, 0);
          expect(result, isNotNull);
          expect(result, equals(150)); // Should be max handicap
        });
      });

      group('WA 720 60m', () {
        const roundId = 'wa_720_60m';

        test('returns handicap 0 for near-perfect score', () {
          // Table shows 703 for HC 0
          final result = HandicapCalculator.calculateHandicap(roundId, 703);
          expect(result, equals(0));
        });

        test('same score yields higher handicap on easier 60m round', () {
          const score = 650;
          final hc70m = HandicapCalculator.calculateHandicap('wa_720_70m', score);
          final hc60m = HandicapCalculator.calculateHandicap('wa_720_60m', score);

          // 60m is easier, so same score = higher (worse) handicap
          // (better archers are expected to score higher on easier rounds)
          expect(hc60m, greaterThan(hc70m!));
        });
      });

      group('WA 18m Indoor', () {
        const roundId = 'wa_18m';

        test('returns handicap 0 for near-perfect score', () {
          // Table shows 592 for HC 0
          final result = HandicapCalculator.calculateHandicap(roundId, 592);
          expect(result, equals(0));
        });

        test('returns correct handicap for typical indoor scores', () {
          // 550 should be around HC 20 range
          final result = HandicapCalculator.calculateHandicap(roundId, 550);
          expect(result, isNotNull);
          expect(result, greaterThanOrEqualTo(15));
          expect(result, lessThanOrEqualTo(30));
        });

        test('handles max score of 600', () {
          final result = HandicapCalculator.calculateHandicap(roundId, 600);
          expect(result, equals(0));
        });
      });

      group('Portsmouth', () {
        const roundId = 'portsmouth';

        test('returns correct handicap for typical scores', () {
          // Portsmouth max is 600, typical club archer might score 500
          final result = HandicapCalculator.calculateHandicap(roundId, 500);
          expect(result, isNotNull);
          expect(result, greaterThan(30));
          expect(result, lessThan(60));
        });

        test('Portsmouth and WA 18m have same handicaps', () {
          // They use the same table
          const score = 550;
          final portsmouthHc = HandicapCalculator.calculateHandicap('portsmouth', score);
          final wa18mHc = HandicapCalculator.calculateHandicap('wa_18m', score);
          expect(portsmouthHc, equals(wa18mHc));
        });
      });

      group('Worcester', () {
        const roundId = 'worcester';

        test('handles 5-zone scoring (max 300)', () {
          // Worcester is 60 arrows at a 5-zone face, max 300
          final result = HandicapCalculator.calculateHandicap(roundId, 280);
          expect(result, isNotNull);
          expect(result, lessThan(30));
        });

        test('returns high handicap for low Worcester score', () {
          final result = HandicapCalculator.calculateHandicap(roundId, 100);
          expect(result, isNotNull);
          expect(result, greaterThan(60));
        });
      });

      group('York (Imperial)', () {
        const roundId = 'york';

        test('handles imperial round format (144 arrows)', () {
          // York max is 1296
          final result = HandicapCalculator.calculateHandicap(roundId, 1000);
          expect(result, isNotNull);
          expect(result, greaterThanOrEqualTo(20));
          expect(result, lessThanOrEqualTo(50));
        });

        test('returns correct handicap for championship-level score', () {
          // 1200 is a strong York score
          final result = HandicapCalculator.calculateHandicap(roundId, 1200);
          expect(result, isNotNull);
          expect(result, lessThan(20));
        });
      });

      group('WA 1440', () {
        test('90m round (men) calculates correctly', () {
          const roundId = 'wa_1440_90m';
          final result = HandicapCalculator.calculateHandicap(roundId, 1300);
          expect(result, isNotNull);
          expect(result, greaterThan(10));
          expect(result, lessThan(40));
        });

        test('70m round (women) calculates correctly', () {
          const roundId = 'wa_1440_70m';
          final result = HandicapCalculator.calculateHandicap(roundId, 1300);
          expect(result, isNotNull);
        });

        test('same score on 90m vs 70m yields lower HC on 90m', () {
          const score = 1300;
          final hc90m = HandicapCalculator.calculateHandicap('wa_1440_90m', score);
          final hc70m = HandicapCalculator.calculateHandicap('wa_1440_70m', score);

          // 90m is harder, so same score = lower (better) handicap
          // (achieving same score on harder round shows more skill)
          expect(hc90m, lessThan(hc70m!));
        });
      });

      group('Unsupported rounds', () {
        test('returns null for unknown round type', () {
          final result = HandicapCalculator.calculateHandicap('unknown_round', 500);
          expect(result, isNull);
        });

        test('returns null for empty round type', () {
          final result = HandicapCalculator.calculateHandicap('', 500);
          expect(result, isNull);
        });
      });
    });

    group('getScoreForHandicap', () {
      test('returns expected score for handicap 0 on WA 720 70m', () {
        final result = HandicapCalculator.getScoreForHandicap('wa_720_70m', 0);
        expect(result, equals(697));
      });

      test('returns expected score for mid-range handicap', () {
        final result = HandicapCalculator.getScoreForHandicap('wa_720_70m', 50);
        expect(result, isNotNull);
        expect(result, greaterThan(500));
        expect(result, lessThan(600));
      });

      test('returns expected score for handicap 150', () {
        final result = HandicapCalculator.getScoreForHandicap('wa_720_70m', 150);
        expect(result, equals(37));
      });

      test('returns null for negative handicap', () {
        final result = HandicapCalculator.getScoreForHandicap('wa_720_70m', -1);
        expect(result, isNull);
      });

      test('returns null for handicap above 150', () {
        final result = HandicapCalculator.getScoreForHandicap('wa_720_70m', 151);
        expect(result, isNull);
      });

      test('returns null for unknown round type', () {
        final result = HandicapCalculator.getScoreForHandicap('unknown', 50);
        expect(result, isNull);
      });

      test('round-trip: score -> handicap -> score is consistent', () {
        const roundId = 'wa_720_70m';

        for (int hc = 0; hc <= 150; hc += 10) {
          final score = HandicapCalculator.getScoreForHandicap(roundId, hc);
          if (score != null) {
            final calculatedHc = HandicapCalculator.calculateHandicap(roundId, score);
            expect(calculatedHc, equals(hc), reason: 'HC $hc -> score $score -> HC $calculatedHc');
          }
        }
      });
    });

    group('isSupported', () {
      test('returns true for supported outdoor rounds', () {
        expect(HandicapCalculator.isSupported('wa_720_70m'), isTrue);
        expect(HandicapCalculator.isSupported('wa_720_60m'), isTrue);
        expect(HandicapCalculator.isSupported('wa_720_50m'), isTrue);
        expect(HandicapCalculator.isSupported('wa_1440_90m'), isTrue);
        expect(HandicapCalculator.isSupported('wa_1440_70m'), isTrue);
      });

      test('returns true for supported indoor rounds', () {
        expect(HandicapCalculator.isSupported('wa_18m'), isTrue);
        expect(HandicapCalculator.isSupported('wa_25m'), isTrue);
        expect(HandicapCalculator.isSupported('portsmouth'), isTrue);
        expect(HandicapCalculator.isSupported('worcester'), isTrue);
        expect(HandicapCalculator.isSupported('vegas'), isTrue);
      });

      test('returns true for supported imperial rounds', () {
        expect(HandicapCalculator.isSupported('york'), isTrue);
        expect(HandicapCalculator.isSupported('hereford'), isTrue);
        expect(HandicapCalculator.isSupported('bristol_i'), isTrue);
        expect(HandicapCalculator.isSupported('national'), isTrue);
      });

      test('returns true for supported metric rounds', () {
        expect(HandicapCalculator.isSupported('metric_i'), isTrue);
        expect(HandicapCalculator.isSupported('metric_ii'), isTrue);
        expect(HandicapCalculator.isSupported('metric_iii'), isTrue);
      });

      test('returns false for unsupported rounds', () {
        expect(HandicapCalculator.isSupported('unknown_round'), isFalse);
        expect(HandicapCalculator.isSupported(''), isFalse);
        expect(HandicapCalculator.isSupported('WA_720_70M'), isFalse); // Case sensitive
      });
    });

    group('isIndoor', () {
      test('correctly identifies indoor rounds', () {
        expect(HandicapCalculator.isIndoor('wa_18m'), isTrue);
        expect(HandicapCalculator.isIndoor('wa_25m'), isTrue);
        expect(HandicapCalculator.isIndoor('portsmouth'), isTrue);
        expect(HandicapCalculator.isIndoor('worcester'), isTrue);
        expect(HandicapCalculator.isIndoor('vegas'), isTrue);
      });

      test('correctly identifies outdoor rounds', () {
        expect(HandicapCalculator.isIndoor('wa_720_70m'), isFalse);
        expect(HandicapCalculator.isIndoor('wa_720_60m'), isFalse);
        expect(HandicapCalculator.isIndoor('wa_1440_90m'), isFalse);
        expect(HandicapCalculator.isIndoor('york'), isFalse);
        expect(HandicapCalculator.isIndoor('national'), isFalse);
      });

      test('returns false for unknown rounds', () {
        expect(HandicapCalculator.isIndoor('unknown'), isFalse);
        expect(HandicapCalculator.isIndoor(''), isFalse);
      });
    });

    group('Handicap Table Consistency', () {
      test('all tables have 151 entries (HC 0-150)', () {
        final testRounds = [
          'wa_720_70m',
          'wa_720_60m',
          'wa_18m',
          'portsmouth',
          'york',
        ];

        for (final roundId in testRounds) {
          // Test that we can get scores for HC 0 and HC 150
          final hc0 = HandicapCalculator.getScoreForHandicap(roundId, 0);
          final hc150 = HandicapCalculator.getScoreForHandicap(roundId, 150);

          expect(hc0, isNotNull, reason: 'HC 0 should exist for $roundId');
          expect(hc150, isNotNull, reason: 'HC 150 should exist for $roundId');
        }
      });

      test('table scores are monotonically decreasing', () {
        final testRounds = ['wa_720_70m', 'wa_18m', 'york'];

        for (final roundId in testRounds) {
          int? previousScore;

          for (int hc = 0; hc <= 150; hc++) {
            final score = HandicapCalculator.getScoreForHandicap(roundId, hc);
            if (score != null && previousScore != null) {
              expect(
                score,
                lessThanOrEqualTo(previousScore),
                reason: 'Scores should decrease as HC increases for $roundId at HC $hc',
              );
            }
            previousScore = score;
          }
        }
      });

      test('no negative scores in tables', () {
        final testRounds = ['wa_720_70m', 'wa_18m', 'worcester'];

        for (final roundId in testRounds) {
          for (int hc = 0; hc <= 150; hc++) {
            final score = HandicapCalculator.getScoreForHandicap(roundId, hc);
            if (score != null) {
              expect(
                score,
                greaterThanOrEqualTo(0),
                reason: 'No negative scores for $roundId at HC $hc',
              );
            }
          }
        }
      });
    });

    group('Real-World Scenarios', () {
      test('tracks improvement over time', () {
        // Simulate archer improving from 500 to 600 on WA 720 70m
        const roundId = 'wa_720_70m';

        final hc500 = HandicapCalculator.calculateHandicap(roundId, 500);
        final hc550 = HandicapCalculator.calculateHandicap(roundId, 550);
        final hc600 = HandicapCalculator.calculateHandicap(roundId, 600);

        // Higher score = lower (better) handicap
        expect(hc600, lessThan(hc550!));
        expect(hc550, lessThan(hc500!));
      });

      test('compares performance across different rounds', () {
        // An archer who shoots 580/600 indoor and 640/720 outdoor
        final indoorHc = HandicapCalculator.calculateHandicap('wa_18m', 580);
        final outdoorHc = HandicapCalculator.calculateHandicap('wa_720_70m', 640);

        // Both should give reasonable handicaps
        expect(indoorHc, isNotNull);
        expect(outdoorHc, isNotNull);

        // These scores are roughly equivalent level (about 97% and 89%)
        // So handicaps should be in same ballpark (within 10-15 points)
        expect((indoorHc! - outdoorHc!).abs(), lessThan(20));
      });

      test('handles classification boundary scores', () {
        // WA 720 70m classifications (approximate):
        // GMB: 640+, MB: 590+, B1: 540+, B2: 490+, B3: 430+
        final gmbScore = 640;
        final b1Score = 540;
        final b3Score = 430;

        final gmbHc = HandicapCalculator.calculateHandicap('wa_720_70m', gmbScore);
        final b1Hc = HandicapCalculator.calculateHandicap('wa_720_70m', b1Score);
        final b3Hc = HandicapCalculator.calculateHandicap('wa_720_70m', b3Score);

        // GMB should be around 10-15
        expect(gmbHc, lessThan(20));

        // B1 should be around 40-50
        expect(b1Hc, greaterThan(35));
        expect(b1Hc, lessThan(55));

        // B3 should be around 65-80
        expect(b3Hc, greaterThan(60));
        expect(b3Hc, lessThan(85));
      });
    });

    group('Alias Round Types', () {
      test('wa_18_60 maps to wa_18m', () {
        const score = 550;
        final hc18m = HandicapCalculator.calculateHandicap('wa_18m', score);
        final hc18_60 = HandicapCalculator.calculateHandicap('wa_18_60', score);
        expect(hc18_60, equals(hc18m));
      });

      test('vegas_300 maps to vegas', () {
        const score = 550;
        final hcVegas = HandicapCalculator.calculateHandicap('vegas', score);
        final hcVegas300 = HandicapCalculator.calculateHandicap('vegas_300', score);
        expect(hcVegas300, equals(hcVegas));
      });
    });
  });
}
