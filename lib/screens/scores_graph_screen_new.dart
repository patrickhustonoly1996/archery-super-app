import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../utils/handicap_calculator.dart';
import '../utils/unique_id.dart';

/// Full-screen scores graph showing handicap progression over time
/// with customizable time ranges and milestone markers
class ScoresGraphScreen extends StatefulWidget {
  const ScoresGraphScreen({super.key});

  @override
  State<ScoresGraphScreen> createState() => _ScoresGraphScreenState();
}

class _ScoresGraphScreenState extends State<ScoresGraphScreen> {
  List<_ScorePoint> _allPoints = [];
  List<Milestone> _milestones = [];
  bool _isLoading = true;
  String _timeFilter = 'all'; // 'all', '1m', '3m', '6m', '9m', '12m', '2y', '5y', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    final sessions = await db.getCompletedSessions();
    final imported = await db.getAllImportedScores();
    final roundTypes = await db.getAllRoundTypes();
    final milestones = await db.getAllMilestones();

    final roundTypesMap = <String, RoundType>{};
    for (final rt in roundTypes) {
      roundTypesMap[rt.id] = rt;
    }

    final points = <_ScorePoint>[];

    // Process plotted sessions
    for (final session in sessions) {
      final roundType = roundTypesMap[session.roundTypeId];
      if (roundType == null) continue;

      final handicap = HandicapCalculator.calculateHandicap(
        session.roundTypeId,
        session.totalScore,
      );

      if (handicap != null) {
        points.add(_ScorePoint(
          date: session.startedAt,
          handicap: handicap,
          score: session.totalScore,
          roundName: roundType.name,
          isIndoor: _isIndoorRound(session.roundTypeId),
          isPlotted: true,
        ));
      }
    }

    // Process imported scores
    for (final score in imported) {
      final roundTypeId = _matchRoundName(score.roundName);
      if (roundTypeId == null) continue;

      final handicap = HandicapCalculator.calculateHandicap(
        roundTypeId,
        score.score,
      );

      if (handicap != null) {
        points.add(_ScorePoint(
          date: score.date,
          handicap: handicap,
          score: score.score,
          roundName: score.roundName,
          isIndoor: _isIndoorRound(roundTypeId),
          isPlotted: false,
        ));
      }
    }

    // Sort by date
    points.sort((a, b) => a.date.compareTo(b.date));

    setState(() {
      _allPoints = points;
      _milestones = milestones;
      _isLoading = false;
    });
  }

  List<_ScorePoint> get _filteredPoints {
    if (_timeFilter == 'all') return _allPoints;

    if (_timeFilter == 'custom' && _customStartDate != null && _customEndDate != null) {
      return _allPoints.where((p) =>
          p.date.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
          p.date.isBefore(_customEndDate!.add(const Duration(days: 1)))).toList();
    }

    final now = DateTime.now();
    final cutoff = switch (_timeFilter) {
      '1m' => DateTime(now.year, now.month - 1, now.day),
      '3m' => DateTime(now.year, now.month - 3, now.day),
      '6m' => DateTime(now.year, now.month - 6, now.day),
      '9m' => DateTime(now.year, now.month - 9, now.day),
      '12m' => DateTime(now.year - 1, now.month, now.day),
      '2y' => DateTime(now.year - 2, now.month, now.day),
      '5y' => DateTime(now.year - 5, now.month, now.day),
      _ => DateTime(1900),
    };

    return _allPoints.where((p) => p.date.isAfter(cutoff)).toList();
  }

  List<Milestone> get _filteredMilestones {
    if (_filteredPoints.isEmpty) return [];

    final minDate = _filteredPoints.first.date;
    final maxDate = _filteredPoints.last.date;

    return _milestones.where((m) =>
        m.date.isAfter(minDate.subtract(const Duration(days: 1))) &&
        m.date.isBefore(maxDate.add(const Duration(days: 1)))).toList();
  }

  bool _isIndoorRound(String roundTypeId) {
    const indoorRounds = {
      'wa_18m',
      'wa_25m',
      'portsmouth',
      'worcester',
      'vegas',
    };
    return indoorRounds.contains(roundTypeId);
  }

  String? _matchRoundName(String roundName) {
    final lower = roundName.toLowerCase().trim();

    // WA Outdoor
    if (lower.contains('720') && lower.contains('70')) return 'wa_720_70m';
    if (lower.contains('720') && lower.contains('60')) return 'wa_720_60m';
    if (lower.contains('1440') && lower.contains('90')) return 'wa_1440_90m';
    if (lower.contains('1440') && lower.contains('70')) return 'wa_1440_70m';

    // WA Indoor
    if (lower.contains('wa') && lower.contains('18')) return 'wa_18m';
    if (lower.contains('wa') && lower.contains('25')) return 'wa_25m';

    // AGB Indoor
    if (lower.contains('portsmouth')) return 'portsmouth';
    if (lower.contains('worcester')) return 'worcester';
    if (lower.contains('vegas')) return 'vegas';

    // AGB Outdoor Imperial
    if (lower == 'york') return 'york';
    if (lower.contains('hereford')) return 'hereford';
    if (lower.contains('st george') || lower.contains('st. george')) {
      return 'st_george';
    }
    if (lower.contains('bristol')) {
      if (lower.contains('i') && !lower.contains('ii')) return 'bristol_i';
      if (lower.contains('ii') && !lower.contains('iii')) return 'bristol_ii';
      if (lower.contains('iii') && !lower.contains('iv')) return 'bristol_iii';
      if (lower.contains('iv') && !lower.contains('v')) return 'bristol_iv';
      if (lower.contains('v')) return 'bristol_v';
    }

    // AGB Metric
    if (lower.contains('metric')) {
      if (lower.contains('i') && !lower.contains('ii')) return 'metric_i';
      if (lower.contains('ii') && !lower.contains('iii')) return 'metric_ii';
      if (lower.contains('iii') && !lower.contains('iv')) return 'metric_iii';
      if (lower.contains('iv') && !lower.contains('v')) return 'metric_iv';
      if (lower.contains('v')) return 'metric_v';
    }

    return null;
  }

  Future<void> _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _customStartDate ?? now.subtract(const Duration(days: 90)),
      end: _customEndDate ?? now,
    );

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
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

    if (result != null) {
      setState(() {
        _customStartDate = result.start;
        _customEndDate = result.end;
        _timeFilter = 'custom';
      });
    }
  }

  Future<void> _showAddMilestoneDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Add Milestone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., First Competition',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
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
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add', style: TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      final db = context.read<AppDatabase>();
      await db.insertMilestone(MilestonesCompanion.insert(
        id: UniqueId.generate(),
        date: selectedDate,
        title: titleController.text,
        description: descController.text.isEmpty
            ? const Value.absent()
            : Value(descController.text),
      ));
      _loadData();
    }
  }

  Future<void> _showMilestonesListDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Milestones'),
        content: SizedBox(
          width: double.maxFinite,
          child: _milestones.isEmpty
              ? const Text(
                  'No milestones yet.\nTap + to add one.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _milestones.length,
                  itemBuilder: (context, index) {
                    final m = _milestones[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 4,
                        height: 40,
                        color: _parseColor(m.color),
                      ),
                      title: Text(m.title),
                      subtitle: Text(
                        '${m.date.day}/${m.date.month}/${m.date.year}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          final db = context.read<AppDatabase>();
                          await db.deleteMilestone(m.id);
                          Navigator.pop(context);
                          _loadData();
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handicap Graph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: _showMilestonesListDialog,
            tooltip: 'View Milestones',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMilestoneDialog,
            tooltip: 'Add Milestone',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _allPoints.isEmpty
              ? _EmptyState()
              : Column(
                  children: [
                    // Time filter - scrollable row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _timeFilter == 'all',
                            onTap: () => setState(() => _timeFilter = 'all'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: '1M',
                            selected: _timeFilter == '1m',
                            onTap: () => setState(() => _timeFilter = '1m'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: '3M',
                            selected: _timeFilter == '3m',
                            onTap: () => setState(() => _timeFilter = '3m'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: '6M',
                            selected: _timeFilter == '6m',
                            onTap: () => setState(() => _timeFilter = '6m'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: '9M',
                            selected: _timeFilter == '9m',
                            onTap: () => setState(() => _timeFilter = '9m'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: '12M',
                            selected: _timeFilter == '12m',
                            onTap: () => setState(() => _timeFilter = '12m'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: '2Y',
                            selected: _timeFilter == '2y',
                            onTap: () => setState(() => _timeFilter = '2y'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: '5Y',
                            selected: _timeFilter == '5y',
                            onTap: () => setState(() => _timeFilter = '5y'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterChip(
                            label: _timeFilter == 'custom' && _customStartDate != null
                                ? '${_customStartDate!.day}/${_customStartDate!.month} - ${_customEndDate!.day}/${_customEndDate!.month}'
                                : 'Custom',
                            selected: _timeFilter == 'custom',
                            onTap: _showCustomDateRangePicker,
                            icon: Icons.date_range,
                          ),
                        ],
                      ),
                    ),

                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendItem(
                            color: const Color(0xFFE53935), // Red
                            label: 'Indoor',
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          _LegendItem(
                            color: const Color(0xFF42A5F5), // Blue
                            label: 'Outdoor',
                          ),
                          if (_filteredMilestones.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.lg),
                            _LegendItem(
                              color: AppColors.gold,
                              label: 'Milestone',
                              isDashed: true,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Graph
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xs,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: _ScoresGraph(
                          points: _filteredPoints,
                          milestones: _filteredMilestones,
                        ),
                      ),
                    ),

                    // Stats summary
                    if (_filteredPoints.isNotEmpty) _StatsSummary(points: _filteredPoints),
                  ],
                ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.backgroundDark : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.backgroundDark : AppColors.textSecondary,
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
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isDashed)
          CustomPaint(
            size: const Size(16, 12),
            painter: _DashedLinePainter(color: color),
          )
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScoresGraph extends StatefulWidget {
  final List<_ScorePoint> points;
  final List<Milestone> milestones;

  const _ScoresGraph({
    required this.points,
    required this.milestones,
  });

  @override
  State<_ScoresGraph> createState() => _ScoresGraphState();
}

class _ScoresGraphState extends State<_ScoresGraph> {
  _ScorePoint? _selectedPoint;
  Milestone? _selectedMilestone;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _handleTap(details, constraints),
          onPanUpdate: (details) => _handlePan(details, constraints),
          onPanEnd: (_) => setState(() {
            _selectedPoint = null;
            _selectedMilestone = null;
          }),
          child: CustomPaint(
            painter: _ScoresGraphPainter(
              points: widget.points,
              milestones: widget.milestones,
              selectedPoint: _selectedPoint,
              selectedMilestone: _selectedMilestone,
            ),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    final result = _findNearest(details.localPosition, constraints);
    setState(() {
      _selectedPoint = result.$1;
      _selectedMilestone = result.$2;
    });
  }

  void _handlePan(DragUpdateDetails details, BoxConstraints constraints) {
    final result = _findNearest(details.localPosition, constraints);
    if (result.$1 != _selectedPoint || result.$2 != _selectedMilestone) {
      setState(() {
        _selectedPoint = result.$1;
        _selectedMilestone = result.$2;
      });
    }
  }

  (_ScorePoint?, Milestone?) _findNearest(Offset position, BoxConstraints constraints) {
    if (widget.points.isEmpty) return (null, null);

    final size = Size(constraints.maxWidth, constraints.maxHeight);
    const leftPadding = 40.0;
    const bottomPadding = 30.0;
    final graphWidth = size.width - leftPadding;
    final graphHeight = size.height - bottomPadding;

    // Find date range
    final minDate = widget.points.first.date;
    final maxDate = widget.points.last.date;
    final dateRange = maxDate.difference(minDate).inDays;

    // Check milestones first (they're vertical lines, easier to hit)
    for (final milestone in widget.milestones) {
      final dayOffset = milestone.date.difference(minDate).inDays;
      final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : graphWidth / 2);

      if ((position.dx - x).abs() < 15) {
        return (null, milestone);
      }
    }

    // Find handicap range
    final minHc = widget.points.map((p) => p.handicap).reduce((a, b) => a < b ? a : b);
    final maxHc = widget.points.map((p) => p.handicap).reduce((a, b) => a > b ? a : b);
    final hcRange = maxHc - minHc;
    final paddedMin = (minHc - (hcRange * 0.1)).clamp(0, 150).toInt();
    final paddedMax = (maxHc + (hcRange * 0.1)).clamp(0, 150).toInt();
    final paddedRange = paddedMax - paddedMin;

    _ScorePoint? nearest;
    double nearestDist = double.infinity;

    for (final point in widget.points) {
      final dayOffset = point.date.difference(minDate).inDays;
      final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : graphWidth / 2);
      final normalizedHc = paddedRange > 0 ? (paddedMax - point.handicap) / paddedRange : 0.5;
      final y = graphHeight - (normalizedHc * graphHeight);

      final dist = (Offset(x, y) - position).distance;
      if (dist < nearestDist && dist < 30) {
        nearestDist = dist;
        nearest = point;
      }
    }

    return (nearest, null);
  }
}

class _ScoresGraphPainter extends CustomPainter {
  final List<_ScorePoint> points;
  final List<Milestone> milestones;
  final _ScorePoint? selectedPoint;
  final Milestone? selectedMilestone;

  static const Color indoorColor = Color(0xFFE53935); // Red
  static const Color outdoorColor = Color(0xFF42A5F5); // Blue

  _ScoresGraphPainter({
    required this.points,
    required this.milestones,
    this.selectedPoint,
    this.selectedMilestone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPadding = 40.0;
    const bottomPadding = 30.0;
    final graphWidth = size.width - leftPadding;
    final graphHeight = size.height - bottomPadding;

    // Find ranges
    final minDate = points.first.date;
    final maxDate = points.last.date;
    final dateRange = maxDate.difference(minDate).inDays;

    final minHc = points.map((p) => p.handicap).reduce((a, b) => a < b ? a : b);
    final maxHc = points.map((p) => p.handicap).reduce((a, b) => a > b ? a : b);
    final hcRange = maxHc - minHc;
    final paddedMin = (minHc - (hcRange * 0.1)).clamp(0, 150).toInt();
    final paddedMax = (maxHc + (hcRange * 0.1)).clamp(0, 150).toInt();
    final paddedRange = paddedMax - paddedMin;

    // Draw grid lines and Y-axis labels (handicap)
    _drawGrid(canvas, size, graphWidth, graphHeight, leftPadding, paddedMin, paddedMax, paddedRange);

    // Draw X-axis labels (dates)
    _drawXAxis(canvas, size, graphWidth, graphHeight, leftPadding, bottomPadding, minDate, maxDate, dateRange);

    // Draw milestone lines
    _drawMilestones(canvas, graphWidth, graphHeight, leftPadding, minDate, dateRange);

    // Draw year separator lines
    _drawYearLines(canvas, graphWidth, graphHeight, leftPadding, minDate, maxDate, dateRange);

    // Draw points
    for (final point in points) {
      final dayOffset = point.date.difference(minDate).inDays;
      final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : graphWidth / 2);
      final normalizedHc = paddedRange > 0 ? (paddedMax - point.handicap) / paddedRange : 0.5;
      final y = graphHeight - (normalizedHc * graphHeight);

      final color = point.isIndoor ? indoorColor : outdoorColor;
      final isSelected = selectedPoint == point;

      // Draw point
      final paint = Paint()
        ..color = isSelected ? color : color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2 : 1;

      final radius = isSelected ? 6.0 : 4.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
      canvas.drawCircle(Offset(x, y), radius, strokePaint);
    }

    // Draw tooltip for selected point
    if (selectedPoint != null) {
      _drawTooltip(canvas, size, graphWidth, graphHeight, leftPadding, paddedMin, paddedMax, paddedRange, minDate, dateRange);
    }

    // Draw milestone tooltip
    if (selectedMilestone != null) {
      _drawMilestoneTooltip(canvas, size, graphWidth, graphHeight, leftPadding, minDate, dateRange);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double graphWidth, double graphHeight,
      double leftPadding, int paddedMin, int paddedMax, int paddedRange) {
    final gridPaint = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
    );

    // Draw 5 horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * graphHeight;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Y-axis label (handicap - inverted so lower is at top)
      final hc = paddedMin + ((4 - i) / 4 * paddedRange).toInt();
      final textSpan = TextSpan(text: '$hc', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding - textPainter.width - 8, y - 6));
    }
  }

  void _drawXAxis(Canvas canvas, Size size, double graphWidth, double graphHeight,
      double leftPadding, double bottomPadding, DateTime minDate, DateTime maxDate, int dateRange) {
    final textStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
    );

    // Determine appropriate labeling based on date range
    if (dateRange <= 90) {
      // For short ranges, show months
      _drawMonthLabels(canvas, size, graphWidth, graphHeight, leftPadding, minDate, maxDate, dateRange, textStyle);
    } else {
      // For longer ranges, show years
      _drawYearLabels(canvas, size, graphWidth, graphHeight, leftPadding, minDate, maxDate, dateRange, textStyle);
    }
  }

  void _drawMonthLabels(Canvas canvas, Size size, double graphWidth, double graphHeight,
      double leftPadding, DateTime minDate, DateTime maxDate, int dateRange, TextStyle textStyle) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    DateTime current = DateTime(minDate.year, minDate.month, 1);
    while (current.isBefore(maxDate)) {
      if (current.isAfter(minDate.subtract(const Duration(days: 1)))) {
        final dayOffset = current.difference(minDate).inDays;
        final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : 0);

        if (x >= leftPadding && x <= size.width - 30) {
          final label = months[current.month - 1];
          final textSpan = TextSpan(text: label, style: textStyle);
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, graphHeight + 8));
        }
      }
      current = DateTime(current.year, current.month + 1, 1);
    }
  }

  void _drawYearLabels(Canvas canvas, Size size, double graphWidth, double graphHeight,
      double leftPadding, DateTime minDate, DateTime maxDate, int dateRange, TextStyle textStyle) {
    final startYear = minDate.year;
    final endYear = maxDate.year;

    for (int year = startYear; year <= endYear; year++) {
      final yearStart = DateTime(year, 1, 1);
      if (yearStart.isBefore(minDate)) continue;

      final dayOffset = yearStart.difference(minDate).inDays;
      final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : 0);

      if (x >= leftPadding && x <= size.width - 20) {
        final textSpan = TextSpan(text: 'Jan $year', style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, graphHeight + 8));
      }
    }
  }

  void _drawYearLines(Canvas canvas, double graphWidth, double graphHeight,
      double leftPadding, DateTime minDate, DateTime maxDate, int dateRange) {
    final linePaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final startYear = minDate.year;
    final endYear = maxDate.year;

    for (int year = startYear; year <= endYear; year++) {
      final yearStart = DateTime(year, 1, 1);
      if (yearStart.isBefore(minDate)) continue;

      final dayOffset = yearStart.difference(minDate).inDays;
      final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : 0);

      if (x > leftPadding) {
        // Dashed line
        const dashHeight = 5.0;
        const gapHeight = 3.0;
        double y = 0;
        while (y < graphHeight) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, (y + dashHeight).clamp(0, graphHeight)),
            linePaint,
          );
          y += dashHeight + gapHeight;
        }
      }
    }
  }

  void _drawMilestones(Canvas canvas, double graphWidth, double graphHeight,
      double leftPadding, DateTime minDate, int dateRange) {
    for (final milestone in milestones) {
      final dayOffset = milestone.date.difference(minDate).inDays;
      final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : graphWidth / 2);

      final isSelected = selectedMilestone == milestone;

      Color lineColor;
      try {
        lineColor = Color(int.parse(milestone.color.replaceFirst('#', '0xFF')));
      } catch (_) {
        lineColor = AppColors.gold;
      }

      final linePaint = Paint()
        ..color = isSelected ? lineColor : lineColor.withValues(alpha: 0.7)
        ..strokeWidth = isSelected ? 2 : 1.5
        ..style = PaintingStyle.stroke;

      // Draw dashed vertical line
      const dashHeight = 6.0;
      const gapHeight = 4.0;
      double y = 0;
      while (y < graphHeight) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + dashHeight).clamp(0, graphHeight)),
          linePaint,
        );
        y += dashHeight + gapHeight;
      }

      // Draw small marker at top
      final markerPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, 4), isSelected ? 5 : 4, markerPaint);
    }
  }

  void _drawTooltip(Canvas canvas, Size size, double graphWidth, double graphHeight,
      double leftPadding, int paddedMin, int paddedMax, int paddedRange,
      DateTime minDate, int dateRange) {
    final point = selectedPoint!;

    final dayOffset = point.date.difference(minDate).inDays;
    final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : graphWidth / 2);
    final normalizedHc = paddedRange > 0 ? (paddedMax - point.handicap) / paddedRange : 0.5;
    final y = graphHeight - (normalizedHc * graphHeight);

    // Tooltip background
    final tooltipText = '${point.roundName}\n${point.date.day}/${point.date.month}/${point.date.year}\nHC ${point.handicap} (${point.score})';
    final textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 11,
    );
    final textSpan = TextSpan(text: tooltipText, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 150);

    final tooltipWidth = textPainter.width + 16;
    final tooltipHeight = textPainter.height + 12;

    // Position tooltip to avoid edges
    var tooltipX = x - tooltipWidth / 2;
    var tooltipY = y - tooltipHeight - 12;

    if (tooltipX < leftPadding) tooltipX = leftPadding;
    if (tooltipX + tooltipWidth > size.width) tooltipX = size.width - tooltipWidth;
    if (tooltipY < 0) tooltipY = y + 12;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(4),
    );

    final tooltipPaint = Paint()..color = AppColors.surfaceDark;
    final borderPaint = Paint()
      ..color = point.isIndoor ? indoorColor : outdoorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(tooltipRect, tooltipPaint);
    canvas.drawRRect(tooltipRect, borderPaint);

    textPainter.paint(canvas, Offset(tooltipX + 8, tooltipY + 6));
  }

  void _drawMilestoneTooltip(Canvas canvas, Size size, double graphWidth, double graphHeight,
      double leftPadding, DateTime minDate, int dateRange) {
    final milestone = selectedMilestone!;

    final dayOffset = milestone.date.difference(minDate).inDays;
    final x = leftPadding + (dateRange > 0 ? (dayOffset / dateRange) * graphWidth : graphWidth / 2);

    Color lineColor;
    try {
      lineColor = Color(int.parse(milestone.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      lineColor = AppColors.gold;
    }

    // Tooltip text
    final tooltipText = '${milestone.title}\n${milestone.date.day}/${milestone.date.month}/${milestone.date.year}${milestone.description != null ? '\n${milestone.description}' : ''}';
    final textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 11,
    );
    final textSpan = TextSpan(text: tooltipText, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 150);

    final tooltipWidth = textPainter.width + 16;
    final tooltipHeight = textPainter.height + 12;

    // Position tooltip
    var tooltipX = x - tooltipWidth / 2;
    const tooltipY = 20.0;

    if (tooltipX < leftPadding) tooltipX = leftPadding;
    if (tooltipX + tooltipWidth > size.width) tooltipX = size.width - tooltipWidth;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(4),
    );

    final tooltipPaint = Paint()..color = AppColors.surfaceDark;
    final borderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(tooltipRect, tooltipPaint);
    canvas.drawRRect(tooltipRect, borderPaint);

    textPainter.paint(canvas, Offset(tooltipX + 8, tooltipY + 6));
  }

  @override
  bool shouldRepaint(_ScoresGraphPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.milestones != milestones ||
        oldDelegate.selectedPoint != selectedPoint ||
        oldDelegate.selectedMilestone != selectedMilestone;
  }
}

class _StatsSummary extends StatelessWidget {
  final List<_ScorePoint> points;

  const _StatsSummary({required this.points});

  @override
  Widget build(BuildContext context) {
    final indoorPoints = points.where((p) => p.isIndoor).toList();
    final outdoorPoints = points.where((p) => !p.isIndoor).toList();

    final bestIndoor = indoorPoints.isEmpty
        ? null
        : indoorPoints.map((p) => p.handicap).reduce((a, b) => a < b ? a : b);
    final bestOutdoor = outdoorPoints.isEmpty
        ? null
        : outdoorPoints.map((p) => p.handicap).reduce((a, b) => a < b ? a : b);

    final avgAll = points.isEmpty
        ? 0
        : points.map((p) => p.handicap).reduce((a, b) => a + b) ~/ points.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Total Scores',
            value: '${points.length}',
          ),
          if (bestIndoor != null)
            _StatItem(
              label: 'Best Indoor',
              value: 'HC $bestIndoor',
              color: const Color(0xFFE53935),
            ),
          if (bestOutdoor != null)
            _StatItem(
              label: 'Best Outdoor',
              value: 'HC $bestOutdoor',
              color: const Color(0xFF42A5F5),
            ),
          _StatItem(
            label: 'Average',
            value: 'HC $avgAll',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color ?? AppColors.gold,
              ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No scores to display',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Import scores or complete a session\nto see your handicap progression',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ScorePoint {
  final DateTime date;
  final int handicap;
  final int score;
  final String roundName;
  final bool isIndoor;
  final bool isPlotted;

  _ScorePoint({
    required this.date,
    required this.handicap,
    required this.score,
    required this.roundName,
    required this.isIndoor,
    required this.isPlotted,
  });
}
