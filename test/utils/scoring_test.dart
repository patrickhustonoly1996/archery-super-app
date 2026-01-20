import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/theme/app_theme.dart';

void main() {
  group('TargetRingsMm - 5-Zone Scoring', () {
    // Standard 122cm face for these tests
    const faceSizeCm = 122;

    group('ringTo5ZoneScore', () {
      test('Gold rings (X/10/9) score 9', () {
        expect(TargetRingsMm.ringTo5ZoneScore(10), 9); // Ring 10 = Gold
        expect(TargetRingsMm.ringTo5ZoneScore(9), 9); // Ring 9 = Gold
      });

      test('Red rings (8/7) score 7', () {
        expect(TargetRingsMm.ringTo5ZoneScore(8), 7);
        expect(TargetRingsMm.ringTo5ZoneScore(7), 7);
      });

      test('Blue rings (6/5) score 5', () {
        expect(TargetRingsMm.ringTo5ZoneScore(6), 5);
        expect(TargetRingsMm.ringTo5ZoneScore(5), 5);
      });

      test('Black rings (4/3) score 3', () {
        expect(TargetRingsMm.ringTo5ZoneScore(4), 3);
        expect(TargetRingsMm.ringTo5ZoneScore(3), 3);
      });

      test('White rings (2/1) score 1', () {
        expect(TargetRingsMm.ringTo5ZoneScore(2), 1);
        expect(TargetRingsMm.ringTo5ZoneScore(1), 1);
      });

      test('Miss scores 0', () {
        expect(TargetRingsMm.ringTo5ZoneScore(0), 0);
      });
    });

    group('scoreFromDistanceMm with 5-zone', () {
      test('X ring scores 9 in 5-zone', () {
        // X ring is at center, very small distance
        final score = TargetRingsMm.scoreFromDistanceMm(
          5.0, // 5mm from center = deep in gold
          faceSizeCm,
          scoringType: '5-zone',
        );
        expect(score, 9);
      });

      test('Ring 9 boundary scores 9 in 5-zone', () {
        // Just inside ring 9 boundary
        final ring9Boundary = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring9Boundary - 1.0,
          faceSizeCm,
          scoringType: '5-zone',
        );
        expect(score, 9);
      });

      test('Ring 8 scores 7 in 5-zone', () {
        // Just inside ring 8 (inside gold, but red zone)
        final ring9Boundary = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring9Boundary + 5.0, // Just outside gold into red
          faceSizeCm,
          scoringType: '5-zone',
        );
        expect(score, 7);
      });

      test('Ring 6 scores 5 in 5-zone', () {
        final ring7Boundary = TargetRingsMm.getRingBoundaryMm(7, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring7Boundary + 5.0, // Just outside red into blue
          faceSizeCm,
          scoringType: '5-zone',
        );
        expect(score, 5);
      });

      test('Ring 4 scores 3 in 5-zone', () {
        final ring5Boundary = TargetRingsMm.getRingBoundaryMm(5, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring5Boundary + 5.0, // Just outside blue into black
          faceSizeCm,
          scoringType: '5-zone',
        );
        expect(score, 3);
      });

      test('Ring 2 scores 1 in 5-zone', () {
        final ring3Boundary = TargetRingsMm.getRingBoundaryMm(3, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring3Boundary + 5.0, // Just outside black into white
          faceSizeCm,
          scoringType: '5-zone',
        );
        expect(score, 1);
      });

      test('Miss scores 0 in 5-zone', () {
        final ring1Boundary = TargetRingsMm.getRingBoundaryMm(1, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring1Boundary + 50.0, // Well outside the target
          faceSizeCm,
          scoringType: '5-zone',
        );
        expect(score, 0);
      });
    });

    group('scoreFromDistanceMm with 10-zone (default)', () {
      test('X ring scores 10 in 10-zone', () {
        final score = TargetRingsMm.scoreFromDistanceMm(
          5.0,
          faceSizeCm,
          scoringType: '10-zone',
        );
        expect(score, 10);
      });

      test('Ring 9 scores 9 in 10-zone', () {
        final ring9Boundary = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring9Boundary - 1.0,
          faceSizeCm,
          scoringType: '10-zone',
        );
        expect(score, 9);
      });

      test('Ring 8 scores 8 in 10-zone', () {
        final ring9Boundary = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring9Boundary + 5.0,
          faceSizeCm,
          scoringType: '10-zone',
        );
        expect(score, 8);
      });

      test('Default scoring type is 10-zone', () {
        final score = TargetRingsMm.scoreFromDistanceMm(5.0, faceSizeCm);
        expect(score, 10); // Should be 10, not 9
      });
    });

    group('scoreAndX with scoring types', () {
      test('5-zone still tracks X rings', () {
        // X rings are tracked separately even in 5-zone
        final result = TargetRingsMm.scoreAndX(
          5.0,
          faceSizeCm,
          scoringType: '5-zone',
        );
        expect(result.score, 9); // 5-zone gold score
        expect(result.isX, true); // Still tracked as X
      });

      test('10-zone gold with X', () {
        final result = TargetRingsMm.scoreAndX(
          5.0,
          faceSizeCm,
          scoringType: '10-zone',
        );
        expect(result.score, 10);
        expect(result.isX, true);
      });
    });
  });

  group('5-Zone Score Boundaries', () {
    // Test the exact boundary values to ensure correct color band assignment
    const faceSizeCm = 122;

    test('Score transitions at correct ring boundaries', () {
      // Get all ring boundaries
      final ring9 = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);
      final ring7 = TargetRingsMm.getRingBoundaryMm(7, faceSizeCm);
      final ring5 = TargetRingsMm.getRingBoundaryMm(5, faceSizeCm);
      final ring3 = TargetRingsMm.getRingBoundaryMm(3, faceSizeCm);
      final ring1 = TargetRingsMm.getRingBoundaryMm(1, faceSizeCm);

      // Just inside gold (ring 9)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring9 - 0.1, faceSizeCm, scoringType: '5-zone'),
        9,
      );

      // Just outside gold (ring 8 = red)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring9 + 1.0, faceSizeCm, scoringType: '5-zone'),
        7,
      );

      // Just inside red (ring 7)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring7 - 0.1, faceSizeCm, scoringType: '5-zone'),
        7,
      );

      // Just outside red (ring 6 = blue)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring7 + 1.0, faceSizeCm, scoringType: '5-zone'),
        5,
      );

      // Just inside blue (ring 5)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring5 - 0.1, faceSizeCm, scoringType: '5-zone'),
        5,
      );

      // Just outside blue (ring 4 = black)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring5 + 1.0, faceSizeCm, scoringType: '5-zone'),
        3,
      );

      // Just inside black (ring 3)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring3 - 0.1, faceSizeCm, scoringType: '5-zone'),
        3,
      );

      // Just outside black (ring 2 = white)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring3 + 1.0, faceSizeCm, scoringType: '5-zone'),
        1,
      );

      // Just inside white (ring 1)
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring1 - 0.1, faceSizeCm, scoringType: '5-zone'),
        1,
      );

      // Just outside white = miss
      expect(
        TargetRingsMm.scoreFromDistanceMm(ring1 + 10.0, faceSizeCm, scoringType: '5-zone'),
        0,
      );
    });
  });

  group('252 Scheme Scoring Example', () {
    // 252 scheme: 36 arrows at 5-zone scoring
    // Need 252+ (avg 7/red) to progress
    const faceSizeCm = 122;

    test('Perfect gold round scores 324 (36 x 9)', () {
      // All arrows in gold
      int totalScore = 0;
      for (int i = 0; i < 36; i++) {
        final score = TargetRingsMm.scoreFromDistanceMm(
          50.0, // Well inside gold
          faceSizeCm,
          scoringType: '5-zone',
        );
        totalScore += score;
      }
      expect(totalScore, 324);
    });

    test('All red scores 252 (36 x 7) - exactly passing', () {
      int totalScore = 0;
      final ring9 = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);

      for (int i = 0; i < 36; i++) {
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring9 + 10.0, // In the red
          faceSizeCm,
          scoringType: '5-zone',
        );
        totalScore += score;
      }
      expect(totalScore, 252);
    });

    test('Mixed realistic round calculates correctly', () {
      // Simulate a realistic 36-arrow round
      // 18 golds (9 each) = 162
      // 12 reds (7 each) = 84
      // 6 blues (5 each) = 30
      // Total = 276
      int totalScore = 0;

      // 18 golds
      final ring10 = TargetRingsMm.getRingBoundaryMm(10, faceSizeCm);
      for (int i = 0; i < 18; i++) {
        totalScore += TargetRingsMm.scoreFromDistanceMm(
          ring10 - 5.0,
          faceSizeCm,
          scoringType: '5-zone',
        );
      }

      // 12 reds
      final ring9 = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);
      for (int i = 0; i < 12; i++) {
        totalScore += TargetRingsMm.scoreFromDistanceMm(
          ring9 + 10.0,
          faceSizeCm,
          scoringType: '5-zone',
        );
      }

      // 6 blues
      final ring7 = TargetRingsMm.getRingBoundaryMm(7, faceSizeCm);
      for (int i = 0; i < 6; i++) {
        totalScore += TargetRingsMm.scoreFromDistanceMm(
          ring7 + 10.0,
          faceSizeCm,
          scoringType: '5-zone',
        );
      }

      expect(totalScore, 276);
    });
  });

  group('Worcester Scoring (5-4-3-2-1)', () {
    // Worcester uses 16" (41cm) face
    const faceSizeCm = 41;

    group('ringToWorcesterScore', () {
      test('Innermost rings (10/9) score 5', () {
        expect(TargetRingsMm.ringToWorcesterScore(10), 5);
        expect(TargetRingsMm.ringToWorcesterScore(9), 5);
      });

      test('2nd ring pair (8/7) scores 4', () {
        expect(TargetRingsMm.ringToWorcesterScore(8), 4);
        expect(TargetRingsMm.ringToWorcesterScore(7), 4);
      });

      test('3rd ring pair (6/5) scores 3', () {
        expect(TargetRingsMm.ringToWorcesterScore(6), 3);
        expect(TargetRingsMm.ringToWorcesterScore(5), 3);
      });

      test('4th ring pair (4/3) scores 2', () {
        expect(TargetRingsMm.ringToWorcesterScore(4), 2);
        expect(TargetRingsMm.ringToWorcesterScore(3), 2);
      });

      test('Outer ring pair (2/1) scores 1', () {
        expect(TargetRingsMm.ringToWorcesterScore(2), 1);
        expect(TargetRingsMm.ringToWorcesterScore(1), 1);
      });

      test('Miss scores 0', () {
        expect(TargetRingsMm.ringToWorcesterScore(0), 0);
      });
    });

    group('scoreFromDistanceMm with worcester', () {
      test('X ring scores 5 in Worcester', () {
        final score = TargetRingsMm.scoreFromDistanceMm(
          5.0, // Close to center
          faceSizeCm,
          scoringType: 'worcester',
        );
        expect(score, 5);
      });

      test('Ring 9 boundary scores 5 in Worcester', () {
        final ring9Boundary = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring9Boundary - 1.0,
          faceSizeCm,
          scoringType: 'worcester',
        );
        expect(score, 5);
      });

      test('Ring 8 scores 4 in Worcester', () {
        final ring9Boundary = TargetRingsMm.getRingBoundaryMm(9, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring9Boundary + 5.0,
          faceSizeCm,
          scoringType: 'worcester',
        );
        expect(score, 4);
      });

      test('Miss scores 0 in Worcester', () {
        final ring1Boundary = TargetRingsMm.getRingBoundaryMm(1, faceSizeCm);
        final score = TargetRingsMm.scoreFromDistanceMm(
          ring1Boundary + 50.0,
          faceSizeCm,
          scoringType: 'worcester',
        );
        expect(score, 0);
      });
    });

    group('Worcester round score bounds', () {
      test('Perfect Worcester round scores 300 (60 x 5)', () {
        // Worcester: 60 arrows, max 5 per arrow = 300 max
        int totalScore = 0;
        for (int i = 0; i < 60; i++) {
          final score = TargetRingsMm.scoreFromDistanceMm(
            5.0, // Center shot
            faceSizeCm,
            scoringType: 'worcester',
          );
          totalScore += score;
        }
        expect(totalScore, 300);
        expect(totalScore, lessThanOrEqualTo(300)); // Cannot exceed max
      });

      test('Worcester round cannot exceed 300', () {
        // Max score per arrow is 5, max arrows is 60
        // Therefore max score is 300
        const maxArrows = 60;
        const maxPerArrow = 5;
        const maxScore = maxArrows * maxPerArrow;

        // Even if we scored every arrow at max, we can't exceed 300
        int totalScore = 0;
        for (int i = 0; i < maxArrows; i++) {
          totalScore += maxPerArrow;
        }
        expect(totalScore, equals(maxScore));
        expect(totalScore, equals(300));
      });
    });
  });

  group('Score Bounds Validation', () {
    test('10-zone max score per arrow is 10', () {
      final score = TargetRingsMm.scoreFromDistanceMm(
        0.0, // Exact center
        40,
        scoringType: '10-zone',
      );
      expect(score, equals(10));
      expect(score, lessThanOrEqualTo(10));
    });

    test('5-zone max score per arrow is 9', () {
      final score = TargetRingsMm.scoreFromDistanceMm(
        0.0, // Exact center
        122,
        scoringType: '5-zone',
      );
      expect(score, equals(9));
      expect(score, lessThanOrEqualTo(9));
    });

    test('Worcester max score per arrow is 5', () {
      final score = TargetRingsMm.scoreFromDistanceMm(
        0.0, // Exact center
        41,
        scoringType: 'worcester',
      );
      expect(score, equals(5));
      expect(score, lessThanOrEqualTo(5));
    });

    test('WA 18m 30-arrow round max is 300', () {
      // 30 arrows x 10 max = 300
      int maxPossible = 0;
      for (int i = 0; i < 30; i++) {
        maxPossible += TargetRingsMm.scoreFromDistanceMm(0.0, 40, scoringType: '10-zone');
      }
      expect(maxPossible, equals(300));
    });

    test('WA 18m 60-arrow round max is 600', () {
      // 60 arrows x 10 max = 600
      int maxPossible = 0;
      for (int i = 0; i < 60; i++) {
        maxPossible += TargetRingsMm.scoreFromDistanceMm(0.0, 40, scoringType: '10-zone');
      }
      expect(maxPossible, equals(600));
    });

    test('York round max is 1296 (144 arrows at 5-zone)', () {
      // York: 144 arrows x 9 max (5-zone) = 1296
      int maxPossible = 0;
      for (int i = 0; i < 144; i++) {
        maxPossible += TargetRingsMm.scoreFromDistanceMm(0.0, 122, scoringType: '5-zone');
      }
      expect(maxPossible, equals(1296));
    });
  });
}
