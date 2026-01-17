import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/auto_plot_provider.dart';
import '../widgets/target_face.dart';
import '../widgets/triple_spot_target.dart';
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

  // Pending arrow position for fixed zoom window (normalized -1 to +1)
  double? _pendingArrowX;
  double? _pendingArrowY;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final db = context.read<AppDatabase>();
    final tripleSpot = await db.getBoolPreference(kTripleSpotViewPref, defaultValue: true);
    final combined = await db.getBoolPreference(kTripleSpotCombinedViewPref, defaultValue: false);
    final compound = await db.getBoolPreference(kCompoundScoringPref, defaultValue: false);
    final confidence = await db.getDoublePreference(kGroupCentreConfidencePref, defaultValue: 1.0);
    final ringNotation = await db.getBoolPreference(kShowRingNotationPref, defaultValue: true);
    if (mounted) {
      setState(() {
        _useTripleSpotView = tripleSpot;
        _useCombinedView = combined;
        _compoundScoring = compound;
        _confidenceMultiplier = confidence;
        _showRingNotation = ringNotation;
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

                const SizedBox(height: AppSpacing.md),

                // Plotting toggles row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indoor toggles: triple spot view + compound scoring
                      if (supportsTripleSpot) ...[
                        // View mode toggle (1 face vs 3 faces)
                        TripleSpotToggle(
                          isTripleSpot: _useTripleSpotView,
                          onChanged: _setTripleSpotView,
                        ),
                        // Compound scoring toggle (smaller inner 10)
                        _CompoundToggle(
                          isCompound: _compoundScoring,
                          onChanged: _setCompoundScoring,
                        ),
                        // Combined vs separate toggle (only when triple spot)
                        if (_useTripleSpotView)
                          _ViewModeToggle(
                            isCombined: _useCombinedView,
                            onChanged: _setCombinedView,
                          ),
                      ],
                      // Arrow tracking toggle (available if quiver selected)
                      if (provider.selectedQuiverId != null)
                        _ArrowTrackingToggle(
                          isEnabled: provider.shaftTaggingEnabled,
                          onChanged: provider.setShaftTagging,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Target face with rolling average overlay and fixed zoom window
                Expanded(
                  child: Stack(
                    children: [
                      // Main target - fills available space naturally
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Use the smaller dimension, leave some space for zoom window
                              final availableSize = constraints.maxWidth < constraints.maxHeight
                                  ? constraints.maxWidth
                                  : constraints.maxHeight;
                              // Target fills most of available space (no arbitrary clamp)
                              final size = availableSize - AppSpacing.md * 2;

                              // Use triple spot view for indoor rounds when enabled
                              if (supportsTripleSpot && _useTripleSpotView) {
                                if (_useCombinedView) {
                                  // Combined view: all arrows on one tri-spot face
                                  return CombinedTripleSpotView(
                                    arrows: provider.allSessionArrows,
                                    size: size,
                                    compoundScoring: _compoundScoring,
                                  );
                                } else {
                                  // Separate view: 3 interactive faces
                                  return InteractiveTripleSpotTarget(
                                    arrows: provider.allSessionArrows,
                                    size: size,
                                    enabled: !provider.isEndComplete,
                                    compoundScoring: _compoundScoring,
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
                              return InteractiveTargetFace(
                                arrows: provider.allSessionArrows,
                                size: size,
                                enabled: !provider.isEndComplete,
                                isIndoor: provider.roundType?.isIndoor ?? false,
                                triSpot: isTriSpot,
                                compoundScoring: _compoundScoring,
                                lineCutterDialogEnabled: true,
                                onArrowPlotted: (x, y) async {
                                  await _plotArrowWithFace(context, provider, x, y, 0);
                                },
                                onPendingArrowChanged: (x, y) {
                                  setState(() {
                                    _pendingArrowX = x;
                                    _pendingArrowY = y;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      // Fixed zoom window at 12 o'clock (top center)
                      if (_pendingArrowX != null && _pendingArrowY != null)
                        Positioned(
                          top: AppSpacing.md,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: FixedZoomWindow(
                              targetX: _pendingArrowX!,
                              targetY: _pendingArrowY!,
                              zoomLevel: 4.0,
                              size: 120,
                              triSpot: (provider.roundType?.faceCount ?? 1) == 3,
                              compoundScoring: _compoundScoring,
                            ),
                          ),
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
                    constraints: const BoxConstraints(maxHeight: 160),
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
                _ActionButtons(provider: provider),

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

/// Toggle between combined and separate view modes
class _ViewModeToggle extends StatelessWidget {
  final bool isCombined;
  final ValueChanged<bool> onChanged;

  const _ViewModeToggle({
    required this.isCombined,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            icon: Icons.grid_view,
            tooltip: 'Separate',
            isSelected: !isCombined,
            onTap: () => onChanged(false),
          ),
          Container(width: 1, height: 32, color: AppColors.surfaceLight),
          _buildOption(
            icon: Icons.circle_outlined,
            tooltip: 'Combined',
            isSelected: isCombined,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold.withOpacity(0.2) : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.gold : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Toggle for compound scoring mode (smaller inner 10/X ring)
class _CompoundToggle extends StatelessWidget {
  final bool isCompound;
  final ValueChanged<bool> onChanged;

  const _CompoundToggle({
    required this.isCompound,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isCompound ? 'Compound (small X)' : 'Recurve (standard X)',
      child: GestureDetector(
        onTap: () => onChanged(!isCompound),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isCompound ? AppColors.gold.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isCompound ? AppColors.gold : AppColors.surfaceLight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isCompound ? 'CPD' : 'REC',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: isCompound ? AppColors.gold : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle for arrow/shaft tracking
class _ArrowTrackingToggle extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _ArrowTrackingToggle({
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isEnabled ? 'Arrow tracking ON' : 'Arrow tracking OFF',
      child: GestureDetector(
        onTap: () => onChanged(!isEnabled),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.gold.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isEnabled ? AppColors.gold : AppColors.surfaceLight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.track_changes,
                size: 14,
                color: isEnabled ? AppColors.gold : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                isEnabled ? 'ON' : 'OFF',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 12,
                  color: isEnabled ? AppColors.gold : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
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

  const _ActionButtons({required this.provider});

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

    // Navigate to capture screen
    final result = await Navigator.of(context).push<List<DetectedArrow>>(
      MaterialPageRoute(
        builder: (_) => AutoPlotCaptureScreen(
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
          faceIndex: arrow.faceIndex,
        );
      }
    }
  }

  String _getTargetTypeFromRound(RoundType roundType) {
    // Determine target size from round configuration
    final targetDiameter = roundType.targetDiameter;
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

          // Auto-Plot button
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, _) {
              final isEnabled = !connectivity.isOffline;
              return IconButton(
                onPressed: isEnabled ? () => _launchAutoPlot(context) : null,
                icon: Icon(
                  Icons.camera_alt,
                  color: isEnabled ? AppColors.gold : AppColors.textSecondary,
                  semanticLabel: 'Auto-Plot',
                ),
                tooltip: 'Auto-Plot (camera)',
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
