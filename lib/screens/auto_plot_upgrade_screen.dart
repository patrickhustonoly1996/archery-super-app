import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auto_plot_provider.dart';

/// Screen showing Auto-Plot Pro benefits and upgrade option
class AutoPlotUpgradeScreen extends StatelessWidget {
  const AutoPlotUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'AUTO-PLOT PRO',
          style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero section
              _buildHeroSection(),
              const SizedBox(height: AppSpacing.xl),

              // Benefits list
              _buildBenefitsSection(),
              const SizedBox(height: AppSpacing.xl),

              // Pricing
              _buildPricingSection(),
              const SizedBox(height: AppSpacing.xl),

              // Upgrade button
              _buildUpgradeButton(context),
              const SizedBox(height: AppSpacing.md),

              // Current usage
              _buildCurrentUsage(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: AppColors.gold,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'UNLIMITED AI DETECTION',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 24,
              color: AppColors.gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Point. Shoot. Plot. No limits.',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      (Icons.all_inclusive, 'Unlimited scans', 'No monthly cap on auto-detection'),
      (Icons.speed, 'Faster plotting', 'Skip manual arrow entry completely'),
      (Icons.camera_alt, 'Reference targets', 'Register clean targets for better accuracy'),
      (Icons.support, 'Priority support', 'Direct access for issues and feedback'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT YOU GET',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...benefits.map((b) => _buildBenefitRow(b.$1, b.$2, b.$3)),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '£',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 20,
                  color: AppColors.gold,
                ),
              ),
              Text(
                '7.20',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 48,
                  color: AppColors.gold,
                ),
              ),
              Text(
                '/mo',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Includes base app subscription',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handleUpgrade(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
      child: Text(
        'UPGRADE TO PRO',
        style: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildCurrentUsage(BuildContext context) {
    return Consumer<AutoPlotProvider>(
      builder: (context, provider, _) {
        if (provider.hasUnlimitedAutoPlot) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'You have Professional tier',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          );
        }

        final remaining = provider.scansRemaining;
        final limit = provider.scanLimit;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Text(
            'Competitor tier: $remaining of $limit scans remaining this month',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  void _handleUpgrade(BuildContext context) {
    // Payment integration not yet implemented
    // Show info dialog directing user to contact for upgrade
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'UPGRADE',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 20,
            color: AppColors.gold,
          ),
        ),
        content: Text(
          'In-app purchases coming soon.\n\n'
          'Contact support to enable Auto-Plot Pro on your account.',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
