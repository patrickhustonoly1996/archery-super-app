import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';

/// Time period options for filtering the chart
enum TimePeriod {
  week('1W', 7),
  month('1M', 30),
  threeMonths('3M', 90),
  sixMonths('6M', 180),
  year('1Y', 365),
  all('All', 0),
  indoorSeason('Indoor', 0), // Oct-Mar
  outdoorSeason('Outdoor', 0), // Apr-Sep
  custom('Custom', 0);

  final String label;
  final int days;
  const TimePeriod(this.label, this.days);
}

/// Volume chart showing session scores over time with time period selector
class VolumeChart extends StatefulWidget {
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
  State<VolumeChart> createState() => _VolumeChartState();
}

class _VolumeChartState extends State<VolumeChart> {
  TimePeriod _selectedPeriod = TimePeriod.threeMonths;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    // Combine and sort all scores by date
    final allScores = <_ScorePoint>[];

    // Add plotted sessions
    for (final session in widget.sessions) {
      final roundType = widget.roundTypes[session.roundTypeId];
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
    for (final score in widget.importedScores) {
      allScores.add(_ScorePoint(
        date: score.date,
        score: score.score,
        percentage: null,
        isPlotted: false,
      ));
    }

    // Sort by date
    allScores.sort((a, b) => a.date.compareTo(b.date));

    if (allScores.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter by selected time period
    final filteredScores = _filterByPeriod(allScores);

    if (filteredScores.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, 0),
              const SizedBox(height: AppSpacing.sm),
              _buildPeriodSelector(),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'No data for this period',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, filteredScores.length),
            const SizedBox(height: AppSpacing.sm),
            _buildPeriodSelector(),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _VolumeChartPainter(scores: filteredScores),
                child: Container(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Date range label
            _buildDateRangeLabel(filteredScores),
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

  Widget _buildHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Score Trend',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.gold,
              ),
        ),
        Text(
          '$count sessions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TimePeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(period.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (period == TimePeriod.custom) {
                    _showCustomDatePicker();
                  } else {
                    setState(() => _selectedPeriod = period);
                  }
                }
              },
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.backgroundDark : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRangeLabel(List<_ScorePoint> scores) {
    if (scores.isEmpty) return const SizedBox.shrink();

    final first = scores.first.date;
    final last = scores.last.date;

    String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year % 100}';

    return Center(
      child: Text(
        '${formatDate(first)} - ${formatDate(last)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    // Show bottom sheet with season suggestions and custom picker
    final result = await showModalBottomSheet<DateTimeRange?>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) => _CustomDatePickerSheet(
        initialRange: _customRange,
      ),
    );

    if (result != null) {
      setState(() {
        _customRange = result;
        _selectedPeriod = TimePeriod.custom;
      });
    }
  }

  List<_ScorePoint> _filterByPeriod(List<_ScorePoint> scores) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case TimePeriod.week:
      case TimePeriod.month:
      case TimePeriod.threeMonths:
      case TimePeriod.sixMonths:
      case TimePeriod.year:
        final cutoff = now.subtract(Duration(days: _selectedPeriod.days));
        return scores.where((s) => s.date.isAfter(cutoff)).toList();

      case TimePeriod.all:
        return scores;

      case TimePeriod.indoorSeason:
        // Indoor: October - March
        return scores.where((s) {
          final month = s.date.month;
          return month >= 10 || month <= 3;
        }).toList();

      case TimePeriod.outdoorSeason:
        // Outdoor: April - September
        return scores.where((s) {
          final month = s.date.month;
          return month >= 4 && month <= 9;
        }).toList();

      case TimePeriod.custom:
        if (_customRange == null) return scores;
        return scores.where((s) {
          return s.date.isAfter(_customRange!.start.subtract(const Duration(days: 1))) &&
                 s.date.isBefore(_customRange!.end.add(const Duration(days: 1)));
        }).toList();
    }
  }
}

/// Bottom sheet for custom date selection with season suggestions
class _CustomDatePickerSheet extends StatelessWidget {
  final DateTimeRange? initialRange;

  const _CustomDatePickerSheet({this.initialRange});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year;

    // Calculate current season date ranges
    final lastIndoorStart = now.month >= 10
        ? DateTime(currentYear, 10, 1)
        : DateTime(currentYear - 1, 10, 1);
    final lastIndoorEnd = now.month >= 10
        ? DateTime(currentYear + 1, 3, 31)
        : DateTime(currentYear, 3, 31);
    final lastOutdoorStart = DateTime(currentYear, 4, 1);
    final lastOutdoorEnd = DateTime(currentYear, 9, 30);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Date Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick season picks
            Text(
              'Quick Picks',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _QuickPickChip(
                  label: 'Indoor ${lastIndoorStart.year}/${lastIndoorEnd.year % 100}',
                  onTap: () => Navigator.pop(
                    context,
                    DateTimeRange(start: lastIndoorStart, end: lastIndoorEnd),
                  ),
                ),
                _QuickPickChip(
                  label: 'Outdoor $currentYear',
                  onTap: () => Navigator.pop(
                    context,
                    DateTimeRange(start: lastOutdoorStart, end: lastOutdoorEnd),
                  ),
                ),
                _QuickPickChip(
                  label: 'Last 90 days',
                  onTap: () => Navigator.pop(
                    context,
                    DateTimeRange(
                      start: now.subtract(const Duration(days: 90)),
                      end: now,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.surfaceLight),
            const SizedBox(height: AppSpacing.md),

            // Custom date picker button
            OutlinedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: now,
                  initialDateRange: initialRange ??
                      DateTimeRange(
                        start: now.subtract(const Duration(days: 90)),
                        end: now,
                      ),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: AppColors.gold,
                          onPrimary: AppColors.backgroundDark,
                          surface: AppColors.surfaceDark,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null && context.mounted) {
                  Navigator.pop(context, range);
                }
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Pick Custom Dates'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.surfaceLight),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
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
      final x = scores.length > 1 ? (i / (scores.length - 1)) * size.width : size.width / 2;
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

    // Draw connecting lines - higher contrast for red light glasses
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = AppColors.gold.withAlpha(180)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

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
        ..color = AppColors.gold.withAlpha(25)
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, areaPaint);
    }

    // Draw imported score points
    final importedPaint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.fill;

    for (final point in importedPoints) {
      canvas.drawCircle(point, 5, importedPaint);
    }

    // Draw plotted session points (on top)
    final plottedPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    for (final point in plottedPoints) {
      canvas.drawCircle(point, 6, plottedPaint);
    }

    // Draw score labels at top and bottom
    final textStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w500,
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
