import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bow_training_provider.dart';
import '../db/database.dart';

/// Introduction screen for bow training with quick-start options
/// Most users just want to pick duration + work/rest ratio and go
/// Structured progression is available via "Details" button
class BowTrainingIntroScreen extends StatefulWidget {
  const BowTrainingIntroScreen({super.key});

  @override
  State<BowTrainingIntroScreen> createState() => _BowTrainingIntroScreenState();
}

class _BowTrainingIntroScreenState extends State<BowTrainingIntroScreen> {
  // Quick start settings
  int _selectedDuration = 10; // minutes
  double _selectedWorkRatio = 0.5; // work:rest ratio (0.5 = 1:2)

  // Available duration options
  static const List<int> _durationOptions = [3, 5, 10, 15, 20, 25, 30];

  // Work/rest ratio presets with display labels
  static const List<({double ratio, String label, String description})>
      _ratioOptions = [
    (ratio: 0.33, label: '1:3', description: 'Easy'),
    (ratio: 0.5, label: '1:2', description: 'Moderate'),
    (ratio: 0.67, label: '2:3', description: 'Challenging'),
    (ratio: 1.0, label: '1:1', description: 'Hard'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BowTrainingProvider>().loadData();
    });
  }

  void _startQuickSession() {
    final provider = context.read<BowTrainingProvider>();
    provider.startQuickSession(
      durationMinutes: _selectedDuration,
      workRatio: _selectedWorkRatio,
    );
  }

  void _startMaxHoldTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MaxHoldTestScreen(),
      ),
    );
  }

  void _showStructuredSessions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StructuredSessionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BowTrainingProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bow Training'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: _showStructuredSessions,
                child: const Text('Details'),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User level indicator (if available)
                  if (provider.userProgress != null) ...[
                    _LevelIndicator(progress: provider.userProgress!),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Duration selector
                  Text(
                    'Duration',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DurationSelector(
                    options: _durationOptions,
                    selected: _selectedDuration,
                    onChanged: (v) => setState(() => _selectedDuration = v),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Work/Rest ratio selector
                  Text(
                    'Work / Rest Ratio',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RatioSelector(
                    options: _ratioOptions,
                    selected: _selectedWorkRatio,
                    onChanged: (v) => setState(() => _selectedWorkRatio = v),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Calculated hold/rest display
                  _HoldRestPreview(
                    ratio: _selectedWorkRatio,
                    durationMinutes: _selectedDuration,
                  ),

                  const Spacer(),

                  // Start button
                  ElevatedButton(
                    onPressed: _startQuickSession,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: Text(
                      'Start ${_selectedDuration} min Session',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Test max hold button
                  OutlinedButton(
                    onPressed: _startMaxHoldTest,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gold),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Test Max Hold',
                      style: TextStyle(color: AppColors.gold),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Explanation text
                  Text(
                    'Test your max hold to get a personalised starting level',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compact level indicator
class _LevelIndicator extends StatelessWidget {
  final UserTrainingProgressData progress;

  const _LevelIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              progress.currentLevel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Current Level',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          Text(
            '${progress.totalSessionsCompleted} sessions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

/// Duration selector chips
class _DurationSelector extends StatelessWidget {
  final List<int> options;
  final int selected;
  final ValueChanged<int> onChanged;

  const _DurationSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((duration) {
          final isSelected = duration == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onChanged(duration),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.surfaceLight,
                  ),
                ),
                child: Text(
                  '$duration min',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.backgroundDark
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Work/rest ratio selector
class _RatioSelector extends StatelessWidget {
  final List<({double ratio, String label, String description})> options;
  final double selected;
  final ValueChanged<double> onChanged;

  const _RatioSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = (option.ratio - selected).abs() < 0.01;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option == options.last ? 0 : AppSpacing.sm,
            ),
            child: GestureDetector(
              onTap: () => onChanged(option.ratio),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold.withOpacity(0.15)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.surfaceLight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.gold.withOpacity(0.8)
                            : AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Shows calculated hold/rest times based on ratio
class _HoldRestPreview extends StatelessWidget {
  final double ratio;
  final int durationMinutes;

  const _HoldRestPreview({
    required this.ratio,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate hold and rest times
    // For a given ratio, if ratio = work/rest, then:
    // work = ratio / (1 + ratio) * cycle_time
    // rest = 1 / (1 + ratio) * cycle_time
    // Using 40s cycle as base for calculations
    final cycleTime = 40.0;
    final holdTime = (ratio / (1 + ratio) * cycleTime).round();
    final restTime = (cycleTime - holdTime).round();

    // Calculate approximate reps
    final cycleSeconds = holdTime + restTime;
    final totalSeconds = durationMinutes * 60;
    final approxReps = (totalSeconds / cycleSeconds).floor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TimeChip(
            label: 'Hold',
            seconds: holdTime,
            color: AppColors.gold,
          ),
          const SizedBox(width: AppSpacing.md),
          _TimeChip(
            label: 'Rest',
            seconds: restTime,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '~$approxReps reps',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final int seconds;
  final Color color;

  const _TimeChip({
    required this.label,
    required this.seconds,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        Text(
          '${seconds}s',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// =============================================================================
// MAX HOLD TEST SCREEN
// =============================================================================

class MaxHoldTestScreen extends StatefulWidget {
  const MaxHoldTestScreen({super.key});

  @override
  State<MaxHoldTestScreen> createState() => _MaxHoldTestScreenState();
}

class _MaxHoldTestScreenState extends State<MaxHoldTestScreen> {
  _TestPhase _phase = _TestPhase.instructions;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int? _maxHoldResult;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _phase = _TestPhase.countdown;
      _elapsedSeconds = 3;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_phase == _TestPhase.countdown) {
        setState(() {
          _elapsedSeconds--;
          if (_elapsedSeconds <= 0) {
            _phase = _TestPhase.holding;
            _elapsedSeconds = 0;
            HapticFeedback.heavyImpact();
          }
        });
      } else if (_phase == _TestPhase.holding) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _stopHold() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _maxHoldResult = _elapsedSeconds;
      _phase = _TestPhase.result;
    });
  }

  String _getSuggestedLevel() {
    if (_maxHoldResult == null) return '1.0';
    final hold = _maxHoldResult!;

    if (hold < 8) return '0.3';
    if (hold < 12) return '0.5';
    if (hold < 18) return '0.7';
    if (hold < 25) return '1.0';
    return '1.3';
  }

  String _getLevelDescription() {
    final level = _getSuggestedLevel();
    switch (level) {
      case '0.3':
        return 'Starting point for complete bow training novices';
      case '0.5':
        return 'Building basic holding capacity';
      case '0.7':
        return 'Foundation level - building consistency';
      case '1.0':
        return 'Standard starting level';
      case '1.3':
        return 'Intermediate level - you have good holding capacity';
      default:
        return 'Standard starting level';
    }
  }

  void _applyLevel() async {
    final provider = context.read<BowTrainingProvider>();
    await provider.setUserLevel(_getSuggestedLevel());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Max Hold Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _buildPhaseContent(),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _TestPhase.instructions:
        return _InstructionsView(onStart: _startTest);
      case _TestPhase.countdown:
        return _CountdownView(seconds: _elapsedSeconds);
      case _TestPhase.holding:
        return _HoldingView(
          seconds: _elapsedSeconds,
          onStop: _stopHold,
        );
      case _TestPhase.result:
        return _ResultView(
          holdSeconds: _maxHoldResult!,
          suggestedLevel: _getSuggestedLevel(),
          levelDescription: _getLevelDescription(),
          onApply: _applyLevel,
          onRetry: () {
            setState(() {
              _phase = _TestPhase.instructions;
              _elapsedSeconds = 0;
              _maxHoldResult = null;
            });
          },
        );
    }
  }
}

enum _TestPhase { instructions, countdown, holding, result }

class _InstructionsView extends StatelessWidget {
  final VoidCallback onStart;

  const _InstructionsView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.info_outline,
          color: AppColors.gold,
          size: 48,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Max Hold Test',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        _InstructionItem(
          number: '1',
          text: 'Warm up first - do some light draws and stretches',
        ),
        _InstructionItem(
          number: '2',
          text: 'Draw your bow with elbow sling and hold at full draw',
        ),
        _InstructionItem(
          number: '3',
          text: 'Maintain good form - stop if form breaks down',
        ),
        _InstructionItem(
          number: '4',
          text: 'Tap the screen when you let down',
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Only do this test if warmed up. Stop immediately if you feel pain.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: onStart,
          child: const Text('Start Test'),
        ),
      ],
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownView extends StatelessWidget {
  final int seconds;

  const _CountdownView({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Get Ready',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '$seconds',
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Draw to full when timer starts',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }
}

class _HoldingView extends StatelessWidget {
  final int seconds;
  final VoidCallback onStop;

  const _HoldingView({
    required this.seconds,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStop,
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HOLD',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _formatTime(seconds),
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 96,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: const Text(
                'TAP ANYWHERE TO STOP',
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ResultView extends StatelessWidget {
  final int holdSeconds;
  final String suggestedLevel;
  final String levelDescription;
  final VoidCallback onApply;
  final VoidCallback onRetry;

  const _ResultView({
    required this.holdSeconds,
    required this.suggestedLevel,
    required this.levelDescription,
    required this.onApply,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 64,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Max Hold',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        Text(
          '${holdSeconds}s',
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Suggested Starting Level',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Level $suggestedLevel',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                levelDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: onApply,
          child: const Text('Use This Level'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: onRetry,
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}

// =============================================================================
// STRUCTURED SESSIONS SCREEN (Details view)
// =============================================================================

class StructuredSessionsScreen extends StatelessWidget {
  const StructuredSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BowTrainingProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Structured Sessions'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: () => _showMoreDetails(context),
                child: const Text('More Details'),
              ),
            ],
          ),
          body: SafeArea(
            child: provider.sessionTemplates.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                : _StructuredSessionsList(provider: provider),
          ),
        );
      },
    );
  }

  void _showMoreDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _MoreDetailsSheet(),
    );
  }
}

class _StructuredSessionsList extends StatelessWidget {
  final BowTrainingProvider provider;

  const _StructuredSessionsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final suggested = provider.suggestedSession;
    final sessionsByLevel = provider.sessionsByLevel;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // User progress summary
        if (provider.userProgress != null) ...[
          _ProgressSummaryCard(progress: provider.userProgress!),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Suggested next session
        if (suggested != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              'Recommended',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          _StructuredSessionCard(
            session: suggested,
            isRecommended: true,
            onTap: () {
              provider.startSession(suggested);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Recent sessions
        if (provider.recentLogs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          ...provider.recentLogs.take(3).map((log) => _RecentLogTile(log: log)),
          const SizedBox(height: AppSpacing.lg),
        ],

        // All sessions grouped by level
        ...sessionsByLevel.entries.map((entry) => _SessionLevelGroupExpanded(
              levelName: entry.key,
              sessions: entry.value,
              suggestedId: suggested?.id,
              provider: provider,
            )),
      ],
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  final UserTrainingProgressData progress;

  const _ProgressSummaryCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Center(
              child: Text(
                progress.currentLevel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Level',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                Text(
                  'Session ${progress.currentLevel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${progress.totalSessionsCompleted}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.gold,
                    ),
              ),
              Text(
                'total sessions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StructuredSessionCard extends StatelessWidget {
  final OlySessionTemplate session;
  final bool isRecommended;
  final VoidCallback onTap;

  const _StructuredSessionCard({
    required this.session,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isRecommended
          ? AppColors.gold.withOpacity(0.1)
          : AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        side: isRecommended
            ? BorderSide(color: AppColors.gold.withOpacity(0.5))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRecommended
                      ? AppColors.gold.withOpacity(0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Center(
                  child: Text(
                    session.version,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isRecommended
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isRecommended
                                ? AppColors.gold
                                : AppColors.textPrimary,
                          ),
                    ),
                    if (session.focus != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.focus!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.durationMinutes} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isRecommended
                              ? AppColors.gold
                              : AppColors.textSecondary,
                        ),
                  ),
                  Icon(
                    Icons.play_arrow,
                    color: isRecommended ? AppColors.gold : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionLevelGroupExpanded extends StatefulWidget {
  final String levelName;
  final List<OlySessionTemplate> sessions;
  final String? suggestedId;
  final BowTrainingProvider provider;

  const _SessionLevelGroupExpanded({
    required this.levelName,
    required this.sessions,
    required this.suggestedId,
    required this.provider,
  });

  @override
  State<_SessionLevelGroupExpanded> createState() =>
      _SessionLevelGroupExpandedState();
}

class _SessionLevelGroupExpandedState
    extends State<_SessionLevelGroupExpanded> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessions.any((s) => s.id == widget.suggestedId)) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.levelName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${widget.sessions.length} sessions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          ...widget.sessions
              .where((s) => s.id != widget.suggestedId)
              .map((session) => _StructuredSessionCard(
                    session: session,
                    isRecommended: false,
                    onTap: () {
                      widget.provider.startSession(session);
                      Navigator.pop(context);
                    },
                  )),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _RecentLogTile extends StatelessWidget {
  final OlyTrainingLog log;

  const _RecentLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(log.completedAt);
    final completionRate = log.plannedExercises > 0
        ? (log.completedExercises / log.plannedExercises * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      color: AppColors.surfaceLight.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              _getSuggestionIcon(log.progressionSuggestion),
              color: _getSuggestionColor(log.progressionSuggestion),
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                log.sessionName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              '$completionRate%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              dateStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSuggestionIcon(String? suggestion) {
    switch (suggestion) {
      case 'progress':
        return Icons.arrow_upward;
      case 'regress':
        return Icons.arrow_downward;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _getSuggestionColor(String? suggestion) {
    switch (suggestion) {
      case 'progress':
        return AppColors.success;
      case 'regress':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

class _MoreDetailsSheet extends StatelessWidget {
  const _MoreDetailsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
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
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'About the Training System',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The OLY Bow Training System is a 26-week progressive program for building holding strength with an elbow sling.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailItem(
            icon: Icons.trending_up,
            title: 'Progressive Overload',
            description: 'Sessions increase in volume, duration, and work ratio',
          ),
          _DetailItem(
            icon: Icons.psychology,
            title: 'Adaptive Difficulty',
            description: 'System adjusts based on your feedback after each session',
          ),
          _DetailItem(
            icon: Icons.health_and_safety,
            title: 'Safety First',
            description: 'Automatic regression when form breaks down',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
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
