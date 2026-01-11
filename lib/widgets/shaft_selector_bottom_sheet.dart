import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';

class ShaftSelectorBottomSheet extends StatelessWidget {
  final List<Shaft> shafts;
  final Function(int shaftNumber) onShaftSelected;
  final VoidCallback onSkip;

  const ShaftSelectorBottomSheet({
    super.key,
    required this.shafts,
    required this.onShaftSelected,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Arrow',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.md),

          // Shaft grid (4 columns)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.2,
            ),
            itemCount: shafts.length,
            itemBuilder: (context, index) {
              final shaft = shafts[index];
              return _ShaftButton(
                number: shaft.number,
                isRetired: shaft.retiredAt != null,
                onTap: shaft.retiredAt == null
                    ? () {
                        Navigator.pop(context);
                        onShaftSelected(shaft.number);
                      }
                    : null,
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Skip button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onSkip();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.surfaceLight),
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
              child: const Text('Skip (no tracking)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShaftButton extends StatelessWidget {
  final int number;
  final bool isRetired;
  final VoidCallback? onTap;

  const _ShaftButton({
    required this.number,
    required this.isRetired,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRetired
          ? AppColors.surfaceLight.withOpacity(0.3)
          : AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isRetired ? AppColors.textMuted : AppColors.gold,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isRetired ? AppColors.textMuted : AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
