import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../utils/shaft_analysis.dart';

class ShaftAnalysisScreen extends StatefulWidget {
  final Quiver quiver;
  final List<Arrow> arrows; // All arrows shot with this quiver

  const ShaftAnalysisScreen({
    super.key,
    required this.quiver,
    required this.arrows,
  });

  @override
  State<ShaftAnalysisScreen> createState() => _ShaftAnalysisScreenState();
}

class _ShaftAnalysisScreenState extends State<ShaftAnalysisScreen> {
  List<ShaftAnalysisResult>? _results;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _loading = true);

    final equipmentProvider = context.read<EquipmentProvider>();
    final shafts = equipmentProvider.getShaftsForQuiver(widget.quiver.id);

    final results = await ShaftAnalysis.analyzeQuiver(
      shafts: shafts,
      allArrows: widget.arrows,
    );

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.quiver.name} Analysis'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnalysisContent(),
    );
  }

  Widget _buildAnalysisContent() {
    if (_results == null || _results!.isEmpty) {
      return const Center(
        child: Text('No shaft data available'),
      );
    }

    final hasData = _results!.any((r) => r.arrowCount > 0);
    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No arrows tracked yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enable shaft tagging in sessions to track individual arrow performance',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final overlapWarning = ShaftAnalysis.getOverlapWarning(_results!);
    final retirementCandidates = ShaftAnalysis.getRetirementCandidates(_results!);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary
        _buildSummaryCard(),

        if (overlapWarning != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildWarningCard(overlapWarning),
        ],

        if (retirementCandidates.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildRetirementCard(retirementCandidates),
        ],

        const SizedBox(height: AppSpacing.lg),
        Text(
          'Individual Shaft Performance',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),

        // Individual shaft results
        ..._results!.where((r) => r.arrowCount > 0).map(_buildShaftCard),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalArrows = widget.arrows.length;
    final trackedArrows = _results!.fold<int>(0, (sum, r) => sum + r.arrowCount);
    final avgScore = widget.arrows.isEmpty
        ? 0.0
        : widget.arrows.map((a) => a.score).reduce((a, b) => a + b) / widget.arrows.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Summary',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStatRow('Total arrows', totalArrows.toString()),
          _buildStatRow('Tracked with shaft IDs', trackedArrows.toString()),
          _buildStatRow('Average score', avgScore.toStringAsFixed(2)),
          _buildStatRow('Active shafts', '${_results!.where((r) => r.arrowCount > 0).length}'),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String warning) {
    return Card(
      color: AppColors.gold.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.gold),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  warning,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementCard(List<Shaft> candidates) {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_outlined, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retirement Candidates',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Shafts ${candidates.map((s) => s.number).join(', ')} show significantly worse performance',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShaftCard(ShaftAnalysisResult result) {
    final Color indicatorColor;
    switch (result.performanceColor) {
      case 'green':
        indicatorColor = AppColors.gold;
        break;
      case 'yellow':
        indicatorColor = Colors.yellow.shade700;
        break;
      case 'red':
        indicatorColor = AppColors.error;
        break;
      default:
        indicatorColor = AppColors.textMuted;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              // Shaft number
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: indicatorColor.withOpacity(0.2),
                  border: Border.all(color: indicatorColor, width: 2),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Center(
                  child: Text(
                    result.shaft.number.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: indicatorColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result.arrowCount} arrows',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Avg score: ${result.avgScore.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Group spread: ${result.groupSpreadMm.toStringAsFixed(1)}mm',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Performance indicator
              Icon(
                result.shouldRetire
                    ? Icons.warning
                    : Icons.check_circle_outline,
                color: indicatorColor,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Recommendation
          Text(
            result.recommendation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),

          // Score distribution
          if (result.scoreDistribution.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Score distribution:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: result.scoreDistribution.entries.map((entry) {
                return Chip(
                  label: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.surfaceLight,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
