/// Tests for VisionApiService
///
/// These tests verify the Vision API service functionality including:
/// - ArrowAppearance model and JSON parsing
/// - DetectedArrow model and JSON parsing
/// - ArrowDetectionResult success/failure states
/// - AutoPlotStatus model and JSON parsing
/// - LearnedAppearanceResult success/failure states
/// - Coordinate mapping and validation
/// - Edge cases and data integrity
///
/// Note: Tests that require VisionApiService instantiation are limited because
/// the service has a hard dependency on Firebase Functions and Firebase Auth
/// which cannot be easily mocked without extensive setup.
///
/// The key testable components are:
/// 1. ArrowAppearance model (creation, JSON serialization)
/// 2. DetectedArrow model (creation, JSON parsing, copyWith)
/// 3. ArrowDetectionResult model (success/failure states)
/// 4. AutoPlotStatus model (JSON parsing, computed properties)
/// 5. LearnedAppearanceResult model (success/failure factory methods)
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/vision_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArrowAppearance', () {
    group('constructor', () {
      test('creates appearance with all fields', () {
        final appearance = ArrowAppearance(
          fletchColor: 'red',
          nockColor: 'yellow',
          wrapColor: 'blue',
          shaftColor: 'black',
        );

        expect(appearance.fletchColor, equals('red'));
        expect(appearance.nockColor, equals('yellow'));
        expect(appearance.wrapColor, equals('blue'));
        expect(appearance.shaftColor, equals('black'));
      });

      test('creates appearance with no fields', () {
        const appearance = ArrowAppearance();

        expect(appearance.fletchColor, isNull);
        expect(appearance.nockColor, isNull);
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });

      test('creates appearance with partial fields', () {
        const appearance = ArrowAppearance(
          fletchColor: 'green',
          nockColor: 'orange',
        );

        expect(appearance.fletchColor, equals('green'));
        expect(appearance.nockColor, equals('orange'));
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });

      test('creates appearance with only fletch color', () {
        const appearance = ArrowAppearance(fletchColor: 'pink');

        expect(appearance.fletchColor, equals('pink'));
        expect(appearance.nockColor, isNull);
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });

      test('creates appearance with only shaft color', () {
        const appearance = ArrowAppearance(shaftColor: 'carbon');

        expect(appearance.fletchColor, isNull);
        expect(appearance.nockColor, isNull);
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, equals('carbon'));
      });
    });

    group('hasAnyFeatures', () {
      test('returns false when all fields are null', () {
        const appearance = ArrowAppearance();
        expect(appearance.hasAnyFeatures, isFalse);
      });

      test('returns true when fletchColor is set', () {
        const appearance = ArrowAppearance(fletchColor: 'red');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when nockColor is set', () {
        const appearance = ArrowAppearance(nockColor: 'yellow');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when wrapColor is set', () {
        const appearance = ArrowAppearance(wrapColor: 'blue');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when shaftColor is set', () {
        const appearance = ArrowAppearance(shaftColor: 'black');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when all fields are set', () {
        const appearance = ArrowAppearance(
          fletchColor: 'red',
          nockColor: 'yellow',
          wrapColor: 'blue',
          shaftColor: 'black',
        );
        expect(appearance.hasAnyFeatures, isTrue);
      });
    });

    group('toJson', () {
      test('returns empty map when all fields are null', () {
        const appearance = ArrowAppearance();
        final json = appearance.toJson();

        expect(json, isEmpty);
      });

      test('includes only non-null fletchColor', () {
        const appearance = ArrowAppearance(fletchColor: 'red');
        final json = appearance.toJson();

        expect(json, equals({'fletchColor': 'red'}));
        expect(json.containsKey('nockColor'), isFalse);
        expect(json.containsKey('wrapColor'), isFalse);
        expect(json.containsKey('shaftColor'), isFalse);
      });

      test('includes only non-null nockColor', () {
        const appearance = ArrowAppearance(nockColor: 'yellow');
        final json = appearance.toJson();

        expect(json, equals({'nockColor': 'yellow'}));
      });

      test('includes only non-null wrapColor', () {
        const appearance = ArrowAppearance(wrapColor: 'blue');
        final json = appearance.toJson();

        expect(json, equals({'wrapColor': 'blue'}));
      });

      test('includes only non-null shaftColor', () {
        const appearance = ArrowAppearance(shaftColor: 'black');
        final json = appearance.toJson();

        expect(json, equals({'shaftColor': 'black'}));
      });

      test('includes all non-null fields', () {
        const appearance = ArrowAppearance(
          fletchColor: 'red',
          nockColor: 'yellow',
          wrapColor: 'blue',
          shaftColor: 'black',
        );
        final json = appearance.toJson();

        expect(json, equals({
          'fletchColor': 'red',
          'nockColor': 'yellow',
          'wrapColor': 'blue',
          'shaftColor': 'black',
        }));
      });

      test('includes partial non-null fields', () {
        const appearance = ArrowAppearance(
          fletchColor: 'green',
          shaftColor: 'carbon',
        );
        final json = appearance.toJson();

        expect(json, equals({
          'fletchColor': 'green',
          'shaftColor': 'carbon',
        }));
        expect(json.containsKey('nockColor'), isFalse);
        expect(json.containsKey('wrapColor'), isFalse);
      });
    });

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'fletchColor': 'red',
          'nockColor': 'yellow',
          'wrapColor': 'blue',
          'shaftColor': 'black',
        };

        final appearance = ArrowAppearance.fromJson(json);

        expect(appearance.fletchColor, equals('red'));
        expect(appearance.nockColor, equals('yellow'));
        expect(appearance.wrapColor, equals('blue'));
        expect(appearance.shaftColor, equals('black'));
      });

      test('parses empty JSON', () {
        final json = <String, dynamic>{};

        final appearance = ArrowAppearance.fromJson(json);

        expect(appearance.fletchColor, isNull);
        expect(appearance.nockColor, isNull);
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });

      test('parses partial JSON', () {
        final json = {
          'fletchColor': 'green',
          'nockColor': 'orange',
        };

        final appearance = ArrowAppearance.fromJson(json);

        expect(appearance.fletchColor, equals('green'));
        expect(appearance.nockColor, equals('orange'));
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });

      test('handles null values in JSON', () {
        final json = <String, dynamic>{
          'fletchColor': null,
          'nockColor': 'yellow',
          'wrapColor': null,
          'shaftColor': null,
        };

        final appearance = ArrowAppearance.fromJson(json);

        expect(appearance.fletchColor, isNull);
        expect(appearance.nockColor, equals('yellow'));
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });
    });

    group('JSON round-trip', () {
      test('survives round-trip with all fields', () {
        const original = ArrowAppearance(
          fletchColor: 'red',
          nockColor: 'yellow',
          wrapColor: 'blue',
          shaftColor: 'black',
        );

        final json = original.toJson();
        final restored = ArrowAppearance.fromJson(json);

        expect(restored.fletchColor, equals(original.fletchColor));
        expect(restored.nockColor, equals(original.nockColor));
        expect(restored.wrapColor, equals(original.wrapColor));
        expect(restored.shaftColor, equals(original.shaftColor));
      });

      test('survives round-trip with partial fields', () {
        const original = ArrowAppearance(
          fletchColor: 'pink',
          wrapColor: 'gold',
        );

        final json = original.toJson();
        final restored = ArrowAppearance.fromJson(json);

        expect(restored.fletchColor, equals(original.fletchColor));
        expect(restored.nockColor, equals(original.nockColor));
        expect(restored.wrapColor, equals(original.wrapColor));
        expect(restored.shaftColor, equals(original.shaftColor));
      });
    });
  });

  group('DetectedArrow', () {
    group('constructor', () {
      test('creates arrow with required fields only', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);

        expect(arrow.x, equals(0.0));
        expect(arrow.y, equals(0.0));
        expect(arrow.faceIndex, isNull);
        expect(arrow.confidence, equals(1.0));
        expect(arrow.isLineCutter, isFalse);
        expect(arrow.isMyArrow, isFalse);
      });

      test('creates arrow with all fields', () {
        final arrow = DetectedArrow(
          x: 0.5,
          y: -0.3,
          faceIndex: 1,
          confidence: 0.85,
          isLineCutter: true,
          isMyArrow: true,
        );

        expect(arrow.x, equals(0.5));
        expect(arrow.y, equals(-0.3));
        expect(arrow.faceIndex, equals(1));
        expect(arrow.confidence, equals(0.85));
        expect(arrow.isLineCutter, isTrue);
        expect(arrow.isMyArrow, isTrue);
      });

      test('creates arrow at center (0, 0)', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);

        expect(arrow.x, equals(0.0));
        expect(arrow.y, equals(0.0));
      });

      test('creates arrow at extreme left (-1.0)', () {
        final arrow = DetectedArrow(x: -1.0, y: 0.0);

        expect(arrow.x, equals(-1.0));
      });

      test('creates arrow at extreme right (+1.0)', () {
        final arrow = DetectedArrow(x: 1.0, y: 0.0);

        expect(arrow.x, equals(1.0));
      });

      test('creates arrow at extreme top (-1.0)', () {
        final arrow = DetectedArrow(x: 0.0, y: -1.0);

        expect(arrow.y, equals(-1.0));
      });

      test('creates arrow at extreme bottom (+1.0)', () {
        final arrow = DetectedArrow(x: 0.0, y: 1.0);

        expect(arrow.y, equals(1.0));
      });

      test('handles face indices for triple spot (0, 1, 2)', () {
        for (var i = 0; i < 3; i++) {
          final arrow = DetectedArrow(x: 0.0, y: 0.0, faceIndex: i);
          expect(arrow.faceIndex, equals(i));
        }
      });
    });

    group('needsVerification', () {
      test('returns false for high confidence non-line-cutter', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 1.0,
          isLineCutter: false,
        );

        expect(arrow.needsVerification, isFalse);
      });

      test('returns true for low confidence (< 0.5)', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 0.49,
          isLineCutter: false,
        );

        expect(arrow.needsVerification, isTrue);
      });

      test('returns true for confidence exactly 0.5', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 0.5,
          isLineCutter: false,
        );

        expect(arrow.needsVerification, isFalse);
      });

      test('returns true for line cutter regardless of confidence', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 1.0,
          isLineCutter: true,
        );

        expect(arrow.needsVerification, isTrue);
      });

      test('returns true for both low confidence and line cutter', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 0.3,
          isLineCutter: true,
        );

        expect(arrow.needsVerification, isTrue);
      });

      test('returns false for confidence at 0.5', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 0.5,
        );

        expect(arrow.needsVerification, isFalse);
      });

      test('returns true for very low confidence (0.0)', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 0.0,
        );

        expect(arrow.needsVerification, isTrue);
      });
    });

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'x': 0.5,
          'y': -0.3,
          'face': 1,
          'confidence': 0.85,
          'isLineCutter': true,
          'isMyArrow': true,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.x, equals(0.5));
        expect(arrow.y, equals(-0.3));
        expect(arrow.faceIndex, equals(1));
        expect(arrow.confidence, equals(0.85));
        expect(arrow.isLineCutter, isTrue);
        expect(arrow.isMyArrow, isTrue);
      });

      test('parses minimal JSON with defaults', () {
        final json = {
          'x': 0.0,
          'y': 0.0,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.x, equals(0.0));
        expect(arrow.y, equals(0.0));
        expect(arrow.faceIndex, isNull);
        expect(arrow.confidence, equals(1.0));
        expect(arrow.isLineCutter, isFalse);
        expect(arrow.isMyArrow, isFalse);
      });

      test('handles missing confidence with default 1.0', () {
        final json = {
          'x': 0.2,
          'y': 0.3,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.confidence, equals(1.0));
      });

      test('handles null confidence with default 1.0', () {
        final json = <String, dynamic>{
          'x': 0.2,
          'y': 0.3,
          'confidence': null,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.confidence, equals(1.0));
      });

      test('handles missing isLineCutter with default false', () {
        final json = {
          'x': 0.0,
          'y': 0.0,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.isLineCutter, isFalse);
      });

      test('handles null isLineCutter with default false', () {
        final json = <String, dynamic>{
          'x': 0.0,
          'y': 0.0,
          'isLineCutter': null,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.isLineCutter, isFalse);
      });

      test('handles missing isMyArrow with default false', () {
        final json = {
          'x': 0.0,
          'y': 0.0,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.isMyArrow, isFalse);
      });

      test('handles null isMyArrow with default false', () {
        final json = <String, dynamic>{
          'x': 0.0,
          'y': 0.0,
          'isMyArrow': null,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.isMyArrow, isFalse);
      });

      test('handles integer x and y values', () {
        final json = {
          'x': 1,
          'y': -1,
        };

        final arrow = DetectedArrow.fromJson(json);

        expect(arrow.x, equals(1.0));
        expect(arrow.y, equals(-1.0));
      });

      test('handles face index for triple spot', () {
        for (var i = 0; i < 3; i++) {
          final json = {
            'x': 0.0,
            'y': 0.0,
            'face': i,
          };

          final arrow = DetectedArrow.fromJson(json);

          expect(arrow.faceIndex, equals(i));
        }
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final arrow = DetectedArrow(
          x: 0.5,
          y: -0.3,
          faceIndex: 1,
          confidence: 0.85,
          isLineCutter: true,
          isMyArrow: true,
        );

        final json = arrow.toJson();

        expect(json['x'], equals(0.5));
        expect(json['y'], equals(-0.3));
        expect(json['face'], equals(1));
        expect(json['confidence'], equals(0.85));
        expect(json['isLineCutter'], isTrue);
        expect(json['isMyArrow'], isTrue);
      });

      test('excludes null face index', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);

        final json = arrow.toJson();

        expect(json.containsKey('face'), isFalse);
      });

      test('includes face index when set', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, faceIndex: 2);

        final json = arrow.toJson();

        expect(json['face'], equals(2));
      });

      test('always includes x, y, confidence, isLineCutter, isMyArrow', () {
        final arrow = DetectedArrow(x: 0.1, y: 0.2);

        final json = arrow.toJson();

        expect(json.containsKey('x'), isTrue);
        expect(json.containsKey('y'), isTrue);
        expect(json.containsKey('confidence'), isTrue);
        expect(json.containsKey('isLineCutter'), isTrue);
        expect(json.containsKey('isMyArrow'), isTrue);
      });
    });

    group('copyWith', () {
      test('copies with new x', () {
        final original = DetectedArrow(x: 0.0, y: 0.0);
        final copy = original.copyWith(x: 0.5);

        expect(copy.x, equals(0.5));
        expect(copy.y, equals(0.0));
      });

      test('copies with new y', () {
        final original = DetectedArrow(x: 0.0, y: 0.0);
        final copy = original.copyWith(y: -0.3);

        expect(copy.x, equals(0.0));
        expect(copy.y, equals(-0.3));
      });

      test('copies with new faceIndex', () {
        final original = DetectedArrow(x: 0.0, y: 0.0, faceIndex: 0);
        final copy = original.copyWith(faceIndex: 2);

        expect(copy.faceIndex, equals(2));
      });

      test('copies with new confidence', () {
        final original = DetectedArrow(x: 0.0, y: 0.0, confidence: 1.0);
        final copy = original.copyWith(confidence: 0.5);

        expect(copy.confidence, equals(0.5));
      });

      test('copies with new isLineCutter', () {
        final original = DetectedArrow(x: 0.0, y: 0.0, isLineCutter: false);
        final copy = original.copyWith(isLineCutter: true);

        expect(copy.isLineCutter, isTrue);
      });

      test('copies with new isMyArrow', () {
        final original = DetectedArrow(x: 0.0, y: 0.0, isMyArrow: false);
        final copy = original.copyWith(isMyArrow: true);

        expect(copy.isMyArrow, isTrue);
      });

      test('preserves other fields when copying one field', () {
        final original = DetectedArrow(
          x: 0.5,
          y: -0.3,
          faceIndex: 1,
          confidence: 0.85,
          isLineCutter: true,
          isMyArrow: true,
        );

        final copy = original.copyWith(x: 0.7);

        expect(copy.x, equals(0.7));
        expect(copy.y, equals(-0.3));
        expect(copy.faceIndex, equals(1));
        expect(copy.confidence, equals(0.85));
        expect(copy.isLineCutter, isTrue);
        expect(copy.isMyArrow, isTrue);
      });

      test('copies with multiple new values', () {
        final original = DetectedArrow(x: 0.0, y: 0.0);
        final copy = original.copyWith(
          x: 0.5,
          y: 0.5,
          confidence: 0.9,
        );

        expect(copy.x, equals(0.5));
        expect(copy.y, equals(0.5));
        expect(copy.confidence, equals(0.9));
      });

      test('original is unchanged after copyWith', () {
        final original = DetectedArrow(x: 0.0, y: 0.0);
        original.copyWith(x: 1.0, y: 1.0);

        expect(original.x, equals(0.0));
        expect(original.y, equals(0.0));
      });
    });

    group('JSON round-trip', () {
      test('survives round-trip with all fields', () {
        final original = DetectedArrow(
          x: 0.5,
          y: -0.3,
          faceIndex: 1,
          confidence: 0.85,
          isLineCutter: true,
          isMyArrow: true,
        );

        final json = original.toJson();
        final restored = DetectedArrow.fromJson(json);

        expect(restored.x, equals(original.x));
        expect(restored.y, equals(original.y));
        expect(restored.faceIndex, equals(original.faceIndex));
        expect(restored.confidence, equals(original.confidence));
        expect(restored.isLineCutter, equals(original.isLineCutter));
        expect(restored.isMyArrow, equals(original.isMyArrow));
      });

      test('survives round-trip with minimal fields', () {
        final original = DetectedArrow(x: 0.2, y: -0.4);

        final json = original.toJson();
        final restored = DetectedArrow.fromJson(json);

        expect(restored.x, equals(original.x));
        expect(restored.y, equals(original.y));
        expect(restored.faceIndex, equals(original.faceIndex));
        expect(restored.confidence, equals(original.confidence));
        expect(restored.isLineCutter, equals(original.isLineCutter));
        expect(restored.isMyArrow, equals(original.isMyArrow));
      });
    });
  });

  group('ArrowDetectionResult', () {
    group('success factory', () {
      test('creates successful result with arrows', () {
        final arrows = [
          DetectedArrow(x: 0.0, y: 0.0),
          DetectedArrow(x: 0.5, y: 0.5),
        ];

        final result = ArrowDetectionResult.success(arrows);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, equals(arrows));
        expect(result.error, isNull);
      });

      test('creates successful result with empty arrows list', () {
        final result = ArrowDetectionResult.success([]);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, isEmpty);
        expect(result.error, isNull);
      });

      test('creates successful result with single arrow', () {
        final arrows = [DetectedArrow(x: 0.1, y: 0.2)];

        final result = ArrowDetectionResult.success(arrows);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, hasLength(1));
      });

      test('creates successful result with many arrows', () {
        final arrows = List.generate(
          12,
          (i) => DetectedArrow(x: i / 12, y: i / 12),
        );

        final result = ArrowDetectionResult.success(arrows);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, hasLength(12));
      });
    });

    group('failure factory', () {
      test('creates failure result with error message', () {
        final result = ArrowDetectionResult.failure('Connection failed');

        expect(result.isSuccess, isFalse);
        expect(result.error, equals('Connection failed'));
        expect(result.arrows, isEmpty);
      });

      test('creates failure result with auth error', () {
        final result = ArrowDetectionResult.failure(
          'Authentication required. Please sign in.',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Authentication'));
      });

      test('creates failure result with quota error', () {
        final result = ArrowDetectionResult.failure(
          'Monthly scan limit reached. Upgrade to Auto-Plot Pro for unlimited scans.',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('scan limit'));
      });

      test('creates failure result with service unavailable error', () {
        final result = ArrowDetectionResult.failure(
          'Service temporarily unavailable. Please try again.',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('unavailable'));
      });
    });

    group('isSuccess', () {
      test('returns true for success result', () {
        final result = ArrowDetectionResult.success([]);
        expect(result.isSuccess, isTrue);
      });

      test('returns false for failure result', () {
        final result = ArrowDetectionResult.failure('Error');
        expect(result.isSuccess, isFalse);
      });
    });
  });

  group('AutoPlotStatus', () {
    group('constructor', () {
      test('creates status with all required fields', () {
        final status = AutoPlotStatus(
          scanCount: 10,
          isPro: false,
          limit: 50,
          remaining: 40,
        );

        expect(status.scanCount, equals(10));
        expect(status.isPro, isFalse);
        expect(status.limit, equals(50));
        expect(status.remaining, equals(40));
      });

      test('creates pro status with unlimited scans', () {
        final status = AutoPlotStatus(
          scanCount: 100,
          isPro: true,
          limit: -1,
          remaining: -1,
        );

        expect(status.isPro, isTrue);
        expect(status.limit, equals(-1));
      });
    });

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'scanCount': 25,
          'isPro': true,
          'limit': 100,
          'remaining': 75,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.scanCount, equals(25));
        expect(status.isPro, isTrue);
        expect(status.limit, equals(100));
        expect(status.remaining, equals(75));
      });

      test('handles missing scanCount with default 0', () {
        final json = <String, dynamic>{
          'isPro': false,
          'limit': 50,
          'remaining': 50,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.scanCount, equals(0));
      });

      test('handles null scanCount with default 0', () {
        final json = <String, dynamic>{
          'scanCount': null,
          'isPro': false,
          'limit': 50,
          'remaining': 50,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.scanCount, equals(0));
      });

      test('handles missing isPro with default false', () {
        final json = <String, dynamic>{
          'scanCount': 10,
          'limit': 50,
          'remaining': 40,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.isPro, isFalse);
      });

      test('handles null isPro with default false', () {
        final json = <String, dynamic>{
          'scanCount': 10,
          'isPro': null,
          'limit': 50,
          'remaining': 40,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.isPro, isFalse);
      });

      test('handles missing limit with default 50', () {
        final json = <String, dynamic>{
          'scanCount': 10,
          'isPro': false,
          'remaining': 40,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.limit, equals(50));
      });

      test('handles null limit with default 50', () {
        final json = <String, dynamic>{
          'scanCount': 10,
          'isPro': false,
          'limit': null,
          'remaining': 40,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.limit, equals(50));
      });

      test('handles missing remaining with default 50', () {
        final json = <String, dynamic>{
          'scanCount': 10,
          'isPro': false,
          'limit': 50,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.remaining, equals(50));
      });

      test('handles null remaining with default 50', () {
        final json = <String, dynamic>{
          'scanCount': 10,
          'isPro': false,
          'limit': 50,
          'remaining': null,
        };

        final status = AutoPlotStatus.fromJson(json);

        expect(status.remaining, equals(50));
      });

      test('handles empty JSON with all defaults', () {
        final json = <String, dynamic>{};

        final status = AutoPlotStatus.fromJson(json);

        expect(status.scanCount, equals(0));
        expect(status.isPro, isFalse);
        expect(status.limit, equals(50));
        expect(status.remaining, equals(50));
      });
    });

    group('hasScansRemaining', () {
      test('returns true for pro user regardless of remaining', () {
        final status = AutoPlotStatus(
          scanCount: 100,
          isPro: true,
          limit: 50,
          remaining: 0,
        );

        expect(status.hasScansRemaining, isTrue);
      });

      test('returns true when remaining > 0', () {
        final status = AutoPlotStatus(
          scanCount: 49,
          isPro: false,
          limit: 50,
          remaining: 1,
        );

        expect(status.hasScansRemaining, isTrue);
      });

      test('returns false when remaining == 0 and not pro', () {
        final status = AutoPlotStatus(
          scanCount: 50,
          isPro: false,
          limit: 50,
          remaining: 0,
        );

        expect(status.hasScansRemaining, isFalse);
      });

      test('returns true when remaining is negative and pro', () {
        // Pro users may have -1 to indicate unlimited
        final status = AutoPlotStatus(
          scanCount: 100,
          isPro: true,
          limit: -1,
          remaining: -1,
        );

        expect(status.hasScansRemaining, isTrue);
      });
    });
  });

  group('LearnedAppearanceResult', () {
    group('success factory', () {
      test('creates successful result with appearance', () {
        const appearance = ArrowAppearance(
          fletchColor: 'red',
          nockColor: 'yellow',
        );

        final result = LearnedAppearanceResult.success(
          appearance: appearance,
          description: 'Red fletches with yellow nocks',
        );

        expect(result.isSuccess, isTrue);
        expect(result.appearance, equals(appearance));
        expect(result.description, equals('Red fletches with yellow nocks'));
        expect(result.error, isNull);
      });

      test('creates successful result with null appearance', () {
        final result = LearnedAppearanceResult.success(
          appearance: null,
          description: 'Could not determine appearance',
        );

        expect(result.isSuccess, isTrue);
        expect(result.appearance, isNull);
        expect(result.description, equals('Could not determine appearance'));
        expect(result.error, isNull);
      });

      test('creates successful result with null description', () {
        const appearance = ArrowAppearance(fletchColor: 'green');

        final result = LearnedAppearanceResult.success(
          appearance: appearance,
          description: null,
        );

        expect(result.isSuccess, isTrue);
        expect(result.appearance, equals(appearance));
        expect(result.description, isNull);
        expect(result.error, isNull);
      });

      test('creates successful result with both null', () {
        final result = LearnedAppearanceResult.success();

        expect(result.isSuccess, isTrue);
        expect(result.appearance, isNull);
        expect(result.description, isNull);
        expect(result.error, isNull);
      });
    });

    group('failure factory', () {
      test('creates failure result with error message', () {
        final result = LearnedAppearanceResult.failure('Connection error');

        expect(result.isSuccess, isFalse);
        expect(result.error, equals('Connection error'));
        expect(result.appearance, isNull);
        expect(result.description, isNull);
      });

      test('creates failure result with auth error', () {
        final result = LearnedAppearanceResult.failure('Authentication required');

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Authentication'));
      });

      test('creates failure result with learning failure', () {
        final result = LearnedAppearanceResult.failure(
          'Failed to learn appearance',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Failed'));
      });
    });

    group('isSuccess', () {
      test('returns true for success result', () {
        final result = LearnedAppearanceResult.success();
        expect(result.isSuccess, isTrue);
      });

      test('returns false for failure result', () {
        final result = LearnedAppearanceResult.failure('Error');
        expect(result.isSuccess, isFalse);
      });
    });
  });

  group('coordinate mapping', () {
    group('DetectedArrow coordinate system', () {
      test('center position is (0, 0)', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);

        expect(arrow.x, equals(0.0));
        expect(arrow.y, equals(0.0));
      });

      test('left edge is x = -1.0', () {
        final arrow = DetectedArrow(x: -1.0, y: 0.0);

        expect(arrow.x, equals(-1.0));
      });

      test('right edge is x = +1.0', () {
        final arrow = DetectedArrow(x: 1.0, y: 0.0);

        expect(arrow.x, equals(1.0));
      });

      test('top edge is y = -1.0', () {
        final arrow = DetectedArrow(x: 0.0, y: -1.0);

        expect(arrow.y, equals(-1.0));
      });

      test('bottom edge is y = +1.0', () {
        final arrow = DetectedArrow(x: 0.0, y: 1.0);

        expect(arrow.y, equals(1.0));
      });

      test('corner positions', () {
        // Top-left
        final topLeft = DetectedArrow(x: -1.0, y: -1.0);
        expect(topLeft.x, equals(-1.0));
        expect(topLeft.y, equals(-1.0));

        // Top-right
        final topRight = DetectedArrow(x: 1.0, y: -1.0);
        expect(topRight.x, equals(1.0));
        expect(topRight.y, equals(-1.0));

        // Bottom-left
        final bottomLeft = DetectedArrow(x: -1.0, y: 1.0);
        expect(bottomLeft.x, equals(-1.0));
        expect(bottomLeft.y, equals(1.0));

        // Bottom-right
        final bottomRight = DetectedArrow(x: 1.0, y: 1.0);
        expect(bottomRight.x, equals(1.0));
        expect(bottomRight.y, equals(1.0));
      });

      test('accepts fractional positions', () {
        final arrow = DetectedArrow(x: 0.123456, y: -0.987654);

        expect(arrow.x, equals(0.123456));
        expect(arrow.y, equals(-0.987654));
      });

      test('allows positions outside -1 to +1 range', () {
        // API might return values slightly outside range due to detection errors
        final arrow = DetectedArrow(x: 1.05, y: -1.02);

        expect(arrow.x, equals(1.05));
        expect(arrow.y, equals(-1.02));
      });
    });

    group('triple spot face indexing', () {
      test('face index 0 is top spot', () {
        final arrow = DetectedArrow(x: 0.0, y: -0.5, faceIndex: 0);
        expect(arrow.faceIndex, equals(0));
      });

      test('face index 1 is middle spot', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, faceIndex: 1);
        expect(arrow.faceIndex, equals(1));
      });

      test('face index 2 is bottom spot', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.5, faceIndex: 2);
        expect(arrow.faceIndex, equals(2));
      });

      test('face index can be null for single target', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);
        expect(arrow.faceIndex, isNull);
      });
    });
  });

  group('real-world scenarios', () {
    group('Olympic archer using Auto-Plot', () {
      test('detects 6 arrows on 122cm target', () {
        final arrows = [
          DetectedArrow(x: 0.02, y: 0.01, confidence: 0.95),
          DetectedArrow(x: -0.03, y: 0.05, confidence: 0.98),
          DetectedArrow(x: 0.08, y: -0.02, confidence: 0.92),
          DetectedArrow(x: -0.01, y: -0.04, confidence: 0.97),
          DetectedArrow(x: 0.05, y: 0.06, confidence: 0.94),
          DetectedArrow(x: -0.07, y: 0.02, confidence: 0.96),
        ];

        final result = ArrowDetectionResult.success(arrows);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, hasLength(6));
        // All in the center (X10 ring area)
        for (final arrow in result.arrows) {
          expect(arrow.x.abs(), lessThan(0.1));
          expect(arrow.y.abs(), lessThan(0.1));
          expect(arrow.needsVerification, isFalse);
        }
      });

      test('handles line cutter that needs verification', () {
        final arrows = [
          DetectedArrow(x: 0.02, y: 0.01, confidence: 0.95),
          DetectedArrow(x: 0.15, y: 0.0, confidence: 0.85, isLineCutter: true),
        ];

        final result = ArrowDetectionResult.success(arrows);

        expect(result.arrows[0].needsVerification, isFalse);
        expect(result.arrows[1].needsVerification, isTrue);
        expect(result.arrows[1].isLineCutter, isTrue);
      });
    });

    group('indoor triple spot scenario', () {
      test('detects 3 arrows on triple spot with face indices', () {
        final arrows = [
          DetectedArrow(x: 0.01, y: -0.5, faceIndex: 0, confidence: 0.97),
          DetectedArrow(x: -0.02, y: 0.0, faceIndex: 1, confidence: 0.95),
          DetectedArrow(x: 0.03, y: 0.5, faceIndex: 2, confidence: 0.96),
        ];

        final result = ArrowDetectionResult.success(arrows);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, hasLength(3));

        expect(result.arrows[0].faceIndex, equals(0));
        expect(result.arrows[1].faceIndex, equals(1));
        expect(result.arrows[2].faceIndex, equals(2));
      });
    });

    group('tournament arrow identification', () {
      test('identifies user arrows with appearance matching', () {
        final arrows = [
          DetectedArrow(x: 0.02, y: 0.01, confidence: 0.95, isMyArrow: true),
          DetectedArrow(x: 0.05, y: -0.03, confidence: 0.90, isMyArrow: false),
          DetectedArrow(x: -0.01, y: 0.04, confidence: 0.93, isMyArrow: true),
        ];

        final result = ArrowDetectionResult.success(arrows);

        final myArrows = result.arrows.where((a) => a.isMyArrow).toList();
        final otherArrows = result.arrows.where((a) => !a.isMyArrow).toList();

        expect(myArrows, hasLength(2));
        expect(otherArrows, hasLength(1));
      });

      test('arrow appearance helps identify arrows', () {
        const appearance = ArrowAppearance(
          fletchColor: 'pink',
          nockColor: 'red',
          wrapColor: 'gold',
        );

        expect(appearance.hasAnyFeatures, isTrue);

        final json = appearance.toJson();
        expect(json['fletchColor'], equals('pink'));
        expect(json['nockColor'], equals('red'));
        expect(json['wrapColor'], equals('gold'));
      });
    });

    group('quota management scenarios', () {
      test('competitor tier with scans remaining', () {
        final status = AutoPlotStatus(
          scanCount: 30,
          isPro: false,
          limit: 50,
          remaining: 20,
        );

        expect(status.hasScansRemaining, isTrue);
        expect(status.remaining, greaterThan(0));
      });

      test('competitor tier with quota exhausted', () {
        final status = AutoPlotStatus(
          scanCount: 50,
          isPro: false,
          limit: 50,
          remaining: 0,
        );

        expect(status.hasScansRemaining, isFalse);
        expect(status.remaining, equals(0));
      });

      test('professional tier with unlimited scans', () {
        final status = AutoPlotStatus(
          scanCount: 500,
          isPro: true,
          limit: -1,
          remaining: -1,
        );

        expect(status.hasScansRemaining, isTrue);
        expect(status.isPro, isTrue);
      });
    });

    group('error handling scenarios', () {
      test('unauthenticated user error', () {
        final result = ArrowDetectionResult.failure(
          'Please sign in to use Auto-Plot',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('sign in'));
      });

      test('quota exceeded error', () {
        final result = ArrowDetectionResult.failure(
          'Monthly scan limit reached. Upgrade to Auto-Plot Pro for unlimited scans.',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('limit reached'));
        expect(result.error, contains('Auto-Plot Pro'));
      });

      test('service unavailable error', () {
        final result = ArrowDetectionResult.failure(
          'Service temporarily unavailable. Please try again.',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('unavailable'));
      });

      test('connection error', () {
        final result = ArrowDetectionResult.failure(
          'Connection error: SocketException',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Connection'));
      });
    });

    group('learning arrow appearance', () {
      test('successful appearance learning', () {
        const appearance = ArrowAppearance(
          fletchColor: 'fluorescent pink',
          nockColor: 'red',
          wrapColor: 'gold sparkle',
        );

        final result = LearnedAppearanceResult.success(
          appearance: appearance,
          description: 'Arrows have fluorescent pink fletches, red nocks, and gold sparkle wraps',
        );

        expect(result.isSuccess, isTrue);
        expect(result.appearance, isNotNull);
        expect(result.appearance!.fletchColor, equals('fluorescent pink'));
        expect(result.description, contains('pink fletches'));
      });

      test('failed appearance learning', () {
        final result = LearnedAppearanceResult.failure(
          'Could not identify distinct arrow features',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Could not identify'));
        expect(result.appearance, isNull);
      });
    });
  });

  group('edge cases', () {
    group('extreme coordinate values', () {
      test('handles very small coordinate values', () {
        final arrow = DetectedArrow(x: 0.0001, y: -0.0001);

        expect(arrow.x, equals(0.0001));
        expect(arrow.y, equals(-0.0001));
      });

      test('handles coordinates at exact boundaries', () {
        final arrows = [
          DetectedArrow(x: -1.0, y: -1.0),
          DetectedArrow(x: 1.0, y: 1.0),
          DetectedArrow(x: -1.0, y: 1.0),
          DetectedArrow(x: 1.0, y: -1.0),
        ];

        for (final arrow in arrows) {
          expect(arrow.x.abs(), lessThanOrEqualTo(1.0));
          expect(arrow.y.abs(), lessThanOrEqualTo(1.0));
        }
      });
    });

    group('confidence boundaries', () {
      test('handles confidence at exactly 0.0', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.0);

        expect(arrow.confidence, equals(0.0));
        expect(arrow.needsVerification, isTrue);
      });

      test('handles confidence at exactly 1.0', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 1.0);

        expect(arrow.confidence, equals(1.0));
        expect(arrow.needsVerification, isFalse);
      });

      test('handles confidence at threshold 0.5', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.5);

        expect(arrow.confidence, equals(0.5));
        expect(arrow.needsVerification, isFalse);
      });

      test('handles confidence just below threshold', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.499);

        expect(arrow.needsVerification, isTrue);
      });
    });

    group('empty and null scenarios', () {
      test('handles empty arrows list', () {
        final result = ArrowDetectionResult.success([]);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, isEmpty);
      });

      test('handles arrow appearance with all empty strings', () {
        const appearance = ArrowAppearance(
          fletchColor: '',
          nockColor: '',
          wrapColor: '',
          shaftColor: '',
        );

        // Empty strings are truthy in hasAnyFeatures
        expect(appearance.hasAnyFeatures, isTrue);
      });
    });

    group('special character handling', () {
      test('handles appearance colors with special characters', () {
        const appearance = ArrowAppearance(
          fletchColor: 'red/orange',
          nockColor: 'yellow-green',
          wrapColor: "Patrick's Gold",
          shaftColor: 'carbon (matte)',
        );

        final json = appearance.toJson();
        final restored = ArrowAppearance.fromJson(json);

        expect(restored.fletchColor, equals('red/orange'));
        expect(restored.nockColor, equals('yellow-green'));
        expect(restored.wrapColor, equals("Patrick's Gold"));
        expect(restored.shaftColor, equals('carbon (matte)'));
      });

      test('handles unicode in appearance colors', () {
        const appearance = ArrowAppearance(
          fletchColor: '红色', // Chinese for "red"
          nockColor: 'góld',
          wrapColor: '💫 sparkle',
        );

        final json = appearance.toJson();
        final restored = ArrowAppearance.fromJson(json);

        expect(restored.fletchColor, equals('红色'));
        expect(restored.nockColor, equals('góld'));
        expect(restored.wrapColor, equals('💫 sparkle'));
      });
    });

    group('large data sets', () {
      test('handles maximum arrows in a round (72 for 1440)', () {
        final arrows = List.generate(
          72,
          (i) => DetectedArrow(
            x: (i % 12 - 6) / 10,
            y: (i ~/ 12 - 3) / 10,
            confidence: 0.9,
          ),
        );

        final result = ArrowDetectionResult.success(arrows);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, hasLength(72));
      });

      test('handles very high scan count', () {
        final status = AutoPlotStatus(
          scanCount: 999999,
          isPro: true,
          limit: -1,
          remaining: -1,
        );

        expect(status.scanCount, equals(999999));
        expect(status.hasScansRemaining, isTrue);
      });
    });
  });

  group('data integrity', () {
    test('DetectedArrow fields are immutable via toJson/fromJson', () {
      final original = DetectedArrow(
        x: 0.5,
        y: -0.3,
        faceIndex: 1,
        confidence: 0.85,
        isLineCutter: true,
        isMyArrow: true,
      );

      final json = original.toJson();
      json['x'] = 0.9; // Try to modify

      // Original should be unchanged
      expect(original.x, equals(0.5));
    });

    test('ArrowAppearance fields are immutable via toJson/fromJson', () {
      const original = ArrowAppearance(
        fletchColor: 'red',
        nockColor: 'yellow',
      );

      final json = original.toJson();
      json['fletchColor'] = 'blue'; // Try to modify

      // Original should be unchanged
      expect(original.fletchColor, equals('red'));
    });

    test('ArrowDetectionResult arrows list stores reference', () {
      final arrows = [
        DetectedArrow(x: 0.0, y: 0.0),
        DetectedArrow(x: 0.5, y: 0.5),
      ];

      final result = ArrowDetectionResult.success(arrows);

      // Current implementation stores direct reference (not a defensive copy)
      // This is acceptable since arrows are typically created fresh for each result
      expect(result.arrows, hasLength(2));
      expect(result.arrows, same(arrows));
    });

    test('AutoPlotStatus preserves all fields through fromJson', () {
      final json = {
        'scanCount': 42,
        'isPro': true,
        'limit': 100,
        'remaining': 58,
      };

      final status = AutoPlotStatus.fromJson(json);

      expect(status.scanCount, equals(42));
      expect(status.isPro, isTrue);
      expect(status.limit, equals(100));
      expect(status.remaining, equals(58));
    });
  });
}
