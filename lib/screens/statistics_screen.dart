import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/offline_indicator.dart';
import '../utils/volume_calculator.dart';
import '../providers/connectivity_provider.dart';
import 'volume_upload_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<VolumeEntry> _volumeEntries = [];
  bool _isLoading = true;
  int _selectedDays = 90; // Default to 90 days view

  @override
  void initState() {
    super.initState();
    _loadVolumeData();
  }

  Future<void> _loadVolumeData() async {
    setState(() => _isLoading = true);

    final db = Provider.of<AppDatabase>(context, listen: false);
    final entries = await db.getAllVolumeEntries();

    setState(() {
      _volumeEntries = entries;
      _isLoading = false;
    });
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VolumeUploadScreen()),
    );

    // Refresh data if import was successful
    if (result == true) {
      _loadVolumeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Volume'),
        actions: [
          // Offline indicator
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, _) => OfflineIndicator(
              isOffline: connectivity.isOffline,
              isSyncing: connectivity.isSyncing,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Bulk Upload',
            onPressed: () => _navigateToUpload(),
          ),
          PopupMenuButton<int>(
            initialValue: _selectedDays,
            icon: const Icon(Icons.filter_list),
            onSelected: (days) {
              setState(() => _selectedDays = days);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 30, child: Text('30 Days')),
              const PopupMenuItem(value: 90, child: Text('90 Days')),
              const PopupMenuItem(value: 180, child: Text('180 Days')),
              const PopupMenuItem(value: 365, child: Text('1 Year')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _volumeEntries.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVolumeDialog(),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.backgroundDark,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.bar_chart,
      title: 'No volume data yet',
      subtitle: 'Track your daily arrow count to monitor training load',
      actionLabel: 'Add Volume Entry',
      onAction: _showAddVolumeDialog,
    );
  }

  Widget _buildContent() {
    // Filter data to selected time range
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedDays));

    final filteredEntries = _volumeEntries
        .where((entry) => entry.date.isAfter(startDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (filteredEntries.isEmpty) {
      return Center(
        child: Text(
          'No data for the last $_selectedDays days',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Convert to DailyVolume format for calculations
    final dailyVolumes = filteredEntries
        .map((e) => DailyVolume(
              date: e.date,
              arrowCount: e.arrowCount,
              notes: e.notes,
            ))
        .toList();

    final metrics = VolumeCalculator.calculateAllMetrics(dailyVolumes);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(dailyVolumes, metrics),
          const SizedBox(height: AppSpacing.lg),
          _buildVolumeChartWithEMA(filteredEntries, metrics),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentEntries(filteredEntries),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<DailyVolume> data, VolumeMetrics metrics) {
    final total7Days = VolumeCalculator.calculateRollingSum(data, 7);
    final avg7Days = VolumeCalculator.calculateRollingAverage(data, 7);
    final current7EMA = metrics.ema7.isNotEmpty ? metrics.ema7.last : 0.0;
    final current28EMA = metrics.ema28.isNotEmpty ? metrics.ema28.last : 0.0;
    final current90EMA = metrics.ema90.isNotEmpty ? metrics.ema90.last : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Last 7 Days',
                '$total7Days',
                'arrows',
                AppColors.gold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                '7-Day Avg',
                avg7Days.toStringAsFixed(1),
                'per day',
                AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '7-Day EMA',
                current7EMA.toStringAsFixed(1),
                'arrows',
                Colors.red,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                '28-Day EMA',
                current28EMA.toStringAsFixed(1),
                'arrows',
                Colors.black,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                '90-Day EMA',
                current90EMA.toStringAsFixed(1),
                'arrows',
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChartWithEMA(List<VolumeEntry> entries, VolumeMetrics metrics) {
    // Calculate bar width based on number of entries
    final barWidth = entries.length > 60 ? 4.0 : entries.length > 30 ? 6.0 : 10.0;

    // Round EMA values to whole numbers
    final ema7Rounded = metrics.ema7.map((v) => v.roundToDouble()).toList();
    final ema28Rounded = metrics.ema28.map((v) => v.roundToDouble()).toList();
    final ema90Rounded = metrics.ema90.map((v) => v.roundToDouble()).toList();

    // Find max value for Y axis scaling
    double maxY = 0;
    for (final entry in entries) {
      if (entry.arrowCount > maxY) maxY = entry.arrowCount.toDouble();
    }
    for (final val in ema7Rounded) {
      if (val > maxY) maxY = val;
    }
    for (final val in ema28Rounded) {
      if (val > maxY) maxY = val;
    }
    for (final val in ema90Rounded) {
      if (val > maxY) maxY = val;
    }
    // Round up to nearest 50 for clean intervals
    maxY = ((maxY / 50).ceil() * 50).toDouble();
    if (maxY < 50) maxY = 50;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Training Volume',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildLegendItem('7d', Colors.red),
                const SizedBox(width: AppSpacing.sm),
                _buildLegendItem('28d', Colors.black),
                const SizedBox(width: AppSpacing.sm),
                _buildLegendItem('90d', Colors.green, isArea: true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  // Line/Area chart layer (bottom) - 90d area behind everything
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: LineChart(
                      LineChartData(
                        maxY: maxY,
                        minY: 0,
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(enabled: false),
                        lineBarsData: [
                          // 90-day EMA as area chart (green fill)
                          if (ema90Rounded.isNotEmpty)
                            LineChartBarData(
                              spots: ema90Rounded.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value);
                              }).toList(),
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withOpacity(0.25),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Bar chart layer (middle)
                  BarChart(
                    BarChartData(
                      maxY: maxY,
                      barGroups: entries.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.arrowCount.toDouble(),
                              color: AppColors.gold.withOpacity(0.7),
                              width: barWidth,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.surfaceLight,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceDark,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final entry = entries[group.x];
                            return BarTooltipItem(
                              '${entry.date.day}/${entry.date.month}\n${rod.toY.toInt()} arrows',
                              TextStyle(
                                color: AppColors.gold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Line chart layer (top) - 7d and 28d EMAs
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: LineChart(
                      LineChartData(
                        maxY: maxY,
                        minY: 0,
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(enabled: false),
                        lineBarsData: [
                          // 28-day EMA (black line)
                          if (ema28Rounded.isNotEmpty)
                            LineChartBarData(
                              spots: ema28Rounded.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value);
                              }).toList(),
                              isCurved: true,
                              color: Colors.black,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                            ),
                          // 7-day EMA (red line)
                          if (ema7Rounded.isNotEmpty)
                            LineChartBarData(
                              spots: ema7Rounded.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value);
                              }).toList(),
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isArea = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: isArea ? 8 : 2,
          decoration: BoxDecoration(
            color: isArea ? color.withOpacity(0.4) : color,
            border: isArea ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEntries(List<VolumeEntry> entries) {
    final recentEntries = entries.reversed.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Entries',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...recentEntries.map((entry) => _buildEntryRow(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(VolumeEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            '${entry.date.day}/${entry.date.month}/${entry.date.year}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            '${entry.arrowCount} arrows',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.note,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddVolumeDialog() async {
    final dateController = TextEditingController();
    final arrowCountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    // Format today's date
    dateController.text =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Volume Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  selectedDate = date;
                  dateController.text = '${date.day}/${date.month}/${date.year}';
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: arrowCountController,
              decoration: const InputDecoration(
                labelText: 'Arrow Count',
                hintText: 'e.g., 120',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Competition day',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final arrowCount = int.tryParse(arrowCountController.text);
              if (arrowCount == null || arrowCount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid arrow count')),
                );
                return;
              }

              final db = Provider.of<AppDatabase>(context, listen: false);
              await db.setVolumeForDate(
                selectedDate,
                arrowCount,
                notes: notesController.text.isEmpty ? null : notesController.text,
              );

              Navigator.pop(context);
              _loadVolumeData();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Volume entry added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
