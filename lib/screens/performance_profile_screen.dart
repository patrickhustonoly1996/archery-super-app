import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../widgets/radar_chart.dart';
import '../utils/performance_profile.dart';

class PerformanceProfileScreen extends StatefulWidget {
  const PerformanceProfileScreen({super.key});

  @override
  State<PerformanceProfileScreen> createState() =>
      _PerformanceProfileScreenState();
}

class _PerformanceProfileScreenState extends State<PerformanceProfileScreen> {
  bool _isLoading = true;
  PerformanceProfile? _currentProfile;
  PerformanceProfile? _comparisonProfile;
  int _selectedDays = 30;
  _ComparisonMode _comparisonMode = _ComparisonMode.none;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);

    final db = Provider.of<AppDatabase>(context, listen: false);

    // Load current profile based on selected days
    final currentProfile = await PerformanceProfileCalculator.getRecentProfile(
      db: db,
      days: _selectedDays,
    );

    // Load comparison profile if needed
    PerformanceProfile? comparisonProfile;
    switch (_comparisonMode) {
      case _ComparisonMode.best:
        comparisonProfile = await PerformanceProfileCalculator.getBestSessionProfile(db: db);
        break;
      case _ComparisonMode.allTime:
        comparisonProfile = await PerformanceProfileCalculator.getAllTimeProfile(db: db);
        break;
      case _ComparisonMode.none:
        break;
    }

    if (mounted) {
      setState(() {
        _currentProfile = currentProfile;
        _comparisonProfile = comparisonProfile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Profile'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedDays,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Time range',
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadProfiles();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
              const PopupMenuItem(value: 365, child: Text('Last year')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_currentProfile == null || !_currentProfile!.hasData) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.lg),
          _buildRadarCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildMetricsGrid(),
          const SizedBox(height: AppSpacing.lg),
          _buildComparisonToggle(),
          if (_comparisonProfile != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildComparisonLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radar,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No session data yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Complete some scoring sessions to see\nyour performance profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final profile = _currentProfile!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last $_selectedDays days',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.sessionCount} session${profile.sessionCount == 1 ? '' : 's'} · ${profile.arrowCount} arrows',
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
                '${profile.scorePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              Text(
                'Score',
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

  Widget _buildRadarCard() {
    final datasets = <RadarChartData>[];

    // Current profile
    if (_currentProfile != null) {
      datasets.add(_currentProfile!.toRadarChartData(label: 'Current'));
    }

    // Comparison profile
    if (_comparisonProfile != null && _comparisonMode != _ComparisonMode.none) {
      datasets.add(RadarChartData(
        label: _comparisonMode == _ComparisonMode.best ? 'Best' : 'All Time',
        points: _comparisonProfile!.toRadarPoints(),
        color: AppColors.textSecondary.withValues(alpha: 0.6),
        showFill: false,
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: RadarChart(
            datasets: datasets,
            size: 280,
            gridLevels: 4,
            showLabels: true,
            showValues: false,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final profile = _currentProfile!;

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
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Accuracy',
                value: '${profile.accuracy.toStringAsFixed(1)}%',
                description: 'Shots in gold (9-10)',
                icon: Icons.gps_fixed,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'X-Rate',
                value: '${profile.xRate.toStringAsFixed(1)}%',
                description: 'Shots in X ring',
                icon: Icons.center_focus_strong,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Consistency',
                value: '${profile.consistency.toStringAsFixed(0)}%',
                description: 'Shot-to-shot stability',
                icon: Icons.straighten,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                label: 'Grouping',
                value: '${profile.grouping.toStringAsFixed(0)}%',
                description: 'Arrow group tightness',
                icon: Icons.filter_tilt_shift,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare Against',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _ComparisonChip(
                  label: 'None',
                  isSelected: _comparisonMode == _ComparisonMode.none,
                  onTap: () {
                    setState(() => _comparisonMode = _ComparisonMode.none);
                    _loadProfiles();
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _ComparisonChip(
                  label: 'Best Session',
                  isSelected: _comparisonMode == _ComparisonMode.best,
                  onTap: () {
                    setState(() => _comparisonMode = _ComparisonMode.best);
                    _loadProfiles();
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _ComparisonChip(
                  label: 'All Time',
                  isSelected: _comparisonMode == _ComparisonMode.allTime,
                  onTap: () {
                    setState(() => _comparisonMode = _ComparisonMode.allTime);
                    _loadProfiles();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonLegend() {
    final comparison = _comparisonProfile!;
    final label = _comparisonMode == _ComparisonMode.best ? 'Best Session' : 'All Time';

    return Card(
      color: AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${comparison.sessionCount} session${comparison.sessionCount == 1 ? '' : 's'} · ${comparison.scorePercent.toStringAsFixed(0)}% score',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
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
}

enum _ComparisonMode { none, best, allTime }

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
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
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
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
              color: AppColors.gold,
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

class _ComparisonChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ComparisonChip({
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
