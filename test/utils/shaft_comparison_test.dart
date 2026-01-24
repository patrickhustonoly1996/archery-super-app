import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/shaft_comparison.dart';
import 'package:archery_super_app/db/database.dart';

void main() {
  group('ShaftComparison', () {
    group('calculateGroupSpread', () {
      test('returns 0 for empty list', () {
        expect(ShaftComparison.calculateGroupSpread([]), 0);
      });

      test('returns 0 for single arrow', () {
        final arrow = _createArrow(xMm: 10, yMm: 10);
        expect(ShaftComparison.calculateGroupSpread([arrow]), 0);
      });

      test('calculates correct spread for two arrows', () {
        final arrows = [
          _createArrow(xMm: 0, yMm: 0),
          _createArrow(xMm: 30, yMm: 40),
        ];
        // Distance = sqrt(30^2 + 40^2) = 50
        expect(ShaftComparison.calculateGroupSpread(arrows), 50);
      });

      test('finds maximum spread among multiple arrows', () {
        final arrows = [
          _createArrow(xMm: 0, yMm: 0),
          _createArrow(xMm: 10, yMm: 10),
          _createArrow(xMm: 60, yMm: 80), // Furthest from origin
        ];
        // Max distance: origin to (60,80) = sqrt(60^2 + 80^2) = 100
        expect(ShaftComparison.calculateGroupSpread(arrows), 100);
      });
    });

    group('calculateGroupCenter', () {
      test('returns (0,0) for empty list', () {
        final center = ShaftComparison.calculateGroupCenter([]);
        expect(center.$1, 0);
        expect(center.$2, 0);
      });

      test('returns arrow position for single arrow', () {
        final arrow = _createArrow(xMm: 25, yMm: 35);
        final center = ShaftComparison.calculateGroupCenter([arrow]);
        expect(center.$1, 25);
        expect(center.$2, 35);
      });

      test('calculates average position for multiple arrows', () {
        final arrows = [
          _createArrow(xMm: 0, yMm: 0),
          _createArrow(xMm: 20, yMm: 40),
          _createArrow(xMm: 40, yMm: 20),
        ];
        final center = ShaftComparison.calculateGroupCenter(arrows);
        expect(center.$1, 20); // (0+20+40)/3
        expect(center.$2, 20); // (0+40+20)/3
      });
    });

    group('calculateAvgDeviation', () {
      test('returns 0 for empty list', () {
        expect(
          ShaftComparison.calculateAvgDeviation([], 0, 0),
          0,
        );
      });

      test('returns 0 when arrow is at center', () {
        final arrow = _createArrow(xMm: 10, yMm: 10);
        expect(
          ShaftComparison.calculateAvgDeviation([arrow], 10, 10),
          0,
        );
      });

      test('calculates average distance from center', () {
        final arrows = [
          _createArrow(xMm: 3, yMm: 4), // Distance 5 from (0,0)
          _createArrow(xMm: 0, yMm: 10), // Distance 10 from (0,0)
        ];
        final avg = ShaftComparison.calculateAvgDeviation(arrows, 0, 0);
        expect(avg, 7.5); // (5+10)/2
      });
    });

    group('ShaftCombinationResult', () {
      test('centerOffsetMm calculates euclidean distance', () {
        final result = ShaftCombinationResult(
          shafts: [],
          arrows: [],
          groupSpreadMm: 0,
          centerXMm: 30,
          centerYMm: 40,
          avgDeviationMm: 0,
        );
        expect(result.centerOffsetMm, 50); // sqrt(30^2 + 40^2)
      });

      test('centerOffsetClock returns 12 for centered group', () {
        final result = ShaftCombinationResult(
          shafts: [],
          arrows: [],
          groupSpreadMm: 0,
          centerXMm: 0,
          centerYMm: 0,
          avgDeviationMm: 0,
        );
        expect(result.centerOffsetClock, 12);
      });
    });

    group('_combinations', () {
      test('generates correct number of combinations', () {
        // 4 choose 2 = 6
        final items = [1, 2, 3, 4];
        final combos = _testCombinations(items, 2);
        expect(combos.length, 6);
      });

      test('generates correct combinations', () {
        final items = ['a', 'b', 'c'];
        final combos = _testCombinations(items, 2);
        expect(combos, containsAll([
          ['a', 'b'],
          ['a', 'c'],
          ['b', 'c'],
        ]));
      });
    });
  });
}

/// Helper to create a mock arrow with specific position
Arrow _createArrow({
  required double xMm,
  required double yMm,
  int rating = 5,
  String? shaftId,
}) {
  return Arrow(
    id: 'arrow-${xMm.hashCode}-${yMm.hashCode}',
    endId: 'end-1',
    faceIndex: 0,
    x: xMm / 150, // Normalized
    y: yMm / 150,
    xMm: xMm,
    yMm: yMm,
    score: 10,
    isX: false,
    sequence: 1,
    shaftId: shaftId,
    shaftNumber: 1,
    nockRotation: null,
    rating: rating,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    deletedAt: null,
  );
}

/// Expose _combinations for testing (workaround since it's private)
List<List<T>> _testCombinations<T>(List<T> items, int k) {
  if (k == 0) return [[]];
  if (items.isEmpty) return [];
  if (k == items.length) return [items];

  final result = <List<T>>[];

  final withFirst = _testCombinations(items.sublist(1), k - 1);
  for (final combo in withFirst) {
    result.add([items[0], ...combo]);
  }

  result.addAll(_testCombinations(items.sublist(1), k));

  return result;
}
