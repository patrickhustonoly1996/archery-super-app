import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../utils/shaft_analysis.dart';

/// Filter options for arrow data set
enum ArrowSetFilter {
  allTime,
  thisSession,
  last30Days,
  last90Days,
}

extension ArrowSetFilterExtension on ArrowSetFilter {
  String get label {
    switch (this) {
      case ArrowSetFilter.allTime:
        return 'All Time';
      case ArrowSetFilter.thisSession:
        return 'This Session';
      case ArrowSetFilter.last30Days:
        return 'Last 30 Days';
      case ArrowSetFilter.last90Days:
        return 'Last 90 Days';
    }
  }
}

class ShaftAnalysisScreen extends StatefulWidget {
  final Quiver quiver;
  final List<Arrow>? arrows; // Optional - if null, loads all arrows for quiver
  final String? sessionId; // Optional - highlights "This Session" filter

  const ShaftAnalysisScreen({
    super.key,
    required this.quiver,
    this.arrows,
    this.sessionId,
  });

  @override
  State<ShaftAnalysisScreen> createState() => _ShaftAnalysisScreenState();
}

class _ShaftAnalysisScreenState extends State<ShaftAnalysisScreen> {
  List<ShaftAnalysisResult>? _results;
  List<Arrow> _filteredArrows = [];
  bool _loading = true;

  // Filter state
  ArrowSetFilter _arrowSetFilter = ArrowSetFilter.allTime;
  String? _selectedRoundTypeId; // null = all round types
  List<RoundType> _availableRoundTypes = [];
  Map<String, int> _roundTypeArrowCounts = {};

  // Best arrows selection
  int _bestArrowsCount = 8; // Default to 8 for competition

  // All arrows for this quiver (cached)
  List<Arrow> _allQuiverArrows = [];
  List<Session> _quiverSessions = [];

  @override
  void initState() {
    super.initState();
    // If arrows passed in with sessionId, default to "This Session" filter
    if (widget.arrows != null && widget.sessionId != null) {
      _arrowSetFilter = ArrowSetFilter.thisSession;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final db = context.read<AppDatabase>();

    // Load all arrows for this quiver
    _allQuiverArrows = await db.getArrowsForQuiver(widget.quiver.id);

    // Load sessions that used this quiver
    final allSessions = await db.getAllSessions();
    _quiverSessions = allSessions
        .where((s) => s.quiverId == widget.quiver.id && s.shaftTaggingEnabled)
        .toList();

    // Get unique round types from sessions
    final roundTypeIds = _quiverSessions.map((s) => s.roundTypeId).toSet();
    _availableRoundTypes = [];
    _roundTypeArrowCounts = {};

    for (final id in roundTypeIds) {
      final roundType = await db.getRoundType(id);
      if (roundType != null) {
        _availableRoundTypes.add(roundType);
        // Count arrows for this round type
        final sessionsForRound = _quiverSessions.where((s) => s.roundTypeId == id);
        int arrowCount = 0;
        for (final session in sessionsForRound) {
          final sessionArrows = await db.getArrowsForSession(session.id);
          arrowCount += sessionArrows.where((a) => a.shaftId != null).length;
        }
        _roundTypeArrowCounts[id] = arrowCount;
      }
    }

    // Sort round types by arrow count (most used first)
    _availableRoundTypes.sort((a, b) =>
        (_roundTypeArrowCounts[b.id] ?? 0).compareTo(_roundTypeArrowCounts[a.id] ?? 0));

    await _applyFilters();
  }

  Future<void> _applyFilters() async {
    setState(() => _loading = true);

    final db = context.read<AppDatabase>();
    List<Arrow> arrows;

    // Apply arrow set filter
    switch (_arrowSetFilter) {
      case ArrowSetFilter.thisSession:
        if (widget.arrows != null) {
          arrows = widget.arrows!;
        } else if (widget.sessionId != null) {
          arrows = await db.getArrowsForSession(widget.sessionId!);
        } else {
          arrows = _allQuiverArrows;
        }
        break;

      case ArrowSetFilter.last30Days:
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        arrows = _allQuiverArrows.where((a) => a.createdAt.isAfter(cutoff)).toList();
        break;

      case ArrowSetFilter.last90Days:
        final cutoff = DateTime.now().subtract(const Duration(days: 90));
        arrows = _allQuiverArrows.where((a) => a.createdAt.isAfter(cutoff)).toList();
        break;

      case ArrowSetFilter.allTime:
      default:
        arrows = _allQuiverArrows;
    }

    // Apply round type filter
    if (_selectedRoundTypeId != null) {
      // Get sessions for this round type
      final sessionsForRound = _quiverSessions
          .where((s) => s.roundTypeId == _selectedRoundTypeId)
          .map((s) => s.id)
          .toSet();

      // Get ends for these sessions
      final endIds = <String>{};
      for (final sessionId in sessionsForRound) {
        final ends = await db.getEndsForSession(sessionId);
        endIds.addAll(ends.map((e) => e.id));
      }

      // Filter arrows to only those from these ends
      arrows = arrows.where((a) => endIds.contains(a.endId)).toList();
    }

    _filteredArrows = arrows;

    // Run analysis
    final equipmentProvider = context.read<EquipmentProvider>();
    final shafts = equipmentProvider.getShaftsForQuiver(widget.quiver.id);

    final results = await ShaftAnalysis.analyzeQuiver(
      shafts: shafts,
      allArrows: _filteredArrows,
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
      body: Column(
        children: [
          // Filters
          _buildFilters(),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _buildAnalysisContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBright),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arrow Set Filter
          Text(
            'ARROW SET',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ArrowSetFilter.values.map((filter) {
                // Hide "This Session" if no session context
                if (filter == ArrowSetFilter.thisSession &&
                    widget.arrows == null &&
                    widget.sessionId == null) {
                  return const SizedBox.shrink();
                }

                final isSelected = _arrowSetFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _arrowSetFilter = filter);
                        _applyFilters();
                      }
                    },
                    selectedColor: AppColors.gold.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.gold,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.gold : AppColors.textSecondary,
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Round Type Filter (only if multiple round types available)
          if (_availableRoundTypes.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'ROUND TYPE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "All" option
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text('All (${_allQuiverArrows.where((a) => a.shaftId != null).length})'),
                      selected: _selectedRoundTypeId == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedRoundTypeId = null);
                          _applyFilters();
                        }
                      },
                      selectedColor: AppColors.gold.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.gold,
                      labelStyle: TextStyle(
                        color: _selectedRoundTypeId == null
                            ? AppColors.gold
                            : AppColors.textSecondary,
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Round type options
                  ..._availableRoundTypes.map((roundType) {
                    final isSelected = _selectedRoundTypeId == roundType.id;
                    final arrowCount = _roundTypeArrowCounts[roundType.id] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text('${roundType.name} ($arrowCount)'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedRoundTypeId = roundType.id);
                            _applyFilters();
                          }
                        },
                        selectedColor: AppColors.gold.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.gold,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.gold : AppColors.textSecondary,
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
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

        // Best Arrows recommendation
        const SizedBox(height: AppSpacing.md),
        _buildBestArrowsCard(),

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

  /// Get shafts ranked by performance score
  /// Score = avgScore * 10 - (groupSpreadMm / 10) - (outlierCount * 2)
  /// Higher is better
  List<ShaftAnalysisResult> _getRankedShafts() {
    final validResults = _results!.where((r) => r.arrowCount >= 3).toList();

    // Calculate performance score for each shaft
    validResults.sort((a, b) {
      final scoreA = _calculatePerformanceScore(a);
      final scoreB = _calculatePerformanceScore(b);
      return scoreB.compareTo(scoreA); // Descending
    });

    return validResults;
  }

  double _calculatePerformanceScore(ShaftAnalysisResult result) {
    // Weight factors:
    // - Average score is most important (x10)
    // - Tight grouping is good (subtract spread penalty)
    // - Fewer outliers is better (subtract outlier penalty)
    final avgScoreWeight = result.avgScore * 10;
    final spreadPenalty = result.groupSpreadMm / 10;
    final outlierPenalty = result.outlierCount * 2;

    return avgScoreWeight - spreadPenalty - outlierPenalty;
  }

  Widget _buildBestArrowsCard() {
    final rankedShafts = _getRankedShafts();

    if (rankedShafts.isEmpty) {
      return const SizedBox.shrink();
    }

    final bestShafts = rankedShafts.take(_bestArrowsCount).toList();
    final shaftNumbers = bestShafts.map((r) => r.shaft.number).toList()..sort();

    // Calculate combined stats for best shafts
    final bestArrowCount = bestShafts.fold<int>(0, (sum, r) => sum + r.arrowCount);
    final bestAvgScore = bestShafts.isEmpty
        ? 0.0
        : bestShafts.map((r) => r.avgScore * r.arrowCount).reduce((a, b) => a + b) /
            bestArrowCount;

    return Card(
      color: AppColors.gold.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count selector
            Row(
              children: [
                Icon(Icons.emoji_events, color: AppColors.gold, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Best Arrows',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
                const Spacer(),
                // Count selector
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 6, label: Text('6')),
                    ButtonSegment(value: 8, label: Text('8')),
                    ButtonSegment(value: 12, label: Text('12')),
                  ],
                  selected: {_bestArrowsCount},
                  onSelectionChanged: (selection) {
                    setState(() => _bestArrowsCount = selection.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Best shaft numbers display
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: shaftNumbers.map((num) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.gold, width: 2),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Center(
                    child: Text(
                      num.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Stats for best set
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avg Score',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      Text(
                        bestAvgScore.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      Text(
                        '$bestArrowCount arrows',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Note about minimum data
            if (rankedShafts.length < _bestArrowsCount) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Only ${rankedShafts.length} shafts have enough data (3+ arrows)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalArrows = _filteredArrows.length;
    final trackedArrows = _results!.fold<int>(0, (sum, r) => sum + r.arrowCount);
    final avgScore = _filteredArrows.isEmpty
        ? 0.0
        : _filteredArrows.map((a) => a.score).reduce((a, b) => a + b) /
            _filteredArrows.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildStatRow('Total arrows', totalArrows.toString()),
            _buildStatRow('Tracked with shaft IDs', trackedArrows.toString()),
            _buildStatRow('Average score', avgScore.toStringAsFixed(2)),
            _buildStatRow(
                'Active shafts', '${_results!.where((r) => r.arrowCount > 0).length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard(String warning) {
    return Card(
      color: AppColors.gold.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
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
      ),
    );
  }

  Widget _buildRetirementCard(List<Shaft> candidates) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Shaft number
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: indicatorColor.withValues(alpha: 0.2),
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
                  result.shouldRetire ? Icons.warning : Icons.check_circle_outline,
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
