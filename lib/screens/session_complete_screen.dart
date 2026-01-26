import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/skills_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/classification_provider.dart';
import '../models/sight_mark.dart';
import '../models/classification.dart';
import '../utils/handicap_calculator.dart';
import '../widgets/stat_box.dart';
import '../widgets/sight_mark_entry_form.dart';
import '../widgets/classification_badge.dart';
import 'home_screen.dart';
import 'scorecard_view_screen.dart';
import 'shaft_analysis_screen.dart';

class SessionCompleteScreen extends StatefulWidget {
  const SessionCompleteScreen({super.key});

  @override
  State<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends State<SessionCompleteScreen> {
  bool _hasCheckedTopPercentile = false;
  bool _hasAwardedXp = false;
  bool _hasPromptedSightMark = false;
  bool _hasCheckedClassification = false;
  bool? _isTopScore;
  bool _snapshotSaved = false;
  bool _sightMarkSaved = false;
  String? _classificationAchieved;
  bool _isClassificationComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTopPercentile();
      _awardSessionXp();
      _promptSightMark();
      _checkClassification();
    });
  }

  /// Award XP for completing this session
  Future<void> _awardSessionXp() async {
    if (_hasAwardedXp) return;
    _hasAwardedXp = true;

    final sessionProvider = context.read<SessionProvider>();
    final skillsProvider = context.read<SkillsProvider>();
    final session = sessionProvider.currentSession;
    final roundType = sessionProvider.roundType;

    if (session == null || roundType == null) return;

    // Calculate handicap for XP
    final handicap = HandicapCalculator.calculateHandicap(
      roundType.id,
      sessionProvider.totalScore,
    ) ?? 100; // Default to 100 if not supported

    // Count arrows
    int arrowCount = 0;
    for (final end in sessionProvider.ends) {
      arrowCount += roundType.arrowsPerEnd;
    }

    // Check if arrows were plotted (has x,y coordinates)
    final allArrows = await sessionProvider.getAllSessionArrows();
    final hasPlottedArrows = allArrows.any((a) => a.xMm != 0 || a.yMm != 0);

    // Check if competition
    final isCompetition = session.sessionType == 'competition';

    // Award XP (wrapped in try-catch to prevent silent failures)
    try {
      await skillsProvider.awardSessionXp(
        sessionId: session.id,
        handicap: handicap,
        arrowCount: arrowCount,
        hasPlottedArrows: hasPlottedArrows,
        isCompetition: isCompetition,
        competitionScore: sessionProvider.totalScore, // Always pass score for PB tracking
        maxScore: roundType.maxScore,
        roundTypeId: roundType.id,
        roundName: roundType.name,
      );
    } catch (e) {
      debugPrint('Error awarding session XP: $e');
    }
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

  /// Check if this session qualifies for any classifications
  Future<void> _checkClassification() async {
    if (_hasCheckedClassification) return;
    _hasCheckedClassification = true;

    final sessionProvider = context.read<SessionProvider>();
    final userProfileProvider = context.read<UserProfileProvider>();
    final classificationProvider = context.read<ClassificationProvider>();

    final session = sessionProvider.currentSession;
    final roundType = sessionProvider.roundType;
    final profile = userProfileProvider.profile;

    if (session == null || roundType == null || profile == null) return;

    // Check if user has classification info set
    final gender = userProfileProvider.gender;
    final ageCategory = userProfileProvider.ageCategory;

    if (gender == null || ageCategory == null) {
      // User hasn't set up classification info yet
      return;
    }

    // Calculate handicap for the score
    final handicap = HandicapCalculator.calculateHandicap(
      roundType.id,
      sessionProvider.totalScore,
    );

    if (handicap == null) {
      // Round not supported for handicap calculation
      return;
    }

    // Get bowstyle from the session's bow or default to user profile
    String bowstyle = userProfileProvider.primaryBowType.value;
    if (session.bowId != null) {
      final equipmentProvider = context.read<EquipmentProvider>();
      final bow = await equipmentProvider.getBow(session.bowId!);
      if (bow != null) {
        bowstyle = bow.bowType;
      }
    }

    // Check and record the classification
    final classification = await classificationProvider.checkAndRecordScore(
      profileId: profile.id,
      handicap: handicap.round(),
      bowstyle: bowstyle,
      ageCategory: ageCategory,
      gender: gender,
      sessionId: session.id,
      score: sessionProvider.totalScore,
      roundId: roundType.id,
      isIndoor: roundType.isIndoor,
    );

    if (classification != null && mounted) {
      setState(() {
        _classificationAchieved = classification.classification;
        _isClassificationComplete = classification.secondSessionId != null;
      });
    }
  }

  /// Prompt user to record sight mark after completing a round
  Future<void> _promptSightMark() async {
    if (_hasPromptedSightMark) return;
    _hasPromptedSightMark = true;

    final sessionProvider = context.read<SessionProvider>();
    final session = sessionProvider.currentSession;
    final roundType = sessionProvider.roundType;

    // Only prompt if we have a bow selected
    if (session == null || roundType == null || session.bowId == null) return;

    // Short delay to let the UI settle
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Show the sight mark prompt
    _showSightMarkPrompt(
      bowId: session.bowId!,
      distance: roundType.distance.toDouble(),
      unit: DistanceUnit.meters, // WA rounds are in meters
      isOutdoor: !roundType.isIndoor,
    );
  }

  void _showSightMarkPrompt({
    required String bowId,
    required double distance,
    required DistanceUnit unit,
    bool isOutdoor = false,
  }) {
    final title = isOutdoor ? 'Record Sight & Conditions?' : 'Record Sight Mark?';
    final message = isOutdoor
        ? 'Record your sight mark and weather conditions for ${distance.toStringAsFixed(0)}${unit.abbreviation}. Conditions will auto-fill from your location.'
        : 'Record your sight mark for ${distance.toStringAsFixed(0)}${unit.abbreviation} to help with future sessions.';

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOutdoor ? Icons.wb_sunny : Icons.visibility,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSightMarkEntry(bowId, distance, unit);
                    },
                    child: const Text('Record'),
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

  void _showSightMarkEntry(String bowId, double distance, DistanceUnit unit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
      ),
      builder: (ctx) => SightMarkEntryForm(
        bowId: bowId,
        defaultDistance: distance,
        defaultUnit: unit,
        onSaved: () {
          Navigator.pop(ctx);
          setState(() => _sightMarkSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sight mark saved'),
              backgroundColor: AppColors.surfaceLight,
            ),
          );
        },
      ),
    );
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
                    color: AppColors.gold.withValues(alpha: 0.2),
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

    // Get skills provider before async gap
    final skillsProvider = context.read<SkillsProvider>();

    await equipmentProvider.saveKitSnapshot(
      sessionId: session.id,
      bowId: session.bowId,
      quiverId: session.quiverId,
      score: sessionProvider.totalScore,
      maxScore: roundType.maxScore,
      roundName: roundType.name,
      reason: 'top_20',
    );

    // Award Equipment XP for saving a kit snapshot
    await skillsProvider.awardEquipmentXp(reason: 'Saved kit snapshot: ${roundType.name}');

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

  Widget _buildClassificationCard() {
    final sessionProvider = context.read<SessionProvider>();
    final roundType = sessionProvider.roundType;
    final scope = roundType?.isIndoor == true
        ? ClassificationScope.indoor
        : ClassificationScope.outdoor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          ClassificationBadge(
            classificationCode: _classificationAchieved!,
            scope: scope,
            isCompact: true,
            showScope: false,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isClassificationComplete
                      ? 'Classification Complete!'
                      : 'Qualifying Score!',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 14,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isClassificationComplete
                      ? 'You\'ve achieved two qualifying scores for ${_classificationAchieved!}'
                      : 'First qualifying score for ${_classificationAchieved!}. One more to go!',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
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

  Widget _buildShaftAnalysisButton(
    BuildContext context,
    dynamic session,
    SessionProvider provider,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final equipmentProvider = context.read<EquipmentProvider>();
              final quiver = equipmentProvider.quivers
                  .where((q) => q.id == session.quiverId)
                  .firstOrNull;

              if (quiver == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quiver not found')),
                );
                return;
              }

              // Get arrows from this session
              final arrows = await provider.getAllSessionArrows();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShaftAnalysisScreen(
                    quiver: quiver,
                    arrows: arrows,
                    sessionId: session.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('View Shaft Analysis'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
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
                      color: AppColors.gold.withValues(alpha: 0.1),
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

                  // Classification achievement notification
                  if (_classificationAchieved != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildClassificationCard(),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Shaft Analysis button - only show if shaft tagging was enabled
                  if (session.shaftTaggingEnabled && session.quiverId != null)
                    _buildShaftAnalysisButton(context, session, provider),

                  // Scorecard & Export button - navigates to full scorecard with signatures
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScorecardViewScreen(
                              sessionId: session.id,
                              isLive: false,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text('View Scorecard & Export'),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

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

