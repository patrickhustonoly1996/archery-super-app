import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/field_course.dart';
import '../models/field_scoring.dart';
import '../providers/field_session_provider.dart';
import '../widgets/field_target_setup_sheet.dart';
import 'field_session_complete_screen.dart';

class AnimalScoringScreen extends StatelessWidget {
  const AnimalScoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FieldSessionProvider>(
      builder: (context, session, _) {
        return Scaffold(
          appBar: _buildAppBar(context, session),
          body: Column(
            children: [
              // Target info header
              _buildTargetHeader(context, session),

              // Main scoring area
              Expanded(
                child: _buildScoringArea(context, session),
              ),

              // Bottom controls
              _buildBottomControls(context, session),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, FieldSessionProvider session) {
    return AppBar(
      title: Text(session.course?.name ?? 'Animal Round'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _showExitConfirmation(context, session),
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

  Widget _buildTargetHeader(BuildContext context, FieldSessionProvider session) {
    final target = session.currentTarget;
    final state = session.animalState;

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
                    ? () => session.previousTarget()
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
                      target.pegConfig.displayString,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: session.currentTargetNumber < session.targetCount
                    ? () => session.nextTarget()
                    : null,
              ),
            ],
          ),

          // Define target button (for new course creation)
          if (session.isNewCourseCreation && target == null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _showTargetSetupSheet(context, session),
              icon: const Icon(Icons.add),
              label: const Text('Define Target'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
              ),
            ),
          ],

          // Station indicators
          if (target != null && state != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildStationIndicators(context, session, state),
          ],
        ],
      ),
    );
  }

  Widget _buildStationIndicators(
    BuildContext context,
    FieldSessionProvider session,
    AnimalRoundState state,
  ) {
    final target = session.currentTarget;
    if (target == null) return const SizedBox.shrink();

    final distances = target.pegConfig.positions;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final stationNum = index + 1;
        final isCurrent = state.currentStation == stationNum;
        final isComplete = state.arrowsShot.any((a) => a.station == stationNum);
        final wasHit = state.scoringStation == stationNum;

        // Get distance for this station if available
        String label = 'Station $stationNum';
        if (index < distances.length) {
          label = distances[index].displayString;
        }

        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: wasHit
                    ? AppColors.success
                    : isCurrent
                        ? AppColors.gold
                        : isComplete
                            ? AppColors.error.withOpacity(0.5)
                            : AppColors.surfaceLight,
                border: Border.all(
                  color: isCurrent ? AppColors.gold : Colors.transparent,
                  width: 3,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$stationNum',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isCurrent || wasHit
                          ? AppColors.background
                          : AppColors.textPrimary,
                      fontFamily: AppFonts.pixel,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildScoringArea(BuildContext context, FieldSessionProvider session) {
    final target = session.currentTarget;
    final state = session.animalState;

    if (target == null && session.isNewCourseCreation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets_outlined,
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

    if (state == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (state.isComplete) {
      return _buildCompletedTarget(context, session, state);
    }

    return _buildScoringButtons(context, session, state);
  }

  Widget _buildCompletedTarget(
    BuildContext context,
    FieldSessionProvider session,
    AnimalRoundState state,
  ) {
    // Calculate score
    int score = 0;
    if (state.scoringStation != null) {
      final scoringArrow = state.arrowsShot.firstWhere(
        (a) => a.station == state.scoringStation && a.zone != AnimalHitZone.miss,
      );
      score = scoringArrow.getScore(isFirstScoringArrow: true);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Result indicator
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.scoringStation != null
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.error.withOpacity(0.2),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.scoringStation != null
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 48,
                  color: state.scoringStation != null
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: AppFonts.pixel,
                        color: state.scoringStation != null
                            ? AppColors.success
                            : AppColors.error,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Shot summary
          Text(
            state.scoringStation != null
                ? 'Hit on Station ${state.scoringStation}'
                : 'Miss - No Score',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Arrow breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: state.arrowsShot.map((arrow) {
              final color = arrow.zone == AnimalHitZone.vital
                  ? AppColors.success
                  : arrow.zone == AnimalHitZone.wound
                      ? AppColors.gold
                      : AppColors.error;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Chip(
                  label: Text('S${arrow.station}: ${arrow.zone.abbreviation}'),
                  backgroundColor: color.withOpacity(0.2),
                  labelStyle: TextStyle(color: color),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Continue button
          ElevatedButton(
            onPressed: () => _completeTargetAndAdvance(context, session),
            child: Text(
              session.currentTargetNumber < session.targetCount
                  ? 'Next Target'
                  : 'Complete Round',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringButtons(
    BuildContext context,
    FieldSessionProvider session,
    AnimalRoundState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Station ${state.currentStation}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: AppFonts.pixel,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Arrow ${state.arrowsShot.length + 1} of 3',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Large hit zone buttons
          Row(
            children: [
              Expanded(
                child: _HitButton(
                  label: 'VITAL',
                  sublabel: _getVitalScore(state.currentStation),
                  color: AppColors.success,
                  onTap: () => session.shootAnimalArrow(AnimalHitZone.vital),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HitButton(
                  label: 'WOUND',
                  sublabel: _getWoundScore(state.currentStation),
                  color: AppColors.gold,
                  onTap: () => session.shootAnimalArrow(AnimalHitZone.wound),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Miss button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => session.shootAnimalArrow(AnimalHitZone.miss),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                side: const BorderSide(color: AppColors.error),
              ),
              child: Text(
                state.currentStation < 3 ? 'MISS - Advance to Station ${state.currentStation + 1}' : 'MISS - No Score',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVitalScore(int station) {
    switch (station) {
      case 1:
        return '21 pts';
      case 2:
        return '18 pts';
      case 3:
        return '14 pts';
      default:
        return '';
    }
  }

  String _getWoundScore(int station) {
    switch (station) {
      case 1:
        return '20 pts';
      case 2:
        return '16 pts';
      case 3:
        return '12 pts';
      default:
        return '';
    }
  }

  Widget _buildBottomControls(BuildContext context, FieldSessionProvider session) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surfaceDark,
      child: SafeArea(
        child: Row(
          children: [
            // Target progress dots
            Expanded(
              child: _buildProgressDots(context, session),
            ),

            const SizedBox(width: AppSpacing.md),

            // Finish button
            if (session.isSessionComplete)
              ElevatedButton(
                onPressed: () => _finishSession(context, session),
                child: const Text('Finish Round'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots(BuildContext context, FieldSessionProvider session) {
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
            onTap: () => session.goToTarget(targetNum),
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

  Future<void> _completeTargetAndAdvance(
    BuildContext context,
    FieldSessionProvider session,
  ) async {
    await session.completeAnimalTarget();

    if (session.currentTargetNumber < session.targetCount) {
      session.nextTarget();
    } else if (session.isSessionComplete) {
      _finishSession(context, session);
    }
  }

  Future<void> _showTargetSetupSheet(
    BuildContext context,
    FieldSessionProvider session,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FieldTargetSetupSheet(
        targetNumber: session.currentTargetNumber,
        roundType: FieldRoundType.animal,
        onSave: (pegConfig, faceSize, notes) async {
          await session.defineTarget(
            pegConfig: pegConfig,
            faceSize: faceSize,
            notes: notes,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _finishSession(
    BuildContext context,
    FieldSessionProvider session,
  ) async {
    await session.completeSession();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const FieldSessionCompleteScreen(),
      ),
    );
  }

  Future<void> _showExitConfirmation(
    BuildContext context,
    FieldSessionProvider session,
  ) async {
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

    if (confirmed == true) {
      await session.cancelSession();
      Navigator.pop(context);
    }
  }
}

class _HitButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _HitButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: AppFonts.pixel,
                    color: AppColors.background,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              sublabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.background.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
