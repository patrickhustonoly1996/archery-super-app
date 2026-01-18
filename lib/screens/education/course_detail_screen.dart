import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entitlement_provider.dart';
import '../../models/course.dart';
import '../../theme/app_theme.dart';
import '../../screens/subscription_screen.dart';
import 'lesson_player_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(
          course.title,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            color: AppTheme.gold,
          ),
        ),
      ),
      body: Consumer<EntitlementProvider>(
        builder: (context, entitlement, _) {
          final hasFullAccess = _checkCourseAccess(entitlement);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, hasFullAccess, entitlement),
                const SizedBox(height: 16),
                _buildDescription(),
                const SizedBox(height: 24),
                _buildLessonsList(context, hasFullAccess),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool hasFullAccess,
    EntitlementProvider entitlement,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.subtitle,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 16,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.video_library, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                '${course.lessonCount} lessons',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                course.formattedTotalDuration,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          if (!hasFullAccess) ...[
            const SizedBox(height: 16),
            _buildUnlockButton(context, entitlement),
          ],
        ],
      ),
    );
  }

  Widget _buildUnlockButton(BuildContext context, EntitlementProvider entitlement) {
    final isPurchase = course.accessType == CourseAccessType.purchase;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          isPurchase ? 'PURCHASE FOR £${course.price?.toInt() ?? 0}' : 'UPGRADE TO UNLOCK',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        course.description,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          color: AppTheme.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildLessonsList(BuildContext context, bool hasFullAccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LESSONS',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...course.lessons.map((lesson) => _buildLessonTile(
                context,
                lesson,
                hasFullAccess || lesson.isFree,
              )),
        ],
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, Lesson lesson, bool canWatch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: canWatch
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonPlayerScreen(
                      course: course,
                      lesson: lesson,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: canWatch
                      ? AppTheme.gold.withValues(alpha: 0.2)
                      : AppTheme.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  canWatch ? Icons.play_arrow : Icons.lock_outline,
                  color: canWatch ? AppTheme.gold : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 14,
                        color: canWatch ? AppTheme.textPrimary : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.formattedDuration,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (lesson.isFree && !_checkCourseAccess(context.read<EntitlementProvider>()))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PREVIEW',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 10,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _checkCourseAccess(EntitlementProvider entitlement) {
    switch (course.accessType) {
      case CourseAccessType.free:
        return true;
      case CourseAccessType.purchase:
        return entitlement.has3dAimingCourse;
      case CourseAccessType.ranger:
        return entitlement.tier.index >= SubscriptionTier.ranger.index;
      case CourseAccessType.elite:
        return entitlement.tier.index >= SubscriptionTier.elite.index;
      case CourseAccessType.hustonSchool:
        return entitlement.hasHustonSchool;
    }
  }
}
