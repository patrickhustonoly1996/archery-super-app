import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entitlement_provider.dart';
import '../../data/courses.dart';
import '../../models/course.dart';
import '../../theme/app_theme.dart';
import 'course_detail_screen.dart';

class CoursesHomeScreen extends StatelessWidget {
  const CoursesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'LEARN',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            color: AppColors.gold,
          ),
        ),
      ),
      body: Consumer<EntitlementProvider>(
        builder: (context, entitlement, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allCourses.length,
            itemBuilder: (context, index) {
              final course = allCourses[index];
              return _buildCourseCard(context, course, entitlement);
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    Course course,
    EntitlementProvider entitlement,
  ) {
    final hasAccess = _checkCourseAccess(course, entitlement);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Placeholder thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  size: 40,
                  color: hasAccess ? AppColors.gold : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: TextStyle(
                              fontFamily: AppFonts.pixel,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!hasAccess)
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.subtitle,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${course.lessonCount} lessons',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          course.formattedTotalDuration,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        _buildAccessBadge(course, hasAccess),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessBadge(Course course, bool hasAccess) {
    if (hasAccess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          course.accessType == CourseAccessType.free ? 'FREE' : 'UNLOCKED',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 10,
            color: Colors.green,
          ),
        ),
      );
    }

    if (course.accessType == CourseAccessType.purchase) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '£${course.price?.toInt() ?? 0}',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 10,
            color: AppColors.gold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        course.accessType.displayText.toUpperCase(),
        style: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 10,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  bool _checkCourseAccess(Course course, EntitlementProvider entitlement) {
    switch (course.accessType) {
      case CourseAccessType.free:
        return true;
      case CourseAccessType.purchase:
        return entitlement.has3dAimingCourse;
      case CourseAccessType.competitor:
        return entitlement.tier.index >= SubscriptionTier.competitor.index;
      case CourseAccessType.professional:
        return entitlement.tier.index >= SubscriptionTier.professional.index;
      case CourseAccessType.hustonSchool:
        return entitlement.hasHustonSchool;
    }
  }
}
