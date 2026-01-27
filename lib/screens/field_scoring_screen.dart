import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/field_course.dart';
import '../models/field_course_target.dart';
import '../models/field_scoring.dart';
import '../providers/field_session_provider.dart';
import '../providers/field_course_provider.dart';
import '../providers/field_sight_mark_provider.dart';
import '../providers/sight_marks_provider.dart';
import '../widgets/field_target_setup_sheet.dart';
import '../widgets/field_scorecard_widget.dart';
import 'field_session_complete_screen.dart';
import 'animal_scoring_screen.dart';

class FieldScoringScreen extends StatefulWidget {
  const FieldScoringScreen({super.key});

  @override
  State<FieldScoringScreen> createState() => _FieldScoringScreenState();
}

class _FieldScoringScreenState extends State<FieldScoringScreen>
    with SingleTickerProviderStateMixin {
  // Arrow scores for current target
  final List<FieldArrowScore> _currentArrowScores = [];
  String? _sightMarkUsed;

  // Track sight marks per target (persists during navigation)
  final Map<int, String> _sightMarksByTarget = {};

  // Track if current target was already scored (editing mode)
  bool _isEditingScored = false;

  // Sight mark text controller
  final TextEditingController _sightMarkController = TextEditingController();

  // Tab controller for scoring/scorecard views
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sightMarkController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FieldSessionProvider>(
      builder: (context, session, _) {
        // Handle animal round separately
        if (session.roundType == FieldRoundType.animal) {
          return const AnimalScoringScreen();
        }

        return Scaffold(
          appBar: _buildAppBar(session),
          body: Column(
            children: [
              // Tab bar
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

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Scoring tab
                    Column(
                      children: [
                        // Target info header
                        _buildTargetHeader(session),

                        // Scoring area
                        Expanded(
                          child: _buildScoringArea(session),
                        ),
                      ],
                    ),

                    // Scorecard tab
                    FieldScorecardWidget(
                      session: session,
                      onTargetTap: (targetNum) {
                        _saveSightMarkForTarget(session.currentTargetNumber);
                        session.goToTarget(targetNum);
                        _loadTargetScores(session);
                        _tabController.animateTo(0); // Switch back to scoring
                      },
                    ),
                  ],
                ),
              ),

              // Bottom controls
              _buildBottomControls(session),
            ],
          ),
        );
      },
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
        // Running total
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
          // Target navigation
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
              Column(
                children: [
                  Text(
                    'Target ${session.currentTargetNumber}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: AppFonts.pixel,
                        ),
                  ),
                  if (target != null)
                    Text(
                      '${target.distanceDisplay} - ${target.faceSizeDisplay}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
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

          // Sight mark prediction
          if (target != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildSightMarkRow(session, target),
          ],
        ],
      ),
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
                // Show prediction info and see sight marks option
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    if (prediction != null) ...[
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: AppColors.gold.withValues(alpha: 0.7),
                      ),
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
                    // See sight marks link
                    GestureDetector(
                      onTap: () => _showSightMarksSheet(target),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.list_alt,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
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

  Future<FieldPredictedSightMark?> _getPredictedSightMark(
    FieldSessionProvider session,
    FieldCourseTarget target,
    FieldSightMarkProvider fieldSightMarks,
  ) async {
    // Need bow ID from session - for now use a placeholder
    // In production this would come from the session's selected bow
    final bowId = session.course?.id; // Placeholder
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
    // TODO: Get actual bow ID from session
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
          // Show marks within 10 units of target distance
          final diff = (m.distance - target.primaryDistance).abs();
          return diff <= 10;
        }).toList()
          ..sort((a, b) =>
              (a.distance - target.primaryDistance)
                  .abs()
                  .compareTo((b.distance - target.primaryDistance).abs()));

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sight Marks near ${target.primaryDistance.round()}${target.unit.abbreviation}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: AppFonts.pixel,
                    ),
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
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${mark.distance.round()}${mark.unit.abbreviation}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.gold,
                              ),
                        ),
                      ),
                      title: Text(
                        mark.sightValue,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontFamily: AppFonts.pixel,
                            ),
                      ),
                      subtitle: mark.isIndoor
                          ? Text(
                              'Indoor',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            )
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

  Widget _buildScoringArea(FieldSessionProvider session) {
    final target = session.currentTarget;
    final roundType = session.roundType;

    if (target == null && session.isNewCourseCreation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Define this target first',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    final arrowsRequired = target?.arrowsRequired ?? 4;
    final zones = FieldScoringUtils.getZonesForRoundType(
      roundType ?? FieldRoundType.field,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Arrow score slots
          _buildArrowSlots(arrowsRequired),

          const SizedBox(height: AppSpacing.xl),

          // Score buttons
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
                  // Remove this and subsequent scores
                  setState(() {
                    _currentArrowScores.removeRange(
                      index,
                      _currentArrowScores.length,
                    );
                  });
                }
              : null,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: hasScore
                  ? _getScoreColor(score!.zone)
                  : AppColors.surfaceDark,
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
      // All arrows scored - show submit button
      return ElevatedButton(
        onPressed: _submitScores,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Submit: ${_calculateTotal()}',
              style: const TextStyle(fontSize: 18),
            ),
            if (_calculateXCount() > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '(${_calculateXCount()}X)',
                style: const TextStyle(color: AppColors.gold),
              ),
            ],
          ],
        ),
      );
    }

    // Show scoring zone buttons
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: zones.map((zone) {
        return _ScoreButton(
          zone: zone,
          onTap: () => _addScore(zone),
        );
      }).toList(),
    );
  }

  Widget _buildBottomControls(FieldSessionProvider session) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surfaceDark,
      child: SafeArea(
        child: Row(
          children: [
            // Target progress dots
            Expanded(
              child: _buildProgressDots(session),
            ),

            const SizedBox(width: AppSpacing.md),

            // Finish button
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
    final completedSet = session.scoredTargets
        .map((t) => t.targetNumber)
        .toSet();

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
                        ? AppColors.gold.withOpacity(0.5)
                        : AppColors.surfaceLight,
                border: isCurrent
                    ? Border.all(color: AppColors.gold, width: 2)
                    : null,
              ),
            ),
          );
        }),
      ),
    );
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
      _isEditingScored = false;

      // Check if this target was already scored
      final existingScore = session.scoredTargets
          .where((t) => t.targetNumber == targetNum)
          .firstOrNull;

      if (existingScore != null) {
        // Load existing scores for review/edit
        _currentArrowScores.addAll(existingScore.arrowScores);
        _sightMarkUsed = existingScore.sightMarkUsed;
        _sightMarkController.text = _sightMarkUsed ?? '';
        _isEditingScored = true;
      } else {
        // Load persisted sight mark if any, or clear
        _sightMarkUsed = _sightMarksByTarget[targetNum];
        _sightMarkController.text = _sightMarkUsed ?? '';
      }
    });
  }

  void _resetCurrentScores() {
    // Deprecated - use _loadTargetScores instead
    final session = context.read<FieldSessionProvider>();
    _loadTargetScores(session);
  }

  void _addScore(FieldScoringZone zone) {
    setState(() {
      _currentArrowScores.add(FieldArrowScore(
        arrowNumber: _currentArrowScores.length + 1,
        zone: zone,
      ));
    });
  }

  int _calculateTotal() {
    return _currentArrowScores.fold(0, (sum, a) => sum + a.score);
  }

  int _calculateXCount() {
    return _currentArrowScores.where((a) => a.isX).length;
  }

  Future<void> _submitScores() async {
    final session = context.read<FieldSessionProvider>();

    await session.scoreTarget(
      arrowScores: _currentArrowScores,
      sightMarkUsed: _sightMarkUsed,
    );

    // Move to next target or show completion
    if (session.currentTargetNumber < session.targetCount) {
      session.nextTarget();
    }
    _resetCurrentScores();
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
  }

  Future<void> _finishSession(FieldSessionProvider session) async {
    await session.completeSession();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FieldSessionCompleteScreen(),
        ),
      );
    }
  }

  Future<void> _showExitConfirmation(FieldSessionProvider session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Session?'),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
        ),
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
        return AppColors.ring8; // Red
      case FieldScoringZone.three:
        return AppColors.ring6; // Blue
      case FieldScoringZone.two:
        return AppColors.ring4; // Black
      case FieldScoringZone.one:
        return AppColors.ring2; // White
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
        return AppColors.textPrimary;
      case FieldScoringZone.three:
        return AppColors.textPrimary;
      case FieldScoringZone.two:
        return AppColors.textPrimary;
      case FieldScoringZone.one:
        return AppColors.background;
      case FieldScoringZone.miss:
        return AppColors.textSecondary;
    }
  }
}

class _ScoreButton extends StatelessWidget {
  final FieldScoringZone zone;
  final VoidCallback onTap;

  const _ScoreButton({
    required this.zone,
    required this.onTap,
  });

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
