import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../widgets/stat_box.dart';
import 'home_screen.dart';

class SessionCompleteScreen extends StatelessWidget {
  const SessionCompleteScreen({super.key});

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

