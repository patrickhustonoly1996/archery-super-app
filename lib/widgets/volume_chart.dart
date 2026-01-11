import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';

/// Simple volume chart showing session scores over time
class VolumeChart extends StatelessWidget {
  final List<Session> sessions;
  final List<ImportedScore> importedScores;
  final Map<String, RoundType> roundTypes;

  const VolumeChart({
    super.key,
    required this.sessions,
    required this.importedScores,
    required this.roundTypes,
  });

  @override
  Widget build(BuildContext context) {
    // Combine and sort all scores by date
    final allScores = <_ScorePoint>[];

    // Add plotted sessions
    for (final session in sessions) {
      final roundType = roundTypes[session.roundTypeId];
      final percentage = roundType != null
          ? (session.totalScore / roundType.maxScore * 100)
          : null;

      allScores.add(_ScorePoint(
        date: session.startedAt,
        score: session.totalScore,
        percentage: percentage,
        isPlotted: true,
      ));
    }

    // Add imported scores
    for (final score in importedScores) {
      allScores.add(_ScorePoint(
        date: score.date,
        score: score.score,
        percentage: null, // Don't have max score for imported
        isPlotted: false,
      ));
    }

    // Sort by date
    allScores.sort((a, b) => a.date.compareTo(b.date));

    if (allScores.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take last 30 sessions for the chart
    final recentScores = allScores.length > 30
        ? allScores.sublist(allScores.length - 30)
        : allScores;

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
                  'Score Trend',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
                Text(
                  'Last ${recentScores.length} sessions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _VolumeChartPainter(scores: recentScores),
                child: Container(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: AppColors.gold,
                  label: 'Plotted',
                ),
                const SizedBox(width: AppSpacing.md),
                _LegendItem(
                  color: AppColors.textSecondary,
                  label: 'Imported',
                ),
              ],
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

class _ScorePoint {
  final DateTime date;
  final int score;
  final double? percentage;
  final bool isPlotted;

  _ScorePoint({
    required this.date,
    required this.score,
    this.percentage,
    required this.isPlotted,
  });
}

class _VolumeChartPainter extends CustomPainter {
  final List<_ScorePoint> scores;

  _VolumeChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    // Find min/max scores for scaling
    final minScore = scores.map((s) => s.score).reduce((a, b) => a < b ? a : b);
    final maxScore = scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    final scoreRange = maxScore - minScore;

    // Add padding to the range
    final paddedMin = minScore - (scoreRange * 0.1);
    final paddedMax = maxScore + (scoreRange * 0.1);
    final paddedRange = paddedMax - paddedMin;

    // Calculate positions
    final points = <Offset>[];
    final plottedPoints = <Offset>[];
    final importedPoints = <Offset>[];

    for (int i = 0; i < scores.length; i++) {
      final x = (i / (scores.length - 1)) * size.width;
      final normalizedScore = paddedRange > 0
          ? (scores[i].score - paddedMin) / paddedRange
          : 0.5;
      final y = size.height - (normalizedScore * size.height);

      final point = Offset(x, y);
      points.add(point);

      if (scores[i].isPlotted) {
        plottedPoints.add(point);
      } else {
        importedPoints.add(point);
      }
    }

    // Draw connecting lines
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = AppColors.textMuted.withOpacity(0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw area under the line
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
        ..color = AppColors.gold.withOpacity(0.05)
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, areaPaint);
    }

    // Draw imported score points
    final importedPaint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.fill;

    for (final point in importedPoints) {
      canvas.drawCircle(point, 3, importedPaint);
    }

    // Draw plotted session points (on top)
    final plottedPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    for (final point in plottedPoints) {
      canvas.drawCircle(point, 4, plottedPaint);
    }

    // Draw score labels at top and bottom
    final textStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
    );

    // Max score label
    final maxTextSpan = TextSpan(
      text: maxScore.toString(),
      style: textStyle,
    );
    final maxTextPainter = TextPainter(
      text: maxTextSpan,
      textDirection: TextDirection.ltr,
    );
    maxTextPainter.layout();
    maxTextPainter.paint(canvas, const Offset(0, 0));

    // Min score label
    final minTextSpan = TextSpan(
      text: minScore.toString(),
      style: textStyle,
    );
    final minTextPainter = TextPainter(
      text: minTextSpan,
      textDirection: TextDirection.ltr,
    );
    minTextPainter.layout();
    minTextPainter.paint(canvas, Offset(0, size.height - 12));
  }

  @override
  bool shouldRepaint(_VolumeChartPainter oldDelegate) {
    return oldDelegate.scores != scores;
  }
}
