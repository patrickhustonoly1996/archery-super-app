import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/skills_provider.dart';
import '../services/xp_calculation_service.dart';
import '../db/database.dart';
import '../widgets/bow_icon.dart';

class PerformanceProfileScreen extends StatefulWidget {
  const PerformanceProfileScreen({super.key});

  @override
  State<PerformanceProfileScreen> createState() =>
      _PerformanceProfileScreenState();
}

class _PerformanceProfileScreenState extends State<PerformanceProfileScreen> {
  static const _seenXpTipsKey = 'skills_profile_seen_xp_tips';
  bool _xpTipsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SkillsProvider>().loadSkills();
      _checkFirstVisit();
    });
  }

  Future<void> _checkFirstVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_seenXpTipsKey) ?? false;
    if (!hasSeen && mounted) {
      // First visit - auto-expand the XP tips section
      setState(() => _xpTipsExpanded = true);
      // Mark as seen
      await prefs.setBool(_seenXpTipsKey, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SKILLS PROFILE',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Consumer<SkillsProvider>(
        builder: (context, provider, _) {
          if (!provider.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final skills = provider.skills;
          if (skills.isEmpty) {
            return _buildEmptyState();
          }

          return _buildContent(skills, provider);
        },
      ),
    );
  }

  Widget _buildContent(List<SkillLevel> skills, SkillsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(skills, provider),
          const SizedBox(height: 24),
          _buildSkillsGrid(skills),
          const SizedBox(height: 24),
          _buildTotalXpCard(skills),
          const SizedBox(height: 24),
          _buildHowToEarnXpSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(List<SkillLevel> skills, SkillsProvider provider) {
    final combinedLevel = provider.combinedLevel;
    final isMaxLevel = combinedLevel >= 99;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(
          color: isMaxLevel ? AppColors.gold : AppColors.gold.withValues(alpha: 0.3),
          width: isMaxLevel ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Combined level display (1-99)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'LEVEL',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 10,
                    color: AppColors.gold.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$combinedLevel',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 36,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARCHER PROFILE',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 18,
                    color: AppColors.gold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${skills.length} skills tracked',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar to next combined level
                _buildCombinedProgressBar(skills),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedProgressBar(List<SkillLevel> skills) {
    // Calculate average progress across all skills
    double totalProgress = 0;
    for (final skill in skills) {
      totalProgress += XpCalculationService.progressToNextLevel(skill.currentXp);
    }
    final avgProgress = skills.isNotEmpty ? totalProgress / skills.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: avgProgress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${(avgProgress * 100).toInt()}% to next level',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsGrid(List<SkillLevel> skills) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        return _SkillTile(skill: skills[index]);
      },
    );
  }

  Widget _buildTotalXpCard(List<SkillLevel> skills) {
    final totalXp = skills.fold<int>(0, (sum, s) => sum + s.currentXp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTAL XP',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 14,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          Text(
            _formatXp(totalXp),
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 20,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnXpSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          GestureDetector(
            onTap: () => setState(() => _xpTipsExpanded = !_xpTipsExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HOW TO EARN XP',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 14,
                      color: AppColors.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  Icon(
                    _xpTipsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.gold,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildXpTip('ARCHERY', 'Complete scored rounds. XP = (150 - handicap) × 2'),
                  _buildXpTip('VOLUME', 'Shoot arrows. 1 XP per 5 arrows'),
                  _buildXpTip('CONSISTENCY', 'Train daily. 10 XP/day + streak bonuses'),
                  _buildXpTip('BOW FITNESS', 'OLY drills. 1 XP per 5s hold time'),
                  _buildXpTip('BREATH WORK', 'Breath training. 1 XP per 10s'),
                  _buildXpTip('EQUIPMENT', 'Log gear changes. 5 XP each'),
                  _buildXpTip('COMPETITION', 'Compete. 20+ XP per competition'),
                  _buildXpTip('ANALYSIS', 'Plot arrows. 3+ XP per session'),
                ],
              ),
            ),
            crossFadeState: _xpTipsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildXpTip(String skill, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              skill,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 10,
                color: AppColors.gold.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(64, 64),
            painter: _SkillIconPainter(skillId: 'archery_skill'),
          ),
          const SizedBox(height: 16),
          Text(
            'NO SKILLS DATA',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 18,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Train to level up your skills',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }
}

/// Individual skill tile with RuneScape-style display
class _SkillTile extends StatelessWidget {
  final SkillLevel skill;

  const _SkillTile({required this.skill});

  @override
  Widget build(BuildContext context) {
    final progress = XpCalculationService.progressToNextLevel(skill.currentXp);
    final isMaxLevel = skill.currentLevel >= 99;

    return GestureDetector(
      onTap: () => _showSkillDetails(context, skill),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(
            color: isMaxLevel
                ? AppColors.gold
                : AppColors.surfaceLight,
            width: isMaxLevel ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Skill icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: skill.id == 'equipment'
                        ? const BowIcon(size: 24, color: AppColors.gold)
                        : CustomPaint(
                            size: const Size(24, 24),
                            painter: _SkillIconPainter(skillId: skill.id),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppFonts.pixel,
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // Level display (RuneScape style)
                          Text(
                            isMaxLevel ? '99' : '${skill.currentLevel}',
                            style: TextStyle(
                              fontFamily: AppFonts.pixel,
                              fontSize: 16,
                              color: AppColors.gold,
                            ),
                          ),
                          Text(
                            '/99',
                            style: TextStyle(
                              fontFamily: AppFonts.pixel,
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // XP progress bar
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: isMaxLevel ? 1.0 : progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isMaxLevel
                          ? AppColors.gold
                          : AppColors.gold.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isMaxLevel ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ] : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isMaxLevel ? 'MAX LEVEL' : '${_formatXp(skill.currentXp)} XP',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 10,
                color: isMaxLevel ? AppColors.gold : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }

  void _showSkillDetails(BuildContext context, SkillLevel skill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SkillDetailSheet(skill: skill),
    );
  }
}

/// Detailed view for a single skill showing XP history
class _SkillDetailSheet extends StatefulWidget {
  final SkillLevel skill;

  const _SkillDetailSheet({required this.skill});

  @override
  State<_SkillDetailSheet> createState() => _SkillDetailSheetState();
}

class _SkillDetailSheetState extends State<_SkillDetailSheet> {
  List<XpHistoryData> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final provider = context.read<SkillsProvider>();
    final history = await provider.getXpHistory(widget.skill.id, limit: 20);
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = XpCalculationService.progressToNextLevel(widget.skill.currentXp);
    final xpToNext = XpCalculationService.xpToNextLevel(widget.skill.currentXp);
    final milestone = XpCalculationService.getMilestoneDescription(widget.skill.currentLevel);
    final isMaxLevel = widget.skill.currentLevel >= 99;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            border: Border(
              top: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      color: AppColors.gold.withValues(alpha: 0.4),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Skill header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Center(
                      child: widget.skill.id == 'equipment'
                          ? const BowIcon(size: 32, color: AppColors.gold)
                          : CustomPaint(
                              size: const Size(32, 32),
                              painter: _SkillIconPainter(skillId: widget.skill.id),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.skill.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 20,
                            color: AppColors.gold,
                            letterSpacing: 2,
                          ),
                        ),
                        if (milestone != null)
                          Text(
                            milestone,
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Level display box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border.all(
                    color: isMaxLevel ? AppColors.gold : AppColors.surfaceLight,
                    width: isMaxLevel ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.skill.currentLevel}',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 48,
                            color: AppColors.gold,
                          ),
                        ),
                        Text(
                          ' / 99',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 24,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: isMaxLevel ? 1.0 : progress,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'XP: ${_formatXp(widget.skill.currentXp)}',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          isMaxLevel ? 'MAX LEVEL' : 'NEXT: ${_formatXp(xpToNext)} XP',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            color: isMaxLevel ? AppColors.gold : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // XP history
              Text(
                'RECENT XP',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 14,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                )
              else if (_history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Center(
                    child: Text(
                      'No XP earned yet',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_history.length, (index) {
                  final entry = _history[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    margin: EdgeInsets.only(bottom: index < _history.length - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '+${entry.xpAmount}',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 14,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.reason ?? entry.source,
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(entry.earnedAt),
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
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

/// Pixel icon painter for skills
class _SkillIconPainter extends CustomPainter {
  final String skillId;

  _SkillIconPainter({required this.skillId});

  @override
  void paint(Canvas canvas, Size size) {
    final p = size.width / 12;
    final paint = Paint()..color = AppColors.gold;
    final dimPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.5);

    switch (skillId) {
      case 'archery_skill':
        _drawTarget(canvas, p, paint, dimPaint);
      case 'volume':
        _drawQuiver(canvas, p, paint, dimPaint);
      case 'consistency':
        _drawCalendar(canvas, p, paint, dimPaint);
      case 'bow_fitness':
        _drawDumbbell(canvas, p, paint, dimPaint);
      case 'breath_work':
        _drawLungs(canvas, p, paint, dimPaint);
      case 'equipment':
        // Handled by BowIcon widget
        break;
      case 'competition':
        _drawTrophy(canvas, p, paint, dimPaint);
      case 'analysis':
        _drawChart(canvas, p, paint, dimPaint);
      default:
        _drawStar(canvas, p, paint, dimPaint);
    }
  }

  void _drawTarget(Canvas c, double p, Paint paint, Paint dim) {
    // Outer ring
    for (int i = 3; i <= 8; i++) {
      _px(c, i, 1, p, dim);
      _px(c, i, 10, p, dim);
    }
    for (int i = 3; i <= 8; i++) {
      _px(c, 1, i, p, dim);
      _px(c, 10, i, p, dim);
    }
    _px(c, 2, 2, p, dim);
    _px(c, 9, 2, p, dim);
    _px(c, 2, 9, p, dim);
    _px(c, 9, 9, p, dim);
    // Inner ring
    for (int i = 4; i <= 7; i++) {
      _px(c, i, 3, p, paint);
      _px(c, i, 8, p, paint);
    }
    _px(c, 3, 4, p, paint);
    _px(c, 3, 7, p, paint);
    _px(c, 8, 4, p, paint);
    _px(c, 8, 7, p, paint);
    // Center
    _px(c, 5, 5, p, paint);
    _px(c, 6, 5, p, paint);
    _px(c, 5, 6, p, paint);
    _px(c, 6, 6, p, paint);
  }

  void _drawQuiver(Canvas c, double p, Paint paint, Paint dim) {
    // Quiver body (diagonal)
    _px(c, 3, 4, p, paint);
    _px(c, 4, 4, p, paint);
    _px(c, 3, 5, p, paint);
    _px(c, 4, 5, p, paint);
    _px(c, 5, 5, p, paint);
    _px(c, 3, 6, p, paint);
    _px(c, 4, 6, p, paint);
    _px(c, 5, 6, p, paint);
    _px(c, 4, 7, p, paint);
    _px(c, 5, 7, p, paint);
    _px(c, 6, 7, p, paint);
    _px(c, 4, 8, p, paint);
    _px(c, 5, 8, p, paint);
    _px(c, 6, 8, p, paint);
    _px(c, 5, 9, p, paint);
    _px(c, 6, 9, p, paint);
    _px(c, 7, 9, p, paint);
    _px(c, 6, 10, p, paint);
    _px(c, 7, 10, p, paint);
    // Arrows sticking out
    _px(c, 2, 3, p, dim);
    _px(c, 2, 2, p, dim);
    _px(c, 4, 3, p, paint);
    _px(c, 4, 2, p, paint);
    _px(c, 4, 1, p, paint);
    _px(c, 6, 4, p, paint);
    _px(c, 6, 3, p, paint);
    _px(c, 7, 2, p, dim);
  }

  void _drawCalendar(Canvas c, double p, Paint paint, Paint dim) {
    // Calendar outline
    for (int x = 2; x <= 9; x++) {
      _px(c, x, 2, p, paint);
      _px(c, x, 10, p, paint);
    }
    for (int y = 2; y <= 10; y++) {
      _px(c, 2, y, p, paint);
      _px(c, 9, y, p, paint);
    }
    // Days grid
    for (int x = 3; x <= 8; x += 2) {
      for (int y = 4; y <= 9; y += 2) {
        _px(c, x, y, p, dim);
      }
    }
    // Check marks on some days
    _px(c, 4, 5, p, paint);
    _px(c, 6, 5, p, paint);
    _px(c, 4, 7, p, paint);
  }

  void _drawDumbbell(Canvas c, double p, Paint paint, Paint dim) {
    // Left weight
    _px(c, 1, 4, p, paint);
    _px(c, 1, 5, p, paint);
    _px(c, 1, 6, p, paint);
    _px(c, 1, 7, p, paint);
    _px(c, 2, 4, p, paint);
    _px(c, 2, 5, p, paint);
    _px(c, 2, 6, p, paint);
    _px(c, 2, 7, p, paint);
    // Bar
    for (int x = 3; x <= 8; x++) {
      _px(c, x, 5, p, dim);
      _px(c, x, 6, p, dim);
    }
    // Right weight
    _px(c, 9, 4, p, paint);
    _px(c, 9, 5, p, paint);
    _px(c, 9, 6, p, paint);
    _px(c, 9, 7, p, paint);
    _px(c, 10, 4, p, paint);
    _px(c, 10, 5, p, paint);
    _px(c, 10, 6, p, paint);
    _px(c, 10, 7, p, paint);
  }

  void _drawLungs(Canvas c, double p, Paint paint, Paint dim) {
    // Trachea
    _px(c, 5, 1, p, paint);
    _px(c, 6, 1, p, paint);
    _px(c, 5, 2, p, paint);
    _px(c, 6, 2, p, paint);
    // Bronchi
    _px(c, 4, 3, p, dim);
    _px(c, 5, 3, p, paint);
    _px(c, 6, 3, p, paint);
    _px(c, 7, 3, p, dim);
    // Left lung
    _px(c, 2, 4, p, dim);
    _px(c, 3, 4, p, paint);
    _px(c, 4, 4, p, paint);
    for (int y = 5; y <= 7; y++) {
      _px(c, 1, y, p, paint);
      _px(c, 2, y, p, paint);
      _px(c, 3, y, p, paint);
      _px(c, 4, y, p, paint);
    }
    _px(c, 2, 8, p, paint);
    _px(c, 3, 8, p, paint);
    _px(c, 4, 8, p, paint);
    _px(c, 3, 9, p, dim);
    // Right lung
    _px(c, 7, 4, p, paint);
    _px(c, 8, 4, p, paint);
    _px(c, 9, 4, p, dim);
    for (int y = 5; y <= 7; y++) {
      _px(c, 7, y, p, paint);
      _px(c, 8, y, p, paint);
      _px(c, 9, y, p, paint);
      _px(c, 10, y, p, paint);
    }
    _px(c, 7, 8, p, paint);
    _px(c, 8, 8, p, paint);
    _px(c, 9, 8, p, paint);
    _px(c, 8, 9, p, dim);
  }

  void _drawTrophy(Canvas c, double p, Paint paint, Paint dim) {
    // Cup top
    for (int x = 3; x <= 8; x++) {
      _px(c, x, 1, p, paint);
    }
    // Cup body
    for (int y = 2; y <= 5; y++) {
      _px(c, 3, y, p, paint);
      _px(c, 8, y, p, paint);
    }
    for (int x = 4; x <= 7; x++) {
      _px(c, x, 2, p, dim);
      _px(c, x, 3, p, dim);
      _px(c, x, 4, p, dim);
    }
    // Handles
    _px(c, 2, 2, p, dim);
    _px(c, 2, 3, p, dim);
    _px(c, 9, 2, p, dim);
    _px(c, 9, 3, p, dim);
    // Cup bottom narrowing
    _px(c, 4, 5, p, paint);
    _px(c, 7, 5, p, paint);
    _px(c, 4, 6, p, paint);
    _px(c, 5, 6, p, paint);
    _px(c, 6, 6, p, paint);
    _px(c, 7, 6, p, paint);
    // Stem
    _px(c, 5, 7, p, paint);
    _px(c, 6, 7, p, paint);
    _px(c, 5, 8, p, paint);
    _px(c, 6, 8, p, paint);
    // Base
    for (int x = 3; x <= 8; x++) {
      _px(c, x, 9, p, paint);
      _px(c, x, 10, p, paint);
    }
  }

  void _drawChart(Canvas c, double p, Paint paint, Paint dim) {
    // Axes
    for (int y = 1; y <= 10; y++) {
      _px(c, 1, y, p, dim);
    }
    for (int x = 1; x <= 10; x++) {
      _px(c, x, 10, p, dim);
    }
    // Bars
    for (int y = 7; y <= 9; y++) _px(c, 3, y, p, paint);
    for (int y = 4; y <= 9; y++) _px(c, 5, y, p, paint);
    for (int y = 5; y <= 9; y++) _px(c, 7, y, p, paint);
    for (int y = 2; y <= 9; y++) _px(c, 9, y, p, paint);
  }

  void _drawStar(Canvas c, double p, Paint paint, Paint dim) {
    _px(c, 5, 1, p, paint);
    _px(c, 6, 1, p, paint);
    _px(c, 5, 2, p, paint);
    _px(c, 6, 2, p, paint);
    _px(c, 4, 3, p, paint);
    _px(c, 5, 3, p, paint);
    _px(c, 6, 3, p, paint);
    _px(c, 7, 3, p, paint);
    for (int x = 1; x <= 10; x++) _px(c, x, 4, p, paint);
    for (int x = 2; x <= 9; x++) _px(c, x, 5, p, paint);
    _px(c, 3, 6, p, paint);
    _px(c, 4, 6, p, paint);
    _px(c, 5, 6, p, paint);
    _px(c, 6, 6, p, paint);
    _px(c, 7, 6, p, paint);
    _px(c, 8, 6, p, paint);
    _px(c, 3, 7, p, paint);
    _px(c, 4, 7, p, paint);
    _px(c, 7, 7, p, paint);
    _px(c, 8, 7, p, paint);
    _px(c, 2, 8, p, paint);
    _px(c, 3, 8, p, paint);
    _px(c, 8, 8, p, paint);
    _px(c, 9, 8, p, paint);
  }

  void _px(Canvas c, int x, int y, double p, Paint paint) {
    c.drawRect(Rect.fromLTWH(x * p, y * p, p, p), paint);
  }

  @override
  bool shouldRepaint(covariant _SkillIconPainter oldDelegate) =>
      skillId != oldDelegate.skillId;
}
