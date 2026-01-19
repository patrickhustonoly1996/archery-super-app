/// Tests for AutoPlotProvider
///
/// These tests verify the auto-plot state management and business logic including:
/// - AutoPlotState enum (idle, capturing, processing, confirming, error)
/// - Access control and entitlement checks
/// - Scan quota tracking (competitor vs professional tiers)
/// - Arrow detection state management
/// - Arrow adjustment and manual addition
/// - Target registration
/// - Arrow appearance learning
/// - State transitions and error handling
/// - Real-world scenarios
/// - Edge cases and data integrity
///
/// Note: Tests use simulated state logic and mock services since AutoPlotProvider
/// has dependencies on AppDatabase, VisionApiService, and EntitlementProvider.
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/providers/auto_plot_provider.dart';
import 'package:archery_super_app/providers/entitlement_provider.dart';
import 'package:archery_super_app/services/vision_api_service.dart';
import 'package:archery_super_app/models/arrow_specifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // AUTOPLOT STATE ENUM TESTS
  // ===========================================================================
  group('AutoPlotState enum', () {
    group('values', () {
      test('has idle state', () {
        expect(AutoPlotState.values, contains(AutoPlotState.idle));
      });

      test('has capturing state', () {
        expect(AutoPlotState.values, contains(AutoPlotState.capturing));
      });

      test('has processing state', () {
        expect(AutoPlotState.values, contains(AutoPlotState.processing));
      });

      test('has confirming state', () {
        expect(AutoPlotState.values, contains(AutoPlotState.confirming));
      });

      test('has error state', () {
        expect(AutoPlotState.values, contains(AutoPlotState.error));
      });

      test('has exactly 5 states', () {
        expect(AutoPlotState.values.length, equals(5));
      });
    });

    group('state ordering', () {
      test('idle is first state', () {
        expect(AutoPlotState.values.first, equals(AutoPlotState.idle));
      });

      test('error is last state', () {
        expect(AutoPlotState.values.last, equals(AutoPlotState.error));
      });

      test('states are in logical order', () {
        expect(AutoPlotState.idle.index, lessThan(AutoPlotState.capturing.index));
        expect(AutoPlotState.capturing.index, lessThan(AutoPlotState.processing.index));
        expect(AutoPlotState.processing.index, lessThan(AutoPlotState.confirming.index));
      });
    });
  });

  // ===========================================================================
  // CONSTANTS TESTS
  // ===========================================================================
  group('Auto-Plot constants', () {
    test('competitor limit is 50 scans per month', () {
      expect(kAutoPlotCompetitorLimit, equals(50));
    });

    test('competitor limit is positive', () {
      expect(kAutoPlotCompetitorLimit, greaterThan(0));
    });
  });

  // ===========================================================================
  // DETECTED ARROW MODEL TESTS
  // ===========================================================================
  group('DetectedArrow model', () {
    group('constructor', () {
      test('creates with required fields', () {
        final arrow = DetectedArrow(x: 0.5, y: -0.3);
        expect(arrow.x, equals(0.5));
        expect(arrow.y, equals(-0.3));
      });

      test('faceIndex defaults to null', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);
        expect(arrow.faceIndex, isNull);
      });

      test('confidence defaults to 1.0', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);
        expect(arrow.confidence, equals(1.0));
      });

      test('isLineCutter defaults to false', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);
        expect(arrow.isLineCutter, isFalse);
      });

      test('isMyArrow defaults to false', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);
        expect(arrow.isMyArrow, isFalse);
      });

      test('accepts all optional fields', () {
        final arrow = DetectedArrow(
          x: 0.25,
          y: -0.5,
          faceIndex: 1,
          confidence: 0.85,
          isLineCutter: true,
          isMyArrow: true,
        );
        expect(arrow.faceIndex, equals(1));
        expect(arrow.confidence, equals(0.85));
        expect(arrow.isLineCutter, isTrue);
        expect(arrow.isMyArrow, isTrue);
      });
    });

    group('coordinate system', () {
      test('x ranges from -1 (left) to +1 (right)', () {
        final leftArrow = DetectedArrow(x: -1.0, y: 0.0);
        final centerArrow = DetectedArrow(x: 0.0, y: 0.0);
        final rightArrow = DetectedArrow(x: 1.0, y: 0.0);

        expect(leftArrow.x, equals(-1.0));
        expect(centerArrow.x, equals(0.0));
        expect(rightArrow.x, equals(1.0));
      });

      test('y ranges from -1 (top) to +1 (bottom)', () {
        final topArrow = DetectedArrow(x: 0.0, y: -1.0);
        final centerArrow = DetectedArrow(x: 0.0, y: 0.0);
        final bottomArrow = DetectedArrow(x: 0.0, y: 1.0);

        expect(topArrow.y, equals(-1.0));
        expect(centerArrow.y, equals(0.0));
        expect(bottomArrow.y, equals(1.0));
      });

      test('center (0,0) represents bullseye', () {
        final bullseye = DetectedArrow(x: 0.0, y: 0.0);
        expect(bullseye.x, equals(0.0));
        expect(bullseye.y, equals(0.0));
      });
    });

    group('faceIndex for triple spot', () {
      test('0 represents top face', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, faceIndex: 0);
        expect(arrow.faceIndex, equals(0));
      });

      test('1 represents middle face', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, faceIndex: 1);
        expect(arrow.faceIndex, equals(1));
      });

      test('2 represents bottom face', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, faceIndex: 2);
        expect(arrow.faceIndex, equals(2));
      });
    });

    group('needsVerification', () {
      test('returns true for low confidence < 0.5', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.49);
        expect(arrow.needsVerification, isTrue);
      });

      test('returns true for line cutters', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, isLineCutter: true);
        expect(arrow.needsVerification, isTrue);
      });

      test('returns true for line cutter with high confidence', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 0.95,
          isLineCutter: true,
        );
        expect(arrow.needsVerification, isTrue);
      });

      test('returns false for high confidence non-line-cutter', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 0.85,
          isLineCutter: false,
        );
        expect(arrow.needsVerification, isFalse);
      });

      test('returns false for exactly 0.5 confidence non-line-cutter', () {
        final arrow = DetectedArrow(
          x: 0.0,
          y: 0.0,
          confidence: 0.5,
          isLineCutter: false,
        );
        expect(arrow.needsVerification, isFalse);
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
    });

    group('fromJson', () {
      test('parses basic arrow', () {
        final json = {'x': 0.5, 'y': -0.3};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.x, equals(0.5));
        expect(arrow.y, equals(-0.3));
      });

      test('parses integer coordinates as doubles', () {
        final json = {'x': 1, 'y': 0};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.x, equals(1.0));
        expect(arrow.y, equals(0.0));
      });

      test('parses face index', () {
        final json = {'x': 0.0, 'y': 0.0, 'face': 2};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.faceIndex, equals(2));
      });

      test('parses confidence', () {
        final json = {'x': 0.0, 'y': 0.0, 'confidence': 0.75};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.confidence, equals(0.75));
      });

      test('defaults confidence to 1.0 when missing', () {
        final json = {'x': 0.0, 'y': 0.0};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.confidence, equals(1.0));
      });

      test('parses isLineCutter', () {
        final json = {'x': 0.0, 'y': 0.0, 'isLineCutter': true};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.isLineCutter, isTrue);
      });

      test('defaults isLineCutter to false when missing', () {
        final json = {'x': 0.0, 'y': 0.0};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.isLineCutter, isFalse);
      });

      test('parses isMyArrow', () {
        final json = {'x': 0.0, 'y': 0.0, 'isMyArrow': true};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.isMyArrow, isTrue);
      });

      test('defaults isMyArrow to false when missing', () {
        final json = {'x': 0.0, 'y': 0.0};
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.isMyArrow, isFalse);
      });

      test('parses all fields together', () {
        final json = {
          'x': 0.25,
          'y': -0.5,
          'face': 1,
          'confidence': 0.9,
          'isLineCutter': true,
          'isMyArrow': true,
        };
        final arrow = DetectedArrow.fromJson(json);
        expect(arrow.x, equals(0.25));
        expect(arrow.y, equals(-0.5));
        expect(arrow.faceIndex, equals(1));
        expect(arrow.confidence, equals(0.9));
        expect(arrow.isLineCutter, isTrue);
        expect(arrow.isMyArrow, isTrue);
      });
    });

    group('toJson', () {
      test('serializes coordinates', () {
        final arrow = DetectedArrow(x: 0.5, y: -0.3);
        final json = arrow.toJson();
        expect(json['x'], equals(0.5));
        expect(json['y'], equals(-0.3));
      });

      test('includes face when present', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, faceIndex: 1);
        final json = arrow.toJson();
        expect(json['face'], equals(1));
      });

      test('excludes face when null', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);
        final json = arrow.toJson();
        expect(json.containsKey('face'), isFalse);
      });

      test('includes confidence', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.85);
        final json = arrow.toJson();
        expect(json['confidence'], equals(0.85));
      });

      test('includes isLineCutter', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, isLineCutter: true);
        final json = arrow.toJson();
        expect(json['isLineCutter'], isTrue);
      });

      test('includes isMyArrow', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, isMyArrow: true);
        final json = arrow.toJson();
        expect(json['isMyArrow'], isTrue);
      });

      test('roundtrip serialization', () {
        final original = DetectedArrow(
          x: 0.25,
          y: -0.5,
          faceIndex: 2,
          confidence: 0.9,
          isLineCutter: true,
          isMyArrow: false,
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
    });

    group('copyWith', () {
      test('copies with new x', () {
        final original = DetectedArrow(x: 0.5, y: 0.3);
        final copied = original.copyWith(x: 0.8);
        expect(copied.x, equals(0.8));
        expect(copied.y, equals(0.3));
      });

      test('copies with new y', () {
        final original = DetectedArrow(x: 0.5, y: 0.3);
        final copied = original.copyWith(y: -0.2);
        expect(copied.x, equals(0.5));
        expect(copied.y, equals(-0.2));
      });

      test('copies with new faceIndex', () {
        final original = DetectedArrow(x: 0.0, y: 0.0, faceIndex: 0);
        final copied = original.copyWith(faceIndex: 2);
        expect(copied.faceIndex, equals(2));
      });

      test('copies with new confidence', () {
        final original = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.5);
        final copied = original.copyWith(confidence: 0.9);
        expect(copied.confidence, equals(0.9));
      });

      test('copies with new isLineCutter', () {
        final original = DetectedArrow(x: 0.0, y: 0.0, isLineCutter: false);
        final copied = original.copyWith(isLineCutter: true);
        expect(copied.isLineCutter, isTrue);
      });

      test('copies with new isMyArrow', () {
        final original = DetectedArrow(x: 0.0, y: 0.0, isMyArrow: false);
        final copied = original.copyWith(isMyArrow: true);
        expect(copied.isMyArrow, isTrue);
      });

      test('preserves values when no changes specified', () {
        final original = DetectedArrow(
          x: 0.5,
          y: -0.3,
          faceIndex: 1,
          confidence: 0.85,
          isLineCutter: true,
          isMyArrow: true,
        );
        final copied = original.copyWith();

        expect(copied.x, equals(original.x));
        expect(copied.y, equals(original.y));
        expect(copied.faceIndex, equals(original.faceIndex));
        expect(copied.confidence, equals(original.confidence));
        expect(copied.isLineCutter, equals(original.isLineCutter));
        expect(copied.isMyArrow, equals(original.isMyArrow));
      });

      test('creates independent copy', () {
        final original = DetectedArrow(x: 0.5, y: 0.3);
        final copied = original.copyWith(x: 0.8);

        // Original should be unchanged
        expect(original.x, equals(0.5));
      });
    });
  });

  // ===========================================================================
  // ARROW DETECTION RESULT TESTS
  // ===========================================================================
  group('ArrowDetectionResult', () {
    group('success factory', () {
      test('creates successful result with arrows', () {
        final arrows = [
          DetectedArrow(x: 0.1, y: 0.2),
          DetectedArrow(x: -0.3, y: 0.4),
        ];
        final result = ArrowDetectionResult.success(arrows);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, equals(arrows));
        expect(result.error, isNull);
      });

      test('creates successful result with empty arrows', () {
        final result = ArrowDetectionResult.success([]);

        expect(result.isSuccess, isTrue);
        expect(result.arrows, isEmpty);
        expect(result.error, isNull);
      });
    });

    group('failure factory', () {
      test('creates failed result with error', () {
        final result = ArrowDetectionResult.failure('Network error');

        expect(result.isSuccess, isFalse);
        expect(result.arrows, isEmpty);
        expect(result.error, equals('Network error'));
      });

      test('creates failed result with null error - still considered success by isSuccess getter', () {
        // Note: The isSuccess getter only checks if error == null
        // So failure(null) will paradoxically return isSuccess = true
        // This is an edge case in the implementation
        final result = ArrowDetectionResult.failure(null);

        expect(result.isSuccess, isTrue); // Because error == null
        expect(result.arrows, isEmpty);
        expect(result.error, isNull);
      });
    });

    group('isSuccess', () {
      test('returns true when error is null', () {
        final result = ArrowDetectionResult.success([]);
        expect(result.isSuccess, isTrue);
      });

      test('returns false when error is present', () {
        final result = ArrowDetectionResult.failure('Error');
        expect(result.isSuccess, isFalse);
      });
    });
  });

  // ===========================================================================
  // AUTO-PLOT STATUS TESTS
  // ===========================================================================
  group('AutoPlotStatus', () {
    group('fromJson', () {
      test('parses full status', () {
        final json = {
          'scanCount': 25,
          'isPro': true,
          'limit': 50,
          'remaining': 25,
        };
        final status = AutoPlotStatus.fromJson(json);

        expect(status.scanCount, equals(25));
        expect(status.isPro, isTrue);
        expect(status.limit, equals(50));
        expect(status.remaining, equals(25));
      });

      test('defaults scanCount to 0', () {
        final json = <String, dynamic>{};
        final status = AutoPlotStatus.fromJson(json);
        expect(status.scanCount, equals(0));
      });

      test('defaults isPro to false', () {
        final json = <String, dynamic>{};
        final status = AutoPlotStatus.fromJson(json);
        expect(status.isPro, isFalse);
      });

      test('defaults limit to 50', () {
        final json = <String, dynamic>{};
        final status = AutoPlotStatus.fromJson(json);
        expect(status.limit, equals(50));
      });

      test('defaults remaining to 50', () {
        final json = <String, dynamic>{};
        final status = AutoPlotStatus.fromJson(json);
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
          scanCount: 25,
          isPro: false,
          limit: 50,
          remaining: 25,
        );
        expect(status.hasScansRemaining, isTrue);
      });

      test('returns false when remaining = 0 and not pro', () {
        final status = AutoPlotStatus(
          scanCount: 50,
          isPro: false,
          limit: 50,
          remaining: 0,
        );
        expect(status.hasScansRemaining, isFalse);
      });
    });
  });

  // ===========================================================================
  // ARROW APPEARANCE TESTS
  // ===========================================================================
  group('ArrowAppearance', () {
    group('constructor', () {
      test('creates with all colors', () {
        final appearance = ArrowAppearance(
          fletchColor: 'green',
          nockColor: 'orange',
          wrapColor: 'white',
          shaftColor: 'black',
        );

        expect(appearance.fletchColor, equals('green'));
        expect(appearance.nockColor, equals('orange'));
        expect(appearance.wrapColor, equals('white'));
        expect(appearance.shaftColor, equals('black'));
      });

      test('allows null colors', () {
        final appearance = ArrowAppearance();

        expect(appearance.fletchColor, isNull);
        expect(appearance.nockColor, isNull);
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });

      test('allows partial colors', () {
        final appearance = ArrowAppearance(
          fletchColor: 'green',
          nockColor: 'orange',
        );

        expect(appearance.fletchColor, equals('green'));
        expect(appearance.nockColor, equals('orange'));
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });
    });

    group('hasAnyFeatures', () {
      test('returns true when fletchColor present', () {
        final appearance = ArrowAppearance(fletchColor: 'green');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when nockColor present', () {
        final appearance = ArrowAppearance(nockColor: 'orange');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when wrapColor present', () {
        final appearance = ArrowAppearance(wrapColor: 'white');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when shaftColor present', () {
        final appearance = ArrowAppearance(shaftColor: 'black');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns false when all colors null', () {
        final appearance = ArrowAppearance();
        expect(appearance.hasAnyFeatures, isFalse);
      });

      test('returns true with multiple colors', () {
        final appearance = ArrowAppearance(
          fletchColor: 'green',
          nockColor: 'orange',
        );
        expect(appearance.hasAnyFeatures, isTrue);
      });
    });

    group('toJson', () {
      test('includes only non-null colors', () {
        final appearance = ArrowAppearance(
          fletchColor: 'green',
          nockColor: 'orange',
        );
        final json = appearance.toJson();

        expect(json['fletchColor'], equals('green'));
        expect(json['nockColor'], equals('orange'));
        expect(json.containsKey('wrapColor'), isFalse);
        expect(json.containsKey('shaftColor'), isFalse);
      });

      test('returns empty map when all null', () {
        final appearance = ArrowAppearance();
        final json = appearance.toJson();

        expect(json, isEmpty);
      });

      test('includes all colors when present', () {
        final appearance = ArrowAppearance(
          fletchColor: 'green',
          nockColor: 'orange',
          wrapColor: 'white',
          shaftColor: 'black',
        );
        final json = appearance.toJson();

        expect(json['fletchColor'], equals('green'));
        expect(json['nockColor'], equals('orange'));
        expect(json['wrapColor'], equals('white'));
        expect(json['shaftColor'], equals('black'));
      });
    });

    group('fromJson', () {
      test('parses all colors', () {
        final json = {
          'fletchColor': 'green',
          'nockColor': 'orange',
          'wrapColor': 'white',
          'shaftColor': 'black',
        };
        final appearance = ArrowAppearance.fromJson(json);

        expect(appearance.fletchColor, equals('green'));
        expect(appearance.nockColor, equals('orange'));
        expect(appearance.wrapColor, equals('white'));
        expect(appearance.shaftColor, equals('black'));
      });

      test('handles missing colors', () {
        final json = {'fletchColor': 'green'};
        final appearance = ArrowAppearance.fromJson(json);

        expect(appearance.fletchColor, equals('green'));
        expect(appearance.nockColor, isNull);
        expect(appearance.wrapColor, isNull);
        expect(appearance.shaftColor, isNull);
      });

      test('handles empty json', () {
        final json = <String, dynamic>{};
        final appearance = ArrowAppearance.fromJson(json);

        expect(appearance.fletchColor, isNull);
        expect(appearance.nockColor, isNull);
      });

      test('roundtrip serialization', () {
        final original = ArrowAppearance(
          fletchColor: 'green',
          nockColor: 'orange',
          wrapColor: 'white',
        );
        final json = original.toJson();
        final restored = ArrowAppearance.fromJson(json);

        expect(restored.fletchColor, equals(original.fletchColor));
        expect(restored.nockColor, equals(original.nockColor));
        expect(restored.wrapColor, equals(original.wrapColor));
      });
    });
  });

  // ===========================================================================
  // ARROW APPEARANCE FOR AUTO-PLOT TESTS
  // ===========================================================================
  group('ArrowAppearanceForAutoPlot', () {
    group('constructor', () {
      test('creates with all colors', () {
        const appearance = ArrowAppearanceForAutoPlot(
          fletchColor: 'green',
          nockColor: 'orange',
          wrapColor: 'white',
        );

        expect(appearance.fletchColor, equals('green'));
        expect(appearance.nockColor, equals('orange'));
        expect(appearance.wrapColor, equals('white'));
      });

      test('allows null colors', () {
        const appearance = ArrowAppearanceForAutoPlot();

        expect(appearance.fletchColor, isNull);
        expect(appearance.nockColor, isNull);
        expect(appearance.wrapColor, isNull);
      });
    });

    group('hasAnyFeatures', () {
      test('returns true when fletchColor present', () {
        const appearance = ArrowAppearanceForAutoPlot(fletchColor: 'green');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when nockColor present', () {
        const appearance = ArrowAppearanceForAutoPlot(nockColor: 'orange');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns true when wrapColor present', () {
        const appearance = ArrowAppearanceForAutoPlot(wrapColor: 'white');
        expect(appearance.hasAnyFeatures, isTrue);
      });

      test('returns false when all null', () {
        const appearance = ArrowAppearanceForAutoPlot();
        expect(appearance.hasAnyFeatures, isFalse);
      });
    });

    group('toJson', () {
      test('includes only non-null colors', () {
        const appearance = ArrowAppearanceForAutoPlot(
          fletchColor: 'green',
          nockColor: 'orange',
        );
        final json = appearance.toJson();

        expect(json['fletchColor'], equals('green'));
        expect(json['nockColor'], equals('orange'));
        expect(json.containsKey('wrapColor'), isFalse);
      });

      test('returns empty map when all null', () {
        const appearance = ArrowAppearanceForAutoPlot();
        final json = appearance.toJson();
        expect(json, isEmpty);
      });
    });
  });

  // ===========================================================================
  // LEARNED APPEARANCE RESULT TESTS
  // ===========================================================================
  group('LearnedAppearanceResult', () {
    group('success factory', () {
      test('creates successful result', () {
        final appearance = ArrowAppearance(fletchColor: 'green');
        final result = LearnedAppearanceResult.success(
          appearance: appearance,
          description: 'Green fletchings',
        );

        expect(result.isSuccess, isTrue);
        expect(result.appearance, equals(appearance));
        expect(result.description, equals('Green fletchings'));
        expect(result.error, isNull);
      });

      test('creates successful result with null appearance', () {
        final result = LearnedAppearanceResult.success();

        expect(result.isSuccess, isTrue);
        expect(result.appearance, isNull);
        expect(result.description, isNull);
      });
    });

    group('failure factory', () {
      test('creates failed result', () {
        final result = LearnedAppearanceResult.failure('Learning failed');

        expect(result.isSuccess, isFalse);
        expect(result.error, equals('Learning failed'));
        expect(result.appearance, isNull);
        expect(result.description, isNull);
      });
    });
  });

  // ===========================================================================
  // PROVIDER STATE SIMULATION TESTS
  // ===========================================================================
  group('Provider state simulation', () {
    // Simulates the provider's internal state management

    group('access control logic', () {
      test('no access without entitlement provider', () {
        // Simulates _entitlementProvider == null
        final hasAutoPlotAccess = null ?? false;
        expect(hasAutoPlotAccess, isFalse);
      });

      test('scansRemaining returns 0 without access', () {
        final hasAutoPlotAccess = false;
        final hasUnlimitedAutoPlot = false;
        final scanCount = 0;

        int scansRemaining() {
          if (!hasAutoPlotAccess) return 0;
          if (hasUnlimitedAutoPlot) return -1;
          return (kAutoPlotCompetitorLimit - scanCount).clamp(0, kAutoPlotCompetitorLimit);
        }

        expect(scansRemaining(), equals(0));
      });

      test('scansRemaining returns -1 for unlimited', () {
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = true;
        final scanCount = 100;

        int scansRemaining() {
          if (!hasAutoPlotAccess) return 0;
          if (hasUnlimitedAutoPlot) return -1;
          return (kAutoPlotCompetitorLimit - scanCount).clamp(0, kAutoPlotCompetitorLimit);
        }

        expect(scansRemaining(), equals(-1));
      });

      test('scansRemaining calculates remaining for competitor', () {
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = false;
        final scanCount = 30;

        int scansRemaining() {
          if (!hasAutoPlotAccess) return 0;
          if (hasUnlimitedAutoPlot) return -1;
          return (kAutoPlotCompetitorLimit - scanCount).clamp(0, kAutoPlotCompetitorLimit);
        }

        expect(scansRemaining(), equals(20));
      });

      test('scansRemaining clamps to 0 when over limit', () {
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = false;
        final scanCount = 60;

        int scansRemaining() {
          if (!hasAutoPlotAccess) return 0;
          if (hasUnlimitedAutoPlot) return -1;
          return (kAutoPlotCompetitorLimit - scanCount).clamp(0, kAutoPlotCompetitorLimit);
        }

        expect(scansRemaining(), equals(0));
      });
    });

    group('canScan logic', () {
      test('cannot scan without access', () {
        final hasAutoPlotAccess = false;
        final hasUnlimitedAutoPlot = false;
        final scanCount = 0;

        bool canScan() {
          if (!hasAutoPlotAccess) return false;
          if (hasUnlimitedAutoPlot) return true;
          return scanCount < kAutoPlotCompetitorLimit;
        }

        expect(canScan(), isFalse);
      });

      test('can always scan with unlimited', () {
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = true;
        final scanCount = 999;

        bool canScan() {
          if (!hasAutoPlotAccess) return false;
          if (hasUnlimitedAutoPlot) return true;
          return scanCount < kAutoPlotCompetitorLimit;
        }

        expect(canScan(), isTrue);
      });

      test('can scan when under limit', () {
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = false;
        final scanCount = 49;

        bool canScan() {
          if (!hasAutoPlotAccess) return false;
          if (hasUnlimitedAutoPlot) return true;
          return scanCount < kAutoPlotCompetitorLimit;
        }

        expect(canScan(), isTrue);
      });

      test('cannot scan at limit', () {
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = false;
        final scanCount = 50;

        bool canScan() {
          if (!hasAutoPlotAccess) return false;
          if (hasUnlimitedAutoPlot) return true;
          return scanCount < kAutoPlotCompetitorLimit;
        }

        expect(canScan(), isFalse);
      });
    });

    group('scanLimit logic', () {
      test('returns -1 for unlimited', () {
        final hasUnlimitedAutoPlot = true;
        final scanLimit = hasUnlimitedAutoPlot ? -1 : kAutoPlotCompetitorLimit;
        expect(scanLimit, equals(-1));
      });

      test('returns 50 for competitor', () {
        final hasUnlimitedAutoPlot = false;
        final scanLimit = hasUnlimitedAutoPlot ? -1 : kAutoPlotCompetitorLimit;
        expect(scanLimit, equals(50));
      });
    });

    group('upgradeMessage logic', () {
      test('returns message when entitlement not configured', () {
        final entitlementProvider = null;
        final hasAutoPlotAccess = false;
        final canScan = false;

        String? upgradeMessage() {
          if (entitlementProvider == null) {
            return 'Unable to verify subscription. Please restart the app.';
          }
          if (!hasAutoPlotAccess) {
            return 'Auto-Plot requires Competitor tier or higher. Upgrade to unlock.';
          }
          if (!canScan) {
            return 'Monthly scan limit reached. Upgrade to Professional for unlimited scans.';
          }
          return null;
        }

        expect(upgradeMessage(), equals('Unable to verify subscription. Please restart the app.'));
      });

      test('returns message when no access', () {
        final entitlementProvider = Object();
        final hasAutoPlotAccess = false;
        final canScan = false;

        String? upgradeMessage() {
          if (entitlementProvider == null) {
            return 'Unable to verify subscription. Please restart the app.';
          }
          if (!hasAutoPlotAccess) {
            return 'Auto-Plot requires Competitor tier or higher. Upgrade to unlock.';
          }
          if (!canScan) {
            return 'Monthly scan limit reached. Upgrade to Professional for unlimited scans.';
          }
          return null;
        }

        expect(upgradeMessage(), contains('Competitor tier'));
      });

      test('returns message when limit reached', () {
        final entitlementProvider = Object();
        final hasAutoPlotAccess = true;
        final canScan = false;

        String? upgradeMessage() {
          if (entitlementProvider == null) {
            return 'Unable to verify subscription. Please restart the app.';
          }
          if (!hasAutoPlotAccess) {
            return 'Auto-Plot requires Competitor tier or higher. Upgrade to unlock.';
          }
          if (!canScan) {
            return 'Monthly scan limit reached. Upgrade to Professional for unlimited scans.';
          }
          return null;
        }

        expect(upgradeMessage(), contains('Monthly scan limit'));
      });

      test('returns null when can scan', () {
        final entitlementProvider = Object();
        final hasAutoPlotAccess = true;
        final canScan = true;

        String? upgradeMessage() {
          if (entitlementProvider == null) {
            return 'Unable to verify subscription. Please restart the app.';
          }
          if (!hasAutoPlotAccess) {
            return 'Auto-Plot requires Competitor tier or higher. Upgrade to unlock.';
          }
          if (!canScan) {
            return 'Monthly scan limit reached. Upgrade to Professional for unlimited scans.';
          }
          return null;
        }

        expect(upgradeMessage(), isNull);
      });
    });
  });

  // ===========================================================================
  // STATE TRANSITIONS TESTS
  // ===========================================================================
  group('State transitions', () {
    group('startCapture', () {
      test('transitions from idle to capturing', () {
        var state = AutoPlotState.idle;
        String? selectedTargetType;
        String? errorMessage;
        List<DetectedArrow> detectedArrows = [];
        Uint8List? capturedImage;

        void startCapture(String targetType) {
          selectedTargetType = targetType;
          state = AutoPlotState.capturing;
          errorMessage = null;
          detectedArrows = [];
          capturedImage = null;
        }

        startCapture('40cm');

        expect(state, equals(AutoPlotState.capturing));
        expect(selectedTargetType, equals('40cm'));
        expect(errorMessage, isNull);
        expect(detectedArrows, isEmpty);
        expect(capturedImage, isNull);
      });

      test('clears previous state on new capture', () {
        var state = AutoPlotState.error;
        String? selectedTargetType = 'old_target';
        String? errorMessage = 'Previous error';
        List<DetectedArrow> detectedArrows = [DetectedArrow(x: 0, y: 0)];
        Uint8List? capturedImage = Uint8List.fromList([1, 2, 3]);

        void startCapture(String targetType) {
          selectedTargetType = targetType;
          state = AutoPlotState.capturing;
          errorMessage = null;
          detectedArrows = [];
          capturedImage = null;
        }

        startCapture('80cm');

        expect(state, equals(AutoPlotState.capturing));
        expect(selectedTargetType, equals('80cm'));
        expect(errorMessage, isNull);
        expect(detectedArrows, isEmpty);
        expect(capturedImage, isNull);
      });
    });

    group('retryCapture', () {
      test('returns to capturing state', () {
        var state = AutoPlotState.error;
        String? errorMessage = 'Detection failed';
        List<DetectedArrow> detectedArrows = [];
        Uint8List? capturedImage = Uint8List.fromList([1, 2, 3]);

        void retryCapture() {
          state = AutoPlotState.capturing;
          errorMessage = null;
          detectedArrows = [];
          capturedImage = null;
        }

        retryCapture();

        expect(state, equals(AutoPlotState.capturing));
        expect(errorMessage, isNull);
        expect(detectedArrows, isEmpty);
        expect(capturedImage, isNull);
      });

      test('clears error state on retry', () {
        var state = AutoPlotState.error;
        String? errorMessage = 'Network timeout';

        void retryCapture() {
          state = AutoPlotState.capturing;
          errorMessage = null;
        }

        retryCapture();

        expect(state, equals(AutoPlotState.capturing));
        expect(errorMessage, isNull);
      });
    });

    group('reset', () {
      test('returns to idle state', () {
        var state = AutoPlotState.confirming;
        String? errorMessage = 'Some error';
        List<DetectedArrow> detectedArrows = [DetectedArrow(x: 0.5, y: 0.5)];
        Uint8List? capturedImage = Uint8List.fromList([1, 2, 3]);
        String? selectedTargetType = '40cm';
        bool isProcessingImage = true;

        void reset() {
          state = AutoPlotState.idle;
          errorMessage = null;
          detectedArrows = [];
          capturedImage = null;
          selectedTargetType = null;
          isProcessingImage = false;
        }

        reset();

        expect(state, equals(AutoPlotState.idle));
        expect(errorMessage, isNull);
        expect(detectedArrows, isEmpty);
        expect(capturedImage, isNull);
        expect(selectedTargetType, isNull);
        expect(isProcessingImage, isFalse);
      });
    });
  });

  // ===========================================================================
  // ARROW MANAGEMENT TESTS
  // ===========================================================================
  group('Arrow management', () {
    group('adjustArrow', () {
      test('updates arrow position at valid index', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0, faceIndex: 0),
          DetectedArrow(x: 0.5, y: 0.5, faceIndex: 1),
        ];

        void adjustArrow(int index, double x, double y) {
          if (index < 0 || index >= detectedArrows.length) return;
          final arrow = detectedArrows[index];
          detectedArrows[index] = DetectedArrow(
            x: x,
            y: y,
            faceIndex: arrow.faceIndex,
          );
        }

        adjustArrow(0, 0.1, -0.2);

        expect(detectedArrows[0].x, equals(0.1));
        expect(detectedArrows[0].y, equals(-0.2));
        expect(detectedArrows[0].faceIndex, equals(0)); // Preserved
        expect(detectedArrows[1].x, equals(0.5)); // Unchanged
      });

      test('ignores negative index', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0),
        ];
        final originalX = detectedArrows[0].x;

        void adjustArrow(int index, double x, double y) {
          if (index < 0 || index >= detectedArrows.length) return;
          final arrow = detectedArrows[index];
          detectedArrows[index] = DetectedArrow(
            x: x,
            y: y,
            faceIndex: arrow.faceIndex,
          );
        }

        adjustArrow(-1, 0.5, 0.5);

        expect(detectedArrows[0].x, equals(originalX));
      });

      test('ignores index beyond list length', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0),
        ];

        void adjustArrow(int index, double x, double y) {
          if (index < 0 || index >= detectedArrows.length) return;
          final arrow = detectedArrows[index];
          detectedArrows[index] = DetectedArrow(
            x: x,
            y: y,
            faceIndex: arrow.faceIndex,
          );
        }

        adjustArrow(5, 0.5, 0.5);

        expect(detectedArrows.length, equals(1));
      });
    });

    group('removeArrow', () {
      test('removes arrow at valid index', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0),
          DetectedArrow(x: 0.5, y: 0.5),
          DetectedArrow(x: 1.0, y: 1.0),
        ];

        void removeArrow(int index) {
          if (index < 0 || index >= detectedArrows.length) return;
          detectedArrows.removeAt(index);
        }

        removeArrow(1);

        expect(detectedArrows.length, equals(2));
        expect(detectedArrows[0].x, equals(0.0));
        expect(detectedArrows[1].x, equals(1.0));
      });

      test('ignores negative index', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0),
        ];

        void removeArrow(int index) {
          if (index < 0 || index >= detectedArrows.length) return;
          detectedArrows.removeAt(index);
        }

        removeArrow(-1);

        expect(detectedArrows.length, equals(1));
      });

      test('ignores index beyond list length', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0),
        ];

        void removeArrow(int index) {
          if (index < 0 || index >= detectedArrows.length) return;
          detectedArrows.removeAt(index);
        }

        removeArrow(5);

        expect(detectedArrows.length, equals(1));
      });
    });

    group('addArrow', () {
      test('adds arrow to list', () {
        final detectedArrows = <DetectedArrow>[];

        void addArrow(double x, double y, {int? faceIndex}) {
          detectedArrows.add(DetectedArrow(x: x, y: y, faceIndex: faceIndex));
        }

        addArrow(0.3, -0.2);

        expect(detectedArrows.length, equals(1));
        expect(detectedArrows[0].x, equals(0.3));
        expect(detectedArrows[0].y, equals(-0.2));
        expect(detectedArrows[0].faceIndex, isNull);
      });

      test('adds arrow with faceIndex', () {
        final detectedArrows = <DetectedArrow>[];

        void addArrow(double x, double y, {int? faceIndex}) {
          detectedArrows.add(DetectedArrow(x: x, y: y, faceIndex: faceIndex));
        }

        addArrow(0.3, -0.2, faceIndex: 2);

        expect(detectedArrows[0].faceIndex, equals(2));
      });

      test('adds multiple arrows', () {
        final detectedArrows = <DetectedArrow>[];

        void addArrow(double x, double y, {int? faceIndex}) {
          detectedArrows.add(DetectedArrow(x: x, y: y, faceIndex: faceIndex));
        }

        addArrow(0.1, 0.1);
        addArrow(0.2, 0.2);
        addArrow(0.3, 0.3);

        expect(detectedArrows.length, equals(3));
      });
    });

    group('confirmArrows', () {
      test('returns copy of arrows and resets', () {
        var state = AutoPlotState.confirming;
        String? errorMessage;
        final originalArrows = [
          DetectedArrow(x: 0.1, y: 0.2),
          DetectedArrow(x: 0.3, y: 0.4),
        ];
        var detectedArrows = List<DetectedArrow>.from(originalArrows);
        Uint8List? capturedImage = Uint8List.fromList([1, 2, 3]);
        String? selectedTargetType = '40cm';
        bool isProcessingImage = false;

        List<DetectedArrow> confirmArrows() {
          final arrows = List<DetectedArrow>.from(detectedArrows);
          // Reset (simulated)
          state = AutoPlotState.idle;
          errorMessage = null;
          detectedArrows = [];
          capturedImage = null;
          selectedTargetType = null;
          isProcessingImage = false;
          return arrows;
        }

        final confirmed = confirmArrows();

        expect(confirmed.length, equals(2));
        expect(confirmed[0].x, equals(0.1));
        expect(confirmed[1].x, equals(0.3));
        expect(state, equals(AutoPlotState.idle));
        expect(detectedArrows, isEmpty);
      });

      test('returned list is independent of internal state', () {
        final detectedArrows = [
          DetectedArrow(x: 0.1, y: 0.2),
        ];

        List<DetectedArrow> confirmArrows() {
          return List<DetectedArrow>.from(detectedArrows);
        }

        final confirmed = confirmArrows();
        detectedArrows.clear();

        expect(confirmed.length, equals(1));
      });
    });
  });

  // ===========================================================================
  // TARGET REGISTRATION TESTS
  // ===========================================================================
  group('Target registration', () {
    group('hasRegisteredTarget', () {
      test('returns true when target exists', () {
        final registeredTargets = [
          _MockRegisteredTarget('tgt-1', '40cm'),
          _MockRegisteredTarget('tgt-2', '80cm'),
        ];

        bool hasRegisteredTarget(String targetType) {
          return registeredTargets.any((t) => t.targetType == targetType);
        }

        expect(hasRegisteredTarget('40cm'), isTrue);
      });

      test('returns false when target not found', () {
        final registeredTargets = [
          _MockRegisteredTarget('tgt-1', '40cm'),
        ];

        bool hasRegisteredTarget(String targetType) {
          return registeredTargets.any((t) => t.targetType == targetType);
        }

        expect(hasRegisteredTarget('122cm'), isFalse);
      });

      test('returns false for empty list', () {
        final registeredTargets = <_MockRegisteredTarget>[];

        bool hasRegisteredTarget(String targetType) {
          return registeredTargets.any((t) => t.targetType == targetType);
        }

        expect(hasRegisteredTarget('40cm'), isFalse);
      });
    });

    group('getRegisteredTargetForType', () {
      test('returns target when found', () {
        final registeredTargets = [
          _MockRegisteredTarget('tgt-1', '40cm'),
          _MockRegisteredTarget('tgt-2', '80cm'),
        ];

        _MockRegisteredTarget? getRegisteredTargetForType(String targetType) {
          try {
            return registeredTargets.firstWhere((t) => t.targetType == targetType);
          } catch (_) {
            return null;
          }
        }

        final target = getRegisteredTargetForType('40cm');
        expect(target, isNotNull);
        expect(target!.id, equals('tgt-1'));
      });

      test('returns null when not found', () {
        final registeredTargets = [
          _MockRegisteredTarget('tgt-1', '40cm'),
        ];

        _MockRegisteredTarget? getRegisteredTargetForType(String targetType) {
          try {
            return registeredTargets.firstWhere((t) => t.targetType == targetType);
          } catch (_) {
            return null;
          }
        }

        expect(getRegisteredTargetForType('122cm'), isNull);
      });
    });
  });

  // ===========================================================================
  // ARROW APPEARANCE TESTS
  // ===========================================================================
  group('Arrow appearance management', () {
    group('setArrowAppearance', () {
      test('sets arrow appearance', () {
        ArrowAppearanceForAutoPlot? arrowAppearance;

        void setArrowAppearance(ArrowAppearanceForAutoPlot? appearance) {
          arrowAppearance = appearance;
        }

        const newAppearance = ArrowAppearanceForAutoPlot(
          fletchColor: 'green',
          nockColor: 'orange',
        );
        setArrowAppearance(newAppearance);

        expect(arrowAppearance, isNotNull);
        expect(arrowAppearance!.fletchColor, equals('green'));
      });

      test('can set to null', () {
        ArrowAppearanceForAutoPlot? arrowAppearance = const ArrowAppearanceForAutoPlot(
          fletchColor: 'green',
        );

        void setArrowAppearance(ArrowAppearanceForAutoPlot? appearance) {
          arrowAppearance = appearance;
        }

        setArrowAppearance(null);

        expect(arrowAppearance, isNull);
      });
    });
  });

  // ===========================================================================
  // REAL-WORLD SCENARIO TESTS
  // ===========================================================================
  group('Real-world scenarios', () {
    group('Olympic archer workflow', () {
      test('typical 70m round detection flow', () {
        var state = AutoPlotState.idle;
        String? selectedTargetType;
        List<DetectedArrow> detectedArrows = [];

        // Start capture for 122cm face (Olympic)
        selectedTargetType = '122cm';
        state = AutoPlotState.capturing;
        expect(state, equals(AutoPlotState.capturing));

        // Simulate processing
        state = AutoPlotState.processing;
        expect(state, equals(AutoPlotState.processing));

        // Detection complete - 3 arrows detected (typical end)
        detectedArrows = [
          DetectedArrow(x: 0.02, y: -0.01, confidence: 0.95), // Near X
          DetectedArrow(x: 0.15, y: 0.1, confidence: 0.88),   // 10 ring
          DetectedArrow(x: -0.2, y: -0.18, confidence: 0.75), // 9 ring, lower confidence
        ];
        state = AutoPlotState.confirming;

        expect(state, equals(AutoPlotState.confirming));
        expect(detectedArrows.length, equals(3));
        expect(detectedArrows[2].needsVerification, isFalse);
      });

      test('handles line cutter on 9/10 ring', () {
        final lineCutter = DetectedArrow(
          x: 0.12, // On the 9/10 ring boundary
          y: 0.0,
          confidence: 0.7,
          isLineCutter: true,
        );

        expect(lineCutter.needsVerification, isTrue);
      });
    });

    group('Indoor triple spot workflow', () {
      test('3 arrows on 3 different faces', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0, faceIndex: 0), // Top face
          DetectedArrow(x: 0.05, y: -0.02, faceIndex: 1), // Middle face
          DetectedArrow(x: -0.03, y: 0.01, faceIndex: 2), // Bottom face
        ];

        expect(detectedArrows.where((a) => a.faceIndex == 0).length, equals(1));
        expect(detectedArrows.where((a) => a.faceIndex == 1).length, equals(1));
        expect(detectedArrows.where((a) => a.faceIndex == 2).length, equals(1));
      });

      test('6 arrows on triple spot', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0, faceIndex: 0),
          DetectedArrow(x: 0.1, y: 0.1, faceIndex: 0),
          DetectedArrow(x: 0.0, y: 0.0, faceIndex: 1),
          DetectedArrow(x: -0.1, y: 0.0, faceIndex: 1),
          DetectedArrow(x: 0.0, y: 0.0, faceIndex: 2),
          DetectedArrow(x: 0.05, y: -0.05, faceIndex: 2),
        ];

        final arrowsPerFace = <int, int>{};
        for (final arrow in detectedArrows) {
          final face = arrow.faceIndex ?? -1;
          arrowsPerFace[face] = (arrowsPerFace[face] ?? 0) + 1;
        }

        expect(arrowsPerFace[0], equals(2));
        expect(arrowsPerFace[1], equals(2));
        expect(arrowsPerFace[2], equals(2));
      });
    });

    group('Tournament scenario with arrow identification', () {
      test('identifies own arrows in mixed field', () {
        final detectedArrows = [
          DetectedArrow(x: 0.0, y: 0.0, isMyArrow: true),
          DetectedArrow(x: 0.2, y: 0.1, isMyArrow: true),
          DetectedArrow(x: -0.3, y: 0.15, isMyArrow: true),
          DetectedArrow(x: 0.5, y: -0.2, isMyArrow: false), // Other archer's arrow
          DetectedArrow(x: -0.1, y: 0.4, isMyArrow: false), // Other archer's arrow
          DetectedArrow(x: 0.35, y: 0.35, isMyArrow: false), // Other archer's arrow
        ];

        final myArrows = detectedArrows.where((a) => a.isMyArrow).toList();
        final otherArrows = detectedArrows.where((a) => !a.isMyArrow).toList();

        expect(myArrows.length, equals(3));
        expect(otherArrows.length, equals(3));
      });
    });

    group('Competitor tier quota management', () {
      test('tracks usage throughout month', () {
        var scanCount = 0;
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = false;

        int scansRemaining() {
          if (!hasAutoPlotAccess) return 0;
          if (hasUnlimitedAutoPlot) return -1;
          return (kAutoPlotCompetitorLimit - scanCount).clamp(0, kAutoPlotCompetitorLimit);
        }

        bool canScan() {
          if (!hasAutoPlotAccess) return false;
          if (hasUnlimitedAutoPlot) return true;
          return scanCount < kAutoPlotCompetitorLimit;
        }

        // First scan
        expect(canScan(), isTrue);
        expect(scansRemaining(), equals(50));
        scanCount++;

        // After 25 scans
        scanCount = 25;
        expect(canScan(), isTrue);
        expect(scansRemaining(), equals(25));

        // After 49 scans
        scanCount = 49;
        expect(canScan(), isTrue);
        expect(scansRemaining(), equals(1));

        // At limit
        scanCount = 50;
        expect(canScan(), isFalse);
        expect(scansRemaining(), equals(0));
      });
    });

    group('Professional tier unlimited usage', () {
      test('allows unlimited scans', () {
        final scanCount = 500;
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = true;

        bool canScan() {
          if (!hasAutoPlotAccess) return false;
          if (hasUnlimitedAutoPlot) return true;
          return scanCount < kAutoPlotCompetitorLimit;
        }

        int scansRemaining() {
          if (!hasAutoPlotAccess) return 0;
          if (hasUnlimitedAutoPlot) return -1;
          return (kAutoPlotCompetitorLimit - scanCount).clamp(0, kAutoPlotCompetitorLimit);
        }

        expect(canScan(), isTrue);
        expect(scansRemaining(), equals(-1));
      });
    });
  });

  // ===========================================================================
  // EDGE CASES AND ERROR HANDLING
  // ===========================================================================
  group('Edge cases', () {
    group('boundary arrow positions', () {
      test('arrow at exact center', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0);
        expect(arrow.x, equals(0.0));
        expect(arrow.y, equals(0.0));
      });

      test('arrow at maximum boundaries', () {
        final arrow = DetectedArrow(x: 1.0, y: 1.0);
        expect(arrow.x, equals(1.0));
        expect(arrow.y, equals(1.0));
      });

      test('arrow at minimum boundaries', () {
        final arrow = DetectedArrow(x: -1.0, y: -1.0);
        expect(arrow.x, equals(-1.0));
        expect(arrow.y, equals(-1.0));
      });

      test('arrow slightly outside boundaries', () {
        // The API might return arrows slightly outside if they're on the edge
        final arrow = DetectedArrow(x: 1.05, y: -1.02);
        expect(arrow.x, greaterThan(1.0));
        expect(arrow.y, lessThan(-1.0));
      });
    });

    group('confidence edge values', () {
      test('minimum confidence 0.0', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.0);
        expect(arrow.confidence, equals(0.0));
        expect(arrow.needsVerification, isTrue);
      });

      test('maximum confidence 1.0', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 1.0);
        expect(arrow.confidence, equals(1.0));
        expect(arrow.needsVerification, isFalse);
      });

      test('threshold confidence 0.5', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.5);
        expect(arrow.needsVerification, isFalse);
      });

      test('just below threshold 0.49', () {
        final arrow = DetectedArrow(x: 0.0, y: 0.0, confidence: 0.49);
        expect(arrow.needsVerification, isTrue);
      });
    });

    group('empty and null handling', () {
      test('handles empty arrows list', () {
        final detectedArrows = <DetectedArrow>[];

        List<DetectedArrow> confirmArrows() {
          return List<DetectedArrow>.from(detectedArrows);
        }

        final confirmed = confirmArrows();
        expect(confirmed, isEmpty);
      });

      test('handles target type with special characters', () {
        var selectedTargetType = 'triple_40cm (indoor)';
        expect(selectedTargetType, isNotEmpty);
      });
    });

    group('scan count boundaries', () {
      test('scan count at exactly 50', () {
        final scanCount = 50;
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = false;

        bool canScan() {
          if (!hasAutoPlotAccess) return false;
          if (hasUnlimitedAutoPlot) return true;
          return scanCount < kAutoPlotCompetitorLimit;
        }

        expect(canScan(), isFalse);
      });

      test('scan count just below limit', () {
        final scanCount = 49;
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = false;

        bool canScan() {
          if (!hasAutoPlotAccess) return false;
          if (hasUnlimitedAutoPlot) return true;
          return scanCount < kAutoPlotCompetitorLimit;
        }

        expect(canScan(), isTrue);
      });

      test('scan count well above limit', () {
        final scanCount = 100;
        final hasAutoPlotAccess = true;
        final hasUnlimitedAutoPlot = false;

        int scansRemaining() {
          if (!hasAutoPlotAccess) return 0;
          if (hasUnlimitedAutoPlot) return -1;
          return (kAutoPlotCompetitorLimit - scanCount).clamp(0, kAutoPlotCompetitorLimit);
        }

        expect(scansRemaining(), equals(0)); // Clamped to 0
      });
    });
  });

  // ===========================================================================
  // DATA INTEGRITY TESTS
  // ===========================================================================
  group('Data integrity', () {
    group('DetectedArrow immutability', () {
      test('copyWith creates new instance', () {
        final original = DetectedArrow(x: 0.5, y: 0.3);
        final copied = original.copyWith(x: 0.8);

        expect(identical(original, copied), isFalse);
        expect(original.x, equals(0.5));
        expect(copied.x, equals(0.8));
      });

      test('modifying copied values does not affect original', () {
        final original = DetectedArrow(x: 0.5, y: 0.3, faceIndex: 1);
        final copied = original.copyWith(faceIndex: 2);

        expect(original.faceIndex, equals(1));
        expect(copied.faceIndex, equals(2));
      });
    });

    group('list independence', () {
      test('confirmed arrows list is independent', () {
        final detectedArrows = [
          DetectedArrow(x: 0.1, y: 0.2),
          DetectedArrow(x: 0.3, y: 0.4),
        ];

        final confirmed = List<DetectedArrow>.from(detectedArrows);
        detectedArrows.clear();

        expect(confirmed.length, equals(2));
      });

      test('adding to list does not affect previously returned list', () {
        final detectedArrows = [
          DetectedArrow(x: 0.1, y: 0.2),
        ];

        final snapshot = List<DetectedArrow>.from(detectedArrows);
        detectedArrows.add(DetectedArrow(x: 0.3, y: 0.4));

        expect(snapshot.length, equals(1));
        expect(detectedArrows.length, equals(2));
      });
    });

    group('JSON roundtrip integrity', () {
      test('DetectedArrow preserves all values through JSON', () {
        final original = DetectedArrow(
          x: 0.123456,
          y: -0.654321,
          faceIndex: 1,
          confidence: 0.876543,
          isLineCutter: true,
          isMyArrow: true,
        );

        final json = original.toJson();
        final restored = DetectedArrow.fromJson(json);

        expect(restored.x, closeTo(original.x, 0.000001));
        expect(restored.y, closeTo(original.y, 0.000001));
        expect(restored.faceIndex, equals(original.faceIndex));
        expect(restored.confidence, closeTo(original.confidence, 0.000001));
        expect(restored.isLineCutter, equals(original.isLineCutter));
        expect(restored.isMyArrow, equals(original.isMyArrow));
      });

      test('ArrowAppearance preserves all values through JSON', () {
        final original = ArrowAppearance(
          fletchColor: 'green',
          nockColor: 'orange',
          wrapColor: 'white',
          shaftColor: 'black',
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

  // ===========================================================================
  // MUTEX AND CONCURRENCY TESTS
  // ===========================================================================
  group('Concurrency protection', () {
    test('processing mutex prevents concurrent image processing', () {
      var isProcessingImage = false;
      var processCount = 0;

      Future<void> processImage() async {
        if (isProcessingImage) {
          return; // Skip if already processing
        }
        isProcessingImage = true;
        processCount++;
        // Simulate async processing
        await Future.delayed(const Duration(milliseconds: 10));
        isProcessingImage = false;
      }

      // Start two concurrent processes
      final future1 = processImage();
      final future2 = processImage();

      return Future.wait([future1, future2]).then((_) {
        // Only one should have been processed
        expect(processCount, equals(1));
      });
    });
  });
}

/// Mock class to simulate RegisteredTarget for testing
class _MockRegisteredTarget {
  final String id;
  final String targetType;
  final String imagePath;
  final bool isTripleSpot;

  _MockRegisteredTarget(this.id, this.targetType, {
    this.imagePath = '/path/to/image.jpg',
    this.isTripleSpot = false,
  });
}
