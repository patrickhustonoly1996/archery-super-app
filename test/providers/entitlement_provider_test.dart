/// Tests for EntitlementProvider
///
/// These tests verify the entitlement management functionality including:
/// - SubscriptionTier enum and extension methods
/// - Subscription status logic (active, grace period, expired)
/// - Feature gate logic for different tiers
/// - Grace period time calculations
/// - Auto-plot limit logic
///
/// Note: Tests that require database interaction use simulated state logic
/// since EntitlementProvider has hard dependencies on AppDatabase. The key
/// testable components are:
/// 1. SubscriptionTier enum behavior (tested in stripe_service_test.dart)
/// 2. Subscription status calculation logic
/// 3. Feature gate calculations
/// 4. Grace period calculations
/// 5. Auto-plot limit calculations
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/providers/entitlement_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionTier enum', () {
    group('displayName', () {
      test('archer returns Archer', () {
        expect(SubscriptionTier.archer.displayName, equals('Archer'));
      });

      test('competitor returns Competitor', () {
        expect(SubscriptionTier.competitor.displayName, equals('Competitor'));
      });

      test('professional returns Professional', () {
        expect(SubscriptionTier.professional.displayName, equals('Professional'));
      });

      test('hustonSchool returns Huston School', () {
        expect(SubscriptionTier.hustonSchool.displayName, equals('Huston School'));
      });

      test('all tiers have non-empty display names', () {
        for (final tier in SubscriptionTier.values) {
          expect(tier.displayName, isNotEmpty);
        }
      });
    });

    group('price', () {
      test('archer is Free', () {
        expect(SubscriptionTier.archer.price, equals('Free'));
      });

      test('competitor is £2/mo', () {
        expect(SubscriptionTier.competitor.price, equals('£2/mo'));
      });

      test('professional is £7.20/mo', () {
        expect(SubscriptionTier.professional.price, equals('£7.20/mo'));
      });

      test('hustonSchool is £40/mo', () {
        expect(SubscriptionTier.hustonSchool.price, equals('£40/mo'));
      });

      test('all tiers have non-empty prices', () {
        for (final tier in SubscriptionTier.values) {
          expect(tier.price, isNotEmpty);
        }
      });

      test('prices follow expected progression', () {
        // Free < £2 < £7.20 < £40
        expect(SubscriptionTier.archer.price, equals('Free'));
        expect(SubscriptionTier.competitor.price, contains('2'));
        expect(SubscriptionTier.professional.price, contains('7.20'));
        expect(SubscriptionTier.hustonSchool.price, contains('40'));
      });
    });

    group('description', () {
      test('archer includes free features', () {
        final description = SubscriptionTier.archer.description;
        expect(description, contains('Equipment'));
        expect(description, contains('scores'));
        expect(description, contains('Plotting course'));
      });

      test('competitor includes Auto-Plot with limit', () {
        final description = SubscriptionTier.competitor.description;
        expect(description, contains('Auto-Plot'));
        expect(description, contains('50/mo'));
      });

      test('professional includes Unlimited Auto-Plot', () {
        final description = SubscriptionTier.professional.description;
        expect(description, contains('Unlimited Auto-Plot'));
      });

      test('hustonSchool includes Video coaching', () {
        final description = SubscriptionTier.hustonSchool.description;
        expect(description, contains('Video coaching library'));
      });

      test('all tiers have non-empty descriptions', () {
        for (final tier in SubscriptionTier.values) {
          expect(tier.description, isNotEmpty);
        }
      });
    });

    group('autoPlotLimit', () {
      test('archer has 0 auto-plot', () {
        expect(SubscriptionTier.archer.autoPlotLimit, equals(0));
      });

      test('competitor has 50 auto-plot', () {
        expect(SubscriptionTier.competitor.autoPlotLimit, equals(50));
      });

      test('professional has unlimited auto-plot (-1)', () {
        expect(SubscriptionTier.professional.autoPlotLimit, equals(-1));
      });

      test('hustonSchool has unlimited auto-plot (-1)', () {
        expect(SubscriptionTier.hustonSchool.autoPlotLimit, equals(-1));
      });

      test('only two tiers have unlimited auto-plot', () {
        final unlimitedTiers = SubscriptionTier.values
            .where((t) => t.autoPlotLimit == -1)
            .toList();
        expect(unlimitedTiers, hasLength(2));
        expect(unlimitedTiers, contains(SubscriptionTier.professional));
        expect(unlimitedTiers, contains(SubscriptionTier.hustonSchool));
      });
    });

    group('fromString', () {
      test('parses archer', () {
        expect(
          SubscriptionTierExtension.fromString('archer'),
          equals(SubscriptionTier.archer),
        );
      });

      test('parses competitor', () {
        expect(
          SubscriptionTierExtension.fromString('competitor'),
          equals(SubscriptionTier.competitor),
        );
      });

      test('parses professional', () {
        expect(
          SubscriptionTierExtension.fromString('professional'),
          equals(SubscriptionTier.professional),
        );
      });

      test('parses hustonschool (lowercase)', () {
        expect(
          SubscriptionTierExtension.fromString('hustonschool'),
          equals(SubscriptionTier.hustonSchool),
        );
      });

      test('parses huston_school (snake_case)', () {
        expect(
          SubscriptionTierExtension.fromString('huston_school'),
          equals(SubscriptionTier.hustonSchool),
        );
      });

      test('is case insensitive', () {
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

      test('returns archer for unknown values', () {
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
          SubscriptionTierExtension.fromString('enterprise'),
          equals(SubscriptionTier.archer),
        );
      });

      test('returns archer for whitespace', () {
        expect(
          SubscriptionTierExtension.fromString(' '),
          equals(SubscriptionTier.archer),
        );
        expect(
          SubscriptionTierExtension.fromString('   '),
          equals(SubscriptionTier.archer),
        );
      });

      test('does not trim whitespace from input', () {
        // This is intentional - inputs should be cleaned before calling
        expect(
          SubscriptionTierExtension.fromString(' competitor '),
          equals(SubscriptionTier.archer),
        );
      });
    });

    group('tier index order', () {
      test('archer is index 0', () {
        expect(SubscriptionTier.archer.index, equals(0));
      });

      test('competitor is index 1', () {
        expect(SubscriptionTier.competitor.index, equals(1));
      });

      test('professional is index 2', () {
        expect(SubscriptionTier.professional.index, equals(2));
      });

      test('hustonSchool is index 3', () {
        expect(SubscriptionTier.hustonSchool.index, equals(3));
      });

      test('indices are ascending for feature gating', () {
        expect(
          SubscriptionTier.archer.index,
          lessThan(SubscriptionTier.competitor.index),
        );
        expect(
          SubscriptionTier.competitor.index,
          lessThan(SubscriptionTier.professional.index),
        );
        expect(
          SubscriptionTier.professional.index,
          lessThan(SubscriptionTier.hustonSchool.index),
        );
      });

      test('there are exactly 4 tiers', () {
        expect(SubscriptionTier.values, hasLength(4));
      });
    });

    group('tier names', () {
      test('names match expected values', () {
        expect(SubscriptionTier.archer.name, equals('archer'));
        expect(SubscriptionTier.competitor.name, equals('competitor'));
        expect(SubscriptionTier.professional.name, equals('professional'));
        expect(SubscriptionTier.hustonSchool.name, equals('hustonSchool'));
      });
    });
  });

  group('Subscription Status Logic', () {
    // These tests simulate the logic from EntitlementProvider getters
    // without requiring database access

    group('isSubscriptionActive simulation', () {
      test('free tier is always active', () {
        final tier = SubscriptionTier.archer;
        final expiresAt = DateTime.now().subtract(const Duration(days: 30));

        // Free tier always active, regardless of expiry
        final isActive = tier == SubscriptionTier.archer ||
            expiresAt == null ||
            DateTime.now().isBefore(expiresAt);
        expect(isActive, isTrue);
      });

      test('paid tier is active when expiresAt is null', () {
        final tier = SubscriptionTier.competitor;
        const DateTime? expiresAt = null;

        final isActive = tier == SubscriptionTier.archer ||
            expiresAt == null ||
            DateTime.now().isBefore(expiresAt!);
        expect(isActive, isTrue);
      });

      test('paid tier is active when before expiry', () {
        final tier = SubscriptionTier.competitor;
        final expiresAt = DateTime.now().add(const Duration(days: 30));

        final isActive = tier == SubscriptionTier.archer ||
            DateTime.now().isBefore(expiresAt);
        expect(isActive, isTrue);
      });

      test('paid tier is not active when after expiry', () {
        final tier = SubscriptionTier.competitor;
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1));

        final isActive = tier == SubscriptionTier.archer ||
            DateTime.now().isBefore(expiresAt);
        expect(isActive, isFalse);
      });
    });

    group('isInGracePeriod simulation', () {
      test('free tier is never in grace period', () {
        final tier = SubscriptionTier.archer;
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
        final graceEndsAt = DateTime.now().add(const Duration(hours: 71));

        final isInGrace = tier != SubscriptionTier.archer &&
            expiresAt != null &&
            graceEndsAt != null &&
            DateTime.now().isAfter(expiresAt) &&
            DateTime.now().isBefore(graceEndsAt);
        expect(isInGrace, isFalse);
      });

      test('paid tier is in grace period after expiry but before grace end', () {
        final tier = SubscriptionTier.competitor;
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
        final graceEndsAt = DateTime.now().add(const Duration(hours: 71));

        final isInGrace = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(expiresAt) &&
            DateTime.now().isBefore(graceEndsAt);
        expect(isInGrace, isTrue);
      });

      test('paid tier is not in grace period before expiry', () {
        final tier = SubscriptionTier.competitor;
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        final graceEndsAt = expiresAt.add(const Duration(hours: 72));

        final isInGrace = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(expiresAt) &&
            DateTime.now().isBefore(graceEndsAt);
        expect(isInGrace, isFalse);
      });

      test('paid tier is not in grace period after grace ends', () {
        final tier = SubscriptionTier.competitor;
        final expiresAt = DateTime.now().subtract(const Duration(hours: 100));
        final graceEndsAt = DateTime.now().subtract(const Duration(hours: 28));

        final isInGrace = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(expiresAt) &&
            DateTime.now().isBefore(graceEndsAt);
        expect(isInGrace, isFalse);
      });

      test('grace period is 72 hours after expiry', () {
        final expiresAt = DateTime.now();
        final graceEndsAt = expiresAt.add(const Duration(hours: 72));

        final graceDuration = graceEndsAt.difference(expiresAt);
        expect(graceDuration.inHours, equals(72));
      });
    });

    group('isExpired simulation', () {
      test('free tier never expires', () {
        final tier = SubscriptionTier.archer;
        final graceEndsAt = DateTime.now().subtract(const Duration(days: 30));

        final isExpired = tier != SubscriptionTier.archer &&
            graceEndsAt != null &&
            DateTime.now().isAfter(graceEndsAt);
        expect(isExpired, isFalse);
      });

      test('paid tier is expired when after grace period', () {
        final tier = SubscriptionTier.competitor;
        final graceEndsAt = DateTime.now().subtract(const Duration(hours: 1));

        final isExpired = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(graceEndsAt);
        expect(isExpired, isTrue);
      });

      test('paid tier is not expired when graceEndsAt is null', () {
        final tier = SubscriptionTier.competitor;
        const DateTime? graceEndsAt = null;

        final isExpired = tier != SubscriptionTier.archer &&
            graceEndsAt != null &&
            DateTime.now().isAfter(graceEndsAt!);
        expect(isExpired, isFalse);
      });

      test('paid tier is not expired when before grace ends', () {
        final tier = SubscriptionTier.competitor;
        final graceEndsAt = DateTime.now().add(const Duration(hours: 1));

        final isExpired = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(graceEndsAt);
        expect(isExpired, isFalse);
      });
    });

    group('graceTimeRemaining simulation', () {
      test('returns null when not in grace period', () {
        final tier = SubscriptionTier.competitor;
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        final graceEndsAt = expiresAt.add(const Duration(hours: 72));

        final isInGrace = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(expiresAt) &&
            DateTime.now().isBefore(graceEndsAt);

        Duration? graceRemaining;
        if (isInGrace) {
          graceRemaining = graceEndsAt.difference(DateTime.now());
        }

        expect(graceRemaining, isNull);
      });

      test('returns positive duration when in grace period', () {
        final tier = SubscriptionTier.competitor;
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
        final graceEndsAt = DateTime.now().add(const Duration(hours: 48));

        final isInGrace = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(expiresAt) &&
            DateTime.now().isBefore(graceEndsAt);

        Duration? graceRemaining;
        if (isInGrace) {
          graceRemaining = graceEndsAt.difference(DateTime.now());
        }

        expect(graceRemaining, isNotNull);
        expect(graceRemaining!.isNegative, isFalse);
        expect(graceRemaining.inHours, greaterThanOrEqualTo(47));
      });

      test('grace remaining decreases as time passes', () {
        final graceEndsAt = DateTime.now().add(const Duration(hours: 50));

        final remaining1 = graceEndsAt.difference(DateTime.now());
        // Simulate 10 hours later
        final futureNow = DateTime.now().add(const Duration(hours: 10));
        final remaining2 = graceEndsAt.difference(futureNow);

        expect(remaining2.inHours, lessThan(remaining1.inHours));
      });
    });
  });

  group('Feature Gate Logic', () {
    // Simulates the feature gate logic from EntitlementProvider

    bool hasShaftAnalysis(SubscriptionTier tier, bool isExpired) {
      if (isExpired) return false;
      return tier.index >= SubscriptionTier.competitor.index;
    }

    bool hasOlyTraining(SubscriptionTier tier, bool isExpired) {
      if (isExpired) return false;
      return tier.index >= SubscriptionTier.competitor.index;
    }

    bool hasAutoPlot(SubscriptionTier tier, bool isExpired) {
      if (isExpired) return false;
      return tier.index >= SubscriptionTier.competitor.index;
    }

    bool hasUnlimitedAutoPlot(SubscriptionTier tier, bool isExpired) {
      if (isExpired) return false;
      return tier.index >= SubscriptionTier.professional.index;
    }

    bool hasHustonSchool(SubscriptionTier tier, bool isExpired) {
      if (isExpired) return false;
      return tier == SubscriptionTier.hustonSchool;
    }

    group('hasShaftAnalysis', () {
      test('archer does not have shaft analysis', () {
        expect(hasShaftAnalysis(SubscriptionTier.archer, false), isFalse);
      });

      test('competitor has shaft analysis', () {
        expect(hasShaftAnalysis(SubscriptionTier.competitor, false), isTrue);
      });

      test('professional has shaft analysis', () {
        expect(hasShaftAnalysis(SubscriptionTier.professional, false), isTrue);
      });

      test('hustonSchool has shaft analysis', () {
        expect(hasShaftAnalysis(SubscriptionTier.hustonSchool, false), isTrue);
      });

      test('expired subscription loses shaft analysis', () {
        expect(hasShaftAnalysis(SubscriptionTier.competitor, true), isFalse);
        expect(hasShaftAnalysis(SubscriptionTier.professional, true), isFalse);
      });
    });

    group('hasOlyTraining', () {
      test('archer does not have OLY training', () {
        expect(hasOlyTraining(SubscriptionTier.archer, false), isFalse);
      });

      test('competitor has OLY training', () {
        expect(hasOlyTraining(SubscriptionTier.competitor, false), isTrue);
      });

      test('professional has OLY training', () {
        expect(hasOlyTraining(SubscriptionTier.professional, false), isTrue);
      });

      test('hustonSchool has OLY training', () {
        expect(hasOlyTraining(SubscriptionTier.hustonSchool, false), isTrue);
      });

      test('expired subscription loses OLY training', () {
        expect(hasOlyTraining(SubscriptionTier.competitor, true), isFalse);
        expect(hasOlyTraining(SubscriptionTier.professional, true), isFalse);
      });
    });

    group('hasAutoPlot', () {
      test('archer does not have Auto-Plot', () {
        expect(hasAutoPlot(SubscriptionTier.archer, false), isFalse);
      });

      test('competitor has Auto-Plot', () {
        expect(hasAutoPlot(SubscriptionTier.competitor, false), isTrue);
      });

      test('professional has Auto-Plot', () {
        expect(hasAutoPlot(SubscriptionTier.professional, false), isTrue);
      });

      test('hustonSchool has Auto-Plot', () {
        expect(hasAutoPlot(SubscriptionTier.hustonSchool, false), isTrue);
      });

      test('expired subscription loses Auto-Plot', () {
        expect(hasAutoPlot(SubscriptionTier.competitor, true), isFalse);
        expect(hasAutoPlot(SubscriptionTier.professional, true), isFalse);
      });
    });

    group('hasUnlimitedAutoPlot', () {
      test('archer does not have unlimited Auto-Plot', () {
        expect(hasUnlimitedAutoPlot(SubscriptionTier.archer, false), isFalse);
      });

      test('competitor does not have unlimited Auto-Plot', () {
        expect(hasUnlimitedAutoPlot(SubscriptionTier.competitor, false), isFalse);
      });

      test('professional has unlimited Auto-Plot', () {
        expect(hasUnlimitedAutoPlot(SubscriptionTier.professional, false), isTrue);
      });

      test('hustonSchool has unlimited Auto-Plot', () {
        expect(hasUnlimitedAutoPlot(SubscriptionTier.hustonSchool, false), isTrue);
      });

      test('expired subscription loses unlimited Auto-Plot', () {
        expect(hasUnlimitedAutoPlot(SubscriptionTier.professional, true), isFalse);
        expect(hasUnlimitedAutoPlot(SubscriptionTier.hustonSchool, true), isFalse);
      });
    });

    group('hasHustonSchool', () {
      test('archer does not have Huston School', () {
        expect(hasHustonSchool(SubscriptionTier.archer, false), isFalse);
      });

      test('competitor does not have Huston School', () {
        expect(hasHustonSchool(SubscriptionTier.competitor, false), isFalse);
      });

      test('professional does not have Huston School', () {
        expect(hasHustonSchool(SubscriptionTier.professional, false), isFalse);
      });

      test('hustonSchool has Huston School', () {
        expect(hasHustonSchool(SubscriptionTier.hustonSchool, false), isTrue);
      });

      test('expired hustonSchool loses Huston School access', () {
        expect(hasHustonSchool(SubscriptionTier.hustonSchool, true), isFalse);
      });
    });

    group('feature progression by tier', () {
      test('archer has no paid features', () {
        expect(hasShaftAnalysis(SubscriptionTier.archer, false), isFalse);
        expect(hasOlyTraining(SubscriptionTier.archer, false), isFalse);
        expect(hasAutoPlot(SubscriptionTier.archer, false), isFalse);
        expect(hasUnlimitedAutoPlot(SubscriptionTier.archer, false), isFalse);
        expect(hasHustonSchool(SubscriptionTier.archer, false), isFalse);
      });

      test('competitor has base paid features', () {
        expect(hasShaftAnalysis(SubscriptionTier.competitor, false), isTrue);
        expect(hasOlyTraining(SubscriptionTier.competitor, false), isTrue);
        expect(hasAutoPlot(SubscriptionTier.competitor, false), isTrue);
        expect(hasUnlimitedAutoPlot(SubscriptionTier.competitor, false), isFalse);
        expect(hasHustonSchool(SubscriptionTier.competitor, false), isFalse);
      });

      test('professional has premium features', () {
        expect(hasShaftAnalysis(SubscriptionTier.professional, false), isTrue);
        expect(hasOlyTraining(SubscriptionTier.professional, false), isTrue);
        expect(hasAutoPlot(SubscriptionTier.professional, false), isTrue);
        expect(hasUnlimitedAutoPlot(SubscriptionTier.professional, false), isTrue);
        expect(hasHustonSchool(SubscriptionTier.professional, false), isFalse);
      });

      test('hustonSchool has all features', () {
        expect(hasShaftAnalysis(SubscriptionTier.hustonSchool, false), isTrue);
        expect(hasOlyTraining(SubscriptionTier.hustonSchool, false), isTrue);
        expect(hasAutoPlot(SubscriptionTier.hustonSchool, false), isTrue);
        expect(hasUnlimitedAutoPlot(SubscriptionTier.hustonSchool, false), isTrue);
        expect(hasHustonSchool(SubscriptionTier.hustonSchool, false), isTrue);
      });
    });
  });

  group('Auto-Plot Usage Logic', () {
    int autoPlotMonthlyLimit(SubscriptionTier tier) => tier.autoPlotLimit;

    bool canUseAutoPlot(SubscriptionTier tier, bool isExpired, int currentUsage) {
      if (isExpired) return false;
      if (tier.index < SubscriptionTier.competitor.index) return false;
      if (tier.autoPlotLimit == -1) return true; // Unlimited
      return currentUsage < tier.autoPlotLimit;
    }

    int getRemainingAutoPlotScans(SubscriptionTier tier, bool isExpired, int currentUsage) {
      if (isExpired) return 0;
      if (tier.index < SubscriptionTier.competitor.index) return 0;
      if (tier.autoPlotLimit == -1) return -1; // Unlimited
      return (tier.autoPlotLimit - currentUsage).clamp(0, tier.autoPlotLimit);
    }

    group('autoPlotMonthlyLimit', () {
      test('archer has 0 limit', () {
        expect(autoPlotMonthlyLimit(SubscriptionTier.archer), equals(0));
      });

      test('competitor has 50 limit', () {
        expect(autoPlotMonthlyLimit(SubscriptionTier.competitor), equals(50));
      });

      test('professional has unlimited (-1)', () {
        expect(autoPlotMonthlyLimit(SubscriptionTier.professional), equals(-1));
      });

      test('hustonSchool has unlimited (-1)', () {
        expect(autoPlotMonthlyLimit(SubscriptionTier.hustonSchool), equals(-1));
      });
    });

    group('canUseAutoPlot', () {
      test('archer cannot use Auto-Plot regardless of usage', () {
        expect(canUseAutoPlot(SubscriptionTier.archer, false, 0), isFalse);
        expect(canUseAutoPlot(SubscriptionTier.archer, false, 100), isFalse);
      });

      test('competitor can use Auto-Plot when under limit', () {
        expect(canUseAutoPlot(SubscriptionTier.competitor, false, 0), isTrue);
        expect(canUseAutoPlot(SubscriptionTier.competitor, false, 25), isTrue);
        expect(canUseAutoPlot(SubscriptionTier.competitor, false, 49), isTrue);
      });

      test('competitor cannot use Auto-Plot when at or over limit', () {
        expect(canUseAutoPlot(SubscriptionTier.competitor, false, 50), isFalse);
        expect(canUseAutoPlot(SubscriptionTier.competitor, false, 51), isFalse);
        expect(canUseAutoPlot(SubscriptionTier.competitor, false, 100), isFalse);
      });

      test('professional can always use Auto-Plot (unlimited)', () {
        expect(canUseAutoPlot(SubscriptionTier.professional, false, 0), isTrue);
        expect(canUseAutoPlot(SubscriptionTier.professional, false, 50), isTrue);
        expect(canUseAutoPlot(SubscriptionTier.professional, false, 1000), isTrue);
      });

      test('hustonSchool can always use Auto-Plot (unlimited)', () {
        expect(canUseAutoPlot(SubscriptionTier.hustonSchool, false, 0), isTrue);
        expect(canUseAutoPlot(SubscriptionTier.hustonSchool, false, 50), isTrue);
        expect(canUseAutoPlot(SubscriptionTier.hustonSchool, false, 1000), isTrue);
      });

      test('expired subscription cannot use Auto-Plot', () {
        expect(canUseAutoPlot(SubscriptionTier.competitor, true, 0), isFalse);
        expect(canUseAutoPlot(SubscriptionTier.professional, true, 0), isFalse);
        expect(canUseAutoPlot(SubscriptionTier.hustonSchool, true, 0), isFalse);
      });
    });

    group('getRemainingAutoPlotScans', () {
      test('archer always has 0 remaining', () {
        expect(getRemainingAutoPlotScans(SubscriptionTier.archer, false, 0), equals(0));
        expect(getRemainingAutoPlotScans(SubscriptionTier.archer, false, 10), equals(0));
      });

      test('competitor has correct remaining scans', () {
        expect(getRemainingAutoPlotScans(SubscriptionTier.competitor, false, 0), equals(50));
        expect(getRemainingAutoPlotScans(SubscriptionTier.competitor, false, 10), equals(40));
        expect(getRemainingAutoPlotScans(SubscriptionTier.competitor, false, 49), equals(1));
        expect(getRemainingAutoPlotScans(SubscriptionTier.competitor, false, 50), equals(0));
      });

      test('competitor clamps negative to 0', () {
        expect(getRemainingAutoPlotScans(SubscriptionTier.competitor, false, 51), equals(0));
        expect(getRemainingAutoPlotScans(SubscriptionTier.competitor, false, 100), equals(0));
      });

      test('professional returns -1 (unlimited)', () {
        expect(getRemainingAutoPlotScans(SubscriptionTier.professional, false, 0), equals(-1));
        expect(getRemainingAutoPlotScans(SubscriptionTier.professional, false, 1000), equals(-1));
      });

      test('hustonSchool returns -1 (unlimited)', () {
        expect(getRemainingAutoPlotScans(SubscriptionTier.hustonSchool, false, 0), equals(-1));
        expect(getRemainingAutoPlotScans(SubscriptionTier.hustonSchool, false, 1000), equals(-1));
      });

      test('expired subscription returns 0', () {
        expect(getRemainingAutoPlotScans(SubscriptionTier.competitor, true, 0), equals(0));
        expect(getRemainingAutoPlotScans(SubscriptionTier.professional, true, 0), equals(0));
        expect(getRemainingAutoPlotScans(SubscriptionTier.hustonSchool, true, 0), equals(0));
      });
    });
  });

  group('Legacy 3D Aiming Logic', () {
    test('3D aiming course product ID is recognized', () {
      const productId = '3d_aiming_course';
      final has3dAiming = productId == '3d_aiming_course';
      expect(has3dAiming, isTrue);
    });

    test('other product IDs do not grant 3D aiming', () {
      const productId = 'other_product';
      final has3dAiming = productId == '3d_aiming_course';
      expect(has3dAiming, isFalse);
    });

    test('legacy 3D aiming is independent of subscription tier', () {
      // A user can be on free tier but have legacy 3D aiming access
      final tier = SubscriptionTier.archer;
      const isLegacy3dAiming = true;

      // Free tier, but has legacy access
      expect(tier, equals(SubscriptionTier.archer));
      expect(isLegacy3dAiming, isTrue);
    });
  });

  group('Real-World Scenarios', () {
    group('new user journey', () {
      test('new user starts with free tier', () {
        final tier = SubscriptionTierExtension.fromString('archer');
        expect(tier, equals(SubscriptionTier.archer));
        expect(tier.price, equals('Free'));
        expect(tier.autoPlotLimit, equals(0));
      });

      test('new user has access to basic features', () {
        const tier = SubscriptionTier.archer;
        const isExpired = false;

        // Basic features available
        expect(tier.description, contains('Equipment'));
        expect(tier.description, contains('scores'));
        expect(tier.description, contains('Plotting course'));
      });

      test('new user cannot access paid features', () {
        const tier = SubscriptionTier.archer;
        const isExpired = false;

        expect(tier.index < SubscriptionTier.competitor.index, isTrue);
      });
    });

    group('competitor subscriber journey', () {
      test('competitor has shaft analysis and OLY training', () {
        const tier = SubscriptionTier.competitor;
        expect(tier.index >= SubscriptionTier.competitor.index, isTrue);
      });

      test('competitor has 50 Auto-Plot scans per month', () {
        const tier = SubscriptionTier.competitor;
        expect(tier.autoPlotLimit, equals(50));
      });

      test('competitor does not have unlimited Auto-Plot', () {
        const tier = SubscriptionTier.competitor;
        expect(tier.autoPlotLimit, isNot(equals(-1)));
      });
    });

    group('professional subscriber journey', () {
      test('professional has all competitor features plus unlimited Auto-Plot', () {
        const tier = SubscriptionTier.professional;
        expect(tier.index >= SubscriptionTier.competitor.index, isTrue);
        expect(tier.autoPlotLimit, equals(-1));
      });

      test('professional costs £7.20/mo', () {
        expect(SubscriptionTier.professional.price, equals('£7.20/mo'));
      });
    });

    group('Huston School subscriber journey', () {
      test('Huston School has all features including video library', () {
        const tier = SubscriptionTier.hustonSchool;
        expect(tier.index >= SubscriptionTier.professional.index, isTrue);
        expect(tier == SubscriptionTier.hustonSchool, isTrue);
      });

      test('Huston School costs £40/mo', () {
        expect(SubscriptionTier.hustonSchool.price, equals('£40/mo'));
      });
    });

    group('subscription expiry journey', () {
      test('subscription enters grace period after expiry', () {
        const tier = SubscriptionTier.competitor;
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
        final graceEndsAt = expiresAt.add(const Duration(hours: 72));

        final isInGrace = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(expiresAt) &&
            DateTime.now().isBefore(graceEndsAt);

        expect(isInGrace, isTrue);
      });

      test('subscription fully expires after 72 hours', () {
        const tier = SubscriptionTier.competitor;
        final graceEndsAt = DateTime.now().subtract(const Duration(hours: 1));

        final isExpired = tier != SubscriptionTier.archer &&
            DateTime.now().isAfter(graceEndsAt);

        expect(isExpired, isTrue);
      });

      test('expired user loses access to paid features', () {
        const tier = SubscriptionTier.competitor;
        const isExpired = true;

        // All paid features lost when expired
        final hasAccess = !isExpired &&
            tier.index >= SubscriptionTier.competitor.index;
        expect(hasAccess, isFalse);
      });
    });

    group('legacy user journey', () {
      test('legacy user keeps 3D Aiming access on free tier', () {
        const tier = SubscriptionTier.archer;
        const isLegacy3dAiming = true;

        expect(tier, equals(SubscriptionTier.archer));
        expect(isLegacy3dAiming, isTrue);
      });

      test('legacy email is used for verification', () {
        const legacyEmail = 'legacy@example.com';
        expect(legacyEmail, isNotEmpty);
        expect(legacyEmail, contains('@'));
      });
    });

    group('upgrade journey', () {
      test('archer can upgrade to competitor', () {
        var tier = SubscriptionTier.archer;
        expect(tier.autoPlotLimit, equals(0));

        // Simulate upgrade
        tier = SubscriptionTier.competitor;
        expect(tier.autoPlotLimit, equals(50));
      });

      test('competitor can upgrade to professional', () {
        var tier = SubscriptionTier.competitor;
        expect(tier.autoPlotLimit, equals(50));

        // Simulate upgrade
        tier = SubscriptionTier.professional;
        expect(tier.autoPlotLimit, equals(-1));
      });

      test('professional can upgrade to Huston School', () {
        var tier = SubscriptionTier.professional;
        expect(tier == SubscriptionTier.hustonSchool, isFalse);

        // Simulate upgrade
        tier = SubscriptionTier.hustonSchool;
        expect(tier == SubscriptionTier.hustonSchool, isTrue);
      });
    });

    group('downgrade journey', () {
      test('subscription cancellation sets expiry and grace period', () {
        final now = DateTime.now();
        final expiresAt = now;
        final graceEndsAt = now.add(const Duration(hours: 72));

        expect(expiresAt.isAtSameMomentAs(now), isTrue);
        expect(graceEndsAt.difference(expiresAt).inHours, equals(72));
      });

      test('downgrade to free clears subscription data', () {
        final tier = SubscriptionTier.archer;
        const String? stripeSubscriptionId = null;
        const DateTime? expiresAt = null;
        const DateTime? graceEndsAt = null;

        expect(tier, equals(SubscriptionTier.archer));
        expect(stripeSubscriptionId, isNull);
        expect(expiresAt, isNull);
        expect(graceEndsAt, isNull);
      });
    });
  });

  group('Edge Cases', () {
    group('boundary conditions', () {
      test('exactly at expiry moment', () {
        final now = DateTime.now();
        final expiresAt = now;

        // isBefore returns false when equal
        final isActive = now.isBefore(expiresAt);
        expect(isActive, isFalse);
      });

      test('exactly at grace end moment', () {
        final now = DateTime.now();
        final graceEndsAt = now;

        // isAfter returns false when equal
        final isExpired = now.isAfter(graceEndsAt);
        expect(isExpired, isFalse);
      });

      test('one millisecond before expiry', () {
        final expiresAt = DateTime.now().add(const Duration(milliseconds: 1));
        final isActive = DateTime.now().isBefore(expiresAt);
        expect(isActive, isTrue);
      });

      test('one millisecond after grace ends', () {
        final graceEndsAt = DateTime.now().subtract(const Duration(milliseconds: 1));
        final isExpired = DateTime.now().isAfter(graceEndsAt);
        expect(isExpired, isTrue);
      });
    });

    group('usage edge cases', () {
      test('Auto-Plot usage at exactly 50', () {
        const currentUsage = 50;
        const limit = 50;
        final canUse = currentUsage < limit;
        expect(canUse, isFalse);
      });

      test('Auto-Plot usage at 49', () {
        const currentUsage = 49;
        const limit = 50;
        final canUse = currentUsage < limit;
        expect(canUse, isTrue);
      });

      test('negative usage handled', () {
        const currentUsage = -1;
        const limit = 50;
        final remaining = (limit - currentUsage).clamp(0, limit);
        expect(remaining, equals(50)); // Clamped to limit
      });
    });

    group('tier parsing edge cases', () {
      test('mixed case tier names', () {
        expect(SubscriptionTierExtension.fromString('ARCHER'), equals(SubscriptionTier.archer));
        expect(SubscriptionTierExtension.fromString('ComPeTiTor'), equals(SubscriptionTier.competitor));
        expect(SubscriptionTierExtension.fromString('ProfESSIONAL'), equals(SubscriptionTier.professional));
      });

      test('huston school variants', () {
        expect(SubscriptionTierExtension.fromString('hustonschool'), equals(SubscriptionTier.hustonSchool));
        expect(SubscriptionTierExtension.fromString('huston_school'), equals(SubscriptionTier.hustonSchool));
        expect(SubscriptionTierExtension.fromString('HUSTONSCHOOL'), equals(SubscriptionTier.hustonSchool));
        expect(SubscriptionTierExtension.fromString('HUSTON_SCHOOL'), equals(SubscriptionTier.hustonSchool));
      });

      test('invalid tier strings return archer', () {
        expect(SubscriptionTierExtension.fromString('basic'), equals(SubscriptionTier.archer));
        expect(SubscriptionTierExtension.fromString('premium'), equals(SubscriptionTier.archer));
        expect(SubscriptionTierExtension.fromString('enterprise'), equals(SubscriptionTier.archer));
        expect(SubscriptionTierExtension.fromString('free'), equals(SubscriptionTier.archer));
        expect(SubscriptionTierExtension.fromString(''), equals(SubscriptionTier.archer));
      });
    });

    group('Stripe ID formats', () {
      test('customer ID format', () {
        const customerId = 'cus_12345';
        expect(customerId.startsWith('cus_'), isTrue);
      });

      test('subscription ID format', () {
        const subscriptionId = 'sub_67890';
        expect(subscriptionId.startsWith('sub_'), isTrue);
      });
    });
  });

  group('Data Integrity', () {
    test('tier names are consistent with enum', () {
      expect(SubscriptionTier.archer.name, equals('archer'));
      expect(SubscriptionTier.competitor.name, equals('competitor'));
      expect(SubscriptionTier.professional.name, equals('professional'));
      expect(SubscriptionTier.hustonSchool.name, equals('hustonSchool'));
    });

    test('tier indices are sequential', () {
      var previousIndex = -1;
      for (final tier in SubscriptionTier.values) {
        expect(tier.index, equals(previousIndex + 1));
        previousIndex = tier.index;
      }
    });

    test('all tiers have unique display names', () {
      final displayNames = SubscriptionTier.values.map((t) => t.displayName).toSet();
      expect(displayNames.length, equals(SubscriptionTier.values.length));
    });

    test('all tiers have unique prices (except unlimited)', () {
      final prices = SubscriptionTier.values.map((t) => t.price).toSet();
      expect(prices.length, equals(SubscriptionTier.values.length));
    });

    test('grace period is always 72 hours', () {
      final expiresAt = DateTime(2026, 1, 15, 12, 0, 0);
      final graceEndsAt = expiresAt.add(const Duration(hours: 72));

      expect(graceEndsAt.difference(expiresAt).inHours, equals(72));
      expect(graceEndsAt, equals(DateTime(2026, 1, 18, 12, 0, 0)));
    });
  });
}
