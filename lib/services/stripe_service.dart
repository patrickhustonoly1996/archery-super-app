import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/entitlement_provider.dart';

/// Handles Stripe payment flows via Firebase Functions
class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Stripe Price IDs
  static const String competitorPriceId = 'price_1SqztNRpdm3uvDfu5wcHwFum';
  static const String professionalPriceId = 'price_1SqzuiRpdm3uvDfuzehsoDZt';
  static const String hustonSchoolPriceId = 'price_1Sr3ETRpdm3uvDfuEEfNt7P1';
  static const String aiming3dPriceId = 'price_1Sr3GJRpdm3uvDfuhGWLxEx3';

  /// Create a checkout session for subscription upgrade
  Future<String?> createSubscriptionCheckout({
    required SubscriptionTier tier,
    String? customerId,
  }) async {
    try {
      final priceId = _getPriceIdForTier(tier);
      if (priceId == null) {
        debugPrint('No price ID for tier: $tier');
        return null;
      }

      final result = await _functions
          .httpsCallable('createCheckoutSession')
          .call({
        'priceId': priceId,
        'mode': 'subscription',
        'customerId': customerId,
      });

      final data = result.data as Map<String, dynamic>;
      return data['url'] as String?;
    } catch (e) {
      debugPrint('Error creating checkout session: $e');
      return null;
    }
  }

  /// Create a checkout session for one-time purchase
  Future<String?> createPurchaseCheckout({
    required String productId,
    String? customerId,
  }) async {
    try {
      final priceId = _getPriceIdForProduct(productId);
      if (priceId == null) {
        debugPrint('No price ID for product: $productId');
        return null;
      }

      final result = await _functions
          .httpsCallable('createCheckoutSession')
          .call({
        'priceId': priceId,
        'mode': 'payment',
        'customerId': customerId,
      });

      final data = result.data as Map<String, dynamic>;
      return data['url'] as String?;
    } catch (e) {
      debugPrint('Error creating purchase checkout: $e');
      return null;
    }
  }

  /// Open checkout URL in browser
  Future<bool> openCheckout(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error opening checkout: $e');
      return false;
    }
  }

  /// Get customer portal URL for managing subscription
  Future<String?> getCustomerPortalUrl(String customerId) async {
    try {
      final result = await _functions
          .httpsCallable('createCustomerPortalSession')
          .call({'customerId': customerId});

      final data = result.data as Map<String, dynamic>;
      return data['url'] as String?;
    } catch (e) {
      debugPrint('Error getting customer portal URL: $e');
      return null;
    }
  }

  /// Fetch current entitlement status from server
  Future<EntitlementStatus?> getEntitlementStatus() async {
    try {
      final result = await _functions
          .httpsCallable('getEntitlementStatus')
          .call();

      final data = result.data as Map<String, dynamic>;
      return EntitlementStatus.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching entitlement status: $e');
      return null;
    }
  }

  /// Check legacy access by email
  Future<LegacyCheckResult?> checkLegacyAccess(String email) async {
    try {
      final result = await _functions
          .httpsCallable('checkLegacyAccess')
          .call({'email': email});

      final data = result.data as Map<String, dynamic>;
      return LegacyCheckResult.fromJson(data);
    } catch (e) {
      debugPrint('Error checking legacy access: $e');
      return null;
    }
  }

  String? _getPriceIdForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.competitor:
        return competitorPriceId;
      case SubscriptionTier.professional:
        return professionalPriceId;
      case SubscriptionTier.hustonSchool:
        return hustonSchoolPriceId;
      case SubscriptionTier.archer:
        return null; // Free tier
    }
  }

  String? _getPriceIdForProduct(String productId) {
    switch (productId) {
      case '3d_aiming_course':
        return aiming3dPriceId;
      default:
        return null;
    }
  }
}

/// Entitlement status returned from server
class EntitlementStatus {
  final String tier;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? expiresAt;
  final bool isLegacy3dAiming;

  EntitlementStatus({
    required this.tier,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.expiresAt,
    this.isLegacy3dAiming = false,
  });

  factory EntitlementStatus.fromJson(Map<String, dynamic> json) {
    return EntitlementStatus(
      tier: json['tier'] as String? ?? 'archer',
      stripeCustomerId: json['stripeCustomerId'] as String?,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isLegacy3dAiming: json['isLegacy3dAiming'] as bool? ?? false,
    );
  }
}

/// Result of legacy access check
class LegacyCheckResult {
  final bool hasLegacyAccess;
  final List<String> grantedProducts;

  LegacyCheckResult({
    required this.hasLegacyAccess,
    required this.grantedProducts,
  });

  factory LegacyCheckResult.fromJson(Map<String, dynamic> json) {
    return LegacyCheckResult(
      hasLegacyAccess: json['hasLegacyAccess'] as bool? ?? false,
      grantedProducts: (json['grantedProducts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
