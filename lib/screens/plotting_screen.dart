import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/auto_plot_provider.dart';
import '../widgets/target_face.dart';
import '../widgets/triple_spot_target.dart';
import '../widgets/plotting_settings_sheet.dart';
import '../widgets/group_centre_widget.dart';
import '../widgets/full_scorecard_widget.dart';
import 'scorecard_view_screen.dart';
import '../widgets/shaft_selector_bottom_sheet.dart';
import '../widgets/offline_indicator.dart';
import '../utils/undo_manager.dart';
import '../db/database.dart';
import 'session_complete_screen.dart';
import 'home_screen.dart';
import 'auto_plot_capture_screen.dart';
import 'auto_plot_scan_screen.dart';
import '../services/vision_api_service.dart';

/// Preference key for triple spot view mode
const String kTripleSpotViewPref = 'indoor_triple_spot_view';

/// Preference key for combined view mode (when viewing triple spot)
const String kTripleSpotCombinedViewPref = 'indoor_triple_spot_combined';

/// Preference key for compound scoring mode (smaller inner 10/X ring)
const String kCompoundScoringPref = 'compound_scoring_mode';

/// Preference key for group centre confidence multiplier
/// 1.0 = ~68% (1 SD), 2.0 = ~95% (2 SD)
const String kGroupCentreConfidencePref = 'group_centre_confidence';

/// Preference key for showing ring notation on group centre
const String kShowRingNotationPref = 'show_ring_notation';

/// Preference key for tracking nock rotation per arrow
const String kTrackNockRotationPref = 'track_nock_rotation';

/// Preference key for triple spot auto-advance
const String kTripleSpotAutoAdvancePref = 'triple_spot_auto_advance';

/// Preference key for triple spot advance order ('column' or 'triangular')
const String kTripleSpotOrderPref = 'triple_spot_order';

class PlottingScreen extends StatefulWidget {
  const PlottingScreen({super.key});

  @override
  State<PlottingScreen> createState() => _PlottingScreenState();
}

class _PlottingScreenState extends State<PlottingScreen> {
  // Default to triple spot for indoor rounds
  bool _useTripleSpotView = true;
  // Default to separate view (3 targets)
  bool _useCombinedView = false;
  // Compound scoring mode - smaller inner 10/X ring
  bool _compoundScoring = false;
  // Group centre confidence multiplier (1.0 = 68%, 2.0 = 95%)
  double _confidenceMultiplier = 1.0;
  // Show ring notation on group centre widgets
  bool _showRingNotation = true;
  // Track nock rotation per arrow
  bool _trackNockRotation = false;
  // Selected face for plotting (0, 1, or 2)
  int _selectedFaceIndex = 0;
  bool _prefsLoaded = false;
  // Triple spot auto-advance settings
  bool _autoAdvanceEnabled = false;
  String _autoAdvanceOrder = 'column'; // 'column' or 'triangular'

  // Pending arrow position for fixed zoom window (normalized -1 to +1)
  // Using ValueNotifier for efficient updates without full widget rebuild
  final ValueNotifier<({double x, double y})?> _pendingArrowNotifier =
      ValueNotifier<({double x, double y})?>(null);

  // Pinch-to-zoom controller for target face
  final TransformationController _zoomController = TransformationController();

  // End history viewing - null means viewing/plotting current end
  int? _viewingEndIndex;
  List<Arrow>? _viewingEndArrows;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _pendingArrowNotifier.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  /// Reset zoom to 1x when starting new end
  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
  }

  /// View arrows from a past end
  Future<void> _viewPastEnd(int endIndex, SessionProvider provider) async {
    final end = provider.ends[endIndex];
    final arrows = await provider.getArrowsForEnd(end.id);
    setState(() {
      _viewingEndIndex = endIndex;
      _viewingEndArrows = arrows;
    });
  }

  /// Return to current end (exit history view)
  void _returnToCurrentEnd() {
    setState(() {
      _viewingEndIndex = null;
      _viewingEndArrows = null;
    });
  }

  Future<void> _loadPreferences() async {
    final db = context.read<AppDatabase>();
    final tripleSpot = await db.getBoolPreference(kTripleSpotViewPref, defaultValue: true);
    final combined = await db.getBoolPreference(kTripleSpotCombinedViewPref, defaultValue: false);
    final compound = await db.getBoolPreference(kCompoundScoringPref, defaultValue: false);
    final confidence = await db.getDoublePreference(kGroupCentreConfidencePref, defaultValue: 1.0);
    final ringNotation = await db.getBoolPreference(kShowRingNotationPref, defaultValue: true);
    final autoAdvance = await db.getBoolPreference(kTripleSpotAutoAdvancePref, defaultValue: false);
    final advanceOrder = await db.getPreference(kTripleSpotOrderPref);
    if (mounted) {
      setState(() {
        _useTripleSpotView = tripleSpot;
        _useCombinedView = combined;
        _compoundScoring = compound;
        _confidenceMultiplier = confidence;
        _showRingNotation = ringNotation;
        _autoAdvanceEnabled = autoAdvance;
        _autoAdvanceOrder = advanceOrder ?? 'column';
        _prefsLoaded = true;
      });
    }
  }

  Future<void> _setTripleSpotView(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kTripleSpotViewPref, value);
    setState(() => _useTripleSpotView = value);
  }

  Future<void> _setCombinedView(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kTripleSpotCombinedViewPref, value);
    setState(() => _useCombinedView = value);
  }

  Future<void> _setCompoundScoring(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kCompoundScoringPref, value);
    setState(() => _compoundScoring = value);
  }

  Future<void> _toggleConfidenceMultiplier() async {
    final db = context.read<AppDatabase>();
    // Cycle between 1.0 (67%) and 2.0 (95%)
    final newValue = _confidenceMultiplier == 1.0 ? 2.0 : 1.0;
    await db.setDoublePreference(kGroupCentreConfidencePref, newValue);
    setState(() => _confidenceMultiplier = newValue);
  }

  Future<void> _toggleRingNotation() async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kShowRingNotationPref, !_showRingNotation);
    setState(() => _showRingNotation = !_showRingNotation);
  }

  Future<void> _setAutoAdvance(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kTripleSpotAutoAdvancePref, value);
    setState(() => _autoAdvanceEnabled = value);
  }

  Future<void> _setAutoAdvanceOrder(String value) async {
    final db = context.read<AppDatabase>();
    await db.setPreference(kTripleSpotOrderPref, value);
    setState(() => _autoAdvanceOrder = value);
  }

  void _showSettingsSheet(BuildContext context, SessionProvider provider, bool supportsTripleSpot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PlottingSettingsSheet(
        supportsTripleSpot: supportsTripleSpot,
        useTripleSpot: _useTripleSpotView,
        onTripleSpotChanged: _setTripleSpotView,
        useCombinedView: _useCombinedView,
        onCombinedViewChanged: _setCombinedView,
        compoundScoring: _compoundScoring,
        onCompoundScoringChanged: _setCompoundScoring,
        confidenceMultiplier: _confidenceMultiplier,
        onToggleConfidence: _toggleConfidenceMultiplier,
        showRingNotation: _showRingNotation,
        onToggleRingNotation: _toggleRingNotation,
        shaftTaggingEnabled: provider.selectedQuiverId != null ? provider.shaftTaggingEnabled : null,
        onShaftTaggingChanged: provider.selectedQuiverId != null ? provider.setShaftTagging : null,
        autoAdvanceEnabled: _autoAdvanceEnabled,
        onAutoAdvanceChanged: _setAutoAdvance,
        autoAdvanceOrder: _autoAdvanceOrder,
        onAutoAdvanceOrderChanged: _setAutoAdvanceOrder,
      ),
    );
  }

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

        // Check if this is an indoor round that supports triple spot
        final isIndoor = provider.roundType?.isIndoor ?? false;
        final supportsTripleSpot = isIndoor;

        return Scaffold(
          appBar: AppBar(
            title: Text(provider.roundType?.name ?? 'Session'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
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
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Center(
                  child: Text(
                    'End ${provider.currentEndNumber}/${provider.totalEnds}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
              // Settings gear icon
              IconButton(
                icon: const Icon(Icons.settings, semanticLabel: 'Settings'),
                tooltip: 'Plotting settings',
                onPressed: () => _showSettingsSheet(context, provider, supportsTripleSpot),
              ),
              // Menu with abandon option
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, semanticLabel: 'Session menu'),
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
                        Icon(Icons.delete_outline, color: AppColors.error, semanticLabel: 'Delete'),
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

                const SizedBox(height: AppSpacing.sm),

                // Target face with rolling average overlay and fixed zoom window
                Expanded(
                  child: Stack(
                    children: [
                      // Main target - fills available space naturally
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Use the smaller dimension for square target
                              final availableSize = constraints.maxWidth < constraints.maxHeight
                                  ? constraints.maxWidth
                                  : constraints.maxHeight;
                              // Target fills available space
                              final size = availableSize;

                              // Determine which arrows to show and whether plotting enabled
                              final isViewingHistory = _viewingEndIndex != null;
                              final displayArrows = isViewingHistory
                                  ? (_viewingEndArrows ?? [])
                                  : provider.allSessionArrows;
                              final canPlot = !provider.isEndComplete && !isViewingHistory;

                              // Use triple spot view for indoor rounds when enabled
                              if (supportsTripleSpot && _useTripleSpotView) {
                                if (_useCombinedView) {
                                  // Combined view: all arrows on one tri-spot face
                                  return CombinedTripleSpotView(
                                    arrows: displayArrows,
                                    size: size,
                                    compoundScoring: _compoundScoring,
                                  );
                                } else {
                                  // Separate view: 3 interactive faces
                                  return InteractiveTripleSpotTarget(
                                    arrows: displayArrows,
                                    size: size,
                                    enabled: canPlot,
                                    compoundScoring: _compoundScoring,
                                    autoAdvance: _autoAdvanceEnabled,
                                    advanceOrder: _autoAdvanceOrder,
                                    onArrowPlotted: (x, y, faceIndex) async {
                                      await _plotArrowWithFace(
                                        context, provider, x, y, faceIndex,
                                      );
                                    },
                                  );
                                }
                              }

                              // Single face view (outdoor or user preference)
                              final isTriSpot = (provider.roundType?.faceCount ?? 1) == 3;
                              // Wrap in InteractiveViewer for pinch-to-zoom
                              // Single-finger gestures pass through for plotting
                              return InteractiveViewer(
                                transformationController: _zoomController,
                                minScale: 1.0,
                                maxScale: 4.0,
                                panEnabled: true,
                                scaleEnabled: true,
                                constrained: true,
                                child: InteractiveTargetFace(
                                  arrows: displayArrows,
                                  size: size,
                                  enabled: canPlot,
                                  isIndoor: provider.roundType?.isIndoor ?? false,
                                  triSpot: isTriSpot,
                                  compoundScoring: _compoundScoring,
                                  lineCutterDialogEnabled: true,
                                  transformController: _zoomController,
                                  onArrowPlotted: (x, y) async {
                                    await _plotArrowWithFace(context, provider, x, y, 0);
                                  },
                                  onPendingArrowChanged: (x, y) {
                                    // Use ValueNotifier for efficient updates without full rebuild
                                    _pendingArrowNotifier.value = x != null && y != null
                                        ? (x: x, y: y)
                                        : null;
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Fixed zoom window at 12 o'clock (top center)
                      // Uses ValueListenableBuilder for efficient updates during touch
                      ValueListenableBuilder<({double x, double y})?>(
                        valueListenable: _pendingArrowNotifier,
                        builder: (context, pending, _) {
                          if (pending == null) return const SizedBox.shrink();
                          return Positioned(
                            top: AppSpacing.md,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: RepaintBoundary(
                                child: FixedZoomWindow(
                                  targetX: pending.x,
                                  targetY: pending.y,
                                  zoomLevel: 4.0,
                                  size: 120,
                                  triSpot: (provider.roundType?.faceCount ?? 1) == 3,
                                  compoundScoring: _compoundScoring,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Rolling 12-arrow group centre (top-left)
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: GestureDetector(
                          onTap: _toggleConfidenceMultiplier,
                          onLongPress: _toggleRingNotation,
                          child: FutureBuilder(
                            // Key forces rebuild when arrows or confidence change
                            key: ValueKey('last12_${provider.ends.length}_${provider.arrowsInCurrentEnd}_${_confidenceMultiplier}_$_showRingNotation'),
                            future: provider.getLastNArrows(12),
                            builder: (context, snapshot) {
                              final arrows = snapshot.data ?? [];
                              final confLabel = _confidenceMultiplier == 1.0 ? '67%' : '95%';
                              return GroupCentreWidget(
                                arrows: arrows,
                                label: 'Last 12 ($confLabel)',
                                size: 80,
                                confidenceMultiplier: _confidenceMultiplier,
                                showRingNotation: _showRingNotation,
                              );
                            },
                          ),
                        ),
                      ),

                      // This round group centre (top-right)
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: GestureDetector(
                          onTap: _toggleConfidenceMultiplier,
                          onLongPress: _toggleRingNotation,
                          child: Builder(
                            // Key forces rebuild when arrows or confidence change
                            key: ValueKey('round_${provider.ends.length}_${provider.arrowsInCurrentEnd}_${_confidenceMultiplier}_$_showRingNotation'),
                            builder: (context) {
                              // Use synchronous allSessionArrows for all arrows in this round
                              final allArrows = provider.allSessionArrows;
                              final confLabel = _confidenceMultiplier == 1.0 ? '67%' : '95%';
                              return GroupCentreWidget(
                                arrows: allArrows,
                                label: 'This Round ($confLabel)',
                                size: 80,
                                confidenceMultiplier: _confidenceMultiplier,
                                showRingNotation: _showRingNotation,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // End history bar
                if (provider.ends.isNotEmpty)
                  _EndHistoryBar(
                    completedEnds: provider.ends.length,
                    currentEndNumber: provider.currentEndNumber,
                    viewingEndIndex: _viewingEndIndex,
                    onEndTapped: (index) {
                      if (index == provider.ends.length) {
                        _returnToCurrentEnd();
                      } else {
                        _viewPastEnd(index, provider);
                      }
                    },
                  ),

                // Divider before scorecard
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  height: 1,
                  color: AppColors.surfaceLight,
                ),

                // Official scorecard (at bottom, not floating)
                GestureDetector(
                  onTap: () => _showFullScorecard(context, provider),
                  child: Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: FutureBuilder(
                      future: provider.getAllCompletedEndArrows(),
                      builder: (context, snapshot) {
                        final completedArrows = snapshot.data ?? [];
                        return FullScorecardWidget(
                          completedEnds: provider.ends,
                          completedEndArrows: completedArrows,
                          currentEndArrows: provider.currentEndArrows,
                          currentEndNumber: provider.currentEndNumber,
                          arrowsPerEnd: provider.arrowsPerEnd,
                          totalEnds: provider.totalEnds,
                          roundName: provider.roundType?.name ?? '',
                          maxScore: provider.roundType?.maxScore,
                          roundType: provider.roundType,
                        );
                      },
                    ),
                  ),
                ),

                // Action buttons
                _ActionButtons(
                  provider: provider,
                  onEndCommit: _resetZoom,
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Plot an arrow with face index support (for triple spot)
  Future<void> _plotArrowWithFace(
    BuildContext context,
    SessionProvider provider,
    double x,
    double y,
    int faceIndex,
  ) async {
    // Check if shaft tagging is enabled
    if (provider.shaftTaggingEnabled && provider.selectedQuiverId != null) {
      // Show shaft selector bottom sheet
      final equipmentProvider = context.read<EquipmentProvider>();
      final shafts = equipmentProvider.getShaftsForQuiver(provider.selectedQuiverId!);

      // Get shaft numbers already used in this end
      final usedShaftNumbers = provider.currentEndArrows
          .where((a) => a.shaftNumber != null)
          .map((a) => a.shaftNumber!)
          .toSet();

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => ShaftSelectorBottomSheet(
          shafts: shafts,
          usedShaftNumbers: usedShaftNumbers,
          onShaftSelected: (shaftNumber, {String? nockRotation}) {
            provider.plotArrow(
              x: x,
              y: y,
              faceIndex: faceIndex,
              shaftNumber: shaftNumber,
              nockRotation: nockRotation,
            );
          },
          onSkip: () {
            provider.plotArrow(x: x, y: y, faceIndex: faceIndex);
          },
        ),
      );
    } else {
      // No shaft tagging - plot directly
      await provider.plotArrow(x: x, y: y, faceIndex: faceIndex);
    }
  }

  void _showFullScorecard(BuildContext context, SessionProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScorecardViewScreen(
          sessionId: provider.currentSession!.id,
          isLive: true,
        ),
      ),
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
    return Semantics(
      label: 'Score summary: Total ${provider.totalScore}, Xs ${provider.totalXs}, This end ${provider.currentEndScore}, ${provider.arrowsInCurrentEnd} of ${provider.arrowsPerEnd} arrows',
      child: Container(
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
  final VoidCallback? onEndCommit;

  const _ActionButtons({
    required this.provider,
    this.onEndCommit,
  });

  void _launchAutoPlot(BuildContext context) async {
    final roundType = provider.roundType;
    if (roundType == null) return;

    // Determine target type from round
    final targetType = _getTargetTypeFromRound(roundType);
    final isTripleSpot = roundType.faceCount == 3;

    // Check connectivity (Auto-Plot requires network)
    final connectivity = context.read<ConnectivityProvider>();
    if (connectivity.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-Plot requires internet connection'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Initialize auto-plot provider
    final autoPlotProvider = context.read<AutoPlotProvider>();
    autoPlotProvider.startCapture(targetType);

    // Navigate to scan screen (circular scan for better accuracy)
    final result = await Navigator.of(context).push<List<DetectedArrow>>(
      MaterialPageRoute(
        builder: (_) => AutoPlotScanScreen(
          targetType: targetType,
          isTripleSpot: isTripleSpot,
        ),
      ),
    );

    // Process detected arrows
    if (result != null && result.isNotEmpty && context.mounted) {
      for (final arrow in result) {
        // Convert normalized coordinates to what the plotting system expects
        await provider.plotArrow(
          x: arrow.x,
          y: arrow.y,
          faceIndex: arrow.faceIndex ?? 0,
        );
      }
    }
  }

  String _getTargetTypeFromRound(RoundType roundType) {
    // Determine target size from round configuration
    final targetDiameter = roundType.faceSize;
    if (roundType.faceCount == 3) {
      return 'triple_40cm';
    }
    if (targetDiameter <= 40) return '40cm';
    if (targetDiameter <= 60) return '60cm';
    if (targetDiameter <= 80) return '80cm';
    return '122cm';
  }

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
              icon: const Icon(Icons.undo, semanticLabel: 'Undo'),
              label: const Text('Undo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.surfaceLight),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Auto-Plot Scan button
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, _) {
              final isEnabled = !connectivity.isOffline;
              return IconButton(
                onPressed: isEnabled ? () => _launchAutoPlot(context) : null,
                icon: Icon(
                  Icons.radar,
                  color: isEnabled ? AppColors.gold : AppColors.textSecondary,
                  semanticLabel: 'Auto-Plot Scan',
                ),
                tooltip: 'Scan target',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceDark,
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              );
            },
          ),

          const SizedBox(width: AppSpacing.sm),

          // Next End / Complete button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: provider.arrowsInCurrentEnd > 0
                  ? () async {
                      await provider.commitEnd();
                      onEndCommit?.call();
                    }
                  : null,
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

/// Horizontal bar showing end numbers for history navigation
class _EndHistoryBar extends StatelessWidget {
  final int completedEnds;
  final int currentEndNumber;
  final int? viewingEndIndex;
  final ValueChanged<int> onEndTapped;

  const _EndHistoryBar({
    required this.completedEnds,
    required this.currentEndNumber,
    required this.viewingEndIndex,
    required this.onEndTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Show completed ends + current end in progress
    final totalToShow = completedEnds + 1;

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < totalToShow; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _EndChip(
                endNumber: i + 1,
                isCurrent: i == completedEnds,
                isViewing: viewingEndIndex == i,
                isCompleted: i < completedEnds,
                onTap: () => onEndTapped(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EndChip extends StatelessWidget {
  final int endNumber;
  final bool isCurrent;
  final bool isViewing;
  final bool isCompleted;
  final VoidCallback onTap;

  const _EndChip({
    required this.endNumber,
    required this.isCurrent,
    required this.isViewing,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isCurrent || isViewing;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.gold.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isHighlighted
                ? AppColors.gold
                : (isCompleted ? AppColors.surfaceLight : Colors.transparent),
            width: isHighlighted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          '$endNumber${isCurrent ? '*' : ''}',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 14,
            color: isHighlighted ? AppColors.gold : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
