import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/target_face.dart';
import '../widgets/group_centre_widget.dart';
import '../widgets/scorecard_widget.dart';
import '../widgets/shaft_selector_bottom_sheet.dart';
import '../widgets/offline_indicator.dart';
import '../utils/undo_manager.dart';
import '../db/database.dart';
import 'session_complete_screen.dart';
import 'home_screen.dart';

class PlottingScreen extends StatelessWidget {
  const PlottingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        if (provider.isSessionComplete) {
          // Navigate to completion screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SessionCompleteScreen()),
            );
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(provider.roundType?.name ?? 'Session'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Leave session (progress saved)',
              onPressed: () {
                // Simply navigate back - session persists in database
                Navigator.of(context).pop();
              },
            ),
            actions: [
              // Offline indicator
              Consumer<ConnectivityProvider>(
                builder: (context, connectivity, _) => OfflineIndicator(
                  isOffline: connectivity.isOffline,
                  isSyncing: connectivity.isSyncing,
                ),
              ),
              // End counter
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Center(
                  child: Text(
                    'End ${provider.currentEndNumber}/${provider.totalEnds}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
              // Menu with abandon option
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'abandon') {
                    _showAbandonDialog(context, provider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'abandon',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('Abandon session'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Score summary bar
                _ScoreSummaryBar(provider: provider),

                const SizedBox(height: AppSpacing.md),

                // Target face with rolling average overlay
                Expanded(
                  child: Stack(
                    children: [
                      // Main target - uses synchronous getter for immediate updates
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints.maxWidth < constraints.maxHeight
                                  ? constraints.maxWidth
                                  : constraints.maxHeight - 120; // Leave room for zoom
                              final isTriSpot = (provider.roundType?.faceCount ?? 1) == 3;
                              return InteractiveTargetFace(
                                arrows: provider.allSessionArrows,
                                size: size.clamp(200.0, 400.0),
                                enabled: !provider.isEndComplete,
                                isIndoor: provider.roundType?.isIndoor ?? false,
                                triSpot: isTriSpot,
                                onArrowPlotted: (x, y) async {
                                  // Check if shaft tagging is enabled
                                  if (provider.shaftTaggingEnabled &&
                                      provider.selectedQuiverId != null) {
                                    // Show shaft selector bottom sheet
                                    final equipmentProvider =
                                        context.read<EquipmentProvider>();
                                    final shafts = equipmentProvider
                                        .getShaftsForQuiver(
                                            provider.selectedQuiverId!);

                                    await showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) =>
                                          ShaftSelectorBottomSheet(
                                        shafts: shafts,
                                        onShaftSelected: (shaftNumber) {
                                          provider.plotArrow(
                                            x: x,
                                            y: y,
                                            shaftNumber: shaftNumber,
                                          );
                                        },
                                        onSkip: () {
                                          provider.plotArrow(x: x, y: y);
                                        },
                                      ),
                                    );
                                  } else {
                                    // No shaft tagging - plot directly
                                    provider.plotArrow(x: x, y: y);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      // Rolling 12-arrow group centre (top-left)
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: FutureBuilder(
                          // Key forces rebuild when arrows change
                          key: ValueKey('last12_${provider.ends.length}_${provider.arrowsInCurrentEnd}'),
                          future: provider.getLastNArrows(12),
                          builder: (context, snapshot) {
                            final arrows = snapshot.data ?? [];
                            return GroupCentreWidget(
                              arrows: arrows,
                              label: 'Last 12',
                              size: 80,
                            );
                          },
                        ),
                      ),

                      // Current half group centre (top-right)
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: FutureBuilder(
                          // Key forces rebuild when arrows or end changes
                          key: ValueKey('half_${provider.currentEndNumber}_${provider.arrowsInCurrentEnd}'),
                          future: provider.getCurrentHalfArrows(),
                          builder: (context, snapshot) {
                            final halfArrows = snapshot.data ?? [];
                            final halfPoint = (provider.totalEnds / 2).ceil();
                            final isSecondHalf = provider.currentEndNumber > halfPoint;
                            return GroupCentreWidget(
                              arrows: halfArrows,
                              label: isSecondHalf ? 'Half 2' : 'Half 1',
                              size: 80,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Official scorecard
                FutureBuilder(
                  future: provider.getAllCompletedEndArrows(),
                  builder: (context, snapshot) {
                    final completedArrows = snapshot.data ?? [];
                    return ScorecardWidget(
                      completedEnds: provider.ends,
                      completedEndArrows: completedArrows,
                      currentEndArrows: provider.currentEndArrows,
                      currentEndNumber: provider.currentEndNumber,
                      arrowsPerEnd: provider.arrowsPerEnd,
                      totalEnds: provider.totalEnds,
                      roundName: provider.roundType?.name ?? '',
                    );
                  },
                ),

                // Action buttons
                _ActionButtons(provider: provider),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAbandonDialog(BuildContext context, SessionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Abandon Session?'),
        content: const Text(
          'All arrows from this session will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final sessionId = provider.currentSession?.id;
              final db = context.read<AppDatabase>();

              await provider.abandonSession();

              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );

                // Show undo snackbar
                if (sessionId != null) {
                  UndoManager.showUndoSnackbar(
                    context: context,
                    message: 'Session deleted',
                    onUndo: () async {
                      await db.restoreSession(sessionId);
                    },
                    onExpired: () async {
                      await db.deleteSession(sessionId);
                    },
                  );
                }
              }
            },
            child: Text(
              'Abandon',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreSummaryBar extends StatelessWidget {
  final SessionProvider provider;

  const _ScoreSummaryBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      color: AppColors.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreItem(
            label: 'Total',
            value: provider.totalScore.toString(),
            highlight: true,
          ),
          _ScoreItem(
            label: 'Xs',
            value: provider.totalXs.toString(),
          ),
          _ScoreItem(
            label: 'This End',
            value: provider.currentEndScore.toString(),
          ),
          _ScoreItem(
            label: 'Arrows',
            value: '${provider.arrowsInCurrentEnd}/${provider.arrowsPerEnd}',
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ScoreItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: highlight ? AppColors.gold : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final SessionProvider provider;

  const _ActionButtons({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Undo button
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  provider.arrowsInCurrentEnd > 0 ? provider.undoLastArrow : null,
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.surfaceLight),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Next End / Complete button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  provider.arrowsInCurrentEnd > 0 ? provider.commitEnd : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  provider.currentEndNumber >= provider.totalEnds
                      ? 'Complete Session'
                      : 'Next End',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
