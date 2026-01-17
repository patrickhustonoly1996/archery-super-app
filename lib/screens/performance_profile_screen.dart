import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radar_chart.dart';
import '../providers/spider_graph_provider.dart';

class PerformanceProfileScreen extends StatefulWidget {
  const PerformanceProfileScreen({super.key});

  @override
  State<PerformanceProfileScreen> createState() =>
      _PerformanceProfileScreenState();
}

class _PerformanceProfileScreenState extends State<PerformanceProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpiderGraphProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Profile'),
        actions: [
          Consumer<SpiderGraphProvider>(
            builder: (context, provider, _) => PopupMenuButton<int>(
              initialValue: provider.timeWindowDays,
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Time range',
              onSelected: (days) {
                provider.setTimeWindow(days);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 7, child: Text('Last 7 days')),
                const PopupMenuItem(value: 30, child: Text('Last 30 days')),
                const PopupMenuItem(value: 90, child: Text('Last 90 days')),
                const PopupMenuItem(value: 365, child: Text('Last year')),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<SpiderGraphProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.data.hasData) {
            return _buildEmptyState(context, provider);
          }

          return _buildContent(context, provider);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SpiderGraphProvider provider) {
    final data = provider.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(provider),
          const SizedBox(height: AppSpacing.lg),
          _buildRadarCard(data),
          const SizedBox(height: AppSpacing.lg),
          _buildMetricsGrid(data),
          const SizedBox(height: AppSpacing.lg),
          _buildTargetToggle(provider),
        ],
      ),
    );
  }

  Widget _buildHeader(SpiderGraphProvider provider) {
    final data = provider.data;
    final spokesWithData = data.dataCount;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last ${provider.timeWindowDays} days',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$spokesWithData of 8 metrics tracked',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Column(
            children: [
              Text(
                _calculateOverallScore(data).toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              Text(
                'Overall',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateOverallScore(SpiderData data) {
    final values = data.values.where((v) => v != null).toList();
    if (values.isEmpty) return 0;
    return values.fold<double>(0, (sum, v) => sum + v!) / values.length;
  }

  Widget _buildRadarCard(SpiderData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: RadarChart(
            datasets: [
              RadarChartData(
                label: 'Current',
                points: _dataToRadarPoints(data),
                color: AppColors.gold,
                showFill: true,
              ),
            ],
            size: 300,
            gridLevels: 4,
            showLabels: true,
            showValues: false,
          ),
        ),
      ),
    );
  }

  List<RadarDataPoint> _dataToRadarPoints(SpiderData data) {
    return [
      RadarDataPoint(
        label: 'Score',
        value: (data.scoreLevel ?? 0) / 100,
        displayValue: data.scoreLevel != null ? '${data.scoreLevel!.toStringAsFixed(0)}%' : '-',
      ),
      RadarDataPoint(
        label: 'Volume',
        value: (data.trainingVolume ?? 0) / 100,
        displayValue: data.trainingVolume != null ? '${data.trainingVolume!.toStringAsFixed(0)}%' : '-',
      ),
      RadarDataPoint(
        label: 'Frequency',
        value: (data.trainingFrequency ?? 0) / 100,
        displayValue: data.trainingFrequency != null ? '${data.trainingFrequency!.toStringAsFixed(0)}%' : '-',
      ),
      RadarDataPoint(
        label: 'Bow Fitness',
        value: (data.bowFitness ?? 0) / 100,
        displayValue: data.bowFitness != null ? '${data.bowFitness!.toStringAsFixed(0)}%' : '-',
      ),
      RadarDataPoint(
        label: 'Form',
        value: (data.formQuality ?? 0) / 100,
        displayValue: data.formQuality != null ? '${data.formQuality!.toStringAsFixed(0)}%' : '-',
      ),
      RadarDataPoint(
        label: 'Stability',
        value: (data.stability ?? 0) / 100,
        displayValue: data.stability != null ? '${data.stability!.toStringAsFixed(0)}%' : '-',
      ),
      RadarDataPoint(
        label: 'Breath Hold',
        value: (data.breathHold ?? 0) / 100,
        displayValue: data.breathHold != null ? '${data.breathHold!.toStringAsFixed(0)}%' : '-',
      ),
      RadarDataPoint(
        label: 'Exhale',
        value: (data.breathExhale ?? 0) / 100,
        displayValue: data.breathExhale != null ? '${data.breathExhale!.toStringAsFixed(0)}%' : '-',
      ),
    ];
  }

  Widget _buildMetricsGrid(SpiderData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metrics Breakdown',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Row 1: Score and Volume
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Score Level',
                value: data.scoreLevel != null ? '${data.scoreLevel!.toStringAsFixed(0)}%' : '-',
                description: 'Best handicap',
                icon: Icons.emoji_events,
                hasData: data.scoreLevel != null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'Volume',
                value: data.trainingVolume != null ? '${data.trainingVolume!.toStringAsFixed(0)}%' : '-',
                description: 'Arrows per week',
                icon: Icons.show_chart,
                hasData: data.trainingVolume != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Row 2: Frequency and Bow Fitness
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Frequency',
                value: data.trainingFrequency != null ? '${data.trainingFrequency!.toStringAsFixed(0)}%' : '-',
                description: 'Days per week',
                icon: Icons.calendar_month,
                hasData: data.trainingFrequency != null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'Bow Fitness',
                value: data.bowFitness != null ? '${data.bowFitness!.toStringAsFixed(0)}%' : '-',
                description: 'Hold time',
                icon: Icons.fitness_center,
                hasData: data.bowFitness != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Row 3: Form and Stability
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Form Quality',
                value: data.formQuality != null ? '${data.formQuality!.toStringAsFixed(0)}%' : '-',
                description: 'Structure rating',
                icon: Icons.accessibility_new,
                hasData: data.formQuality != null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'Stability',
                value: data.stability != null ? '${data.stability!.toStringAsFixed(0)}%' : '-',
                description: 'Shaking rating',
                icon: Icons.straighten,
                hasData: data.stability != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Row 4: Breath Hold and Exhale
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Breath Hold',
                value: data.breathHold != null ? '${data.breathHold!.toStringAsFixed(0)}%' : '-',
                description: 'Best hold time',
                icon: Icons.air,
                hasData: data.breathHold != null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'Exhale',
                value: data.breathExhale != null ? '${data.breathExhale!.toStringAsFixed(0)}%' : '-',
                description: 'Best exhale time',
                icon: Icons.waves,
                hasData: data.breathExhale != null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetToggle(SpiderGraphProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Level',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Metrics are scaled against these targets',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _TargetChip(
                  label: 'Standard',
                  isSelected: !provider.useEliteTargets,
                  onTap: () => provider.setEliteMode(false),
                ),
                const SizedBox(width: AppSpacing.sm),
                _TargetChip(
                  label: 'Elite',
                  isSelected: provider.useEliteTargets,
                  onTap: () => provider.setEliteMode(true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTargetDetails(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetDetails(SpiderGraphProvider provider) {
    final targets = provider.targets;
    return Column(
      children: [
        _TargetRow(label: 'Arrows/week', value: '${targets.arrowsPerWeek}'),
        _TargetRow(label: 'Training days', value: '${targets.trainingDaysPerWeek}/week'),
        _TargetRow(label: 'Hold time', value: '${targets.holdMinutesPerWeek} min/week'),
        _TargetRow(label: 'Breath hold', value: '${targets.breathHoldSeconds}s'),
        _TargetRow(label: 'Exhale', value: '${targets.breathExhaleSeconds}s'),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, SpiderGraphProvider provider) {
    // Create sample data for demonstration
    final sampleData = SpiderData(
      scoreLevel: 45,      // Intermediate handicap
      trainingVolume: 60,  // ~360 arrows/week
      trainingFrequency: 57, // ~4 days/week
      bowFitness: 40,      // ~8 min hold/week
      formQuality: 65,     // Decent form
      stability: 55,       // Moderate stability
      breathHold: 25,      // 15s hold
      breathExhale: 30,    // 18s exhale
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sample indicator banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.gold,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Sample profile shown. Train with the app to see your data populate.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Sample header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample: Intermediate Archer',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '8 of 8 metrics tracked',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Column(
                  children: [
                    Text(
                      '47',
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Overall',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Sample radar chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: RadarChart(
                  datasets: [
                    RadarChartData(
                      label: 'Sample',
                      points: _dataToRadarPoints(sampleData),
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      showFill: true,
                    ),
                  ],
                  size: 300,
                  gridLevels: 4,
                  showLabels: true,
                  showValues: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // What data comes from where
          Text(
            'Data Sources',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DataSourceTile(
            spoke: 'Score Level',
            source: 'Scoring sessions & imported scores',
            icon: Icons.emoji_events,
          ),
          _DataSourceTile(
            spoke: 'Volume',
            source: 'Arrow volume tracking',
            icon: Icons.show_chart,
          ),
          _DataSourceTile(
            spoke: 'Frequency',
            source: 'All training activities',
            icon: Icons.calendar_month,
          ),
          _DataSourceTile(
            spoke: 'Bow Fitness',
            source: 'Bow training sessions',
            icon: Icons.fitness_center,
          ),
          _DataSourceTile(
            spoke: 'Form & Stability',
            source: 'Bow training feedback',
            icon: Icons.accessibility_new,
          ),
          _DataSourceTile(
            spoke: 'Breath Hold & Exhale',
            source: 'Breath training sessions',
            icon: Icons.air,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final IconData icon;
  final bool hasData;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    this.hasData = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: hasData ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: hasData ? AppColors.textSecondary : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: hasData ? AppColors.gold : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TargetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
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
          color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.gold : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final String label;
  final String value;

  const _TargetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSourceTile extends StatelessWidget {
  final String spoke;
  final String source;
  final IconData icon;

  const _DataSourceTile({
    required this.spoke,
    required this.source,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spoke,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
