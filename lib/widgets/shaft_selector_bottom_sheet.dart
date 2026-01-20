import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import 'nock_rotation_selector.dart';

/// Result returned from ShaftSelectorBottomSheet
class ShaftSelectionResult {
  final int? shaftNumber;
  final String? nockRotation;
  final int rating;
  final bool skipped;
  /// If true, don't show the shaft selector again for this session
  final bool dontAskAgain;

  const ShaftSelectionResult({
    this.shaftNumber,
    this.nockRotation,
    this.rating = 5,
    this.skipped = false,
    this.dontAskAgain = false,
  });

  /// User explicitly skipped shaft selection
  factory ShaftSelectionResult.skip() => const ShaftSelectionResult(skipped: true);

  /// User skipped and doesn't want to be asked again this session
  factory ShaftSelectionResult.skipAndDontAsk() => const ShaftSelectionResult(
    skipped: true,
    dontAskAgain: true,
  );
}

class ShaftSelectorBottomSheet extends StatefulWidget {
  final List<Shaft> shafts;
  final Function(int shaftNumber, {String? nockRotation, int rating})? onShaftSelected;
  final VoidCallback? onSkip;
  /// Shaft numbers already used in this end (disabled but not retired)
  final Set<int> usedShaftNumbers;
  /// Whether to show nock rotation selector
  final bool showNockRotation;
  /// Whether to show shot rating selector
  final bool showRating;

  const ShaftSelectorBottomSheet({
    super.key,
    required this.shafts,
    this.onShaftSelected,
    this.onSkip,
    this.usedShaftNumbers = const {},
    this.showNockRotation = false,
    this.showRating = true,
  });

  @override
  State<ShaftSelectorBottomSheet> createState() =>
      _ShaftSelectorBottomSheetState();
}

class _ShaftSelectorBottomSheetState extends State<ShaftSelectorBottomSheet> {
  String? _selectedNockRotation;
  int _rating = 5; // Default to 5 stars (good shot)

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

          // Shot rating (default 5 stars, tap to reduce)
          if (widget.showRating) ...[
            _ShotRatingSelector(
              rating: _rating,
              onChanged: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

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
                        // Return result for new API, also call legacy callback
                        final result = ShaftSelectionResult(
                          shaftNumber: shaft.number,
                          nockRotation: _selectedNockRotation,
                          rating: _rating,
                        );
                        Navigator.pop(context, result);
                        widget.onShaftSelected?.call(
                          shaft.number,
                          nockRotation: _selectedNockRotation,
                          rating: _rating,
                        );
                      }
                    : null,
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Skip buttons row
          Row(
            children: [
              // Skip this arrow only
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Return skip result for new API, also call legacy callback
                    Navigator.pop(context, ShaftSelectionResult.skip());
                    widget.onSkip?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Don't ask again this session
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, ShaftSelectionResult.skipAndDontAsk());
                    widget.onSkip?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                  ),
                  child: Text(
                    "Don't ask again",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Star rating selector - 5 stars default, tap lower to mark as "bad shot"
class _ShotRatingSelector extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _ShotRatingSelector({
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Shot:',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i <= rating ? Icons.star : Icons.star_border,
                size: 28,
                color: i <= rating
                    ? (rating >= 4 ? AppColors.gold : AppColors.textMuted)
                    : AppColors.surfaceLight,
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        if (rating < 4)
          Text(
            'exclude',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
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
        ? AppColors.surfaceLight.withValues(alpha: 0.3)
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
