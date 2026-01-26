import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/auto_plot_provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/sight_marks_provider.dart';
import '../models/sight_mark.dart';
import '../widgets/target_face.dart';
import '../widgets/triple_spot_target.dart';
import '../widgets/face_indicator_sidebar.dart';
import '../widgets/plotting_settings_sheet.dart';
import '../widgets/group_centre_widget.dart';
import '../widgets/full_scorecard_widget.dart';
import 'scorecard_view_screen.dart';
import '../widgets/shaft_selector_bottom_sheet.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/scoring_timer_widget.dart';
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

/// Preference key for face layout mode (single, singleTracked, verticalTriple, triangular)
const String kFaceLayoutPref = 'face_layout_mode';

/// Preference key for single face tracking enabled (prompts for face order on first use)
const String kSingleFaceTrackingPref = 'single_face_tracking_enabled';

/// Face layout modes for indoor rounds
enum FaceLayout {
  /// True single face (no face tracking, all arrows on same target)
  single,
  /// Single face view but tracks which face each arrow is on
  singleTracked,
  /// 3 faces stacked vertically (default for triple spot)
  verticalTriple,
  /// 3 faces in triangle (1 top, 2 below) - WA 18m only
  triangular,
}

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

/// Preference key for scoring timer enabled
const String kScoringTimerEnabledPref = 'scoring_timer_enabled';

/// Preference key for scoring timer duration (seconds: 90, 120, 180, 240)
const String kScoringTimerDurationPref = 'scoring_timer_duration';

/// Preference key for scoring timer lead-in (seconds: 10 or 15)
const String kScoringTimerLeadInPref = 'scoring_timer_lead_in';

/// Preference key for zoom window enabled
const String kZoomWindowEnabledPref = 'zoom_window_enabled';

/// Preference key for line cutter prompt enabled
const String kLineCutterEnabledPref = 'line_cutter_enabled';

/// Preference key for arrow marker size multiplier (0.5 to 2.0, default 1.0)
const String kArrowMarkerSizePref = 'arrow_marker_size';

class PlottingScreen extends StatefulWidget {
  const PlottingScreen({super.key});

  @override
  State<PlottingScreen> createState() => _PlottingScreenState();
}

class _PlottingScreenState extends State<PlottingScreen>
    with WidgetsBindingObserver {
  // Default to triple spot for indoor rounds
  bool _useTripleSpotView = true;
  // Default to separate view (3 targets)
  bool _useCombinedView = false;
  // Compound scoring mode - smaller inner 10/X ring
  bool _compoundScoring = false;
  // Face layout mode for indoor rounds
  FaceLayout _faceLayout = FaceLayout.verticalTriple;
  // Single face tracking enabled (for singleTracked mode)
  bool _singleFaceTracking = false;
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

  // Scoring timer settings
  bool _timerEnabled = false;
  int _timerDuration = 120; // seconds (90, 120, 180, 240)
  int _timerLeadIn = 10; // seconds (10 or 15)

  // Zoom window enabled (shows magnified view during plotting)
  bool _zoomWindowEnabled = true;

  // Line cutter prompt enabled (asks IN/OUT when on ring boundary)
  bool _lineCutterEnabled = true;

  // Arrow marker size multiplier (0.5 = half size, 1.0 = default, 2.0 = double)
  double _arrowMarkerSize = 1.0;

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

  // Auto-commit timer (45 seconds after last arrow)
  Timer? _autoCommitTimer;
  static const _autoCommitDelay = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoCommitTimer?.cancel();
    _pendingArrowNotifier.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-commit when app is backgrounded (paused or inactive)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final provider = context.read<SessionProvider>();
      if (provider.isEndReadyToCommit) {
        _autoCommitTimer?.cancel();
        _commitEndWithHalfwayCheck(provider);
      }
    }
  }

  /// Start the 45-second auto-commit timer
  void _startAutoCommitTimer(SessionProvider provider) {
    _autoCommitTimer?.cancel();
    _autoCommitTimer = Timer(_autoCommitDelay, () {
      if (mounted && provider.isEndReadyToCommit) {
        _commitEndWithHalfwayCheck(provider);
      }
    });
  }

  /// Cancel the auto-commit timer (called on undo or manual commit)
  void _cancelAutoCommitTimer() {
    _autoCommitTimer?.cancel();
    _autoCommitTimer = null;
  }

  /// Commit end and check for break checkpoint (halfway or distance boundary)
  Future<void> _commitEndWithHalfwayCheck(SessionProvider provider) async {
    _cancelAutoCommitTimer();

    await provider.commitEnd();
    _resetZoom();

    // Show break checkpoint if we just crossed a boundary (distance change or halfway)
    if (mounted && provider.isAtBreakCheckpoint) {
      final breakEndNumber = provider.breakCheckpointEndNumber!;
      _showBreakCheckpoint(provider, breakEndNumber);
    }
  }

  /// Reset zoom to 1x when starting new end
  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
  }

  /// Get the set of arrow IDs to highlight (current or selected end)
  Set<String> _getHighlightedArrowIds(SessionProvider provider) {
    if (_viewingEndIndex != null && _viewingEndArrows != null) {
      // Viewing history - highlight that end's arrows
      return _viewingEndArrows!.map((a) => a.id).toSet();
    }
    // Current end - highlight current end arrows
    return provider.currentEndArrows.map((a) => a.id).toSet();
  }

  /// Show a break checkpoint dialog (halfway or distance boundary)
  Future<void> _showBreakCheckpoint(SessionProvider provider, int breakEndNumber) async {
    provider.markBreakCheckpointShown(breakEndNumber);

    String? breakNotes;
    bool clearPlotFace = false;
    final sightMarkController = TextEditingController();

    // Determine if this is a distance change or a simple halfway break
    final isDistanceChange = provider.isDistanceBoundary(breakEndNumber);
    final nextDistanceLeg = isDistanceChange ? provider.currentDistanceLeg : null;
    final isHalfway = breakEndNumber == (provider.totalEnds / 2).ceil();

    // Get the distance for the NEXT leg (what they're about to shoot)
    // For distance change: use the next distance leg
    // For halfway: use the current round's distance
    final nextDistance = nextDistanceLeg?.distance ?? provider.roundType?.distance?.toDouble();
    final distanceUnit = nextDistanceLeg?.unit ?? 'm';

    // Build title and description based on break type
    String title;
    String description;
    String notesLabel;
    if (isDistanceChange && nextDistanceLeg != null) {
      title = 'DISTANCE CHANGE';
      description = 'End $breakEndNumber complete. Next: ${nextDistanceLeg.displayDistance}';
      notesLabel = 'Notes for this distance (optional)';
    } else if (isHalfway) {
      title = 'HALFWAY CHECKPOINT';
      description = 'End $breakEndNumber of ${provider.totalEnds} complete';
      notesLabel = 'First half notes (optional)';
    } else {
      title = 'BREAK';
      description = 'End $breakEndNumber of ${provider.totalEnds} complete';
      notesLabel = 'Notes (optional)';
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isDistanceChange ? Icons.swap_horiz : Icons.flag,
                    color: AppColors.gold,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 18,
                      color: AppColors.gold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sight mark recording for next distance
              if (nextDistance != null) ...[
                Row(
                  children: [
                    Icon(Icons.visibility, color: AppColors.gold, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Sight mark for ${nextDistance.toStringAsFixed(0)}$distanceUnit',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: sightMarkController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., 5.14 or 51.4',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    prefixIcon: Icon(Icons.my_location, color: AppColors.textMuted),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Notes field
              Text(
                notesLabel,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                style: TextStyle(fontFamily: AppFonts.body, color: AppColors.textPrimary),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Shot execution, timing, conditions...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onChanged: (value) => breakNotes = value,
              ),
              const SizedBox(height: AppSpacing.md),

              // Clear plot face toggle
              SwitchListTile(
                value: clearPlotFace,
                onChanged: (value) => setSheetState(() => clearPlotFace = value),
                title: Text(
                  'Clear plot face',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Hide previous arrows (data preserved)',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
                activeColor: AppColors.gold,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Apply settings after dialog closes
    if (clearPlotFace) {
      provider.setArrowsHiddenBeforeEnd(provider.currentEndNumber);
    }

    // Save sight mark if provided
    final sightMarkValue = sightMarkController.text.trim();
    if (sightMarkValue.isNotEmpty && nextDistance != null && provider.selectedBowId != null) {
      try {
        final sightMarksProvider = context.read<SightMarksProvider>();
        await sightMarksProvider.addSightMark(
          bowId: provider.selectedBowId!,
          distance: nextDistance,
          unit: distanceUnit == 'yd' ? DistanceUnit.yards : DistanceUnit.meters,
          sightValue: sightMarkValue,
          confidenceScore: 0.8, // Slightly higher confidence - recorded during round
          isIndoor: provider.roundType?.isIndoor ?? false,
        );
      } catch (e) {
        debugPrint('Failed to save sight mark: $e');
      }
    }

    // Log notes if provided
    if (breakNotes != null && breakNotes!.isNotEmpty) {
      debugPrint('Break notes: $breakNotes');
    }

    sightMarkController.dispose();
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
    final timerEnabled = await db.getBoolPreference(kScoringTimerEnabledPref, defaultValue: false);
    final timerDuration = await db.getIntPreference(kScoringTimerDurationPref, defaultValue: 120);
    final timerLeadIn = await db.getIntPreference(kScoringTimerLeadInPref, defaultValue: 10);
    final zoomWindowEnabled = await db.getBoolPreference(kZoomWindowEnabledPref, defaultValue: true);
    final lineCutterEnabled = await db.getBoolPreference(kLineCutterEnabledPref, defaultValue: true);
    final arrowMarkerSize = await db.getDoublePreference(kArrowMarkerSizePref, defaultValue: 1.0);
    final faceLayoutStr = await db.getPreference(kFaceLayoutPref);
    final singleFaceTracking = await db.getBoolPreference(kSingleFaceTrackingPref, defaultValue: false);
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
        _timerEnabled = timerEnabled;
        _timerDuration = timerDuration;
        _timerLeadIn = timerLeadIn;
        _zoomWindowEnabled = zoomWindowEnabled;
        _lineCutterEnabled = lineCutterEnabled;
        _arrowMarkerSize = arrowMarkerSize;
        _faceLayout = FaceLayout.values.firstWhere(
          (e) => e.name == faceLayoutStr,
          orElse: () => FaceLayout.verticalTriple,
        );
        _singleFaceTracking = singleFaceTracking;
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

  Future<void> _setTimerEnabled(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kScoringTimerEnabledPref, value);
    setState(() => _timerEnabled = value);
  }

  Future<void> _setTimerDuration(int value) async {
    final db = context.read<AppDatabase>();
    await db.setIntPreference(kScoringTimerDurationPref, value);
    setState(() => _timerDuration = value);
  }

  Future<void> _setTimerLeadIn(int value) async {
    final db = context.read<AppDatabase>();
    await db.setIntPreference(kScoringTimerLeadInPref, value);
    setState(() => _timerLeadIn = value);
  }

  Future<void> _setZoomWindowEnabled(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kZoomWindowEnabledPref, value);
    setState(() => _zoomWindowEnabled = value);
  }

  Future<void> _setLineCutterEnabled(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kLineCutterEnabledPref, value);
    setState(() => _lineCutterEnabled = value);
  }

  Future<void> _setArrowMarkerSize(double value) async {
    final db = context.read<AppDatabase>();
    await db.setDoublePreference(kArrowMarkerSizePref, value);
    setState(() => _arrowMarkerSize = value);
  }

  Future<void> _setFaceLayout(FaceLayout layout) async {
    final db = context.read<AppDatabase>();
    await db.setPreference(kFaceLayoutPref, layout.name);
    setState(() => _faceLayout = layout);
  }

  Future<void> _setSingleFaceTracking(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kSingleFaceTrackingPref, value);
    setState(() => _singleFaceTracking = value);
  }

  /// Show face setup dialog when switching to single face view for indoor rounds
  /// Asks if user wants true single face or single view with face tracking
  Future<void> _showFaceSetupDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'FACE CONFIGURATION',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you shooting?',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _FaceSetupOption(
              title: 'Single face',
              subtitle: 'All arrows on one target',
              icon: Icons.crop_square,
              onTap: () => Navigator.pop(ctx, 'single'),
            ),
            const SizedBox(height: 8),
            _FaceSetupOption(
              title: 'Triple spot (single view)',
              subtitle: 'Track which face each arrow is on',
              icon: Icons.view_agenda_outlined,
              onTap: () => Navigator.pop(ctx, 'tracked'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == 'single') {
      // True single face - no tracking
      await _setSingleFaceTracking(false);
      await _setTripleSpotView(false);
    } else if (result == 'tracked') {
      // Single view with face tracking - ask for order
      final order = await _showFaceOrderDialog();
      if (order != null) {
        await _setAutoAdvanceOrder(order);
        await _setSingleFaceTracking(true);
        await _setTripleSpotView(false);
      }
    }
  }

  /// Show dialog to select face shooting order
  Future<String?> _showFaceOrderDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'SHOOTING ORDER',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What order do you shoot?',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _FaceSetupOption(
              title: 'Top \u2192 Middle \u2192 Bottom',
              subtitle: '1 \u2192 2 \u2192 3',
              icon: Icons.arrow_downward,
              onTap: () => Navigator.pop(ctx, 'column'),
            ),
            const SizedBox(height: 8),
            _FaceSetupOption(
              title: 'Top \u2192 Bottom \u2192 Middle',
              subtitle: '1 \u2192 3 \u2192 2',
              icon: Icons.swap_vert,
              onTap: () => Navigator.pop(ctx, 'triangular'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
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
          timerEnabled: _timerEnabled,
          onTimerEnabledChanged: (value) {
            _setTimerEnabled(value);
            setSheetState(() {});
          },
          timerDuration: _timerDuration,
          onTimerDurationChanged: (value) {
            _setTimerDuration(value);
            setSheetState(() {});
          },
          timerLeadIn: _timerLeadIn,
          onTimerLeadInChanged: (value) {
            _setTimerLeadIn(value);
            setSheetState(() {});
          },
          zoomWindowEnabled: _zoomWindowEnabled,
          onZoomWindowEnabledChanged: (value) {
            _setZoomWindowEnabled(value);
            setSheetState(() {});
          },
          lineCutterEnabled: _lineCutterEnabled,
          onLineCutterEnabledChanged: (value) {
            _setLineCutterEnabled(value);
            setSheetState(() {});
          },
          arrowMarkerSize: _arrowMarkerSize,
          onArrowMarkerSizeChanged: (value) {
            _setArrowMarkerSize(value);
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
        // Allow user override for any indoor round with small faces (60cm or less)
        final isIndoor = provider.roundType?.isIndoor ?? false;
        final faceCount = provider.roundType?.faceCount ?? 1;
        final faceSize = provider.roundType?.faceSize ?? 122;
        // Rounds with faceCount == 3 always support triple spot
        // Indoor rounds with 60cm or smaller faces can also use triple spot
        final supportsTripleSpot = isIndoor && (faceCount == 3 || faceSize <= 60);
        // Triangular layout only for WA 18m style (already has faceCount == 3)
        final supportsTriangular = isIndoor && faceCount == 3;

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
                  PopupMenuItem(
                    value: 'abandon',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error, semanticLabel: 'Delete'),
                        const SizedBox(width: AppSpacing.sm),
                        const Flexible(
                          child: Text('Abandon session', overflow: TextOverflow.ellipsis),
                        ),
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
                                  : provider.displayArrows;
                              final canPlot = !provider.isEndComplete && !isViewingHistory;
                              final highlightedIds = _getHighlightedArrowIds(provider);

                              // Use triple spot view for indoor rounds when enabled
                              if (supportsTripleSpot && _useTripleSpotView) {
                                if (_useCombinedView) {
                                  // Combined view: all arrows on one tri-spot face (read-only)
                                  return InteractiveViewer(
                                    transformationController: _zoomController,
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    panEnabled: true, // OK here - no plotting interaction
                                    scaleEnabled: true,
                                    constrained: true,
                                    child: CombinedTripleSpotView(
                                      arrows: displayArrows,
                                      size: size,
                                      compoundScoring: _compoundScoring,
                                      highlightedArrowIds: highlightedIds,
                                    ),
                                  );
                                } else if (_faceLayout == FaceLayout.triangular && supportsTriangular) {
                                  // Triangular view: 1 face on top, 2 below (WA 18m style)
                                  return InteractiveViewer(
                                    transformationController: _zoomController,
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    panEnabled: false, // Disabled so single-finger goes to child for plotting
                                    scaleEnabled: true,
                                    constrained: true,
                                    child: TriangularTripleSpotTarget(
                                      arrows: displayArrows,
                                      size: size,
                                      enabled: canPlot,
                                      compoundScoring: _compoundScoring,
                                      autoAdvance: _autoAdvanceEnabled,
                                      advanceOrder: _autoAdvanceOrder,
                                      selectedFace: _selectedFaceIndex,
                                      highlightedArrowIds: highlightedIds,
                                      transformController: _zoomController,
                                      arrowSizeMultiplier: _arrowMarkerSize,
                                      onFaceChanged: (face) => setState(() => _selectedFaceIndex = face),
                                      onArrowPlotted: (x, y, faceIndex, {scoreOverride}) async {
                                        await _plotArrowWithFace(
                                          context, provider, x, y, faceIndex,
                                          scoreOverride: scoreOverride,
                                        );
                                      },
                                      onPendingArrowChanged: (x, y) {
                                        _pendingArrowNotifier.value = x != null && y != null
                                            ? (x: x, y: y)
                                            : null;
                                      },
                                    ),
                                  );
                                } else {
                                  // Vertical separate view: 3 interactive faces stacked
                                  return InteractiveViewer(
                                    transformationController: _zoomController,
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    panEnabled: false, // Disabled so single-finger goes to child for plotting
                                    scaleEnabled: true,
                                    constrained: true,
                                    child: InteractiveTripleSpotTarget(
                                      arrows: displayArrows,
                                      size: size,
                                      enabled: canPlot,
                                      compoundScoring: _compoundScoring,
                                      autoAdvance: _autoAdvanceEnabled,
                                      advanceOrder: _autoAdvanceOrder,
                                      selectedFace: _selectedFaceIndex,
                                      highlightedArrowIds: highlightedIds,
                                      transformController: _zoomController,
                                      arrowSizeMultiplier: _arrowMarkerSize,
                                      onFaceChanged: (face) => setState(() => _selectedFaceIndex = face),
                                      onArrowPlotted: (x, y, faceIndex, {scoreOverride}) async {
                                        await _plotArrowWithFace(
                                          context, provider, x, y, faceIndex,
                                          scoreOverride: scoreOverride,
                                        );
                                      },
                                      onPendingArrowChanged: (x, y) {
                                        _pendingArrowNotifier.value = x != null && y != null
                                            ? (x: x, y: y)
                                            : null;
                                      },
                                    ),
                                  );
                                }
                              }

                              // Single face view (outdoor or user preference)
                              // When single face tracking is enabled, arrows are assigned to faces
                              // and auto-advance cycles through faces
                              final isTriSpot = (provider.roundType?.faceCount ?? 1) == 3;
                              // Wrap in InteractiveViewer for pinch-to-zoom
                              // panEnabled=false so single-finger gestures go to child for plotting
                              return InteractiveViewer(
                                transformationController: _zoomController,
                                minScale: 1.0,
                                maxScale: 4.0,
                                panEnabled: false,
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
                                      lineCutterDialogEnabled: _lineCutterEnabled,
                                      faceSizeCm: provider.faceSizeCm,
                                      scoringType: provider.roundType?.scoringType ?? '10-zone',
                                      transformController: _zoomController,
                                      colorblindMode: accessibility.colorblindMode,
                                      showRingLabels: accessibility.showRingLabels,
                                      highlightedArrowIds: highlightedIds,
                                      arrowSizeMultiplier: _arrowMarkerSize,
                                      onArrowPlotted: (x, y, {scoreOverride}) async {
                                        // Use current face index when tracking enabled, else face 0
                                        final faceIndex = _singleFaceTracking ? _selectedFaceIndex : 0;
                                        await _plotArrowWithFace(context, provider, x, y, faceIndex, scoreOverride: scoreOverride);

                                        // Auto-advance to next face when tracking enabled
                                        if (_singleFaceTracking && _autoAdvanceEnabled) {
                                          setState(() {
                                            if (_autoAdvanceOrder == 'triangular') {
                                              // 0→2, 1→0, 2→1
                                              const order = [2, 0, 1];
                                              _selectedFaceIndex = order[_selectedFaceIndex];
                                            } else {
                                              // Column: 0→1→2→0
                                              _selectedFaceIndex = (_selectedFaceIndex + 1) % 3;
                                            }
                                          });
                                        }
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

                      // Fixed zoom window - position depends on view mode and arrow position
                      // For triple spot: right side to avoid covering top face
                      // For single face: top center (but moves to bottom if arrow is in upper half)
                      if (_zoomWindowEnabled)
                        Consumer<AccessibilityProvider>(
                          builder: (context, accessibility, _) {
                            return ValueListenableBuilder<({double x, double y})?>(
                              valueListenable: _pendingArrowNotifier,
                              builder: (context, pending, _) {
                                if (pending == null) return const SizedBox.shrink();

                                // Position to the right for triple spot view to avoid covering top face
                                final useTripleSpotPosition = supportsTripleSpot && _useTripleSpotView && !_useCombinedView;

                                // For single face: move zoom window to bottom if arrow is in upper half
                                // (negative Y = upper half in normalized coords where center is 0)
                                final arrowInUpperHalf = pending.y < -0.2;

                                return Positioned(
                                  // For triple spot: always at top right
                                  // For single face: top if arrow is in lower half, bottom if in upper half
                                  top: useTripleSpotPosition || !arrowInUpperHalf ? AppSpacing.md : null,
                                  bottom: !useTripleSpotPosition && arrowInUpperHalf ? AppSpacing.md : null,
                                  right: useTripleSpotPosition ? AppSpacing.md : null,
                                  left: useTripleSpotPosition ? null : 0,
                                  child: useTripleSpotPosition
                                      ? RepaintBoundary(
                                          child: FixedZoomWindow(
                                            targetX: pending.x,
                                            targetY: pending.y,
                                            currentZoomLevel: _zoomController.value.getMaxScaleOnAxis(),
                                            relativeZoom: 2.0,
                                            size: 100, // Slightly smaller for side position
                                            triSpot: true,
                                            compoundScoring: _compoundScoring,
                                            colorblindMode: accessibility.colorblindMode,
                                          ),
                                        )
                                      : Center(
                                          child: RepaintBoundary(
                                            child: FixedZoomWindow(
                                              targetX: pending.x,
                                              targetY: pending.y,
                                              currentZoomLevel: _zoomController.value.getMaxScaleOnAxis(),
                                              relativeZoom: 2.0,
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

                      // Face layout toggle buttons (left side)
                      // Shows view mode options when triple spot is supported
                      if (supportsTripleSpot && _useTripleSpotView)
                        Positioned(
                          left: AppSpacing.md,
                          top: 100, // Below the group centre widget
                          child: FaceLayoutToggle(
                            currentLayout: _useCombinedView
                                ? 'combined'
                                : (_faceLayout == FaceLayout.triangular ? 'triangular' : 'vertical'),
                            triangularSupported: supportsTriangular,
                            onLayoutChanged: (layout) {
                              if (layout == 'combined') {
                                _setCombinedView(true);
                              } else if (layout == 'triangular') {
                                _setCombinedView(false);
                                _setFaceLayout(FaceLayout.triangular);
                              } else if (layout == 'single') {
                                // Show face setup dialog to ask about tracking
                                _showFaceSetupDialog();
                              } else {
                                // vertical
                                _setCombinedView(false);
                                _setFaceLayout(FaceLayout.verticalTriple);
                              }
                            },
                          ),
                        ),

                      // Face indicator sidebar (when using single face tracking mode)
                      // Shows which face is currently active for arrow assignment
                      if (supportsTripleSpot && _singleFaceTracking && !_useTripleSpotView)
                        Positioned(
                          left: AppSpacing.md,
                          top: 100,
                          child: FaceIndicatorSidebar(
                            currentFace: _selectedFaceIndex,
                            arrowCounts: [
                              provider.currentEndArrows.where((a) => a.faceIndex == 0).length,
                              provider.currentEndArrows.where((a) => a.faceIndex == 1).length,
                              provider.currentEndArrows.where((a) => a.faceIndex == 2).length,
                            ],
                            layoutStyle: _autoAdvanceOrder,
                            onFaceSelected: (face) => setState(() => _selectedFaceIndex = face),
                          ),
                        ),

                      // Quick toggle for triple spot view mode (legacy bottom-left position)
                      // Kept for easy access - switches between stacked and combined views
                      if (supportsTripleSpot && _useTripleSpotView)
                        Positioned(
                          bottom: AppSpacing.md,
                          left: AppSpacing.md,
                          child: _TripleSpotViewToggle(
                            isCombined: _useCombinedView,
                            onToggle: () => _setCombinedView(!_useCombinedView),
                          ),
                        ),

                      // Scoring timer widget (bottom right)
                      Positioned(
                        bottom: AppSpacing.md,
                        right: AppSpacing.md,
                        child: ScoringTimerWidget(
                          enabled: _timerEnabled,
                          leadInSeconds: _timerLeadIn,
                          durationSeconds: _timerDuration,
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
                    onArrowTapped: (arrowIndex) => _showArrowOptions(context, provider, arrowIndex),
                  ),

                // Action buttons
                _ActionButtons(
                  provider: provider,
                  onEndCommit: () => _commitEndWithHalfwayCheck(provider),
                  onUndo: _cancelAutoCommitTimer,
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
  /// [scoreOverride] allows overriding the calculated score (from line cutter dialog)
  Future<void> _plotArrowWithFace(
    BuildContext context,
    SessionProvider provider,
    double x,
    double y,
    int faceIndex, {
    ({int score, bool isX})? scoreOverride,
  }) async {
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

      // Handle result: selection, skip, dontAskAgain, or dismiss
      if (result != null && result.shaftNumber != null) {
        // User selected a shaft
        await provider.plotArrow(
          x: x,
          y: y,
          faceIndex: faceIndex,
          shaftNumber: result.shaftNumber,
          nockRotation: result.nockRotation,
          rating: result.rating,
          scoreOverride: scoreOverride,
        );
      } else if (result != null && result.dontAskAgain) {
        // User chose "Don't ask again" - disable shaft tagging for session
        await provider.setShaftTagging(false);
        // Plot without shaft tracking
        await provider.plotArrow(x: x, y: y, faceIndex: faceIndex, scoreOverride: scoreOverride);
      } else {
        // User skipped or dismissed - plot without shaft tracking
        await provider.plotArrow(x: x, y: y, faceIndex: faceIndex, scoreOverride: scoreOverride);
      }
    } else {
      // No shaft tagging - plot directly
      await provider.plotArrow(x: x, y: y, faceIndex: faceIndex, scoreOverride: scoreOverride);
    }

    // Start auto-commit timer if end is now ready to commit
    if (provider.isEndReadyToCommit) {
      _startAutoCommitTimer(provider);
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

  /// Show options for a tapped arrow (delete or re-plot)
  void _showArrowOptions(BuildContext context, SessionProvider provider, int arrowIndex) {
    final arrows = provider.currentEndArrows;
    if (arrowIndex >= arrows.length) return;

    final arrow = arrows[arrowIndex];
    final scoreDisplay = arrow.isX ? 'X' : arrow.score.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    scoreDisplay,
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 20,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Arrow ${arrowIndex + 1}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Delete option
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Arrow'),
              subtitle: Text(
                'Remove this arrow and re-plot',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await provider.deleteArrowAtIndex(arrowIndex);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Arrow $scoreDisplay deleted'),
                      backgroundColor: AppColors.surfaceLight,
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: AppColors.gold,
                        onPressed: () {
                          // Undo is handled by the standard undo mechanism
                          provider.undoLastArrow();
                        },
                      ),
                    ),
                  );
                }
              },
            ),

            // Move to end option (if not last arrow)
            if (arrowIndex < arrows.length - 1)
              ListTile(
                leading: Icon(Icons.swap_horiz, color: AppColors.textSecondary),
                title: const Text('Move to End'),
                subtitle: Text(
                  'Move this arrow to the last position',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await provider.moveArrowToEnd(arrowIndex);
                },
              ),

            const SizedBox(height: AppSpacing.sm),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
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
  final VoidCallback? onUndo;

  const _ActionButtons({
    required this.provider,
    this.onEndCommit,
    this.onUndo,
  });

  void _launchAutoPlot(BuildContext context) async {
    final roundType = provider.roundType;
    if (roundType == null) return;

    // Determine target type from round
    final targetType = _getTargetTypeFromRound(roundType);
    final isTripleSpot = roundType.faceCount == 3;

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
              onPressed: provider.totalArrowsInSession > 0
                  ? () {
                      onUndo?.call();
                      provider.undoLastArrow();
                    }
                  : null,
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
                  semanticLabel: isEnabled ? 'Auto-Plot' : 'Auto-Plot unavailable offline',
                ),
                tooltip: isEnabled ? 'Auto-Plot' : 'Auto-Plot (offline)',
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
              onPressed: provider.arrowsInCurrentEnd > 0 && !provider.isCommittingEnd
                  ? () => onEndCommit?.call()
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: provider.isCommittingEnd
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
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
  final void Function(int arrowIndex)? onArrowTapped;

  const _CollapsibleScorecard({
    required this.provider,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onTapFullView,
    required this.viewingEndIndex,
    required this.onEndTapped,
    this.onArrowTapped,
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
            // Drag handle indicator with full scorecard button
            GestureDetector(
              onTap: onToggleExpanded,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    // Expand/collapse section
                    Expanded(
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
                    // Full scorecard button (icon only for compact display)
                    GestureDetector(
                      onTap: onTapFullView,
                      child: Tooltip(
                        message: 'View Full Scorecard',
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                          ),
                          child: Icon(
                            Icons.fullscreen,
                            size: 16,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Current end row with tappable arrows (always visible)
            _CurrentEndRow(
              provider: provider,
              viewingEndIndex: viewingEndIndex,
              onArrowTapped: onArrowTapped,
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

              // Full scorecard (increased height for better visibility)
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
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
  final void Function(int arrowIndex)? onArrowTapped;

  const _CurrentEndRow({
    required this.provider,
    required this.viewingEndIndex,
    this.onArrowTapped,
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

          // Arrow scores (tappable for current end)
          Expanded(
            child: Row(
              children: List.generate(provider.arrowsPerEnd, (i) {
                final hasArrow = i < arrows.length;
                final arrow = hasArrow ? arrows[i] : null;
                final canTap = hasArrow && onArrowTapped != null && !isViewingHistory;

                return GestureDetector(
                  onTap: canTap ? () => onArrowTapped!(i) : null,
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: canTap
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.surfaceLight.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          )
                        : null,
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

/// Option button for face setup dialogs
class _FaceSetupOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FaceSetupOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
