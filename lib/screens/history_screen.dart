import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../widgets/handicap_chart.dart';
import '../utils/handicap_calculator.dart';
import 'session_detail_screen.dart';
import 'import_screen.dart';

/// Unified score entry combining plotted sessions and imported scores
class UnifiedScore {
  final DateTime date;
  final int score;
  final int? handicap;
  final String roundName;
  final String? roundTypeId;
  final int? xCount;
  final bool isIndoor;
  final bool isCompetition;
  final bool isPlotted;
  final String? location;
  final Session? session;
  final RoundType? roundType;

  UnifiedScore({
    required this.date,
    required this.score,
    required this.handicap,
    required this.roundName,
    required this.roundTypeId,
    required this.xCount,
    required this.isIndoor,
    required this.isCompetition,
    required this.isPlotted,
    this.location,
    this.session,
    this.roundType,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Session> _sessions = [];
  List<ImportedScore> _importedScores = [];
  Map<String, RoundType> _roundTypes = {};
  bool _isLoading = true;

  // Filters
  bool _showIndoor = true;
  bool _showOutdoor = true;
  bool _showCompetition = true;
  bool _showPractice = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = context.read<AppDatabase>();
    final sessions = await db.getCompletedSessions();
    final imported = await db.getAllImportedScores();
    final allRoundTypes = await db.getAllRoundTypes();

    // Create lookup map for round types
    final roundTypesMap = <String, RoundType>{};
    for (final rt in allRoundTypes) {
      roundTypesMap[rt.id] = rt;
    }

    setState(() {
      _sessions = sessions;
      _importedScores = imported;
      _roundTypes = roundTypesMap;
      _isLoading = false;
    });
  }

  /// Match imported round name to round type ID (same logic as handicap_chart)
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

  /// Build unified list of all scores
  List<UnifiedScore> _buildUnifiedScores() {
    final scores = <UnifiedScore>[];

    // Add plotted sessions
    for (final session in _sessions) {
      final roundType = _roundTypes[session.roundTypeId];
      final handicap = HandicapCalculator.calculateHandicap(
        session.roundTypeId,
        session.totalScore,
      );
      final isIndoor = roundType?.isIndoor ??
          HandicapCalculator.isIndoor(session.roundTypeId);
      final isCompetition = session.sessionType == 'competition';

      scores.add(UnifiedScore(
        date: session.startedAt,
        score: session.totalScore,
        handicap: handicap,
        roundName: roundType?.name ?? session.roundTypeId,
        roundTypeId: session.roundTypeId,
        xCount: session.totalXs > 0 ? session.totalXs : null,
        isIndoor: isIndoor,
        isCompetition: isCompetition,
        isPlotted: true,
        location: session.location,
        session: session,
        roundType: roundType,
      ));
    }

    // Add imported scores
    for (final imported in _importedScores) {
      final roundTypeId = _matchRoundName(imported.roundName);
      final handicap = roundTypeId != null
          ? HandicapCalculator.calculateHandicap(roundTypeId, imported.score)
          : null;
      final isIndoor = roundTypeId != null
          ? HandicapCalculator.isIndoor(roundTypeId)
          : _guessIndoorFromName(imported.roundName);
      final isCompetition = imported.sessionType == 'competition';

      scores.add(UnifiedScore(
        date: imported.date,
        score: imported.score,
        handicap: handicap,
        roundName: imported.roundName,
        roundTypeId: roundTypeId,
        xCount: imported.xCount,
        isIndoor: isIndoor,
        isCompetition: isCompetition,
        isPlotted: false,
        location: imported.location,
      ));
    }

    // Sort by date (most recent first)
    scores.sort((a, b) => b.date.compareTo(a.date));

    return scores;
  }

  /// Guess if a round is indoor from the name
  bool _guessIndoorFromName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('indoor') ||
        lower.contains('18m') ||
        lower.contains('25m') ||
        lower.contains('portsmouth') ||
        lower.contains('worcester') ||
        lower.contains('vegas');
  }

  /// Filter scores based on current filter settings
  List<UnifiedScore> _filterScores(List<UnifiedScore> scores) {
    return scores.where((s) {
      if (s.isIndoor && !_showIndoor) return false;
      if (!s.isIndoor && !_showOutdoor) return false;
      if (s.isCompetition && !_showCompetition) return false;
      if (!s.isCompetition && !_showPractice) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scores Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import Scores',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              );
              _loadHistory();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _sessions.isEmpty && _importedScores.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: AppColors.gold,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final allScores = _buildUnifiedScores();
    final filteredScores = _filterScores(allScores);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Handicap progression chart
        if (allScores.isNotEmpty) ...[
          HandicapChart(
            sessions: _sessions,
            importedScores: _importedScores,
            roundTypes: _roundTypes,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Filter chips
        _buildFilterChips(allScores),
        const SizedBox(height: AppSpacing.md),

        // Score count
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            '${filteredScores.length} scores',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.gold,
                ),
          ),
        ),

        // Unified score list
        ...filteredScores.map((s) => _UnifiedScoreTile(
              score: s,
              onTap: s.isPlotted && s.session != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SessionDetailScreen(
                            session: s.session!,
                            roundType: s.roundType,
                          ),
                        ),
                      );
                    }
                  : null,
            )),
      ],
    );
  }

  Widget _buildFilterChips(List<UnifiedScore> allScores) {
    // Count scores by category
    final indoorCount = allScores.where((s) => s.isIndoor).length;
    final outdoorCount = allScores.where((s) => !s.isIndoor).length;
    final compCount = allScores.where((s) => s.isCompetition).length;
    final practiceCount = allScores.where((s) => !s.isCompetition).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Venue type row
        Row(
          children: [
            _FilterChip(
              label: 'Indoor',
              count: indoorCount,
              isSelected: _showIndoor,
              color: AppColors.cyan,
              onTap: () => setState(() => _showIndoor = !_showIndoor),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Outdoor',
              count: outdoorCount,
              isSelected: _showOutdoor,
              color: AppColors.magenta,
              onTap: () => setState(() => _showOutdoor = !_showOutdoor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Session type row
        Row(
          children: [
            _FilterChip(
              label: 'Competition',
              count: compCount,
              isSelected: _showCompetition,
              color: AppColors.gold,
              onTap: () => setState(() => _showCompetition = !_showCompetition),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Practice',
              count: practiceCount,
              isSelected: _showPractice,
              color: AppColors.textSecondary,
              onTap: () => setState(() => _showPractice = !_showPractice),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? color : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  /// Generate sample score data for demonstration
  List<_SampleScore> _generateSampleScores() {
    final now = DateTime.now();
    return [
      _SampleScore(
        date: now.subtract(const Duration(days: 2)),
        roundName: 'WA 720 70m',
        score: 658,
        handicap: 32,
        isIndoor: false,
        isCompetition: false,
      ),
      _SampleScore(
        date: now.subtract(const Duration(days: 7)),
        roundName: 'Portsmouth',
        score: 572,
        handicap: 28,
        isIndoor: true,
        isCompetition: true,
      ),
      _SampleScore(
        date: now.subtract(const Duration(days: 12)),
        roundName: 'WA 720 70m',
        score: 645,
        handicap: 35,
        isIndoor: false,
        isCompetition: false,
      ),
      _SampleScore(
        date: now.subtract(const Duration(days: 18)),
        roundName: 'Portsmouth',
        score: 568,
        handicap: 29,
        isIndoor: true,
        isCompetition: false,
      ),
      _SampleScore(
        date: now.subtract(const Duration(days: 25)),
        roundName: 'WA 18m',
        score: 565,
        handicap: 30,
        isIndoor: true,
        isCompetition: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sampleScores = _generateSampleScores();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demo mode banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.gold, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Sample Scores Preview',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'This shows what your score history will look like. Record sessions or import scores to track your progress.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Sample score tiles (faded)
          Opacity(
            opacity: 0.6,
            child: Column(
              children: sampleScores.map((s) => _SampleScoreTile(score: s)).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Call to action
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Column(
              children: [
                Text(
                  'Start Tracking Your Scores',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Record sessions in the app or import historical scores to track handicap progression.',
                  style: TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ImportScreen()),
                      );
                    },
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import Score History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
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

class _SampleScore {
  final DateTime date;
  final String roundName;
  final int score;
  final int handicap;
  final bool isIndoor;
  final bool isCompetition;

  _SampleScore({
    required this.date,
    required this.roundName,
    required this.score,
    required this.handicap,
    required this.isIndoor,
    required this.isCompetition,
  });
}

class _SampleScoreTile extends StatelessWidget {
  final _SampleScore score;

  const _SampleScoreTile({required this.score});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${score.date.day}/${score.date.month}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Round info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score.roundName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: score.isIndoor ? AppColors.cyan : AppColors.magenta,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        score.isIndoor ? 'Indoor' : 'Outdoor',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (score.isCompetition) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Comp',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Score and handicap
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.score}',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'HC ${score.handicap}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedScoreTile extends StatelessWidget {
  final UnifiedScore score;
  final VoidCallback? onTap;

  const _UnifiedScoreTile({required this.score, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${score.date.day}/${score.date.month}/${score.date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Handicap prominently displayed
              _HandicapBox(
                handicap: score.handicap,
                isPlotted: score.isPlotted,
              ),

              const SizedBox(width: AppSpacing.md),

              // Details column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Round name
                    Text(
                      score.roundName,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    // Date and location
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (score.location != null) ...[
                          Text(
                            '  •  ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Expanded(
                            child: Text(
                              score.location!,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Category badges
                    Row(
                      children: [
                        _CategoryBadge(
                          label: score.isIndoor ? 'Indoor' : 'Outdoor',
                          color: score.isIndoor
                              ? AppColors.cyan
                              : AppColors.magenta,
                        ),
                        const SizedBox(width: 6),
                        _CategoryBadge(
                          label: score.isCompetition ? 'Comp' : 'Practice',
                          color: score.isCompetition
                              ? AppColors.gold
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Score and X count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.score.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (score.xCount != null && score.xCount! > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${score.xCount}X',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandicapBox extends StatelessWidget {
  final int? handicap;
  final bool isPlotted;

  const _HandicapBox({required this.handicap, required this.isPlotted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isPlotted
            ? AppColors.gold.withOpacity(0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color:
              isPlotted ? AppColors.gold.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            handicap != null ? 'HC $handicap' : '--',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isPlotted ? AppColors.gold : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
