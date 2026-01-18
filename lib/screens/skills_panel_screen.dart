import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../providers/skills_provider.dart';
import '../services/xp_calculation_service.dart';
import '../theme/app_theme.dart';

/// Bottom sheet displaying all skills with their levels and XP progress.
/// Accessible from home screen or by tapping any level badge.
class SkillsPanelScreen extends StatelessWidget {
  const SkillsPanelScreen({super.key});

  /// Show the skills panel as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SkillsPanelScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            border: Border(
              top: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
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

              // Header
              Consumer<SkillsProvider>(
                builder: (context, skillsProvider, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SKILLS',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 20,
                            color: AppColors.gold,
                            letterSpacing: 2,
                          ),
                        ),
                        // Total level
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.gold, width: 1),
                          ),
                          child: Text(
                            'TOTAL: ${skillsProvider.totalLevel}',
                            style: TextStyle(
                              fontFamily: AppFonts.pixel,
                              fontSize: 12,
                              color: AppColors.gold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Skills list
              Expanded(
                child: Consumer<SkillsProvider>(
                  builder: (context, skillsProvider, _) {
                    if (!skillsProvider.isLoaded) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      );
                    }

                    final skills = skillsProvider.skills;
                    if (skills.isEmpty) {
                      return Center(
                        child: Text(
                          'No skills data',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: skills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final skill = skills[index];
                        return _SkillCard(skill: skill);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual skill card with level, progress bar, and XP info.
class _SkillCard extends StatelessWidget {
  final SkillLevel skill;

  const _SkillCard({required this.skill});

  @override
  Widget build(BuildContext context) {
    final progress = XpCalculationService.progressToNextLevel(skill.currentXp);
    final currentLevelXp = XpCalculationService.xpForLevel(skill.currentLevel);
    final nextLevelXp = XpCalculationService.xpForLevel(skill.currentLevel + 1);
    final xpInLevel = skill.currentXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    final isMaxLevel = skill.currentLevel >= 99;

    return GestureDetector(
      onTap: () => _showSkillDetails(context, skill),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.surfaceLight, width: 1),
        ),
        child: Row(
          children: [
            // Skill icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: _SkillIcon(skillId: skill.id),
              ),
            ),
            const SizedBox(width: 12),

            // Skill info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          skill.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMaxLevel
                              ? AppColors.gold.withValues(alpha: 0.25)
                              : AppColors.gold.withValues(alpha: 0.15),
                          border: Border.all(
                            color: isMaxLevel ? AppColors.gold : AppColors.gold.withValues(alpha: 0.5),
                            width: isMaxLevel ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          isMaxLevel ? 'MAX' : 'LV${skill.currentLevel}',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 10,
                            color: AppColors.gold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Progress bar
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
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // XP text
                  Text(
                    isMaxLevel
                        ? '${_formatXp(skill.currentXp)} XP TOTAL'
                        : '${_formatXp(xpInLevel)} / ${_formatXp(xpNeeded)} XP',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
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

/// Detailed view for a single skill showing XP history.
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Center(
                      child: _SkillIcon(skillId: widget.skill.id, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.skill.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 18,
                            color: AppColors.gold,
                            letterSpacing: 1,
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

              // Level display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border.all(color: AppColors.surfaceLight, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LEVEL',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 12,
                            color: AppColors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${widget.skill.currentLevel}',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 32,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: isMaxLevel ? 1.0 : progress,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL XP: ${_formatXp(widget.skill.currentXp)}',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          isMaxLevel ? 'MAX LEVEL' : 'NEXT: ${_formatXp(xpToNext)} XP',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            color: isMaxLevel ? AppColors.gold : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent XP history
              Text(
                'RECENT XP',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 12,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),

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

/// Pixel icon for each skill type.
class _SkillIcon extends StatelessWidget {
  final String skillId;
  final double size;

  const _SkillIcon({required this.skillId, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SkillIconPainter(skillId: skillId),
    );
  }
}

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
        _drawArrows(canvas, p, paint, dimPaint);
      case 'consistency':
        _drawCalendar(canvas, p, paint, dimPaint);
      case 'bow_fitness':
        _drawMuscle(canvas, p, paint, dimPaint);
      case 'breath_work':
        _drawLungs(canvas, p, paint, dimPaint);
      case 'equipment':
        _drawGear(canvas, p, paint, dimPaint);
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

  void _drawArrows(Canvas c, double p, Paint paint, Paint dim) {
    // Three arrows pointing right
    for (int x = 2; x <= 9; x++) {
      _px(c, x, 3, p, dim);
      _px(c, x, 6, p, paint);
      _px(c, x, 9, p, dim);
    }
    // Arrow heads
    _px(c, 10, 2, p, dim);
    _px(c, 10, 3, p, dim);
    _px(c, 10, 4, p, dim);
    _px(c, 10, 5, p, paint);
    _px(c, 10, 6, p, paint);
    _px(c, 10, 7, p, paint);
    _px(c, 10, 8, p, dim);
    _px(c, 10, 9, p, dim);
    _px(c, 10, 10, p, dim);
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

  void _drawMuscle(Canvas c, double p, Paint paint, Paint dim) {
    // Bicep shape
    _px(c, 2, 6, p, paint);
    _px(c, 3, 5, p, paint);
    _px(c, 3, 6, p, paint);
    _px(c, 3, 7, p, paint);
    _px(c, 4, 4, p, paint);
    _px(c, 4, 5, p, paint);
    _px(c, 4, 6, p, paint);
    _px(c, 4, 7, p, paint);
    _px(c, 5, 3, p, dim);
    _px(c, 5, 4, p, paint);
    _px(c, 5, 5, p, paint);
    _px(c, 5, 6, p, paint);
    _px(c, 5, 7, p, paint);
    _px(c, 6, 4, p, paint);
    _px(c, 6, 5, p, paint);
    _px(c, 6, 6, p, paint);
    _px(c, 6, 7, p, paint);
    _px(c, 7, 5, p, paint);
    _px(c, 7, 6, p, paint);
    _px(c, 7, 7, p, paint);
    _px(c, 8, 6, p, paint);
    _px(c, 8, 7, p, paint);
    _px(c, 9, 7, p, dim);
    _px(c, 9, 8, p, dim);
  }

  void _drawLungs(Canvas c, double p, Paint paint, Paint dim) {
    _px(c, 5, 1, p, paint);
    _px(c, 6, 1, p, paint);
    _px(c, 5, 2, p, paint);
    _px(c, 6, 2, p, paint);
    _px(c, 4, 3, p, dim);
    _px(c, 5, 3, p, paint);
    _px(c, 6, 3, p, paint);
    _px(c, 7, 3, p, dim);
    _px(c, 2, 4, p, paint);
    _px(c, 3, 4, p, paint);
    _px(c, 4, 4, p, paint);
    _px(c, 7, 4, p, paint);
    _px(c, 8, 4, p, paint);
    _px(c, 9, 4, p, paint);
    for (int y = 5; y <= 7; y++) {
      _px(c, 1, y, p, paint);
      _px(c, 2, y, p, paint);
      _px(c, 3, y, p, paint);
      _px(c, 4, y, p, paint);
      _px(c, 7, y, p, paint);
      _px(c, 8, y, p, paint);
      _px(c, 9, y, p, paint);
      _px(c, 10, y, p, paint);
    }
    _px(c, 2, 8, p, paint);
    _px(c, 3, 8, p, paint);
    _px(c, 4, 8, p, paint);
    _px(c, 7, 8, p, paint);
    _px(c, 8, 8, p, paint);
    _px(c, 9, 8, p, paint);
    _px(c, 3, 9, p, dim);
    _px(c, 8, 9, p, dim);
  }

  void _drawGear(Canvas c, double p, Paint paint, Paint dim) {
    // Outer teeth
    _px(c, 5, 1, p, paint);
    _px(c, 6, 1, p, paint);
    _px(c, 9, 3, p, paint);
    _px(c, 9, 4, p, paint);
    _px(c, 10, 5, p, paint);
    _px(c, 10, 6, p, paint);
    _px(c, 9, 8, p, paint);
    _px(c, 8, 9, p, paint);
    _px(c, 5, 10, p, paint);
    _px(c, 6, 10, p, paint);
    _px(c, 2, 8, p, paint);
    _px(c, 3, 9, p, paint);
    _px(c, 1, 5, p, paint);
    _px(c, 1, 6, p, paint);
    _px(c, 2, 3, p, paint);
    _px(c, 3, 2, p, paint);
    // Inner circle
    for (int i = 4; i <= 7; i++) {
      _px(c, i, 3, p, dim);
      _px(c, i, 8, p, dim);
    }
    _px(c, 3, 4, p, dim);
    _px(c, 3, 7, p, dim);
    _px(c, 8, 4, p, dim);
    _px(c, 8, 7, p, dim);
    // Center
    _px(c, 5, 5, p, paint);
    _px(c, 6, 5, p, paint);
    _px(c, 5, 6, p, paint);
    _px(c, 6, 6, p, paint);
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
