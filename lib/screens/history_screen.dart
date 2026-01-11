import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../widgets/volume_chart.dart';
import '../widgets/handicap_chart.dart';
import 'session_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
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
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Handicap progression chart
                      if (_sessions.isNotEmpty || _importedScores.isNotEmpty) ...[
                        HandicapChart(
                          sessions: _sessions,
                          importedScores: _importedScores,
                          roundTypes: _roundTypes,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Volume chart (raw scores)
                      if (_sessions.isNotEmpty || _importedScores.isNotEmpty) ...[
                        VolumeChart(
                          sessions: _sessions,
                          importedScores: _importedScores,
                          roundTypes: _roundTypes,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Plotted sessions
                      if (_sessions.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                          ),
                          child: Text(
                            'Plotted Sessions',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.gold,
                                    ),
                          ),
                        ),
                        ..._sessions.map((s) => _SessionTile(
                              session: s,
                              roundType: _roundTypes[s.roundTypeId],
                            )),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Imported scores
                      if (_importedScores.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                          ),
                          child: Text(
                            'Imported Scores',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.gold,
                                    ),
                          ),
                        ),
                        ..._importedScores
                            .map((s) => _ImportedScoreTile(score: s)),
                      ],
                    ],
                  ),
                ),
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
            Icons.history,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No sessions yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Complete a session or import scores to see them here',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;
  final RoundType? roundType;

  const _SessionTile({required this.session, this.roundType});

  @override
  Widget build(BuildContext context) {
    final date = session.startedAt;
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final roundName = roundType?.name ?? session.roundTypeId;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(
                session: session,
                roundType: roundType,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
            // Score
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Center(
                child: Text(
                  session.totalScore.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roundName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Xs
            if (session.totalXs > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${session.totalXs}X',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportedScoreTile extends StatelessWidget {
  final ImportedScore score;

  const _ImportedScoreTile({required this.score});

  @override
  Widget build(BuildContext context) {
    final date = score.date;
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Score
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Center(
                child: Text(
                  score.score.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score.roundName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
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
                ],
              ),
            ),

            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                score.sessionType,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
