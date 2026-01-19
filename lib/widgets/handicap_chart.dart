import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import '../utils/handicap_calculator.dart';
import '../utils/round_matcher.dart';

/// Handicap progression chart showing performance over time
/// standardized across different round types using Archery GB tables.
///
/// Lower handicap = better performance (0 = world record level)
class HandicapChart extends StatelessWidget {
  final List<Session> sessions;
  final List<ImportedScore> importedScores;
  final Map<String, RoundType> roundTypes;
  final ColorblindMode colorblindMode;

  const HandicapChart({
    super.key,
    required this.sessions,
    required this.importedScores,
    required this.roundTypes,
    this.colorblindMode = ColorblindMode.none,
  });

  @override
  Widget build(BuildContext context) {
    // Convert scores to handicaps
    final allHandicaps = <_HandicapPoint>[];

    // Process plotted sessions
    for (final session in sessions) {
      final roundType = roundTypes[session.roundTypeId];
      if (roundType == null) continue;

      final handicap = HandicapCalculator.calculateHandicap(
        session.roundTypeId,
        session.totalScore,
      );

      if (handicap != null) {
        allHandicaps.add(_HandicapPoint(
          date: session.startedAt,
          handicap: handicap,
          score: session.totalScore,
          roundName: roundType.name,
          isCompetition: session.sessionType == 'competition',
        ));
      }
    }

    // Process imported scores
    for (final score in importedScores) {
      // Try to match round name to round type ID (pass score to help distinguish 720 vs half)
      final roundTypeId = matchRoundName(score.roundName, score: score.score);
      if (roundTypeId == null) continue;

      final handicap = HandicapCalculator.calculateHandicap(
        roundTypeId,
        score.score,
      );

      if (handicap != null) {
        allHandicaps.add(_HandicapPoint(
          date: score.date,
          handicap: handicap,
          score: score.score,
          roundName: score.roundName,
          isCompetition: score.sessionType == 'competition',
        ));
      }
    }

    // Sort by date
    allHandicaps.sort((a, b) => a.date.compareTo(b.date));

    if (allHandicaps.isEmpty) {
      return _buildSamplePreview(context);
    }

    // Take last 30 for the chart
    final recentHandicaps = allHandicaps.length > 30
        ? allHandicaps.sublist(allHandicaps.length - 30)
        : allHandicaps;

    // Calculate stats
    final avgHandicap = recentHandicaps
            .map((h) => h.handicap)
            .reduce((a, b) => a + b) ~/
        recentHandicaps.length;

    final bestHandicap = recentHandicaps
        .map((h) => h.handicap)
        .reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Handicap Progression',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
                Text(
                  'Last ${recentHandicaps.length} rounds',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Stats row
            Row(
              children: [
                _StatBadge(label: 'Current', value: 'HC ${recentHandicaps.last.handicap}'),
                const SizedBox(width: AppSpacing.sm),
                _StatBadge(label: 'Average', value: 'HC $avgHandicap'),
                const SizedBox(width: AppSpacing.sm),
                _StatBadge(label: 'Best', value: 'HC $bestHandicap', isHighlight: true),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Chart
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _HandicapChartPainter(
                  handicaps: recentHandicaps,
                  colorblindMode: colorblindMode,
                ),
                child: Container(),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Legend - use colorblind-friendly colors
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: AppColors.gold,
                  label: 'Competition',
                ),
                const SizedBox(width: AppSpacing.md),
                _LegendItem(
                  color: AccessibleColors.getPracticeColor(colorblindMode),
                  label: 'Practice',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  /// Build a sample preview chart when no real data exists
  Widget _buildSamplePreview(BuildContext context) {
    // Generate realistic sample handicap progression data
    // Shows improvement over time (handicap decreasing)
    final now = DateTime.now();
    final sampleHandicaps = <_HandicapPoint>[
      _HandicapPoint(date: now.subtract(const Duration(days: 180)), handicap: 58, score: 580, roundName: 'WA 720 70m', isCompetition: false),
      _HandicapPoint(date: now.subtract(const Duration(days: 160)), handicap: 55, score: 595, roundName: 'Portsmouth', isCompetition: true),
      _HandicapPoint(date: now.subtract(const Duration(days: 140)), handicap: 52, score: 610, roundName: 'WA 720 70m', isCompetition: true),
      _HandicapPoint(date: now.subtract(const Duration(days: 120)), handicap: 54, score: 600, roundName: 'York', isCompetition: false),
      _HandicapPoint(date: now.subtract(const Duration(days: 100)), handicap: 49, score: 625, roundName: 'WA 720 70m', isCompetition: true),
      _HandicapPoint(date: now.subtract(const Duration(days: 80)), handicap: 47, score: 635, roundName: 'Portsmouth', isCompetition: true),
      _HandicapPoint(date: now.subtract(const Duration(days: 60)), handicap: 45, score: 645, roundName: 'WA 18m', isCompetition: false),
      _HandicapPoint(date: now.subtract(const Duration(days: 40)), handicap: 43, score: 655, roundName: 'WA 720 70m', isCompetition: true),
      _HandicapPoint(date: now.subtract(const Duration(days: 20)), handicap: 41, score: 665, roundName: 'Portsmouth', isCompetition: true),
      _HandicapPoint(date: now, handicap: 38, score: 680, roundName: 'WA 720 70m', isCompetition: true),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Handicap Progression',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SAMPLE',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Stats row with sample values
            Row(
              children: [
                _StatBadge(label: 'Current', value: 'HC ${sampleHandicaps.last.handicap}'),
                const SizedBox(width: AppSpacing.sm),
                _StatBadge(label: 'Average', value: 'HC 48'),
                const SizedBox(width: AppSpacing.sm),
                _StatBadge(label: 'Best', value: 'HC ${sampleHandicaps.last.handicap}', isHighlight: true),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Sample chart with reduced opacity
            Opacity(
              opacity: 0.6,
              child: SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: _HandicapChartPainter(handicaps: sampleHandicaps),
                  child: Container(),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Helpful message instead of legend
            Center(
              child: Text(
                'Your handicap progression will appear here',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _StatBadge({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHighlight ? AppColors.gold : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _HandicapPoint {
  final DateTime date;
  final int handicap;
  final int score;
  final String roundName;
  final bool isCompetition;

  _HandicapPoint({
    required this.date,
    required this.handicap,
    required this.score,
    required this.roundName,
    required this.isCompetition,
  });
}

class _HandicapChartPainter extends CustomPainter {
  final List<_HandicapPoint> handicaps;
  final ColorblindMode colorblindMode;

  _HandicapChartPainter({
    required this.handicaps,
    this.colorblindMode = ColorblindMode.none,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (handicaps.isEmpty) return;

    // Find min/max handicaps for scaling (remember: lower is better!)
    final minHandicap = handicaps
        .map((h) => h.handicap)
        .reduce((a, b) => a < b ? a : b);
    final maxHandicap = handicaps
        .map((h) => h.handicap)
        .reduce((a, b) => a > b ? a : b);
    final handicapRange = maxHandicap - minHandicap;

    // Add padding to the range
    final paddedMin = (minHandicap - (handicapRange * 0.1)).clamp(0, 150).toInt();
    final paddedMax = (maxHandicap + (handicapRange * 0.1)).clamp(0, 150).toInt();
    final paddedRange = paddedMax - paddedMin;

    // Calculate positions
    final points = <Offset>[];
    final competitionPoints = <Offset>[];
    final practicePoints = <Offset>[];

    for (int i = 0; i < handicaps.length; i++) {
      final x = handicaps.length > 1 ? (i / (handicaps.length - 1)) * size.width : size.width / 2;

      // Invert Y-axis so improvement (lower handicap) goes up visually
      final normalizedHandicap = paddedRange > 0
          ? (paddedMax - handicaps[i].handicap) / paddedRange
          : 0.5;
      final y = size.height - (normalizedHandicap * size.height);

      final point = Offset(x, y);
      points.add(point);

      if (handicaps[i].isCompetition) {
        competitionPoints.add(point);
      } else {
        practicePoints.add(point);
      }
    }

    // Draw connecting line with subtle glow
    if (points.length > 1) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      // Glow layer
      final glowPaint = Paint()
        ..color = AppColors.gold.withValues(alpha: 0.15)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glowPaint);

      // Main line
      final linePaint = Paint()
        ..color = AppColors.gold.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);
    }

    // Draw area under the line with gradient effect
    if (points.length > 1) {
      final areaPath = Path()
        ..moveTo(points[0].dx, size.height)
        ..lineTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        areaPath.lineTo(points[i].dx, points[i].dy);
      }

      areaPath.lineTo(points.last.dx, size.height);
      areaPath.close();

      final areaPaint = Paint()
        ..color = AppColors.gold.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, areaPaint);
    }

    // Draw practice score points with colorblind-friendly color
    final practiceColor = AccessibleColors.getPracticeColor(colorblindMode);
    final practiceGlowPaint = Paint()
      ..color = practiceColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final practicePaint = Paint()
      ..color = practiceColor
      ..style = PaintingStyle.fill;

    for (final point in practicePoints) {
      canvas.drawCircle(point, 6, practiceGlowPaint); // Glow
      canvas.drawCircle(point, 3, practicePaint); // Core
    }

    // Draw competition score points with gold glow (on top)
    final competitionGlowPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final competitionPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    for (final point in competitionPoints) {
      canvas.drawCircle(point, 8, competitionGlowPaint); // Glow
      canvas.drawCircle(point, 4, competitionPaint); // Core
    }

    // Draw handicap labels at top and bottom
    final textStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
    );

    // Best handicap label (top - remember: lower is better!)
    final bestTextSpan = TextSpan(
      text: 'HC $paddedMin',
      style: textStyle,
    );
    final bestTextPainter = TextPainter(
      text: bestTextSpan,
      textDirection: TextDirection.ltr,
    );
    bestTextPainter.layout();
    bestTextPainter.paint(canvas, const Offset(0, 0));

    // Worst handicap label (bottom)
    final worstTextSpan = TextSpan(
      text: 'HC $paddedMax',
      style: textStyle,
    );
    final worstTextPainter = TextPainter(
      text: worstTextSpan,
      textDirection: TextDirection.ltr,
    );
    worstTextPainter.layout();
    worstTextPainter.paint(canvas, Offset(0, size.height - 12));
  }

  @override
  bool shouldRepaint(_HandicapChartPainter oldDelegate) {
    return oldDelegate.handicaps != handicaps ||
        oldDelegate.colorblindMode != colorblindMode;
  }
}
