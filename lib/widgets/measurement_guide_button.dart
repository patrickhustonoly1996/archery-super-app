import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/measurement_guides.dart';

/// Info button that shows measurement guide for equipment specs
class MeasurementGuideButton extends StatelessWidget {
  final String tuningType;
  final String bowType;
  final double size;

  const MeasurementGuideButton({
    super.key,
    required this.tuningType,
    required this.bowType,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMeasurementGuide(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.info_outline,
          size: size,
          color: AppColors.neonCyan,
        ),
      ),
    );
  }

  void _showMeasurementGuide(BuildContext context) {
    final checklist = MeasurementGuides.getChecklist(tuningType);
    final tips = MeasurementGuides.getTips(tuningType, bowType);
    final displayName = MeasurementGuides.getDisplayName(tuningType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Row(
          children: [
            const Icon(Icons.straighten, color: AppColors.gold, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'HOW TO MEASURE: $displayName'.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 14,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (checklist.isNotEmpty) ...[
                const Text(
                  'STEPS',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...checklist.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.gold),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 11,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              if (tips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'TIPS',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 12,
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: AppColors.neonCyan,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'GOT IT',
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
