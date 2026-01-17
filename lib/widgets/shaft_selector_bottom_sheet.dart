import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import 'nock_rotation_selector.dart';

class ShaftSelectorBottomSheet extends StatefulWidget {
  final List<Shaft> shafts;
  final Function(int shaftNumber, {String? nockRotation}) onShaftSelected;
  final VoidCallback onSkip;
  /// Shaft numbers already used in this end (disabled but not retired)
  final Set<int> usedShaftNumbers;
  /// Whether to show nock rotation selector
  final bool showNockRotation;

  const ShaftSelectorBottomSheet({
    super.key,
    required this.shafts,
    required this.onShaftSelected,
    required this.onSkip,
    this.usedShaftNumbers = const {},
    this.showNockRotation = false,
  });

  @override
  State<ShaftSelectorBottomSheet> createState() =>
      _ShaftSelectorBottomSheetState();
}

class _ShaftSelectorBottomSheetState extends State<ShaftSelectorBottomSheet> {
  String? _selectedNockRotation;

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

          // Nock rotation selector (optional)
          if (widget.showNockRotation) ...[
            Center(
              child: NockRotationSelector(
                selectedPosition: _selectedNockRotation,
                onSelected: (pos) => setState(() => _selectedNockRotation = pos),
                size: 100,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

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
            itemCount: widget.shafts.length,
            itemBuilder: (context, index) {
              final shaft = widget.shafts[index];
              final isRetired = shaft.retiredAt != null;
              final isUsedThisEnd = widget.usedShaftNumbers.contains(shaft.number);
              final isAvailable = !isRetired && !isUsedThisEnd;
              return _ShaftButton(
                number: shaft.number,
                isRetired: isRetired,
                isUsedThisEnd: isUsedThisEnd,
                onTap: isAvailable
                    ? () {
                        Navigator.pop(context);
                        widget.onShaftSelected(
                          shaft.number,
                          nockRotation: _selectedNockRotation,
                        );
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
                widget.onSkip();
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
  final bool isUsedThisEnd;
  final VoidCallback? onTap;

  const _ShaftButton({
    required this.number,
    required this.isRetired,
    this.isUsedThisEnd = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine visual state
    final isDisabled = isRetired || isUsedThisEnd;
    final backgroundColor = isDisabled
        ? AppColors.surfaceLight.withOpacity(0.3)
        : AppColors.surfaceDark;
    final borderColor = isDisabled ? AppColors.textMuted : AppColors.gold;
    final textColor = isDisabled ? AppColors.textMuted : AppColors.gold;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  number.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Show checkmark for used shafts (not retired, just used this end)
              if (isUsedThisEnd && !isRetired)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
