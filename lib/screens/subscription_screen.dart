import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entitlement_provider.dart';
import '../services/stripe_service.dart';
import '../theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(
          'SUBSCRIPTION',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            color: AppTheme.gold,
          ),
        ),
      ),
      body: Consumer<EntitlementProvider>(
        builder: (context, entitlement, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCurrentTierBadge(entitlement),
                const SizedBox(height: 24),
                _buildTierCard(
                  context,
                  tier: SubscriptionTier.archer,
                  currentTier: entitlement.tier,
                ),
                const SizedBox(height: 12),
                _buildTierCard(
                  context,
                  tier: SubscriptionTier.ranger,
                  currentTier: entitlement.tier,
                ),
                const SizedBox(height: 12),
                _buildTierCard(
                  context,
                  tier: SubscriptionTier.elite,
                  currentTier: entitlement.tier,
                ),
                const SizedBox(height: 24),
                _buildOneTimePurchases(context, entitlement),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentTierBadge(EntitlementProvider entitlement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: AppTheme.gold, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  entitlement.tier.displayName.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 24,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required SubscriptionTier tier,
    required SubscriptionTier currentTier,
  }) {
    final isCurrent = tier == currentTier;
    final isUpgrade = tier.index > currentTier.index;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: isCurrent
            ? Border.all(color: AppTheme.gold, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tier.displayName.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 20,
                    color: isCurrent ? AppTheme.gold : AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                tier.price,
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 18,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tier.description,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          if (isUpgrade) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleUpgrade(context, tier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  'UPGRADE',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (isCurrent) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'CURRENT PLAN',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 12,
                  color: AppTheme.gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOneTimePurchases(BuildContext context, EntitlementProvider entitlement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ONE-TIME PURCHASES',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3D AIMING COURSE',
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visual aiming system mastery',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (entitlement.has3dAimingCourse)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'OWNED',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _handlePurchase(context, '3d_aiming_course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    '£12',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpgrade(BuildContext context, SubscriptionTier tier) async {
    final stripeService = StripeService();
    final entitlement = context.read<EntitlementProvider>();

    final url = await stripeService.createSubscriptionCheckout(
      tier: tier,
      customerId: entitlement.stripeCustomerId,
    );

    if (url != null) {
      await stripeService.openCheckout(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to start checkout. Please try again.',
              style: TextStyle(fontFamily: AppFonts.body),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePurchase(BuildContext context, String productId) async {
    final stripeService = StripeService();
    final entitlement = context.read<EntitlementProvider>();

    final url = await stripeService.createPurchaseCheckout(
      productId: productId,
      customerId: entitlement.stripeCustomerId,
    );

    if (url != null) {
      await stripeService.openCheckout(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to start checkout. Please try again.',
              style: TextStyle(fontFamily: AppFonts.body),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
