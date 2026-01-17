import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_box.dart';

class SessionDetailScreen extends StatefulWidget {
  final Session session;
  final RoundType? roundType;

  const SessionDetailScreen({
    super.key,
    required this.session,
    this.roundType,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  List<End> _ends = [];
  Map<String, List<Arrow>> _arrowsByEnd = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to access context after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessionData();
    });
  }

  Future<void> _loadSessionData() async {
    try {
      final db = context.read<AppDatabase>();
      final ends = await db.getEndsForSession(widget.session.id);
      final arrowsByEnd = <String, List<Arrow>>{};

      for (final end in ends) {
        final arrows = await db.getArrowsForEnd(end.id);
        arrowsByEnd[end.id] = arrows;
      }

      if (mounted) {
        setState(() {
          _ends = ends;
          _arrowsByEnd = arrowsByEnd;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load session data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.session.startedAt;
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final roundName = widget.roundType?.name ?? widget.session.roundTypeId;
    final percentage = widget.roundType != null
        ? (widget.session.totalScore / widget.roundType!.maxScore * 100)
            .toStringAsFixed(1)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Detail'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                           size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!,
                           style: TextStyle(color: AppColors.error)),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadSessionData();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card with session summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            roundName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.gold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            dateStr,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (widget.session.location != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.session.location!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              StatBox(
                                label: 'Score',
                                value: widget.session.totalScore.toString(),
                                highlighted: true,
                              ),
                              if (widget.session.totalXs > 0)
                                StatBox(
                                  label: 'Xs',
                                  value: widget.session.totalXs.toString(),
                                  highlighted: true,
                                ),
                              if (percentage != null)
                                StatBox(
                                  label: 'Percentage',
                                  value: '$percentage%',
                                ),
                              StatBox(
                                label: 'Ends',
                                value: _ends.length.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Notes section
                  if (widget.session.notes != null &&
                      widget.session.notes!.isNotEmpty) ...[
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.gold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          widget.session.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Ends breakdown
                  Text(
                    'End Scores',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.gold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // List of ends
                  ..._ends.map((end) {
                    final arrows = _arrowsByEnd[end.id] ?? [];
                    return _EndCard(
                      end: end,
                      arrows: arrows,
                    );
                  }),
                ],
              ),
            ),
    );
  }
}


class _EndCard extends StatelessWidget {
  final End end;
  final List<Arrow> arrows;

  const _EndCard({
    required this.end,
    required this.arrows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // End header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'E${end.endNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Score: ${end.endScore}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (end.endXs > 0) ...[
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
                      '${end.endXs}X',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ],
            ),

            // Arrow scores
            if (arrows.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: arrows.map((arrow) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: arrow.isX
                          ? AppColors.gold.withOpacity(0.2)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                      border: arrow.isX
                          ? Border.all(color: AppColors.gold, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        arrow.score.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: arrow.isX
                                  ? AppColors.gold
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
