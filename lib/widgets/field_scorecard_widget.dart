import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/field_scoring.dart';
import '../models/field_course_target.dart';
import '../providers/field_session_provider.dart';

/// Scorecard display for field archery sessions
class FieldScorecardWidget extends StatelessWidget {
  final FieldSessionProvider session;
  final Function(int targetNumber)? onTargetTap;

  const FieldScorecardWidget({
    super.key,
    required this.session,
    this.onTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    final targets = List.generate(session.targetCount, (i) => i + 1);
    final scoredMap = {
      for (final s in session.scoredTargets) s.targetNumber: s
    };

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with totals
          _buildTotalsHeader(context),
          const SizedBox(height: AppSpacing.md),

          // Scorecard grid
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header row
                  _buildHeaderRow(context),
                  const Divider(height: 1, color: AppColors.surfaceLight),

                  // Target rows
                  ...targets.map((targetNum) {
                    final score = scoredMap[targetNum];
                    final target = session.course?.getTarget(targetNum);
                    final isCurrent = targetNum == session.currentTargetNumber;

                    return _buildTargetRow(
                      context,
                      targetNum: targetNum,
                      target: target,
                      score: score,
                      isCurrent: isCurrent,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem(context, 'Score', '${session.totalScore}'),
          _buildTotalItem(context, 'Targets', '${session.completedTargets}/${session.targetCount}'),
          _buildTotalItem(context, 'Xs', '${session.totalXs}'),
        ],
      ),
    );
  }

  Widget _buildTotalItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.gold,
                fontFamily: AppFonts.pixel,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      color: AppColors.surfaceDark,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                '#',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Distance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                'Arrows',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                'Total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                'R/T',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow(
    BuildContext context, {
    required int targetNum,
    FieldCourseTarget? target,
    FieldTargetScore? score,
    required bool isCurrent,
  }) {
    final isScored = score != null;
    final runningTotal = _calculateRunningTotal(targetNum);

    return GestureDetector(
      onTap: onTargetTap != null ? () => onTargetTap!(targetNum) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.gold.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.surfaceLight.withValues(alpha: 0.3),
            ),
            left: isCurrent
                ? BorderSide(color: AppColors.gold, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Target number
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  '$targetNum',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isCurrent ? AppColors.gold : AppColors.textPrimary,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ),
            ),

            // Distance
            Expanded(
              flex: 2,
              child: Text(
                target?.distanceDisplay ?? '-',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),

            // Arrow scores
            SizedBox(
              width: 100,
              child: isScored
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: score.arrowScores.map((a) {
                        return Container(
                          width: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          alignment: Alignment.center,
                          child: Text(
                            a.zone.display,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getScoreColor(a.zone),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                          ),
                        );
                      }).toList(),
                    )
                  : Center(
                      child: Text(
                        '-',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ),
            ),

            // Total score
            SizedBox(
              width: 50,
              child: Center(
                child: Text(
                  isScored ? '${score.totalScore}' : '-',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isScored ? AppColors.gold : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            // Running total
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  runningTotal > 0 ? '$runningTotal' : '-',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateRunningTotal(int throughTargetNum) {
    int total = 0;
    for (final score in session.scoredTargets) {
      if (score.targetNumber <= throughTargetNum) {
        total += score.totalScore;
      }
    }
    return total;
  }

  Color _getScoreColor(FieldScoringZone zone) {
    switch (zone) {
      case FieldScoringZone.x:
      case FieldScoringZone.five:
        return AppColors.gold;
      case FieldScoringZone.four:
        return const Color(0xFFFF5555);
      case FieldScoringZone.three:
        return const Color(0xFF5599FF);
      case FieldScoringZone.two:
        return AppColors.textPrimary;
      case FieldScoringZone.one:
        return AppColors.textSecondary;
      case FieldScoringZone.miss:
        return AppColors.textMuted;
    }
  }
}
