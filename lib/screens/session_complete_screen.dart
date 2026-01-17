import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../widgets/stat_box.dart';
import 'home_screen.dart';

class SessionCompleteScreen extends StatefulWidget {
  const SessionCompleteScreen({super.key});

  @override
  State<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends State<SessionCompleteScreen> {
  bool _hasCheckedTopPercentile = false;
  bool? _isTopScore;
  bool _snapshotSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTopPercentile();
    });
  }

  Future<void> _checkTopPercentile() async {
    if (_hasCheckedTopPercentile) return;
    _hasCheckedTopPercentile = true;

    final sessionProvider = context.read<SessionProvider>();
    final equipmentProvider = context.read<EquipmentProvider>();
    final session = sessionProvider.currentSession;
    final roundType = sessionProvider.roundType;

    if (session == null || roundType == null) return;

    final isTop = await equipmentProvider.isTopPercentileScore(
      sessionProvider.totalScore,
      roundType.id,
    );

    if (mounted && isTop == true) {
      setState(() => _isTopScore = true);
      _showKitSnapshotPrompt();
    }
  }

  void _showKitSnapshotPrompt() {
    final sessionProvider = context.read<SessionProvider>();
    final session = sessionProvider.currentSession;
    final roundType = sessionProvider.roundType;

    if (session == null || roundType == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Top 20% Score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.gold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This score is in your top 20% for ${roundType.name}. Save your current kit setup?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _saveKitSnapshot();
                    },
                    child: const Text('Save Kit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _saveKitSnapshot() async {
    final sessionProvider = context.read<SessionProvider>();
    final equipmentProvider = context.read<EquipmentProvider>();
    final session = sessionProvider.currentSession;
    final roundType = sessionProvider.roundType;

    if (session == null || roundType == null) return;

    await equipmentProvider.saveKitSnapshot(
      sessionId: session.id,
      bowId: session.bowId,
      quiverId: session.quiverId,
      score: sessionProvider.totalScore,
      maxScore: roundType.maxScore,
      roundName: roundType.name,
      reason: 'top_20',
    );

    if (mounted) {
      setState(() => _snapshotSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kit snapshot saved'),
          backgroundColor: AppColors.surfaceLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        final session = provider.currentSession;
        final roundType = provider.roundType;

        if (session == null || roundType == null) {
          return const Scaffold(
            body: Center(child: Text('No session data')),
          );
        }

        final percentage =
            (provider.totalScore / roundType.maxScore * 100).toStringAsFixed(1);

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SingleChildScrollView(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xxl),

                  // Completion icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.gold,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    'Session Complete',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.gold,
                        ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    roundType.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Score display
                  Text(
                    provider.totalScore.toString(),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),

                  Text(
                    'out of ${roundType.maxScore}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatBox(
                        label: 'Xs',
                        value: provider.totalXs.toString(),
                        highlighted: true,
                        showBackground: true,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      StatBox(
                        label: 'Percentage',
                        value: '$percentage%',
                        highlighted: true,
                        showBackground: true,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      StatBox(
                        label: 'Ends',
                        value: provider.ends.length.toString(),
                        highlighted: true,
                        showBackground: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // End scores summary
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Scores',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.ends.map((end) {
                            return Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  end.endScore.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Done button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.clearSession();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text('Done'),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

