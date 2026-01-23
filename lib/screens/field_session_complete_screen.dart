import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/field_course.dart';
import '../providers/field_session_provider.dart';
import '../providers/field_course_provider.dart';

class FieldSessionCompleteScreen extends StatelessWidget {
  const FieldSessionCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FieldSessionProvider>(
      builder: (context, session, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Round Complete'),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score summary card
                _buildScoreSummary(context, session),

                const SizedBox(height: AppSpacing.xl),

                // Target breakdown
                _buildTargetBreakdown(context, session),

                const SizedBox(height: AppSpacing.xl),

                // Course save option (if new course)
                if (session.isNewCourseCreation)
                  _buildCourseSaveOption(context, session),

                const SizedBox(height: AppSpacing.xl),

                // Action buttons
                _buildActions(context, session),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreSummary(BuildContext context, FieldSessionProvider session) {
    final roundType = session.roundType;
    final maxScore = roundType?.maxScore ?? 560;
    final percentage = (session.totalScore / maxScore * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withOpacity(0.2),
            AppColors.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            roundType?.displayName ?? 'Field Round',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${session.totalScore}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontFamily: AppFonts.pixel,
                  color: AppColors.gold,
                  fontSize: 64,
                ),
          ),
          Text(
            '/ $maxScore',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(context, '$percentage%', 'Accuracy'),
              const SizedBox(width: AppSpacing.md),
              if (session.totalXs > 0)
                _buildStatChip(context, '${session.totalXs}', 'X Count'),
              const SizedBox(width: AppSpacing.md),
              _buildStatChip(
                context,
                '${session.completedTargets}',
                'Targets',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: AppFonts.pixel,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBreakdown(BuildContext context, FieldSessionProvider session) {
    final targets = session.scoredTargets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Scores',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Column(
            children: targets.asMap().entries.map((entry) {
              final index = entry.key;
              final target = entry.value;
              final isLast = index == targets.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: AppColors.surfaceLight),
                        ),
                ),
                child: Row(
                  children: [
                    // Target number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${target.targetNumber}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Arrow scores
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: target.arrowScores.map((arrow) {
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getScoreColor(arrow.zone),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              arrow.zone.display,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppFonts.body,
                                color: _getScoreTextColor(arrow.zone),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Total
                    Text(
                      '${target.totalScore}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: AppFonts.pixel,
                            color: AppColors.gold,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSaveOption(BuildContext context, FieldSessionProvider session) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_alt, color: AppColors.gold),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Saved',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
                Text(
                  'You can shoot this course again from your saved courses.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildActions(BuildContext context, FieldSessionProvider session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Color _getScoreColor(dynamic zone) {
    // Import the actual zone type
    final zoneName = zone.toString().split('.').last;
    switch (zoneName) {
      case 'x':
      case 'five':
        return AppColors.gold;
      case 'four':
        return AppColors.ring8;
      case 'three':
        return AppColors.ring6;
      case 'two':
        return AppColors.ring4;
      case 'one':
        return AppColors.ring2;
      default:
        return AppColors.surfaceLight;
    }
  }

  Color _getScoreTextColor(dynamic zone) {
    final zoneName = zone.toString().split('.').last;
    switch (zoneName) {
      case 'x':
      case 'five':
        return AppColors.background;
      case 'one':
        return AppColors.background;
      default:
        return AppColors.textPrimary;
    }
  }
}
