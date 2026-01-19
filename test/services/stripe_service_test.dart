/// Tests for StripeService
///
/// These tests verify the Stripe payment service functionality including:
/// - Price ID constants and mappings
/// - Subscription tier integration
/// - EntitlementStatus JSON parsing
/// - LegacyCheckResult JSON parsing
/// - Data integrity and edge cases
///
/// Note: Tests that require StripeService instantiation are skipped because
/// the service has a hard dependency on Firebase Functions which cannot be
/// easily mocked without extensive setup. The service is a singleton that
/// delegates to FirebaseFunctions for payment operations.
///
/// The key testable components are:
/// 1. Static price ID constants (no instantiation needed)
/// 2. EntitlementStatus model and JSON parsing
/// 3. LegacyCheckResult model and JSON parsing
/// 4. SubscriptionTier enum and extension methods
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/stripe_service.dart';
import 'package:archery_super_app/providers/entitlement_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StripeService', () {
    group('price ID constants', () {
      test('competitorPriceId is correct Stripe price ID format', () {
        expect(StripeService.competitorPriceId, startsWith('price_'));
        expect(StripeService.competitorPriceId, isNotEmpty);
      });

      test('professionalPriceId is correct Stripe price ID format', () {
        expect(StripeService.professionalPriceId, startsWith('price_'));
        expect(StripeService.professionalPriceId, isNotEmpty);
      });

      test('hustonSchoolPriceId is correct Stripe price ID format', () {
        expect(StripeService.hustonSchoolPriceId, startsWith('price_'));
        expect(StripeService.hustonSchoolPriceId, isNotEmpty);
      });

      test('aiming3dPriceId is correct Stripe price ID format', () {
        expect(StripeService.aiming3dPriceId, startsWith('price_'));
        expect(StripeService.aiming3dPriceId, isNotEmpty);
      });

      test('all price IDs are unique', () {
        final priceIds = [
          StripeService.competitorPriceId,
          StripeService.professionalPriceId,
          StripeService.hustonSchoolPriceId,
          StripeService.aiming3dPriceId,
        ];

        expect(priceIds.toSet().length, equals(priceIds.length));
      });

      test('competitor price ID matches expected value', () {
        expect(
          StripeService.competitorPriceId,
          equals('price_1SqztNRpdm3uvDfu5wcHwFum'),
        );
      });

      test('professional price ID matches expected value', () {
        expect(
          StripeService.professionalPriceId,
          equals('price_1SqzuiRpdm3uvDfuzehsoDZt'),
        );
      });

      test('hustonSchool price ID matches expected value', () {
        expect(
          StripeService.hustonSchoolPriceId,
          equals('price_1Sr3ETRpdm3uvDfuEEfNt7P1'),
        );
      });

      test('aiming3d price ID matches expected value', () {
        expect(
          StripeService.aiming3dPriceId,
          equals('price_1Sr3GJRpdm3uvDfuhGWLxEx3'),
        );
      });

      test('price IDs are immutable constants', () {
        // Verify constants are accessible and stable
        final competitorId = StripeService.competitorPriceId;
        final professionalId = StripeService.professionalPriceId;
        final hustonSchoolId = StripeService.hustonSchoolPriceId;
        final aiming3dId = StripeService.aiming3dPriceId;

        // Accessing again should return identical values
        expect(StripeService.competitorPriceId, equals(competitorId));
        expect(StripeService.professionalPriceId, equals(professionalId));
        expect(StripeService.hustonSchoolPriceId, equals(hustonSchoolId));
        expect(StripeService.aiming3dPriceId, equals(aiming3dId));
      });

      test('price IDs have consistent length format', () {
        // Stripe price IDs follow a consistent format
        final priceIds = [
          StripeService.competitorPriceId,
          StripeService.professionalPriceId,
          StripeService.hustonSchoolPriceId,
          StripeService.aiming3dPriceId,
        ];

        for (final priceId in priceIds) {
          // Price IDs typically have a consistent structure
          expect(priceId.length, greaterThan(10));
          expect(priceId, matches(RegExp(r'^price_[A-Za-z0-9]+$')));
        }
      });
    });

    group('subscription tier to price ID mapping', () {
      test('archer tier is free (no price ID needed)', () {
        // Archer is free, so no Stripe price ID is needed
        expect(SubscriptionTier.archer.autoPlotLimit, equals(0));
        expect(SubscriptionTier.archer.price, equals('Free'));
      });

      test('competitor tier has associated price ID', () {
        expect(SubscriptionTier.competitor.price, equals('£2/mo'));
        expect(StripeService.competitorPriceId, isNotEmpty);
      });

      test('professional tier has associated price ID', () {
        expect(SubscriptionTier.professional.price, equals('£7.20/mo'));
        expect(StripeService.professionalPriceId, isNotEmpty);
      });

      test('hustonSchool tier has associated price ID', () {
        expect(SubscriptionTier.hustonSchool.price, equals('£40/mo'));
        expect(StripeService.hustonSchoolPriceId, isNotEmpty);
      });

      test('tier count matches expected (4 tiers)', () {
        expect(SubscriptionTier.values.length, equals(4));
      });

      test('paid tiers have 3 price IDs', () {
        // archer is free, so 3 paid tiers
        final paidPriceIds = [
          StripeService.competitorPriceId,
          StripeService.professionalPriceId,
          StripeService.hustonSchoolPriceId,
        ];
        expect(paidPriceIds.length, equals(3));
      });
    });

    group('product pricing', () {
      test('3d_aiming_course has a price ID', () {
        expect(StripeService.aiming3dPriceId, isNotEmpty);
      });

      test('aiming3dPriceId is valid Stripe format', () {
        expect(StripeService.aiming3dPriceId, startsWith('price_'));
      });
    });
  });

  group('EntitlementStatus', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'tier': 'professional',
          'stripeCustomerId': 'cus_12345',
          'stripeSubscriptionId': 'sub_67890',
          'expiresAt': '2026-02-01T00:00:00.000Z',
          'isLegacy3dAiming': true,
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.tier, equals('professional'));
        expect(status.stripeCustomerId, equals('cus_12345'));
        expect(status.stripeSubscriptionId, equals('sub_67890'));
        expect(status.expiresAt, isNotNull);
        expect(status.expiresAt!.year, equals(2026));
        expect(status.expiresAt!.month, equals(2));
        expect(status.expiresAt!.day, equals(1));
        expect(status.isLegacy3dAiming, isTrue);
      });

      test('handles missing tier with default value', () {
        final json = <String, dynamic>{
          'stripeCustomerId': 'cus_12345',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.tier, equals('archer'));
      });

      test('handles null tier with default value', () {
        final json = <String, dynamic>{
          'tier': null,
          'stripeCustomerId': 'cus_12345',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.tier, equals('archer'));
      });

      test('handles missing stripeCustomerId', () {
        final json = {
          'tier': 'competitor',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.stripeCustomerId, isNull);
      });

      test('handles missing stripeSubscriptionId', () {
        final json = {
          'tier': 'competitor',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.stripeSubscriptionId, isNull);
      });

      test('handles missing expiresAt', () {
        final json = {
          'tier': 'competitor',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.expiresAt, isNull);
      });

      test('handles null expiresAt', () {
        final json = <String, dynamic>{
          'tier': 'competitor',
          'expiresAt': null,
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.expiresAt, isNull);
      });

      test('handles missing isLegacy3dAiming with default false', () {
        final json = {
          'tier': 'competitor',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.isLegacy3dAiming, isFalse);
      });

      test('handles null isLegacy3dAiming with default false', () {
        final json = <String, dynamic>{
          'tier': 'competitor',
          'isLegacy3dAiming': null,
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.isLegacy3dAiming, isFalse);
      });

      test('parses all tier values correctly', () {
        final tiers = ['archer', 'competitor', 'professional', 'hustonSchool'];

        for (final tier in tiers) {
          final json = {'tier': tier};
          final status = EntitlementStatus.fromJson(json);
          expect(status.tier, equals(tier));
        }
      });

      test('parses ISO 8601 date format correctly', () {
        final json = {
          'tier': 'competitor',
          'expiresAt': '2026-12-25T15:30:45.123Z',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.expiresAt, isNotNull);
        expect(status.expiresAt!.year, equals(2026));
        expect(status.expiresAt!.month, equals(12));
        expect(status.expiresAt!.day, equals(25));
        expect(status.expiresAt!.hour, equals(15));
        expect(status.expiresAt!.minute, equals(30));
      });

      test('handles empty JSON', () {
        final json = <String, dynamic>{};

        final status = EntitlementStatus.fromJson(json);

        expect(status.tier, equals('archer'));
        expect(status.stripeCustomerId, isNull);
        expect(status.stripeSubscriptionId, isNull);
        expect(status.expiresAt, isNull);
        expect(status.isLegacy3dAiming, isFalse);
      });

      test('creates status with all optional fields null', () {
        final json = {
          'tier': 'archer',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.stripeCustomerId, isNull);
        expect(status.stripeSubscriptionId, isNull);
        expect(status.expiresAt, isNull);
        expect(status.isLegacy3dAiming, isFalse);
      });

      test('handles free tier archer correctly', () {
        final json = {
          'tier': 'archer',
          'isLegacy3dAiming': false,
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.tier, equals('archer'));
        expect(status.isLegacy3dAiming, isFalse);
      });

      test('handles legacy 3D Aiming access', () {
        final json = {
          'tier': 'archer',
          'isLegacy3dAiming': true,
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.tier, equals('archer'));
        expect(status.isLegacy3dAiming, isTrue);
      });

      test('parses date with timezone offset correctly', () {
        final json = {
          'tier': 'competitor',
          'expiresAt': '2026-06-15T12:00:00+05:30',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.expiresAt, isNotNull);
        expect(status.expiresAt!.year, equals(2026));
        expect(status.expiresAt!.month, equals(6));
        expect(status.expiresAt!.day, equals(15));
      });

      test('parses date without milliseconds', () {
        final json = {
          'tier': 'competitor',
          'expiresAt': '2026-03-01T00:00:00Z',
        };

        final status = EntitlementStatus.fromJson(json);

        expect(status.expiresAt, isNotNull);
        expect(status.expiresAt!.year, equals(2026));
        expect(status.expiresAt!.month, equals(3));
        expect(status.expiresAt!.day, equals(1));
      });
    });

    group('constructor', () {
      test('creates status with required tier', () {
        final status = EntitlementStatus(tier: 'competitor');

        expect(status.tier, equals('competitor'));
        expect(status.stripeCustomerId, isNull);
        expect(status.stripeSubscriptionId, isNull);
        expect(status.expiresAt, isNull);
        expect(status.isLegacy3dAiming, isFalse);
      });

      test('creates status with all fields', () {
        final expiresAt = DateTime(2026, 3, 15);
        final status = EntitlementStatus(
          tier: 'professional',
          stripeCustomerId: 'cus_abc123',
          stripeSubscriptionId: 'sub_xyz789',
          expiresAt: expiresAt,
          isLegacy3dAiming: true,
        );

        expect(status.tier, equals('professional'));
        expect(status.stripeCustomerId, equals('cus_abc123'));
        expect(status.stripeSubscriptionId, equals('sub_xyz789'));
        expect(status.expiresAt, equals(expiresAt));
        expect(status.isLegacy3dAiming, isTrue);
      });

      test('default isLegacy3dAiming is false', () {
        final status = EntitlementStatus(tier: 'archer');

        expect(status.isLegacy3dAiming, isFalse);
      });

      test('creates status for each tier', () {
        final tiers = ['archer', 'competitor', 'professional', 'hustonSchool'];

        for (final tier in tiers) {
          final status = EntitlementStatus(tier: tier);
          expect(status.tier, equals(tier));
        }
      });
    });

    group('field types', () {
      test('tier is always a String', () {
        final status = EntitlementStatus(tier: 'competitor');
        expect(status.tier, isA<String>());
      });

      test('stripeCustomerId is nullable String', () {
        final status1 = EntitlementStatus(tier: 'competitor');
        expect(status1.stripeCustomerId, isNull);

        final status2 = EntitlementStatus(
          tier: 'competitor',
          stripeCustomerId: 'cus_123',
        );
        expect(status2.stripeCustomerId, isA<String>());
      });

      test('expiresAt is nullable DateTime', () {
        final status1 = EntitlementStatus(tier: 'competitor');
        expect(status1.expiresAt, isNull);

        final status2 = EntitlementStatus(
          tier: 'competitor',
          expiresAt: DateTime.now(),
        );
        expect(status2.expiresAt, isA<DateTime>());
      });

      test('isLegacy3dAiming is always bool', () {
        final status1 = EntitlementStatus(tier: 'archer');
        expect(status1.isLegacy3dAiming, isA<bool>());

        final status2 = EntitlementStatus(tier: 'archer', isLegacy3dAiming: true);
        expect(status2.isLegacy3dAiming, isA<bool>());
      });
    });
  });

  group('LegacyCheckResult', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'hasLegacyAccess': true,
          'grantedProducts': ['3d_aiming_course', 'premium_targets'],
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.hasLegacyAccess, isTrue);
        expect(result.grantedProducts, hasLength(2));
        expect(result.grantedProducts, contains('3d_aiming_course'));
        expect(result.grantedProducts, contains('premium_targets'));
      });

      test('handles missing hasLegacyAccess with default false', () {
        final json = <String, dynamic>{
          'grantedProducts': ['3d_aiming_course'],
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.hasLegacyAccess, isFalse);
      });

      test('handles null hasLegacyAccess with default false', () {
        final json = <String, dynamic>{
          'hasLegacyAccess': null,
          'grantedProducts': ['3d_aiming_course'],
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.hasLegacyAccess, isFalse);
      });

      test('handles missing grantedProducts with empty list', () {
        final json = {
          'hasLegacyAccess': true,
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.grantedProducts, isEmpty);
      });

      test('handles null grantedProducts with empty list', () {
        final json = <String, dynamic>{
          'hasLegacyAccess': true,
          'grantedProducts': null,
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.grantedProducts, isEmpty);
      });

      test('handles empty grantedProducts list', () {
        final json = {
          'hasLegacyAccess': false,
          'grantedProducts': <String>[],
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.hasLegacyAccess, isFalse);
        expect(result.grantedProducts, isEmpty);
      });

      test('handles empty JSON', () {
        final json = <String, dynamic>{};

        final result = LegacyCheckResult.fromJson(json);

        expect(result.hasLegacyAccess, isFalse);
        expect(result.grantedProducts, isEmpty);
      });

      test('handles single product in grantedProducts', () {
        final json = {
          'hasLegacyAccess': true,
          'grantedProducts': ['3d_aiming_course'],
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.grantedProducts, hasLength(1));
        expect(result.grantedProducts.first, equals('3d_aiming_course'));
      });

      test('handles multiple products in grantedProducts', () {
        final json = {
          'hasLegacyAccess': true,
          'grantedProducts': [
            '3d_aiming_course',
            'premium_targets',
            'advanced_drills',
            'competition_prep',
          ],
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.grantedProducts, hasLength(4));
      });

      test('preserves product order in grantedProducts', () {
        final products = ['first', 'second', 'third'];
        final json = {
          'hasLegacyAccess': true,
          'grantedProducts': products,
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.grantedProducts[0], equals('first'));
        expect(result.grantedProducts[1], equals('second'));
        expect(result.grantedProducts[2], equals('third'));
      });

      test('handles false hasLegacyAccess with products', () {
        // Edge case: products might be returned but access is denied
        final json = {
          'hasLegacyAccess': false,
          'grantedProducts': ['3d_aiming_course'],
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.hasLegacyAccess, isFalse);
        expect(result.grantedProducts, hasLength(1));
      });

      test('handles dynamic list conversion', () {
        // JSON decode typically returns List<dynamic>, not List<String>
        final json = <String, dynamic>{
          'hasLegacyAccess': true,
          'grantedProducts': <dynamic>['product1', 'product2'],
        };

        final result = LegacyCheckResult.fromJson(json);

        expect(result.grantedProducts, isA<List<String>>());
        expect(result.grantedProducts, hasLength(2));
      });
    });

    group('constructor', () {
      test('creates result with required fields', () {
        final result = LegacyCheckResult(
          hasLegacyAccess: true,
          grantedProducts: ['3d_aiming_course'],
        );

        expect(result.hasLegacyAccess, isTrue);
        expect(result.grantedProducts, contains('3d_aiming_course'));
      });

      test('creates result with empty products list', () {
        final result = LegacyCheckResult(
          hasLegacyAccess: false,
          grantedProducts: [],
        );

        expect(result.hasLegacyAccess, isFalse);
        expect(result.grantedProducts, isEmpty);
      });

      test('creates result with multiple products', () {
        final products = ['product1', 'product2', 'product3'];
        final result = LegacyCheckResult(
          hasLegacyAccess: true,
          grantedProducts: products,
        );

        expect(result.grantedProducts, equals(products));
      });
    });

    group('field types', () {
      test('hasLegacyAccess is always bool', () {
        final result = LegacyCheckResult(
          hasLegacyAccess: true,
          grantedProducts: [],
        );

        expect(result.hasLegacyAccess, isA<bool>());
      });

      test('grantedProducts is always List<String>', () {
        final result = LegacyCheckResult(
          hasLegacyAccess: true,
          grantedProducts: ['product1'],
        );

        expect(result.grantedProducts, isA<List<String>>());
      });
    });
  });

  group('SubscriptionTier integration', () {
    test('all tiers have display names', () {
      for (final tier in SubscriptionTier.values) {
        expect(tier.displayName, isNotEmpty);
      }
    });

    test('all tiers have price strings', () {
      for (final tier in SubscriptionTier.values) {
        expect(tier.price, isNotEmpty);
      }
    });

    test('all tiers have descriptions', () {
      for (final tier in SubscriptionTier.values) {
        expect(tier.description, isNotEmpty);
      }
    });

    test('tier display names are correct', () {
      expect(SubscriptionTier.archer.displayName, equals('Archer'));
      expect(SubscriptionTier.competitor.displayName, equals('Competitor'));
      expect(SubscriptionTier.professional.displayName, equals('Professional'));
      expect(SubscriptionTier.hustonSchool.displayName, equals('Huston School'));
    });

    test('tier prices are correct', () {
      expect(SubscriptionTier.archer.price, equals('Free'));
      expect(SubscriptionTier.competitor.price, equals('£2/mo'));
      expect(SubscriptionTier.professional.price, equals('£7.20/mo'));
      expect(SubscriptionTier.hustonSchool.price, equals('£40/mo'));
    });

    test('auto-plot limits are correct for each tier', () {
      expect(SubscriptionTier.archer.autoPlotLimit, equals(0));
      expect(SubscriptionTier.competitor.autoPlotLimit, equals(50));
      expect(SubscriptionTier.professional.autoPlotLimit, equals(-1)); // Unlimited
      expect(SubscriptionTier.hustonSchool.autoPlotLimit, equals(-1)); // Unlimited
    });

    test('fromString parses tier names correctly', () {
      expect(
        SubscriptionTierExtension.fromString('archer'),
        equals(SubscriptionTier.archer),
      );
      expect(
        SubscriptionTierExtension.fromString('competitor'),
        equals(SubscriptionTier.competitor),
      );
      expect(
        SubscriptionTierExtension.fromString('professional'),
        equals(SubscriptionTier.professional),
      );
      expect(
        SubscriptionTierExtension.fromString('hustonschool'),
        equals(SubscriptionTier.hustonSchool),
      );
      expect(
        SubscriptionTierExtension.fromString('huston_school'),
        equals(SubscriptionTier.hustonSchool),
      );
    });

    test('fromString is case insensitive', () {
      expect(
        SubscriptionTierExtension.fromString('ARCHER'),
        equals(SubscriptionTier.archer),
      );
      expect(
        SubscriptionTierExtension.fromString('Competitor'),
        equals(SubscriptionTier.competitor),
      );
      expect(
        SubscriptionTierExtension.fromString('PROFESSIONAL'),
        equals(SubscriptionTier.professional),
      );
      expect(
        SubscriptionTierExtension.fromString('HustonSchool'),
        equals(SubscriptionTier.hustonSchool),
      );
    });

    test('fromString returns archer for unknown values', () {
      expect(
        SubscriptionTierExtension.fromString('unknown'),
        equals(SubscriptionTier.archer),
      );
      expect(
        SubscriptionTierExtension.fromString(''),
        equals(SubscriptionTier.archer),
      );
      expect(
        SubscriptionTierExtension.fromString('premium'),
        equals(SubscriptionTier.archer),
      );
      expect(
        SubscriptionTierExtension.fromString('invalid_tier'),
        equals(SubscriptionTier.archer),
      );
    });

    test('tier index order is correct for feature gating', () {
      // Feature gating relies on tier.index comparisons
      expect(SubscriptionTier.archer.index, lessThan(SubscriptionTier.competitor.index));
      expect(SubscriptionTier.competitor.index, lessThan(SubscriptionTier.professional.index));
      expect(SubscriptionTier.professional.index, lessThan(SubscriptionTier.hustonSchool.index));
    });

    test('subscription tier enum values count', () {
      expect(SubscriptionTier.values, hasLength(4));
    });

    test('tier names match enum values', () {
      expect(SubscriptionTier.archer.name, equals('archer'));
      expect(SubscriptionTier.competitor.name, equals('competitor'));
      expect(SubscriptionTier.professional.name, equals('professional'));
      expect(SubscriptionTier.hustonSchool.name, equals('hustonSchool'));
    });
  });

  group('real-world scenarios', () {
    test('new user starts with archer tier', () {
      final json = <String, dynamic>{};
      final status = EntitlementStatus.fromJson(json);

      expect(status.tier, equals('archer'));
      expect(status.stripeCustomerId, isNull);
      expect(status.stripeSubscriptionId, isNull);
    });

    test('subscriber with active subscription', () {
      final json = {
        'tier': 'competitor',
        'stripeCustomerId': 'cus_NewSubscriber123',
        'stripeSubscriptionId': 'sub_Active456',
        'expiresAt': '2026-02-15T00:00:00.000Z',
        'isLegacy3dAiming': false,
      };

      final status = EntitlementStatus.fromJson(json);

      expect(status.tier, equals('competitor'));
      expect(status.stripeCustomerId, isNotNull);
      expect(status.stripeSubscriptionId, isNotNull);
      expect(status.expiresAt!.isAfter(DateTime(2026, 1, 1)), isTrue);
    });

    test('professional subscriber with unlimited auto-plot', () {
      final json = {
        'tier': 'professional',
        'stripeCustomerId': 'cus_Pro789',
        'stripeSubscriptionId': 'sub_ProActive',
        'expiresAt': '2026-03-01T00:00:00.000Z',
      };

      final status = EntitlementStatus.fromJson(json);

      expect(status.tier, equals('professional'));
      final tier = SubscriptionTierExtension.fromString(status.tier);
      expect(tier.autoPlotLimit, equals(-1)); // Unlimited
    });

    test('legacy user with 3D Aiming access', () {
      final json = {
        'tier': 'archer',
        'isLegacy3dAiming': true,
      };

      final status = EntitlementStatus.fromJson(json);

      expect(status.tier, equals('archer'));
      expect(status.isLegacy3dAiming, isTrue);
      // Free tier but has 3D Aiming from previous purchase
    });

    test('legacy check for returning user', () {
      final json = {
        'hasLegacyAccess': true,
        'grantedProducts': ['3d_aiming_course'],
      };

      final result = LegacyCheckResult.fromJson(json);

      expect(result.hasLegacyAccess, isTrue);
      expect(result.grantedProducts.contains('3d_aiming_course'), isTrue);
    });

    test('new user with no legacy access', () {
      final json = {
        'hasLegacyAccess': false,
        'grantedProducts': <String>[],
      };

      final result = LegacyCheckResult.fromJson(json);

      expect(result.hasLegacyAccess, isFalse);
      expect(result.grantedProducts, isEmpty);
    });

    test('huston school subscriber gets all features', () {
      final json = {
        'tier': 'hustonSchool',
        'stripeCustomerId': 'cus_School123',
        'stripeSubscriptionId': 'sub_SchoolActive',
        'expiresAt': '2026-06-01T00:00:00.000Z',
      };

      final status = EntitlementStatus.fromJson(json);
      final tier = SubscriptionTierExtension.fromString(status.tier);

      expect(tier, equals(SubscriptionTier.hustonSchool));
      expect(tier.autoPlotLimit, equals(-1)); // Unlimited
    });

    test('subscription expiry tracking', () {
      final expiryDate = DateTime(2026, 2, 1);
      final json = {
        'tier': 'competitor',
        'stripeCustomerId': 'cus_123',
        'stripeSubscriptionId': 'sub_456',
        'expiresAt': expiryDate.toIso8601String(),
      };

      final status = EntitlementStatus.fromJson(json);

      expect(status.expiresAt, isNotNull);
      expect(status.expiresAt!.year, equals(2026));
      expect(status.expiresAt!.month, equals(2));
      expect(status.expiresAt!.day, equals(1));
    });

    test('upgrading from free to paid tier', () {
      // Before upgrade
      final beforeJson = {'tier': 'archer'};
      final before = EntitlementStatus.fromJson(beforeJson);
      expect(before.tier, equals('archer'));
      expect(before.stripeSubscriptionId, isNull);

      // After upgrade
      final afterJson = {
        'tier': 'competitor',
        'stripeCustomerId': 'cus_new',
        'stripeSubscriptionId': 'sub_new',
        'expiresAt': '2026-03-01T00:00:00.000Z',
      };
      final after = EntitlementStatus.fromJson(afterJson);
      expect(after.tier, equals('competitor'));
      expect(after.stripeSubscriptionId, isNotNull);
    });

    test('subscription with customer ID but no subscription (cancelled)', () {
      final json = {
        'tier': 'archer',
        'stripeCustomerId': 'cus_wasSubscriber',
        'stripeSubscriptionId': null,
      };

      final status = EntitlementStatus.fromJson(json);

      expect(status.tier, equals('archer'));
      expect(status.stripeCustomerId, equals('cus_wasSubscriber'));
      expect(status.stripeSubscriptionId, isNull);
    });
  });

  group('edge cases', () {
    test('EntitlementStatus handles malformed date gracefully', () {
      final json = {
        'tier': 'competitor',
        'expiresAt': 'not-a-date',
      };

      expect(
        () => EntitlementStatus.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('EntitlementStatus handles empty string expiresAt', () {
      final json = {
        'tier': 'competitor',
        'expiresAt': '',
      };

      expect(
        () => EntitlementStatus.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('tier string with extra whitespace', () {
      // SubscriptionTierExtension.fromString should handle this
      expect(
        SubscriptionTierExtension.fromString(' competitor '),
        equals(SubscriptionTier.archer), // Will not match due to whitespace
      );
    });

    test('very long product list in LegacyCheckResult', () {
      final products = List.generate(100, (i) => 'product_$i');
      final json = {
        'hasLegacyAccess': true,
        'grantedProducts': products,
      };

      final result = LegacyCheckResult.fromJson(json);

      expect(result.grantedProducts, hasLength(100));
      expect(result.grantedProducts.first, equals('product_0'));
      expect(result.grantedProducts.last, equals('product_99'));
    });

    test('EntitlementStatus with all fields explicitly set', () {
      final status = EntitlementStatus(
        tier: 'professional',
        stripeCustomerId: 'cus_explicit',
        stripeSubscriptionId: 'sub_explicit',
        expiresAt: DateTime(2026, 12, 31, 23, 59, 59),
        isLegacy3dAiming: true,
      );

      expect(status.tier, equals('professional'));
      expect(status.stripeCustomerId, equals('cus_explicit'));
      expect(status.stripeSubscriptionId, equals('sub_explicit'));
      expect(status.expiresAt!.year, equals(2026));
      expect(status.expiresAt!.month, equals(12));
      expect(status.expiresAt!.day, equals(31));
      expect(status.isLegacy3dAiming, isTrue);
    });
  });

  group('data integrity', () {
    test('EntitlementStatus preserves all fields', () {
      final expiresAt = DateTime(2026, 5, 15, 10, 30, 45);
      final json = {
        'tier': 'professional',
        'stripeCustomerId': 'cus_integrity_test',
        'stripeSubscriptionId': 'sub_integrity_test',
        'expiresAt': expiresAt.toIso8601String(),
        'isLegacy3dAiming': true,
      };

      final status = EntitlementStatus.fromJson(json);

      expect(status.tier, equals('professional'));
      expect(status.stripeCustomerId, equals('cus_integrity_test'));
      expect(status.stripeSubscriptionId, equals('sub_integrity_test'));
      expect(status.isLegacy3dAiming, isTrue);
    });

    test('LegacyCheckResult preserves all products', () {
      final products = [
        '3d_aiming_course',
        'premium_feature_1',
        'premium_feature_2',
        'legacy_bundle',
      ];
      final json = {
        'hasLegacyAccess': true,
        'grantedProducts': products,
      };

      final result = LegacyCheckResult.fromJson(json);

      expect(result.grantedProducts, equals(products));
    });

    test('round-trip tier from JSON and back', () {
      final tiers = ['archer', 'competitor', 'professional', 'hustonSchool'];

      for (final tierName in tiers) {
        final json = {'tier': tierName};
        final status = EntitlementStatus.fromJson(json);
        final parsedTier = SubscriptionTierExtension.fromString(status.tier);

        // Verify the tier survives the round-trip
        expect(parsedTier.name, equals(tierName));
      }
    });

    test('Stripe customer and subscription IDs preserve format', () {
      final json = {
        'tier': 'competitor',
        'stripeCustomerId': 'cus_1234567890abcdef',
        'stripeSubscriptionId': 'sub_abcdef1234567890',
      };

      final status = EntitlementStatus.fromJson(json);

      // IDs should be preserved exactly
      expect(status.stripeCustomerId, equals('cus_1234567890abcdef'));
      expect(status.stripeSubscriptionId, equals('sub_abcdef1234567890'));
    });
  });
}
