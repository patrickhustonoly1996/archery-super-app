import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../widgets/handicap_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/filter_chip.dart';
import '../utils/handicap_calculator.dart';
import '../utils/round_matcher.dart';
import '../utils/undo_manager.dart';
import '../providers/connectivity_provider.dart';
import '../providers/accessibility_provider.dart';
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
  final ImportedScore? importedScore;

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
    this.importedScore,
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
      final roundTypeId = matchRoundName(imported.roundName, score: imported.score);
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
        importedScore: imported,
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
          // Offline indicator
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, _) => OfflineIndicator(
              isOffline: connectivity.isOffline,
              isSyncing: connectivity.isSyncing,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, semanticLabel: 'Import scores'),
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
              ? EmptyState(
                  icon: Icons.history,
                  title: 'No sessions yet',
                  subtitle: 'Start training to see your history here',
                  actionLabel: 'Import Score History',
                  onAction: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ImportScreen()),
                    );
                    _loadHistory();
                  },
                )
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
          Consumer<AccessibilityProvider>(
            builder: (context, accessibility, _) {
              return HandicapChart(
                sessions: _sessions,
                importedScores: _importedScores,
                roundTypes: _roundTypes,
                colorblindMode: accessibility.colorblindMode,
              );
            },
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
              onLongPress: !s.isPlotted && s.importedScore != null
                  ? () => _showScoreOptionsDialog(s.importedScore!)
                  : null,
            )),
      ],
    );
  }

  Future<void> _showScoreOptionsDialog(ImportedScore score) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Text(
                    score.roundName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${score.date.day}/${score.date.month}/${score.date.year} • ${score.score} pts',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                    ),
                  ),
                  if (score.location != null && score.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      score.location!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.gold),
              title: Text('Edit Score', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Score', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );

    if (result == 'edit') {
      await _showEditScoreDialog(score);
    } else if (result == 'delete') {
      await _confirmDeleteScore(score);
    }
  }

  Future<void> _showEditScoreDialog(ImportedScore score) async {
    final roundNameController = TextEditingController(text: score.roundName);
    final scoreController = TextEditingController(text: score.score.toString());
    final xCountController = TextEditingController(text: score.xCount?.toString() ?? '');
    final locationController = TextEditingController(text: score.location ?? '');
    final notesController = TextEditingController(text: score.notes ?? '');
    DateTime selectedDate = score.date;
    String sessionType = score.sessionType;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Score'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roundNameController,
                  decoration: const InputDecoration(labelText: 'Round Name'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: scoreController,
                        decoration: const InputDecoration(labelText: 'Score'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: xCountController,
                        decoration: const InputDecoration(labelText: 'X Count'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location (optional)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: sessionType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'competition', child: Text('Competition')),
                    DropdownMenuItem(value: 'practice', child: Text('Practice')),
                  ],
                  onChanged: (v) => setDialogState(() => sessionType = v ?? 'competition'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newScore = int.tryParse(scoreController.text);
                if (newScore == null || newScore <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid score')),
                  );
                  return;
                }
                if (roundNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a round name')),
                  );
                  return;
                }

                final db = context.read<AppDatabase>();
                await db.updateImportedScore(
                  ImportedScoresCompanion(
                    id: Value(score.id),
                    date: Value(selectedDate),
                    roundName: Value(roundNameController.text.trim()),
                    score: Value(newScore),
                    xCount: Value(xCountController.text.isEmpty
                        ? null
                        : int.tryParse(xCountController.text)),
                    location: Value(locationController.text.isEmpty
                        ? null
                        : locationController.text),
                    notes: Value(notesController.text.isEmpty
                        ? null
                        : notesController.text),
                    sessionType: Value(sessionType),
                    updatedAt: Value(DateTime.now()),
                  ),
                );

                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Score updated')),
        );
        _promptEditAnother();
      }
    }
  }

  Future<void> _confirmDeleteScore(ImportedScore score) async {
    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Score?'),
        content: Text(
          'Delete ${score.roundName} (${score.score} pts) from ${score.date.day}/${score.date.month}/${score.date.year}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    // Second confirmation (double-check)
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
          'This will remove the score from your history. You can undo this action for a few seconds.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, delete it'),
          ),
        ],
      ),
    );

    if (secondConfirm != true || !mounted) return;

    // Perform soft delete with undo option
    final db = context.read<AppDatabase>();
    await db.softDeleteImportedScore(score.id);
    _loadHistory();

    if (!mounted) return;

    UndoManager.showUndoSnackbar(
      context: context,
      message: 'Score deleted',
      onUndo: () async {
        await db.restoreImportedScore(score.id);
        if (mounted) _loadHistory();
      },
      onExpired: () async {
        await db.deleteImportedScore(score.id);
      },
    );

    // After undo window, prompt for more edits
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _promptEditAnother();
    });
  }

  void _promptEditAnother() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit More?'),
        content: const Text('Would you like to edit or delete another score?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, I\'m done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Long-press any imported score to edit or delete'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Yes, show scores'),
          ),
        ],
      ),
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
            AppFilterChip(
              label: 'Indoor',
              count: indoorCount,
              isSelected: _showIndoor,
              color: AppColors.cyan,
              onTap: () => setState(() => _showIndoor = !_showIndoor),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppFilterChip(
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
            AppFilterChip(
              label: 'Competition',
              count: compCount,
              isSelected: _showCompetition,
              color: AppColors.gold,
              onTap: () => setState(() => _showCompetition = !_showCompetition),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppFilterChip(
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



class _UnifiedScoreTile extends StatelessWidget {
  final UnifiedScore score;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _UnifiedScoreTile({required this.score, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${score.date.day}/${score.date.month}/${score.date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap ?? onLongPress,
        onLongPress: onLongPress,
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
                        color: AppColors.gold.withValues(alpha: 0.2),
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
            ? AppColors.gold.withValues(alpha: 0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color:
              isPlotted ? AppColors.gold.withValues(alpha: 0.3) : Colors.transparent,
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
        color: color.withValues(alpha: 0.1),
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
