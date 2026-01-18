import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entitlement_provider.dart';
import '../theme/app_theme.dart';
import '../screens/subscription_screen.dart';

/// Feature that can be gated
enum GatedFeature {
  shaftAnalysis,
  olyTraining,
  autoPlot,
  unlimitedAutoPlot,
  hustonSchool,
  aiming3dCourse,
}

extension GatedFeatureExtension on GatedFeature {
  String get displayName {
    switch (this) {
      case GatedFeature.shaftAnalysis:
        return 'Shaft Analysis';
      case GatedFeature.olyTraining:
        return 'OLY Training';
      case GatedFeature.autoPlot:
        return 'Auto-Plot';
      case GatedFeature.unlimitedAutoPlot:
        return 'Unlimited Auto-Plot';
      case GatedFeature.hustonSchool:
        return 'Huston School';
      case GatedFeature.aiming3dCourse:
        return '3D Aiming Course';
    }
  }

  SubscriptionTier get requiredTier {
    switch (this) {
      case GatedFeature.shaftAnalysis:
      case GatedFeature.olyTraining:
      case GatedFeature.autoPlot:
        return SubscriptionTier.ranger;
      case GatedFeature.unlimitedAutoPlot:
        return SubscriptionTier.elite;
      case GatedFeature.hustonSchool:
        return SubscriptionTier.hustonSchool;
      case GatedFeature.aiming3dCourse:
        return SubscriptionTier.archer; // Purchase-based, not tier-based
    }
  }
}

/// Widget that gates content behind entitlement checks
/// Shows locked state with upgrade prompt when user doesn't have access
class FeatureGate extends StatelessWidget {
  final GatedFeature feature;
  final Widget child;
  final Widget? lockedChild; // Optional custom locked state
  final bool showUpgradeButton;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedChild,
    this.showUpgradeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EntitlementProvider>(
      builder: (context, entitlement, _) {
        final hasAccess = _checkAccess(entitlement);

        if (hasAccess) {
          return child;
        }

        return lockedChild ?? _buildLockedState(context, entitlement);
      },
    );
  }

  bool _checkAccess(EntitlementProvider entitlement) {
    switch (feature) {
      case GatedFeature.shaftAnalysis:
        return entitlement.hasShaftAnalysis;
      case GatedFeature.olyTraining:
        return entitlement.hasOlyTraining;
      case GatedFeature.autoPlot:
        return entitlement.hasAutoPlot;
      case GatedFeature.unlimitedAutoPlot:
        return entitlement.hasUnlimitedAutoPlot;
      case GatedFeature.hustonSchool:
        return entitlement.hasHustonSchool;
      case GatedFeature.aiming3dCourse:
        return entitlement.has3dAimingCourse;
    }
  }

  Widget _buildLockedState(BuildContext context, EntitlementProvider entitlement) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            feature.displayName,
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 20,
              color: AppTheme.gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getLockedMessage(entitlement),
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (showUpgradeButton) ...[
            const SizedBox(height: 24),
            _buildUpgradeButton(context),
          ],
        ],
      ),
    );
  }

  String _getLockedMessage(EntitlementProvider entitlement) {
    if (entitlement.isInGracePeriod) {
      final remaining = entitlement.graceTimeRemaining;
      if (remaining != null) {
        final hours = remaining.inHours;
        return 'Your subscription has expired. '
            'You have ${hours}h remaining before features are locked. '
            'Renew now to keep access.';
      }
    }

    if (feature == GatedFeature.aiming3dCourse) {
      return 'This course requires a one-time purchase.';
    }

    return 'This feature requires ${feature.requiredTier.displayName} or higher.';
  }

  Widget _buildUpgradeButton(BuildContext context) {
    final isPurchase = feature == GatedFeature.aiming3dCourse;

    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: Text(
        isPurchase ? 'PURCHASE' : 'UPGRADE',
        style: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Simpler inline check - returns true/false without building UI
class FeatureCheck {
  static bool hasAccess(BuildContext context, GatedFeature feature) {
    final entitlement = context.read<EntitlementProvider>();
    switch (feature) {
      case GatedFeature.shaftAnalysis:
        return entitlement.hasShaftAnalysis;
      case GatedFeature.olyTraining:
        return entitlement.hasOlyTraining;
      case GatedFeature.autoPlot:
        return entitlement.hasAutoPlot;
      case GatedFeature.unlimitedAutoPlot:
        return entitlement.hasUnlimitedAutoPlot;
      case GatedFeature.hustonSchool:
        return entitlement.hasHustonSchool;
      case GatedFeature.aiming3dCourse:
        return entitlement.has3dAimingCourse;
    }
  }

  /// Show upgrade dialog if user doesn't have access
  static Future<bool> checkAndPrompt(
    BuildContext context,
    GatedFeature feature,
  ) async {
    if (hasAccess(context, feature)) {
      return true;
    }

    final shouldUpgrade = await showDialog<bool>(
      context: context,
      builder: (context) => _UpgradeDialog(feature: feature),
    );

    if (shouldUpgrade == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    }

    return false;
  }
}

class _UpgradeDialog extends StatelessWidget {
  final GatedFeature feature;

  const _UpgradeDialog({required this.feature});

  @override
  Widget build(BuildContext context) {
    final isPurchase = feature == GatedFeature.aiming3dCourse;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: AppTheme.gold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature.displayName,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                color: AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        isPurchase
            ? 'This course requires a one-time purchase of £12.'
            : 'Upgrade to ${feature.requiredTier.displayName} to unlock this feature.',
        style: TextStyle(
          fontFamily: AppFonts.body,
          color: AppTheme.textPrimary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'CANCEL',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            isPurchase ? 'PURCHASE' : 'UPGRADE',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              color: AppTheme.gold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Banner shown when user is in grace period
class GracePeriodBanner extends StatelessWidget {
  const GracePeriodBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EntitlementProvider>(
      builder: (context, entitlement, _) {
        if (!entitlement.isInGracePeriod) {
          return const SizedBox.shrink();
        }

        final remaining = entitlement.graceTimeRemaining;
        final hours = remaining?.inHours ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.orange.withValues(alpha: 0.2),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Subscription expired. ${hours}h grace period remaining.',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  );
                },
                child: Text(
                  'RENEW',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 12,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
