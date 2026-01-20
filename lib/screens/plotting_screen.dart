import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/auto_plot_provider.dart';
import '../providers/accessibility_provider.dart';
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
import 'auto_plot_scan_router.dart';
import '../services/vision_api_service.dart';
import '../utils/target_coordinate_system.dart';

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

/// Preference key for hiding scores (sensitive athletes)
const String kHideScoresPref = 'hide_scores_mode';

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
  // Show ring notation on group centre widgets (hidden by default, show on long-press)
  bool _showRingNotation = false;
  // Selected face for plotting (0, 1, or 2)
  int _selectedFaceIndex = 0;
  // Triple spot auto-advance settings (enabled by default)
  bool _autoAdvanceEnabled = true;
  String _autoAdvanceOrder = 'column'; // 'column' or 'triangular'
  // Hide scores mode (for sensitive athletes)
  bool _hideScores = false;
  // Scorecard expanded state
  bool _scorecardExpanded = false;

  // Pending arrow position for fixed zoom window (normalized -1 to +1)
  // Using ValueNotifier for efficient updates without full widget rebuild
  final ValueNotifier<({double x, double y})?> _pendingArrowNotifier =
      ValueNotifier<({double x, double y})?>(null);

  // Pinch-to-zoom controller for target face
  final TransformationController _zoomController = TransformationController();

  // End history viewing - null means viewing/plotting current end
  int? _viewingEndIndex;
  List<Arrow>? _viewingEndArrows;

  // Prevent duplicate navigation to session complete screen
  bool _navigatingToComplete = false;

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
    // Immediately highlight the selected end chip for visual feedback
    setState(() {
      _viewingEndIndex = endIndex;
      // Keep previous arrows while loading (prevents flash to empty)
      // If no previous arrows, this will briefly show empty which is acceptable
    });

    // Load arrows from database
    final end = provider.ends[endIndex];
    final arrows = await provider.getArrowsForEnd(end.id);

    // Update with loaded arrows (if still viewing this end)
    if (mounted && _viewingEndIndex == endIndex) {
      setState(() {
        _viewingEndArrows = arrows;
      });
    }
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
    final ringNotation = await db.getBoolPreference(kShowRingNotationPref, defaultValue: false);
    final autoAdvance = await db.getBoolPreference(kTripleSpotAutoAdvancePref, defaultValue: true);
    final advanceOrder = await db.getPreference(kTripleSpotOrderPref);
    final hideScores = await db.getBoolPreference(kHideScoresPref, defaultValue: false);
    if (mounted) {
      setState(() {
        _useTripleSpotView = tripleSpot;
        _useCombinedView = combined;
        _compoundScoring = compound;
        _confidenceMultiplier = confidence;
        _showRingNotation = ringNotation;
        _autoAdvanceEnabled = autoAdvance;
        _autoAdvanceOrder = advanceOrder ?? 'column';
        _hideScores = hideScores;
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

  Future<void> _toggleHideScores() async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kHideScoresPref, !_hideScores);
    setState(() => _hideScores = !_hideScores);
  }

  void _showSettingsSheet(BuildContext context, SessionProvider provider, bool supportsTripleSpot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => PlottingSettingsSheet(
          supportsTripleSpot: supportsTripleSpot,
          useTripleSpot: _useTripleSpotView,
          onTripleSpotChanged: (value) {
            _setTripleSpotView(value);
            setSheetState(() {});
          },
          useCombinedView: _useCombinedView,
          onCombinedViewChanged: (value) {
            _setCombinedView(value);
            setSheetState(() {});
          },
          compoundScoring: _compoundScoring,
          onCompoundScoringChanged: (value) {
            _setCompoundScoring(value);
            setSheetState(() {});
          },
          confidenceMultiplier: _confidenceMultiplier,
          onToggleConfidence: () {
            _toggleConfidenceMultiplier();
            setSheetState(() {});
          },
          showRingNotation: _showRingNotation,
          onToggleRingNotation: () {
            _toggleRingNotation();
            setSheetState(() {});
          },
          shaftTaggingEnabled: provider.selectedQuiverId != null ? provider.shaftTaggingEnabled : null,
          onShaftTaggingChanged: provider.selectedQuiverId != null ? (value) {
            provider.setShaftTagging(value);
            setSheetState(() {});
          } : null,
          autoAdvanceEnabled: _autoAdvanceEnabled,
          onAutoAdvanceChanged: (value) {
            _setAutoAdvance(value);
            setSheetState(() {});
          },
          autoAdvanceOrder: _autoAdvanceOrder,
          onAutoAdvanceOrderChanged: (value) {
            _setAutoAdvanceOrder(value);
            setSheetState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        if (provider.isSessionComplete && !_navigatingToComplete) {
          // Navigate to completion screen (only once)
          _navigatingToComplete = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SessionCompleteScreen()),
              );
            }
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
              // Hide scores toggle (for sensitive athletes)
              IconButton(
                icon: Icon(
                  _hideScores ? Icons.visibility_off : Icons.visibility,
                  color: _hideScores ? AppColors.gold : null,
                  semanticLabel: _hideScores ? 'Show scores' : 'Hide scores',
                ),
                tooltip: _hideScores ? 'Show scores' : 'Hide scores',
                onPressed: _toggleHideScores,
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
                                    selectedFace: _selectedFaceIndex,
                                    onFaceChanged: (face) => setState(() => _selectedFaceIndex = face),
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
                                child: Consumer<AccessibilityProvider>(
                                  builder: (context, accessibility, _) {
                                    return InteractiveTargetFace(
                                      arrows: displayArrows,
                                      size: size,
                                      enabled: canPlot,
                                      isIndoor: provider.roundType?.isIndoor ?? false,
                                      triSpot: isTriSpot,
                                      compoundScoring: _compoundScoring,
                                      lineCutterDialogEnabled: true,
                                      scoringType: provider.roundType?.scoringType ?? '10-zone',
                                      transformController: _zoomController,
                                      colorblindMode: accessibility.colorblindMode,
                                      showRingLabels: accessibility.showRingLabels,
                                      onArrowPlotted: (x, y) async {
                                        await _plotArrowWithFace(context, provider, x, y, 0);
                                      },
                                      onPendingArrowChanged: (x, y) {
                                        // Use ValueNotifier for efficient updates without full rebuild
                                        _pendingArrowNotifier.value = x != null && y != null
                                            ? (x: x, y: y)
                                            : null;
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Fixed zoom window at 12 o'clock (top center)
                      // Uses ValueListenableBuilder for efficient updates during touch
                      Consumer<AccessibilityProvider>(
                        builder: (context, accessibility, _) {
                          return ValueListenableBuilder<({double x, double y})?>(
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
                                      colorblindMode: accessibility.colorblindMode,
                                    ),
                                  ),
                                ),
                              );
                            },
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
                          child: Builder(
                            builder: (context) {
                              // Use synchronous cached data - no FutureBuilder needed
                              final arrows = provider.lastNArrows(12);
                              return GroupCentreWidget(
                                arrows: arrows,
                                label: 'Last 12',
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
                              return GroupCentreWidget(
                                arrows: allArrows,
                                label: 'This Round',
                                size: 80,
                                confidenceMultiplier: _confidenceMultiplier,
                                showRingNotation: _showRingNotation,
                              );
                            },
                          ),
                        ),
                      ),

                      // Quick toggle for triple spot view mode (stacked vs combined)
                      // Positioned at bottom left to avoid overlapping with triple spot target
                      if (supportsTripleSpot && _useTripleSpotView)
                        Positioned(
                          bottom: AppSpacing.md,
                          left: AppSpacing.md,
                          child: _TripleSpotViewToggle(
                            isCombined: _useCombinedView,
                            onToggle: () => _setCombinedView(!_useCombinedView),
                          ),
                        ),
                    ],
                  ),
                ),

                // Collapsible scorecard (hidden when _hideScores is true)
                if (!_hideScores)
                  _CollapsibleScorecard(
                    provider: provider,
                    isExpanded: _scorecardExpanded,
                    onToggleExpanded: () => setState(() => _scorecardExpanded = !_scorecardExpanded),
                    onTapFullView: () => _showFullScorecard(context, provider),
                    viewingEndIndex: _viewingEndIndex,
                    onEndTapped: (index) {
                      if (index == provider.ends.length) {
                        _returnToCurrentEnd();
                      } else {
                        _viewPastEnd(index, provider);
                      }
                    },
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

      final result = await showModalBottomSheet<ShaftSelectionResult>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => ShaftSelectorBottomSheet(
          shafts: shafts,
          usedShaftNumbers: usedShaftNumbers,
        ),
      );

      // Handle result: selection, skip, or dismiss
      if (result != null && result.shaftNumber != null) {
        // User selected a shaft
        await provider.plotArrow(
          x: x,
          y: y,
          faceIndex: faceIndex,
          shaftNumber: result.shaftNumber,
          nockRotation: result.nockRotation,
          rating: result.rating,
        );
      } else {
        // User skipped or dismissed - plot without shaft tracking
        await provider.plotArrow(x: x, y: y, faceIndex: faceIndex);
      }
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

    // Load arrow appearance from active quiver for identification
    final equipmentProvider = context.read<EquipmentProvider>();
    await autoPlotProvider.loadArrowAppearanceFromQuiver(equipmentProvider.defaultQuiver);

    autoPlotProvider.startCapture(targetType);

    // Navigate to scan screen (circular scan for better accuracy)
    // Uses platform-specific implementation (native camera on mobile, web APIs in browser)
    final result = await Navigator.of(context).push<List<DetectedArrow>>(
      MaterialPageRoute(
        builder: (_) => AutoPlotScanRouter(
          targetType: targetType,
          isTripleSpot: isTripleSpot,
        ),
      ),
    );

    // Process detected arrows
    if (result != null && result.isNotEmpty && context.mounted) {
      int arrowsWithoutFaceIndex = 0;

      for (final arrow in result) {
        int faceIndex;

        if (arrow.faceIndex != null) {
          // Use API-detected face index
          faceIndex = arrow.faceIndex!;
        } else if (isTripleSpot) {
          // For tri-spot without API face detection, assign based on current face distribution
          faceIndex = TripleSpotFaceDistributor.nextFaceIndexFromArrows(
            provider.currentEndArrows,
            (a) => a.faceIndex,
          );
          arrowsWithoutFaceIndex++;
        } else {
          // Single face - always 0
          faceIndex = 0;
        }

        await provider.plotArrow(
          x: arrow.x,
          y: arrow.y,
          faceIndex: faceIndex,
        );
      }

      // Warn user if we had to guess face assignments
      if (arrowsWithoutFaceIndex > 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$arrowsWithoutFaceIndex arrow${arrowsWithoutFaceIndex > 1 ? 's' : ''} auto-assigned to faces. Use Undo if incorrect.',
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.surfaceDark,
          ),
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
                  provider.totalArrowsInSession > 0 ? provider.undoLastArrow : null,
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
                  Icons.auto_awesome,
                  color: isEnabled ? AppColors.gold : AppColors.textSecondary,
                  semanticLabel: 'Auto-Plot',
                ),
                tooltip: 'Auto-Plot',
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

/// Quick toggle for switching between stacked (3 faces) and combined (1 target) view
class _TripleSpotViewToggle extends StatelessWidget {
  final bool isCombined;
  final VoidCallback onToggle;

  const _TripleSpotViewToggle({
    required this.isCombined,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stacked icon (3 horizontal lines)
            _ViewOption(
              icon: Icons.view_agenda_outlined,
              label: '3',
              isSelected: !isCombined,
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: AppColors.surfaceLight),
            const SizedBox(width: 8),
            // Combined icon (single circle)
            _ViewOption(
              icon: Icons.adjust,
              label: '1',
              isSelected: isCombined,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _ViewOption({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.gold : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Collapsible scorecard showing current end by default, expandable to show full history
class _CollapsibleScorecard extends StatelessWidget {
  final SessionProvider provider;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onTapFullView;
  final int? viewingEndIndex;
  final ValueChanged<int> onEndTapped;

  const _CollapsibleScorecard({
    required this.provider,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onTapFullView,
    required this.viewingEndIndex,
    required this.onEndTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Drag up to expand, drag down to collapse
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100 && !isExpanded) {
            onToggleExpanded();
          } else if (details.primaryVelocity! > 100 && isExpanded) {
            onToggleExpanded();
          }
        }
      },
      onDoubleTap: onTapFullView,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: AppColors.surfaceLight, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle indicator
            GestureDetector(
              onTap: onToggleExpanded,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            // Current end row (always visible)
            _CurrentEndRow(
              provider: provider,
              viewingEndIndex: viewingEndIndex,
            ),

            // Expanded content: end history and full scorecard
            if (isExpanded) ...[
              Container(height: 1, color: AppColors.surfaceLight),

              // End history bar
              if (provider.ends.isNotEmpty)
                _EndHistoryBar(
                  completedEnds: provider.ends.length,
                  currentEndNumber: provider.currentEndNumber,
                  viewingEndIndex: viewingEndIndex,
                  onEndTapped: onEndTapped,
                ),

              // Full scorecard (limited height)
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                child: FullScorecardWidget(
                  completedEnds: provider.ends,
                  completedEndArrows: provider.completedEndArrowsByEnd,
                  currentEndArrows: provider.currentEndArrows,
                  currentEndNumber: provider.currentEndNumber,
                  arrowsPerEnd: provider.arrowsPerEnd,
                  totalEnds: provider.totalEnds,
                  roundName: provider.roundType?.name ?? '',
                  maxScore: provider.roundType?.maxScore,
                  roundType: provider.roundType,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows the current end being filled in with score summary
class _CurrentEndRow extends StatelessWidget {
  final SessionProvider provider;
  final int? viewingEndIndex;

  const _CurrentEndRow({
    required this.provider,
    required this.viewingEndIndex,
  });

  Color _getScoreColor(int score, bool isX) {
    if (isX) return AppColors.gold;
    if (score == 10) return AppColors.gold;
    if (score >= 9) return AppColors.gold.withValues(alpha: 0.8);
    if (score >= 7) return const Color(0xFFFF5555); // Red
    if (score >= 5) return const Color(0xFF5599FF); // Blue
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final isViewingHistory = viewingEndIndex != null;
    final arrows = provider.currentEndArrows;
    final endScore = arrows.fold(0, (sum, a) => sum + a.score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          // End number indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isViewingHistory
                  ? Colors.transparent
                  : AppColors.gold.withValues(alpha: 0.2),
              border: Border.all(
                color: isViewingHistory ? AppColors.surfaceLight : AppColors.gold,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              '${provider.currentEndNumber}',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isViewingHistory ? AppColors.textMuted : AppColors.gold,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Arrow scores
          Expanded(
            child: Row(
              children: List.generate(provider.arrowsPerEnd, (i) {
                final hasArrow = i < arrows.length;
                final arrow = hasArrow ? arrows[i] : null;

                return Container(
                  width: 28,
                  margin: const EdgeInsets.only(right: 4),
                  child: Center(
                    child: hasArrow
                        ? Text(
                            arrow!.isX ? 'X' : arrow.score.toString(),
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(arrow.score, arrow.isX),
                            ),
                          )
                        : Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.surfaceLight,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                  ),
                );
              }),
            ),
          ),

          // End total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  arrows.isNotEmpty ? '$endScore' : '-',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  'R/T: ${provider.totalScore}',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    color: AppColors.textSecondary,
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
