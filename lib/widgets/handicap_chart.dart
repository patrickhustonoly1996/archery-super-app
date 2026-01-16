import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import '../utils/handicap_calculator.dart';

/// Handicap progression chart showing performance over time
/// standardized across different round types using Archery GB tables.
///
/// Lower handicap = better performance (0 = world record level)
class HandicapChart extends StatelessWidget {
  final List<Session> sessions;
  final List<ImportedScore> importedScores;
  final Map<String, RoundType> roundTypes;

  const HandicapChart({
    super.key,
    required this.sessions,
    required this.importedScores,
    required this.roundTypes,
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
          isPlotted: true,
        ));
      }
    }

    // Process imported scores
    for (final score in importedScores) {
      // Try to match round name to round type ID (pass score to help distinguish 720 vs half)
      final roundTypeId = _matchRoundName(score.roundName, score: score.score);
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
          isPlotted: false,
        ));
      }
    }

    // Sort by date
    allHandicaps.sort((a, b) => a.date.compareTo(b.date));

    if (allHandicaps.isEmpty) {
      return const SizedBox.shrink();
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
                painter: _HandicapChartPainter(handicaps: recentHandicaps),
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

  /// Match imported round name to round type ID
  /// Flexible fuzzy matching on common round names
  /// Uses score to distinguish 720 (72 arrows) from half round (36 arrows)
  String? _matchRoundName(String roundName, {int? score}) {
    final lower = roundName.toLowerCase().trim();

    // WA Outdoor - 720 rounds
    // But if score <= 360, it's probably a half round (36 arrows), not a bad 720
    if (lower.contains('720')) {
      if (score != null && score <= 360) {
        return 'half_metric_70m'; // Score too low for 720
      }
      if (lower.contains('70') || lower.contains('gent') || lower.contains('men')) return 'wa_720_70m';
      if (lower.contains('60') || lower.contains('ladi') || lower.contains('women')) return 'wa_720_60m';
      if (lower.contains('50')) return 'wa_720_50m';
      return 'wa_720_70m'; // Default to 70m
    }

    // WA Outdoor - 1440 rounds (FITA)
    if (lower.contains('1440') || lower.contains('fita')) {
      if (lower.contains('90') || lower.contains('gent') || lower.contains('men')) return 'wa_1440_90m';
      if (lower.contains('70') || lower.contains('ladi') || lower.contains('women')) return 'wa_1440_70m';
      if (lower.contains('60')) return 'wa_1440_60m';
      return 'wa_1440_90m';
    }

    // 70m rounds - use score to decide full 720 vs half round
    if (lower.contains('70m') || lower.contains('70 m') || lower.contains('h2h') ||
        lower.contains('head') || lower.contains('match') || lower.contains('half')) {
      if (score != null && score > 360) {
        return 'wa_720_70m';
      }
      return 'half_metric_70m';
    }

    // Generic "70" without "m" - use score to decide
    if (lower.contains('70') && !lower.contains('1440') && !lower.contains('720')) {
      if (score != null && score > 360) {
        return 'wa_720_70m';
      }
      return 'half_metric_70m';
    }

    // WA Indoor
    if (lower.contains('18m') || lower.contains('18 m') ||
        (lower.contains('wa') && lower.contains('18'))) return 'wa_18m';
    if (lower.contains('25m') || lower.contains('25 m') ||
        (lower.contains('wa') && lower.contains('25'))) return 'wa_25m';

    // AGB Indoor
    if (lower.contains('portsmouth') || lower.contains('portsm')) return 'portsmouth';
    if (lower.contains('worcester')) return 'worcester';
    if (lower.contains('vegas')) return 'vegas';
    if (lower.contains('bray')) {
      if (lower.contains('ii') || lower.contains('2')) return 'bray_2';
      return 'bray_1';
    }
    if (lower.contains('stafford')) return 'stafford';

    // AGB Outdoor Imperial
    if (lower == 'york' || lower.contains('york')) return 'york';
    if (lower.contains('hereford')) return 'hereford';
    if (lower.contains('st george') || lower.contains('st. george')) return 'st_george';
    if (lower.contains('bristol')) {
      if (lower.contains('v') && !lower.contains('iv')) return 'bristol_v';
      if (lower.contains('iv')) return 'bristol_iv';
      if (lower.contains('iii')) return 'bristol_iii';
      if (lower.contains('ii')) return 'bristol_ii';
      if (lower.contains('i')) return 'bristol_i';
    }

    // National rounds
    if (lower.contains('national')) {
      if (lower.contains('long')) return 'long_national';
      if (lower.contains('short')) return 'short_national';
      return 'national';
    }

    // AGB Metric
    if (lower.contains('metric')) {
      if (lower.contains('v') && !lower.contains('iv')) return 'metric_v';
      if (lower.contains('iv')) return 'metric_iv';
      if (lower.contains('iii')) return 'metric_iii';
      if (lower.contains('ii')) return 'metric_ii';
      if (lower.contains('i')) return 'metric_i';
    }

    // Fallbacks
    if (lower.contains('indoor')) return 'portsmouth';
    if (lower.contains('outdoor')) return 'wa_720_70m';

    return null;
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
  final bool isPlotted;

  _HandicapPoint({
    required this.date,
    required this.handicap,
    required this.score,
    required this.roundName,
    required this.isPlotted,
  });
}

class _HandicapChartPainter extends CustomPainter {
  final List<_HandicapPoint> handicaps;

  _HandicapChartPainter({required this.handicaps});

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
    final plottedPoints = <Offset>[];
    final importedPoints = <Offset>[];

    for (int i = 0; i < handicaps.length; i++) {
      final x = handicaps.length > 1 ? (i / (handicaps.length - 1)) * size.width : size.width / 2;

      // Invert Y-axis so improvement (lower handicap) goes up visually
      final normalizedHandicap = paddedRange > 0
          ? (paddedMax - handicaps[i].handicap) / paddedRange
          : 0.5;
      final y = size.height - (normalizedHandicap * size.height);

      final point = Offset(x, y);
      points.add(point);

      if (handicaps[i].isPlotted) {
        plottedPoints.add(point);
      } else {
        importedPoints.add(point);
      }
    }

    // Draw connecting lines
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = AppColors.textMuted.withValues(alpha: 0.3)
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
        ..color = AppColors.gold.withValues(alpha: 0.05)
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
    return oldDelegate.handicaps != handicaps;
  }
}
