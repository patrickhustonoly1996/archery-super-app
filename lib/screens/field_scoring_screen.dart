import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/field_course.dart';
import '../models/field_course_target.dart';
import '../models/field_scoring.dart';
import '../models/field_peg_state.dart';
import '../providers/field_session_provider.dart';
import '../providers/field_sight_mark_provider.dart';
import '../providers/field_peg_flow_provider.dart';
import '../providers/sight_marks_provider.dart';
import '../widgets/field_target_setup_sheet.dart';
import '../widgets/field_scorecard_widget.dart';
import '../widgets/inclinometer_widget.dart';
import '../widgets/field_interactive_target_face.dart';
import '../widgets/field_sightmark_record_sheet.dart';
import 'field_session_complete_screen.dart';
import 'animal_scoring_screen.dart';

class FieldScoringScreen extends StatefulWidget {
  const FieldScoringScreen({super.key});

  @override
  State<FieldScoringScreen> createState() => _FieldScoringScreenState();
}

class _FieldScoringScreenState extends State<FieldScoringScreen>
    with SingleTickerProviderStateMixin {
  // Legacy arrow scores (fallback for non-peg-flow targets)
  final List<FieldArrowScore> _currentArrowScores = [];
  String? _sightMarkUsed;
  final Map<int, String> _sightMarksByTarget = {};
  final TextEditingController _sightMarkController = TextEditingController();
  late TabController _tabController;

  // Peg flow provider (screen-scoped, not in Provider tree)
  final FieldPegFlowProvider _pegFlowProvider = FieldPegFlowProvider();

  // Whether peg flow is active for current target
  bool _isPegFlowActive = false;

  // Angle state for current target
  double? _confirmedAngle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pegFlowProvider.addListener(_onPegFlowChanged);
  }

  @override
  void dispose() {
    _sightMarkController.dispose();
    _tabController.dispose();
    _pegFlowProvider.removeListener(_onPegFlowChanged);
    _pegFlowProvider.dispose();
    super.dispose();
  }

  void _onPegFlowChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FieldSessionProvider>(
      builder: (context, session, _) {
        if (session.roundType == FieldRoundType.animal) {
          return const AnimalScoringScreen();
        }

        return Scaffold(
          appBar: _buildAppBar(session),
          body: Column(
            children: [
              Container(
                color: AppColors.surfaceDark,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'SCORE'),
                    Tab(text: 'SCORECARD'),
                  ],
                  labelColor: AppColors.gold,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.gold,
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontFamily: AppFonts.pixel,
                      ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Scoring tab
                    _buildScoringTab(session),
                    // Scorecard tab
                    FieldScorecardWidget(
                      session: session,
                      onTargetTap: (targetNum) {
                        _saveSightMarkForTarget(session.currentTargetNumber);
                        session.goToTarget(targetNum);
                        _loadTargetScores(session);
                        _tabController.animateTo(0);
                      },
                    ),
                  ],
                ),
              ),
              _buildBottomControls(session),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoringTab(FieldSessionProvider session) {
    final target = session.currentTarget;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTargetHeader(session),

          // Angle section (only when target exists and peg flow is active)
          if (target != null && _isPegFlowActive && _confirmedAngle == null)
            _buildAngleSection(),

          // Sightmark recommendation
          if (_isPegFlowActive && _pegFlowProvider.currentRecommendation != null)
            _buildSightMarkRecommendation(),

          // Scoring mode toggle + scoring area
          if (target != null) ...[
            if (_isPegFlowActive) _buildScoringModeToggle(),
            _buildScoringArea(session),
          ],

          // Poor shot toggle (after arrow is scored on current peg)
          if (_isPegFlowActive && _pegFlowProvider.currentPeg?.isScored == true)
            _buildPoorShotToggle(),

          // Next Peg / Submit Target button
          if (_isPegFlowActive) _buildPegActionButton(session),
        ],
      ),
    );
  }

  AppBar _buildAppBar(FieldSessionProvider session) {
    return AppBar(
      title: Text(session.course?.name ?? session.roundType?.displayName ?? 'Field'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _showExitConfirmation(session),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.totalScore}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.gold,
                        fontFamily: AppFonts.pixel,
                      ),
                ),
                Text(
                  '${session.completedTargets}/${session.targetCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetHeader(FieldSessionProvider session) {
    final target = session.currentTarget;
    final isNewCourse = session.isNewCourseCreation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surfaceDark,
      child: Column(
        children: [
          // Target navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: session.currentTargetNumber > 1
                    ? () {
                        _saveSightMarkForTarget(session.currentTargetNumber);
                        session.previousTarget();
                        _loadTargetScores(session);
                      }
                    : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Target ${session.currentTargetNumber}/${session.targetCount}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontFamily: AppFonts.pixel,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${session.totalScore}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.gold,
                                fontFamily: AppFonts.pixel,
                              ),
                        ),
                      ],
                    ),
                    if (target != null)
                      Text(
                        target.pegConfig.isSequential
                            ? '${target.pegConfig.displayString}  ${target.faceSizeDisplay}'
                            : '${target.distanceDisplay} - ${target.faceSizeDisplay}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: session.currentTargetNumber < session.targetCount
                    ? () {
                        _saveSightMarkForTarget(session.currentTargetNumber);
                        session.nextTarget();
                        _loadTargetScores(session);
                      }
                    : null,
              ),
            ],
          ),

          // Peg progress for walk-downs
          if (_isPegFlowActive && _pegFlowProvider.pegFlow != null) ...[
            if (_pegFlowProvider.pegFlow!.isWalkDown) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildPegProgress(),
            ],
          ],

          // Define target button (for new course creation)
          if (isNewCourse && target == null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _showTargetSetupSheet(session),
              icon: const Icon(Icons.add),
              label: const Text('Define Target'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
              ),
            ),
          ],

          // Legacy sight mark row (when peg flow is NOT active)
          if (target != null && !_isPegFlowActive) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildSightMarkRow(session, target),
          ],
        ],
      ),
    );
  }

  Widget _buildPegProgress() {
    final flow = _pegFlowProvider.pegFlow!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PEG ${flow.currentPegIndex + 1}/${flow.pegCount}: ${flow.currentPeg.distanceDisplay}',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
          ),
        ),
        if (flow.isWalkDown && flow.currentPegIndex == 0) ...[
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () => _pegFlowProvider.toggleConsistentAngle(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: flow.consistentAngleEnabled
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
                border: Border.all(
                  color: flow.consistentAngleEnabled
                      ? AppColors.gold
                      : AppColors.surfaceLight,
                ),
              ),
              child: Text(
                'SAME ANGLE',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 10,
                  color: flow.consistentAngleEnabled
                      ? AppColors.gold
                      : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAngleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: InclinometerWidget(
        prefilledAngle: _pegFlowProvider.currentPeg?.angleDegrees,
        onAngleConfirmed: (angle) {
          setState(() {
            _confirmedAngle = angle;
          });
          _pegFlowProvider.setAngle(angle, 'gyroscope');
        },
      ),
    );
  }

  Widget _buildSightMarkRecommendation() {
    final rec = _pegFlowProvider.currentRecommendation!;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MARK: ',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                rec.displayValue,
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 24,
                  color: AppColors.gold,
                ),
              ),
              const Spacer(),
              // Confidence indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(rec.confidence).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  rec.confidence.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 9,
                    color: _getConfidenceColor(rec.confidence),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (rec.hasAdjustments) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              rec.breakdownText,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 10,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getConfidenceColor(dynamic confidence) {
    final name = confidence.toString().split('.').last;
    switch (name) {
      case 'high':
        return AppColors.gold;
      case 'medium':
        return AppColors.textPrimary;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _buildScoringModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _ModeToggleButton(
              label: 'PLOT',
              icon: Icons.gps_fixed,
              isSelected: _pegFlowProvider.scoringMode == FieldScoringMode.plotting,
              onTap: () => _pegFlowProvider.setScoringMode(FieldScoringMode.plotting),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ModeToggleButton(
              label: 'BUTTONS',
              icon: Icons.grid_view,
              isSelected: _pegFlowProvider.scoringMode == FieldScoringMode.buttons,
              onTap: () => _pegFlowProvider.setScoringMode(FieldScoringMode.buttons),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringArea(FieldSessionProvider session) {
    final target = session.currentTarget;

    if (target == null && session.isNewCourseCreation) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flag_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Define this target first',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Peg flow mode
    if (_isPegFlowActive) {
      final currentPeg = _pegFlowProvider.currentPeg;
      if (currentPeg != null && !currentPeg.isScored) {
        if (_pegFlowProvider.scoringMode == FieldScoringMode.plotting) {
          return _buildPlottingArea(session);
        } else {
          return _buildButtonScoringArea(session);
        }
      }
      // Current peg already scored — show the arrow result
      if (currentPeg != null && currentPeg.isScored) {
        return _buildScoredPegDisplay(currentPeg);
      }
    }

    // Legacy button scoring (fallback)
    return _buildLegacyButtonScoring(session);
  }

  Widget _buildPlottingArea(FieldSessionProvider session) {
    final flow = _pegFlowProvider.pegFlow!;
    final existingArrows = flow.pegs
        .where((p) => p.isScored && p.arrowScore?.coordinate != null)
        .map((p) => p.arrowScore!.coordinate!)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AspectRatio(
        aspectRatio: 1,
        child: FieldInteractiveTargetFace(
          existingArrows: existingArrows,
          faceSizeCm: flow.faceSize,
          roundType: session.roundType ?? FieldRoundType.field,
          enabled: !_pegFlowProvider.currentPeg!.isScored,
          onArrowScored: (result) {
            _pegFlowProvider.scoreArrowByPlot(result.coordinate, result.zone);
          },
        ),
      ),
    );
  }

  Widget _buildButtonScoringArea(FieldSessionProvider session) {
    final zones = FieldScoringUtils.getZonesForRoundType(
      session.roundType ?? FieldRoundType.field,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.center,
        children: zones.map((zone) {
          return _ScoreButton(
            zone: zone,
            onTap: () => _pegFlowProvider.scoreArrowByButton(zone),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoredPegDisplay(FieldPegState peg) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getScoreColor(peg.arrowScore!.zone),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                peg.arrowScore!.zone.display,
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 36,
                  color: _getScoreTextColor(peg.arrowScore!.zone),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Arrow ${peg.pegIndex + 1}: ${peg.arrowScore!.zone.display}',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoorShotToggle() {
    final currentPeg = _pegFlowProvider.currentPeg;
    if (currentPeg == null || !currentPeg.isScored) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showPoorShotMenu(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: currentPeg.isPoorShot
                    ? Colors.orange.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(
                  color: currentPeg.isPoorShot
                      ? Colors.orange
                      : AppColors.surfaceLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentPeg.isPoorShot ? Icons.warning : Icons.warning_outlined,
                    size: 16,
                    color: currentPeg.isPoorShot ? Colors.orange : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    currentPeg.isPoorShot
                        ? 'POOR SHOT (${currentPeg.poorShotDirection?.toUpperCase() ?? ""})'
                        : 'POOR SHOT?',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      color: currentPeg.isPoorShot ? Colors.orange : AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPoorShotMenu() {
    final currentPeg = _pegFlowProvider.currentPeg;
    if (currentPeg == null) return;

    if (currentPeg.isPoorShot) {
      // Already marked — un-mark it
      _pegFlowProvider.togglePoorShot();
      return;
    }

    // Show direction picker
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'POOR SHOT DIRECTION',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PoorShotDirectionButton(
                    label: 'HIGH',
                    icon: Icons.arrow_upward,
                    onTap: () {
                      _pegFlowProvider.togglePoorShot(direction: 'high');
                      Navigator.pop(context);
                    },
                  ),
                  _PoorShotDirectionButton(
                    label: 'LOW',
                    icon: Icons.arrow_downward,
                    onTap: () {
                      _pegFlowProvider.togglePoorShot(direction: 'low');
                      Navigator.pop(context);
                    },
                  ),
                  _PoorShotDirectionButton(
                    label: 'LEFT',
                    icon: Icons.arrow_back,
                    onTap: () {
                      _pegFlowProvider.togglePoorShot(direction: 'left');
                      Navigator.pop(context);
                    },
                  ),
                  _PoorShotDirectionButton(
                    label: 'RIGHT',
                    icon: Icons.arrow_forward,
                    onTap: () {
                      _pegFlowProvider.togglePoorShot(direction: 'right');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPegActionButton(FieldSessionProvider session) {
    final flow = _pegFlowProvider.pegFlow;
    if (flow == null) return const SizedBox.shrink();

    final currentPeg = _pegFlowProvider.currentPeg;
    if (currentPeg == null || !currentPeg.isScored) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: flow.isComplete
              ? () => _submitPegFlowScores(session)
              : flow.canAdvance
                  ? () {
                      _confirmedAngle = null; // Reset for next peg
                      _pegFlowProvider.nextPeg();
                    }
                  : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: flow.isComplete ? AppColors.gold : null,
            foregroundColor: flow.isComplete ? AppColors.background : null,
          ),
          child: Text(
            flow.isComplete
                ? 'SUBMIT TARGET: ${flow.totalScore}${flow.totalXCount > 0 ? " (${flow.totalXCount}X)" : ""}'
                : 'NEXT PEG',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPegFlowScores(FieldSessionProvider session) async {
    final scores = _pegFlowProvider.getFinalScores();
    final pegSightMarks = _pegFlowProvider.getPegSightMarks();

    await session.scoreTarget(
      arrowScores: scores,
      sightMarkUsed: pegSightMarks != null ? jsonEncode(pegSightMarks) : _sightMarkUsed,
    );

    // Show sightmark recording sheet
    if (mounted) {
      final pegs = _pegFlowProvider.pegFlow?.pegs ?? [];
      final isWalkDown = _pegFlowProvider.pegFlow?.isWalkDown ?? false;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => FieldSightmarkRecordSheet(
          pegs: pegs,
          isWalkDown: isWalkDown,
          onSave: (marks) {
            // TODO: Persist via FieldSightMarkProvider.recordActualMark
          },
        ),
      );
    }

    // Move to next target
    if (session.currentTargetNumber < session.targetCount) {
      session.nextTarget();
    }
    _loadTargetScores(session);
  }

  // ===========================================================================
  // LEGACY BUTTON SCORING (non-peg-flow fallback)
  // ===========================================================================

  Widget _buildLegacyButtonScoring(FieldSessionProvider session) {
    final target = session.currentTarget;
    final arrowsRequired = target?.arrowsRequired ?? 4;
    final zones = FieldScoringUtils.getZonesForRoundType(
      session.roundType ?? FieldRoundType.field,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _buildArrowSlots(arrowsRequired),
          const SizedBox(height: AppSpacing.xl),
          _buildScoreButtons(zones, arrowsRequired),
        ],
      ),
    );
  }

  Widget _buildArrowSlots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(count, (index) {
        final hasScore = index < _currentArrowScores.length;
        final score = hasScore ? _currentArrowScores[index] : null;

        return GestureDetector(
          onTap: hasScore
              ? () {
                  setState(() {
                    _currentArrowScores.removeRange(index, _currentArrowScores.length);
                  });
                }
              : null,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: hasScore ? _getScoreColor(score!.zone) : AppColors.surfaceDark,
              border: Border.all(
                color: index == _currentArrowScores.length
                    ? AppColors.gold
                    : AppColors.surfaceLight,
                width: index == _currentArrowScores.length ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              hasScore ? score!.zone.display : '${index + 1}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: hasScore
                        ? _getScoreTextColor(score!.zone)
                        : AppColors.textMuted,
                    fontFamily: AppFonts.pixel,
                  ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildScoreButtons(List<FieldScoringZone> zones, int arrowsRequired) {
    if (_currentArrowScores.length >= arrowsRequired) {
      return ElevatedButton(
        onPressed: _submitScores,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Submit: ${_calculateTotal()}', style: const TextStyle(fontSize: 18)),
            if (_calculateXCount() > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Text('(${_calculateXCount()}X)', style: const TextStyle(color: AppColors.gold)),
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: zones.map((zone) {
        return _ScoreButton(zone: zone, onTap: () => _addScore(zone));
      }).toList(),
    );
  }

  Widget _buildSightMarkRow(FieldSessionProvider session, FieldCourseTarget target) {
    return Consumer2<FieldSightMarkProvider, SightMarksProvider>(
      builder: (context, fieldSightMarks, baseSightMarks, _) {
        return FutureBuilder<FieldPredictedSightMark?>(
          future: _getPredictedSightMark(session, target, fieldSightMarks),
          builder: (context, snapshot) {
            final prediction = snapshot.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sight Mark:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _sightMarkController,
                          decoration: InputDecoration(
                            hintText: prediction?.displayValue ?? 'Enter sight mark',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.xs),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            suffixIcon: prediction != null
                                ? IconButton(
                                    icon: const Icon(Icons.auto_awesome, size: 18),
                                    color: AppColors.gold,
                                    tooltip: 'Use predicted',
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      _sightMarkController.text = prediction.displayValue;
                                      _sightMarkUsed = prediction.displayValue;
                                    },
                                  )
                                : null,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) => _sightMarkUsed = value,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    if (prediction != null) ...[
                      Icon(Icons.lightbulb_outline, size: 14, color: AppColors.gold.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getPredictionLabel(prediction),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.gold.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    GestureDetector(
                      onTap: () => _showSightMarksSheet(target),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'See marks',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomControls(FieldSessionProvider session) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surfaceDark,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildProgressDots(session)),
            const SizedBox(width: AppSpacing.md),
            if (session.isSessionComplete)
              ElevatedButton(
                onPressed: () => _finishSession(session),
                child: const Text('Finish Round'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots(FieldSessionProvider session) {
    final completedSet = session.scoredTargets.map((t) => t.targetNumber).toSet();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(session.targetCount, (index) {
          final targetNum = index + 1;
          final isCompleted = completedSet.contains(targetNum);
          final isCurrent = targetNum == session.currentTargetNumber;

          return GestureDetector(
            onTap: () {
              _saveSightMarkForTarget(session.currentTargetNumber);
              session.goToTarget(targetNum);
              _loadTargetScores(session);
            },
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.gold
                    : isCurrent
                        ? AppColors.gold.withValues(alpha: 0.5)
                        : AppColors.surfaceLight,
                border: isCurrent ? Border.all(color: AppColors.gold, width: 2) : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // TARGET INITIALIZATION & SCORING HELPERS
  // ===========================================================================

  void _initializePegFlow(FieldSessionProvider session) {
    final target = session.currentTarget;
    if (target == null) {
      _isPegFlowActive = false;
      return;
    }

    // Initialize peg flow for this target
    _pegFlowProvider.initializeForTarget(
      target: target,
      arrowSpeedFps: 195.0, // TODO: Get from bow profile
    );

    _isPegFlowActive = true;
    _confirmedAngle = null;
  }

  void _saveSightMarkForTarget(int targetNum) {
    if (_sightMarkUsed != null && _sightMarkUsed!.isNotEmpty) {
      _sightMarksByTarget[targetNum] = _sightMarkUsed!;
    }
  }

  void _loadTargetScores(FieldSessionProvider session) {
    final targetNum = session.currentTargetNumber;

    setState(() {
      _currentArrowScores.clear();

      final existingScore = session.scoredTargets
          .where((t) => t.targetNumber == targetNum)
          .firstOrNull;

      if (existingScore != null) {
        _currentArrowScores.addAll(existingScore.arrowScores);
        _sightMarkUsed = existingScore.sightMarkUsed;
        _sightMarkController.text = _sightMarkUsed ?? '';
        _isPegFlowActive = false;
      } else {
        _sightMarkUsed = _sightMarksByTarget[targetNum];
        _sightMarkController.text = _sightMarkUsed ?? '';
        _initializePegFlow(session);
      }
    });
  }

  void _addScore(FieldScoringZone zone) {
    setState(() {
      _currentArrowScores.add(FieldArrowScore(
        arrowNumber: _currentArrowScores.length + 1,
        zone: zone,
      ));
    });
  }

  int _calculateTotal() => _currentArrowScores.fold(0, (sum, a) => sum + a.score);
  int _calculateXCount() => _currentArrowScores.where((a) => a.isX).length;

  Future<void> _submitScores() async {
    final session = context.read<FieldSessionProvider>();
    await session.scoreTarget(
      arrowScores: _currentArrowScores,
      sightMarkUsed: _sightMarkUsed,
    );
    if (session.currentTargetNumber < session.targetCount) {
      session.nextTarget();
    }
    _loadTargetScores(session);
  }

  Future<FieldPredictedSightMark?> _getPredictedSightMark(
    FieldSessionProvider session,
    FieldCourseTarget target,
    FieldSightMarkProvider fieldSightMarks,
  ) async {
    final bowId = session.course?.id;
    if (bowId == null) return null;
    return fieldSightMarks.getPredictedMark(
      courseTargetId: target.id,
      bowId: bowId,
      distance: target.primaryDistance,
      unit: target.unit,
    );
  }

  String _getPredictionLabel(FieldPredictedSightMark prediction) {
    if (prediction.hasCourseLearning) {
      return 'Predicted: ${prediction.displayValue} (${prediction.differentialDisplay} from ${prediction.shotCount} shots)';
    }
    return 'Predicted: ${prediction.displayValue}';
  }

  void _showSightMarksSheet(FieldCourseTarget target) {
    final sightMarksProvider = context.read<SightMarksProvider>();
    final session = context.read<FieldSessionProvider>();
    final bowId = session.course?.id ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final marks = sightMarksProvider.getMarksForBow(bowId);
        final nearbyMarks = marks.where((m) {
          final diff = (m.distance - target.primaryDistance).abs();
          return diff <= 10;
        }).toList()
          ..sort((a, b) =>
              (a.distance - target.primaryDistance).abs()
                  .compareTo((b.distance - target.primaryDistance).abs()));

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sight Marks near ${target.primaryDistance.round()}${target.unit.abbreviation}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: AppFonts.pixel),
              ),
              const SizedBox(height: AppSpacing.md),
              if (nearbyMarks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No recorded sight marks near this distance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                )
              else
                ...nearbyMarks.take(5).map((mark) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${mark.distance.round()}${mark.unit.abbreviation}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gold),
                        ),
                      ),
                      title: Text(
                        mark.sightValue,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: AppFonts.pixel),
                      ),
                      subtitle: mark.isIndoor
                          ? Text('Indoor', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted))
                          : null,
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        _sightMarkController.text = mark.sightValue;
                        _sightMarkUsed = mark.sightValue;
                        Navigator.pop(context);
                      },
                    )),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTargetSetupSheet(FieldSessionProvider session) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FieldTargetSetupSheet(
        targetNumber: session.currentTargetNumber,
        roundType: session.roundType ?? FieldRoundType.field,
        onSave: (pegConfig, faceSize, notes) async {
          await session.defineTarget(
            pegConfig: pegConfig,
            faceSize: faceSize,
            notes: notes,
          );
          if (mounted) Navigator.pop(context);
        },
      ),
    );
    // Re-initialize peg flow after target is defined
    if (mounted) {
      final s = context.read<FieldSessionProvider>();
      _initializePegFlow(s);
      setState(() {});
    }
  }

  Future<void> _finishSession(FieldSessionProvider session) async {
    await session.completeSession();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FieldSessionCompleteScreen()),
      );
    }
  }

  Future<void> _showExitConfirmation(FieldSessionProvider session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Session?'),
        content: const Text('Your progress will be lost. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await session.cancelSession();
      Navigator.pop(context);
    }
  }

  Color _getScoreColor(FieldScoringZone zone) {
    switch (zone) {
      case FieldScoringZone.x:
      case FieldScoringZone.five:
        return AppColors.gold;
      case FieldScoringZone.four:
        return AppColors.ring8;
      case FieldScoringZone.three:
        return AppColors.ring6;
      case FieldScoringZone.two:
        return AppColors.ring4;
      case FieldScoringZone.one:
        return AppColors.ring2;
      case FieldScoringZone.miss:
        return AppColors.surfaceLight;
    }
  }

  Color _getScoreTextColor(FieldScoringZone zone) {
    switch (zone) {
      case FieldScoringZone.x:
      case FieldScoringZone.five:
        return AppColors.background;
      case FieldScoringZone.four:
      case FieldScoringZone.three:
      case FieldScoringZone.two:
        return AppColors.textPrimary;
      case FieldScoringZone.one:
        return AppColors.background;
      case FieldScoringZone.miss:
        return AppColors.textSecondary;
    }
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _ScoreButton extends StatelessWidget {
  final FieldScoringZone zone;
  final VoidCallback onTap;

  const _ScoreButton({required this.zone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getButtonColor();
    final textColor = _getTextColor();

    return SizedBox(
      width: 64,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ),
        child: Text(
          zone.display,
          style: TextStyle(
            fontSize: 24,
            fontFamily: AppFonts.pixel,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (zone) {
      case FieldScoringZone.x:
      case FieldScoringZone.five:
        return AppColors.gold;
      case FieldScoringZone.four:
        return AppColors.ring8;
      case FieldScoringZone.three:
        return AppColors.ring6;
      case FieldScoringZone.two:
        return AppColors.ring4;
      case FieldScoringZone.one:
        return AppColors.ring2;
      case FieldScoringZone.miss:
        return AppColors.surfaceLight;
    }
  }

  Color _getTextColor() {
    switch (zone) {
      case FieldScoringZone.x:
      case FieldScoringZone.five:
        return AppColors.background;
      case FieldScoringZone.one:
        return AppColors.background;
      default:
        return AppColors.textPrimary;
    }
  }
}

class _ModeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.gold : AppColors.textMuted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoorShotDirectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PoorShotDirectionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 10,
                color: Colors.orange,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
