import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../theme/app_theme.dart';
import '../db/database.dart';
import '../models/tuning_session.dart';
import 'tuning_checklist_screen.dart';

/// Tuning history screen showing timeline of tuning sessions
class TuningHistoryScreen extends StatefulWidget {
  final String? bowId;

  const TuningHistoryScreen({super.key, this.bowId});

  @override
  State<TuningHistoryScreen> createState() => _TuningHistoryScreenState();
}

class _TuningHistoryScreenState extends State<TuningHistoryScreen> {
  String? _filterBowId;
  String? _filterTuningType;

  @override
  void initState() {
    super.initState();
    _filterBowId = widget.bowId;
  }

  @override
  Widget build(BuildContext context) {
    final database = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TUNING HISTORY',
          style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<TuningSession>>(
        stream: _getTuningSessionsStream(database),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!;

          if (sessions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionCard(context, session, database);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TuningChecklistScreen(),
            ),
          );
        },
        backgroundColor: AppColors.gold,
        child: const Icon(
          Icons.add,
          color: AppColors.backgroundDark,
        ),
      ),
    );
  }

  Stream<List<TuningSession>> _getTuningSessionsStream(AppDatabase database) {
    if (_filterBowId != null && _filterTuningType != null) {
      return (database.select(database.tuningSessions)
            ..where((t) => t.bowId.equals(_filterBowId!))
            ..where((t) => t.tuningType.equals(_filterTuningType!))
            ..orderBy([(t) => drift.OrderingTerm.desc(t.date)]))
          .watch();
    } else if (_filterBowId != null) {
      return database.getTuningSessionsForBow(_filterBowId!).asStream();
    } else if (_filterTuningType != null) {
      return database.getTuningSessionsByType(_filterTuningType!).asStream();
    } else {
      return database.getAllTuningSessions().asStream();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.tune,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No tuning sessions yet',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Tap + to log your first tuning session',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, TuningSession session, AppDatabase database) {
    final dateStr = _formatDate(session.date);

    Map<String, dynamic>? results;
    try {
      if (session.results != null) {
        results = jsonDecode(session.results!) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore parse errors
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surfaceDark,
      child: InkWell(
        onTap: () => _showSessionDetails(context, session, results),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.gold, width: 1),
                    ),
                    child: Text(
                      TuningType.displayName(session.tuningType),
                      style: const TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 12,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBright,
                    ),
                    child: Text(
                      BowType.displayName(session.bowType),
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (session.tuningType == TuningType.paperTune && results != null) ...[
                _buildPaperTunePreview(results),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (session.bowId != null) ...[
                FutureBuilder<Bow?>(
                  future: database.getBow(session.bowId!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Text(
                        'Bow: ${snapshot.data!.name}',
                        style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                Text(
                  session.notes!,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperTunePreview(Map<String, dynamic> results) {
    final direction = results['tearDirection'] as String? ?? TearDirection.clean;
    final size = results['tearSize'] as String? ?? TearSize.medium;

    Color statusColor = AppColors.success;
    if (direction != TearDirection.clean) {
      statusColor = size == TearSize.large ? AppColors.error : AppColors.neonCyan;
    }

    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          color: statusColor,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Tear: ${TearDirection.displayName(direction)} (${TearSize.displayName(size)})',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  void _showSessionDetails(
    BuildContext context,
    TuningSession session,
    Map<String, dynamic>? results,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    TuningType.displayName(session.tuningType),
                    style: const TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 20,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _formatDateTime(session.date),
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (results != null) ...[
                    if (session.tuningType == TuningType.paperTune) ...[
                      _buildDetailSection(
                        'PAPER TUNE RESULTS',
                        _buildPaperTuneDetails(results),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (results['checklist'] != null) ...[
                      _buildDetailSection(
                        'CHECKLIST',
                        _buildChecklistDetails(results['checklist'] as Map<String, dynamic>),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    _buildDetailSection(
                      'NOTES',
                      Text(
                        session.notes!,
                        style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 14,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        content,
      ],
    );
  }

  Widget _buildPaperTuneDetails(Map<String, dynamic> results) {
    final direction = results['tearDirection'] as String? ?? TearDirection.clean;
    final size = results['tearSize'] as String? ?? TearSize.medium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Direction: ${TearDirection.displayName(direction)}',
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Size: ${TearSize.displayName(size)}',
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistDetails(Map<String, dynamic> checklist) {
    final items = checklist.entries.toList();
    items.sort((a, b) {
      final aChecked = a.value as bool;
      final bChecked = b.value as bool;
      if (aChecked == bChecked) return 0;
      return aChecked ? -1 : 1; // Checked items first
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((entry) {
        final item = entry.key;
        final checked = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 16,
                color: checked ? AppColors.gold : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: checked ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text(
            'FILTER SESSIONS',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 16,
              color: AppColors.gold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'All sessions',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _filterBowId = null;
                    _filterTuningType = null;
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(color: AppColors.textSecondary),
              const Text(
                'Filter options coming soon',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} - $hour:$minute';
  }
}
