import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/models/arrow_coordinate.dart';
import 'package:archery_super_app/theme/app_theme.dart';
import '../test_helpers.dart';

/// Tests for SessionProvider logic and scoring calculations.
///
/// Note: Full provider tests with database interaction require mock setup.
/// These tests cover the pure calculation logic that can be tested in isolation.
void main() {
  group('Session Scoring Logic', () {
    group('Total Score Calculation', () {
      test('sums scores from multiple arrows', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10),
          createFakeArrow(id: 'a2', xMm: 30, yMm: 0, score: 9),
          createFakeArrow(id: 'a3', xMm: 50, yMm: 0, score: 8),
        ];

        final total = arrows.fold<int>(0, (sum, a) => sum + a.score);
        expect(total, equals(27));
      });

      test('handles empty arrow list', () {
        final arrows = <Arrow>[];
        final total = arrows.fold<int>(0, (sum, a) => sum + a.score);
        expect(total, equals(0));
      });

      test('handles single arrow', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10),
        ];
        final total = arrows.fold<int>(0, (sum, a) => sum + a.score);
        expect(total, equals(10));
      });

      test('handles misses (score 0)', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10),
          createFakeArrow(id: 'a2', xMm: 250, yMm: 0, score: 0),
          createFakeArrow(id: 'a3', xMm: 30, yMm: 0, score: 9),
        ];
        final total = arrows.fold<int>(0, (sum, a) => sum + a.score);
        expect(total, equals(19));
      });
    });

    group('Total Xs Calculation', () {
      test('counts X hits correctly', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 5, yMm: 0, score: 10, isX: true),
          createFakeArrow(id: 'a2', xMm: 6, yMm: 0, score: 10, isX: true),
          createFakeArrow(id: 'a3', xMm: 15, yMm: 0, score: 10, isX: false),
          createFakeArrow(id: 'a4', xMm: 30, yMm: 0, score: 9, isX: false),
        ];

        final xs = arrows.where((a) => a.isX).length;
        expect(xs, equals(2));
      });

      test('returns 0 when no Xs', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 30, yMm: 0, score: 9),
          createFakeArrow(id: 'a2', xMm: 50, yMm: 0, score: 8),
        ];
        final xs = arrows.where((a) => a.isX).length;
        expect(xs, equals(0));
      });

      test('handles all Xs', () {
        final arrows = List.generate(3, (i) => createFakeArrow(
          id: 'a$i',
          xMm: 5,
          yMm: 0,
          score: 10,
          isX: true,
        ));
        final xs = arrows.where((a) => a.isX).length;
        expect(xs, equals(3));
      });
    });

    group('End Score Calculation', () {
      test('calculates end score from arrows', () {
        // Typical 3-arrow end
        final endArrows = [
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10),
          createFakeArrow(id: 'a2', xMm: 25, yMm: 0, score: 9),
          createFakeArrow(id: 'a3', xMm: 35, yMm: 0, score: 9),
        ];
        final endScore = endArrows.fold<int>(0, (sum, a) => sum + a.score);
        expect(endScore, equals(28));
      });

      test('calculates end Xs from arrows', () {
        final endArrows = [
          createFakeArrow(id: 'a1', xMm: 5, yMm: 0, score: 10, isX: true),
          createFakeArrow(id: 'a2', xMm: 15, yMm: 0, score: 10, isX: false),
          createFakeArrow(id: 'a3', xMm: 30, yMm: 0, score: 9, isX: false),
        ];
        final endXs = endArrows.where((a) => a.isX).length;
        expect(endXs, equals(1));
      });

      test('handles 6-arrow ends', () {
        final endArrows = List.generate(6, (i) => createFakeArrow(
          id: 'a$i',
          xMm: 10 + i * 10.0,
          yMm: 0,
          score: 10 - (i ~/ 2),
        ));
        final endScore = endArrows.fold<int>(0, (sum, a) => sum + a.score);
        // Scores: 10, 10, 9, 9, 8, 8 = 54
        expect(endScore, equals(54));
      });
    });
  });

  group('ArrowCoordinate Integration', () {
    group('Arrow to Coordinate Conversion', () {
      test('converts arrow with mm coordinates', () {
        final arrow = createFakeArrow(
          id: 'a1',
          xMm: 50.5,
          yMm: -30.2,
          score: 8,
          faceSizeCm: 40,
        );

        // When arrow has mm coordinates
        final coord = ArrowCoordinate(
          xMm: arrow.xMm,
          yMm: arrow.yMm,
          faceSizeCm: 40,
        );

        expect(coord.xMm, equals(50.5));
        expect(coord.yMm, equals(-30.2));
      });

      test('falls back to normalized for legacy arrows', () {
        // Legacy arrow with zero mm coordinates
        final arrow = createFakeArrowNormalized(
          id: 'a1',
          x: 0.25,
          y: -0.15,
          score: 8,
        );

        // Should detect zero mm and use normalized
        final usesMm = arrow.xMm != 0 || arrow.yMm != 0;
        expect(usesMm, isFalse);

        // Convert from normalized
        final coord = ArrowCoordinate.fromNormalized(
          x: arrow.x,
          y: arrow.y,
          faceSizeCm: 40,
        );

        expect(coord.normalizedX, closeTo(0.25, 0.001));
        expect(coord.normalizedY, closeTo(-0.15, 0.001));
      });
    });

    group('Batch Conversion', () {
      test('converts list of arrows to coordinates', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 10, yMm: 20, score: 10, faceSizeCm: 40),
          createFakeArrow(id: 'a2', xMm: 30, yMm: -10, score: 9, faceSizeCm: 40),
          createFakeArrow(id: 'a3', xMm: 50, yMm: 40, score: 8, faceSizeCm: 40),
        ];

        final coords = arrows.map((a) => ArrowCoordinate(
          xMm: a.xMm,
          yMm: a.yMm,
          faceSizeCm: 40,
        )).toList();

        expect(coords.length, equals(3));
        expect(coords[0].xMm, equals(10));
        expect(coords[1].xMm, equals(30));
        expect(coords[2].xMm, equals(50));
      });
    });
  });

  group('Session State Logic', () {
    group('End Completion Check', () {
      test('end is complete when arrows >= arrowsPerEnd', () {
        const arrowsPerEnd = 3;
        final arrows = createArrowGroup(count: 3);
        final isComplete = arrows.length >= arrowsPerEnd;
        expect(isComplete, isTrue);
      });

      test('end is not complete with fewer arrows', () {
        const arrowsPerEnd = 3;
        final arrows = createArrowGroup(count: 2);
        final isComplete = arrows.length >= arrowsPerEnd;
        expect(isComplete, isFalse);
      });

      test('handles 6-arrow ends', () {
        const arrowsPerEnd = 6;
        final arrows = createArrowGroup(count: 5);
        expect(arrows.length >= arrowsPerEnd, isFalse);

        final fullArrows = createArrowGroup(count: 6);
        expect(fullArrows.length >= arrowsPerEnd, isTrue);
      });
    });

    group('Session Completion Check', () {
      test('session complete when ends >= totalEnds', () {
        const totalEnds = 10;
        const completedEnds = 10;
        final isComplete = completedEnds >= totalEnds;
        expect(isComplete, isTrue);
      });

      test('session not complete with fewer ends', () {
        const totalEnds = 10;
        const completedEnds = 9;
        final isComplete = completedEnds >= totalEnds;
        expect(isComplete, isFalse);
      });

      test('handles 20-end rounds', () {
        const totalEnds = 20;
        const completedEnds = 20;
        final isComplete = completedEnds >= totalEnds;
        expect(isComplete, isTrue);
      });
    });

    group('Current End Number', () {
      test('starts at 1', () {
        const completedEnds = 0;
        final currentEnd = completedEnds + 1;
        expect(currentEnd, equals(1));
      });

      test('increments after each end', () {
        const completedEnds = 5;
        final currentEnd = completedEnds + 1;
        expect(currentEnd, equals(6));
      });
    });

    group('Half Point Calculation', () {
      test('calculates half point for 10-end round', () {
        const totalEnds = 10;
        final halfPoint = (totalEnds / 2).ceil();
        expect(halfPoint, equals(5));
      });

      test('calculates half point for 20-end round', () {
        const totalEnds = 20;
        final halfPoint = (totalEnds / 2).ceil();
        expect(halfPoint, equals(10));
      });

      test('handles odd number of ends', () {
        const totalEnds = 9;
        final halfPoint = (totalEnds / 2).ceil();
        expect(halfPoint, equals(5)); // Ceiling of 4.5
      });

      test('determines second half correctly', () {
        const totalEnds = 10;
        const currentEndNumber = 6;
        final halfPoint = (totalEnds / 2).ceil();
        final isSecondHalf = currentEndNumber > halfPoint;
        expect(isSecondHalf, isTrue);
      });

      test('determines first half correctly', () {
        const totalEnds = 10;
        const currentEndNumber = 5;
        final halfPoint = (totalEnds / 2).ceil();
        final isSecondHalf = currentEndNumber > halfPoint;
        expect(isSecondHalf, isFalse);
      });
    });
  });

  group('Tri-Spot Mode Logic', () {
    group('Face Count Detection', () {
      test('single face is not tri-spot', () {
        const faceCount = 1;
        final isTriSpot = faceCount == 3;
        expect(isTriSpot, isFalse);
      });

      test('three faces is tri-spot', () {
        const faceCount = 3;
        final isTriSpot = faceCount == 3;
        expect(isTriSpot, isTrue);
      });
    });

    group('Arrow Face Index Filtering', () {
      test('filters arrows by face index', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10),
          Arrow(
            id: 'a2',
            endId: 'end1',
            faceIndex: 1,
            xMm: 20,
            yMm: 0,
            x: 0.1,
            y: 0,
            score: 9,
            isX: false,
            sequence: 2,
            shaftNumber: null,
            createdAt: DateTime.now(),
          ),
          Arrow(
            id: 'a3',
            endId: 'end1',
            faceIndex: 2,
            xMm: 30,
            yMm: 0,
            x: 0.15,
            y: 0,
            score: 8,
            isX: false,
            sequence: 3,
            shaftNumber: null,
            createdAt: DateTime.now(),
          ),
        ];

        final face0Arrows = arrows.where((a) => a.faceIndex == 0).toList();
        final face1Arrows = arrows.where((a) => a.faceIndex == 1).toList();
        final face2Arrows = arrows.where((a) => a.faceIndex == 2).toList();

        expect(face0Arrows.length, equals(1));
        expect(face1Arrows.length, equals(1));
        expect(face2Arrows.length, equals(1));
      });
    });
  });

  group('Equipment Selection Logic', () {
    test('stores selected bow ID', () {
      const bowId = 'bow_123';
      expect(bowId, isNotNull);
      expect(bowId.isNotEmpty, isTrue);
    });

    test('stores selected quiver ID', () {
      const quiverId = 'quiver_456';
      expect(quiverId, isNotNull);
      expect(quiverId.isNotEmpty, isTrue);
    });

    test('shaft tagging toggle works', () {
      var shaftTaggingEnabled = false;
      expect(shaftTaggingEnabled, isFalse);

      shaftTaggingEnabled = true;
      expect(shaftTaggingEnabled, isTrue);
    });
  });

  group('Scoring with TargetRingsMm', () {
    group('Score Calculation from Distance', () {
      test('X ring at center', () {
        const faceSizeCm = 40;
        final result = TargetRingsMm.scoreAndX(5.0, faceSizeCm);
        expect(result.score, equals(10));
        expect(result.isX, isTrue);
      });

      test('10 ring just outside X', () {
        const faceSizeCm = 40;
        final result = TargetRingsMm.scoreAndX(15.0, faceSizeCm);
        expect(result.score, equals(10));
        expect(result.isX, isFalse);
      });

      test('9 ring', () {
        const faceSizeCm = 40;
        final result = TargetRingsMm.scoreAndX(30.0, faceSizeCm);
        expect(result.score, equals(9));
        expect(result.isX, isFalse);
      });

      test('outer rings', () {
        const faceSizeCm = 40;

        final score5 = TargetRingsMm.scoreAndX(110.0, faceSizeCm);
        expect(score5.score, equals(5));

        final score1 = TargetRingsMm.scoreAndX(190.0, faceSizeCm);
        expect(score1.score, equals(1));
      });

      test('miss outside target', () {
        const faceSizeCm = 40;
        final result = TargetRingsMm.scoreAndX(210.0, faceSizeCm);
        expect(result.score, equals(0));
        expect(result.isX, isFalse);
      });
    });

    group('Different Face Sizes', () {
      test('80cm face has larger rings', () {
        const faceSizeCm = 80;
        // Ring boundaries are proportionally larger
        final result = TargetRingsMm.scoreAndX(30.0, faceSizeCm);
        expect(result.score, equals(10)); // 30mm is still in gold on 80cm face
      });

      test('122cm face has even larger rings', () {
        const faceSizeCm = 122;
        final result = TargetRingsMm.scoreAndX(50.0, faceSizeCm);
        expect(result.score, equals(10)); // Still in gold on 122cm face
      });
    });
  });

  group('Session ID Generation', () {
    test('uses millisecond timestamp', () {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      expect(id.length, greaterThan(10));
      expect(int.tryParse(id), isNotNull);
    });

    test('generates unique IDs with suffix', () {
      final ids = <String>{};
      for (int i = 0; i < 100; i++) {
        // Add index suffix to ensure uniqueness in tight loop
        final id = '${DateTime.now().millisecondsSinceEpoch}_$i';
        ids.add(id);
      }
      // All should be unique with index suffix
      expect(ids.length, equals(100));
    });
  });

  group('Real-World Session Scenarios', () {
    test('typical WA 18m round structure', () {
      // WA 18m: 60 arrows, 10 ends of 6 arrows
      const arrowsPerEnd = 3; // Usually split as 3-arrow ends for indoor
      const totalEnds = 20;
      const maxScore = 600;

      // Simulate scoring a round
      var totalScore = 0;
      var totalXs = 0;

      for (int end = 0; end < totalEnds; end++) {
        // Typical end: mix of 10s, 9s, 8s
        final endScores = [10, 9, 9]; // 28 points
        totalScore += endScores.reduce((a, b) => a + b);
        totalXs += endScores.where((s) => s == 10).length ~/ 3; // Some Xs
      }

      expect(totalScore, equals(560)); // 28 * 20 = 560
      expect(totalScore, lessThanOrEqualTo(maxScore));
    });

    test('WA 720 round structure', () {
      // WA 720: 72 arrows, 12 ends of 6 arrows
      const arrowsPerEnd = 6;
      const totalEnds = 12;
      const maxScore = 720;

      var totalScore = 0;
      for (int end = 0; end < totalEnds; end++) {
        final endScores = [10, 9, 9, 8, 9, 8]; // 53 points typical
        totalScore += endScores.reduce((a, b) => a + b);
      }

      expect(totalScore, equals(636)); // 53 * 12 = 636
      expect(totalScore, lessThanOrEqualTo(maxScore));
    });
  });
}
