import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/models/distance_leg.dart';

void main() {
  group('DistanceLeg', () {
    test('creates distance leg with required fields', () {
      final leg = DistanceLeg(
        distance: 100,
        unit: 'yd',
        arrowCount: 72,
      );

      expect(leg.distance, 100);
      expect(leg.unit, 'yd');
      expect(leg.arrowCount, 72);
      expect(leg.faceSize, isNull);
    });

    test('creates distance leg with optional face size', () {
      final leg = DistanceLeg(
        distance: 50,
        unit: 'm',
        arrowCount: 36,
        faceSize: 80,
      );

      expect(leg.faceSize, 80);
    });

    test('calculates ends for arrows per end', () {
      final leg = DistanceLeg(
        distance: 100,
        unit: 'yd',
        arrowCount: 72,
      );

      expect(leg.endsForArrowsPerEnd(6), 12); // 72 / 6 = 12 ends
      expect(leg.endsForArrowsPerEnd(3), 24); // 72 / 3 = 24 ends
    });

    test('displays distance with unit', () {
      final yardLeg = DistanceLeg(distance: 100, unit: 'yd', arrowCount: 72);
      final meterLeg = DistanceLeg(distance: 70, unit: 'm', arrowCount: 36);

      expect(yardLeg.displayDistance, '100yd');
      expect(meterLeg.displayDistance, '70m');
    });

    test('serializes to JSON', () {
      final leg = DistanceLeg(
        distance: 100,
        unit: 'yd',
        arrowCount: 72,
        faceSize: 122,
      );

      final json = leg.toJson();

      expect(json['distance'], 100);
      expect(json['unit'], 'yd');
      expect(json['arrowCount'], 72);
      expect(json['faceSize'], 122);
    });

    test('deserializes from JSON', () {
      final json = {
        'distance': 80,
        'unit': 'yd',
        'arrowCount': 48,
      };

      final leg = DistanceLeg.fromJson(json);

      expect(leg.distance, 80);
      expect(leg.unit, 'yd');
      expect(leg.arrowCount, 48);
      expect(leg.faceSize, isNull);
    });

    test('deserializes with default unit', () {
      final json = {
        'distance': 70,
        'arrowCount': 36,
      };

      final leg = DistanceLeg.fromJson(json);

      expect(leg.unit, 'm'); // Default unit
    });
  });

  group('DistanceLegsParser', () {
    test('parses valid JSON string', () {
      const json =
          '[{"distance":100,"unit":"yd","arrowCount":72},{"distance":80,"unit":"yd","arrowCount":48}]';

      final legs = json.parseDistanceLegs();

      expect(legs, isNotNull);
      expect(legs!.length, 2);
      expect(legs[0].distance, 100);
      expect(legs[1].distance, 80);
    });

    test('returns null for null string', () {
      String? nullString;
      expect(nullString.parseDistanceLegs(), isNull);
    });

    test('returns null for empty string', () {
      expect(''.parseDistanceLegs(), isNull);
    });

    test('returns null for invalid JSON', () {
      expect('invalid json'.parseDistanceLegs(), isNull);
    });
  });

  group('DistanceLegsEncoder', () {
    test('encodes list to JSON string', () {
      final legs = [
        DistanceLeg(distance: 100, unit: 'yd', arrowCount: 72),
        DistanceLeg(distance: 80, unit: 'yd', arrowCount: 48),
      ];

      final json = legs.toDistanceLegsJson();

      expect(json, contains('"distance":100'));
      expect(json, contains('"distance":80'));
    });
  });

  group('DistanceLegTracker', () {
    late DistanceLegTracker tracker;

    setUp(() {
      // York round: 72 at 100yd, 48 at 80yd, 24 at 60yd = 144 arrows = 24 ends
      tracker = DistanceLegTracker(
        legs: [
          DistanceLeg(distance: 100, unit: 'yd', arrowCount: 72),
          DistanceLeg(distance: 80, unit: 'yd', arrowCount: 48),
          DistanceLeg(distance: 60, unit: 'yd', arrowCount: 24),
        ],
        arrowsPerEnd: 6,
      );
    });

    test('identifies multi-distance round', () {
      expect(tracker.isMultiDistance, isTrue);

      final singleDistance = DistanceLegTracker(
        legs: [DistanceLeg(distance: 70, unit: 'm', arrowCount: 72)],
        arrowsPerEnd: 6,
      );
      expect(singleDistance.isMultiDistance, isFalse);
    });

    test('calculates leg boundaries', () {
      // York: 12 ends at 100yd, 8 ends at 80yd, 4 ends at 60yd
      expect(tracker.legBoundaryEnds, [12, 20, 24]);
    });

    test('identifies leg boundary ends', () {
      expect(tracker.isLegBoundary(12), isTrue);
      expect(tracker.isLegBoundary(20), isTrue);
      expect(tracker.isLegBoundary(24), isTrue);
      expect(tracker.isLegBoundary(11), isFalse);
      expect(tracker.isLegBoundary(13), isFalse);
    });

    test('gets leg index for end number', () {
      // Ends 1-12 are at 100yd (leg 0)
      expect(tracker.getLegIndexForEnd(1), 0);
      expect(tracker.getLegIndexForEnd(6), 0);
      expect(tracker.getLegIndexForEnd(12), 0);

      // Ends 13-20 are at 80yd (leg 1)
      expect(tracker.getLegIndexForEnd(13), 1);
      expect(tracker.getLegIndexForEnd(16), 1);
      expect(tracker.getLegIndexForEnd(20), 1);

      // Ends 21-24 are at 60yd (leg 2)
      expect(tracker.getLegIndexForEnd(21), 2);
      expect(tracker.getLegIndexForEnd(24), 2);
    });

    test('gets leg for end number', () {
      expect(tracker.getLegForEnd(1).distance, 100);
      expect(tracker.getLegForEnd(12).distance, 100);
      expect(tracker.getLegForEnd(13).distance, 80);
      expect(tracker.getLegForEnd(21).distance, 60);
    });

    test('calculates first end of leg', () {
      expect(tracker.firstEndOfLeg(0), 1);
      expect(tracker.firstEndOfLeg(1), 13);
      expect(tracker.firstEndOfLeg(2), 21);
    });

    test('calculates last end of leg', () {
      expect(tracker.lastEndOfLeg(0), 12);
      expect(tracker.lastEndOfLeg(1), 20);
      expect(tracker.lastEndOfLeg(2), 24);
    });

    test('calculates cumulative arrows', () {
      expect(tracker.cumulativeArrowsAtLeg(0), 72);
      expect(tracker.cumulativeArrowsAtLeg(1), 120); // 72 + 48
      expect(tracker.cumulativeArrowsAtLeg(2), 144); // 72 + 48 + 24
    });
  });

  group('WA 1440 Multi-Distance', () {
    test('handles 4-distance WA 1440 round', () {
      // WA 1440: 36 arrows at each of 4 distances = 144 arrows = 24 ends (6 per distance)
      final tracker = DistanceLegTracker(
        legs: [
          DistanceLeg(distance: 90, unit: 'm', arrowCount: 36),
          DistanceLeg(distance: 70, unit: 'm', arrowCount: 36),
          DistanceLeg(distance: 50, unit: 'm', arrowCount: 36, faceSize: 80),
          DistanceLeg(distance: 30, unit: 'm', arrowCount: 36, faceSize: 80),
        ],
        arrowsPerEnd: 6,
      );

      expect(tracker.legBoundaryEnds, [6, 12, 18, 24]);
      expect(tracker.getLegForEnd(1).distance, 90);
      expect(tracker.getLegForEnd(7).distance, 70);
      expect(tracker.getLegForEnd(13).distance, 50);
      expect(tracker.getLegForEnd(19).distance, 30);

      // Check face size changes
      expect(tracker.getLegForEnd(1).faceSize, isNull); // Default 122cm
      expect(tracker.getLegForEnd(13).faceSize, 80); // Smaller face at 50m
    });
  });

  group('National Round Multi-Distance', () {
    test('handles 2-distance National round', () {
      // National: 48 at 60yd, 24 at 50yd = 72 arrows = 12 ends
      final tracker = DistanceLegTracker(
        legs: [
          DistanceLeg(distance: 60, unit: 'yd', arrowCount: 48),
          DistanceLeg(distance: 50, unit: 'yd', arrowCount: 24),
        ],
        arrowsPerEnd: 6,
      );

      expect(tracker.legBoundaryEnds, [8, 12]);
      expect(tracker.getLegForEnd(1).distance, 60);
      expect(tracker.getLegForEnd(8).distance, 60);
      expect(tracker.getLegForEnd(9).distance, 50);
      expect(tracker.getLegForEnd(12).distance, 50);
    });
  });
}
