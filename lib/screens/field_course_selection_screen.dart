import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/field_course.dart' as model;
import '../providers/field_course_provider.dart';

class FieldCourseSelectionScreen extends StatefulWidget {
  final model.FieldRoundType roundType;

  const FieldCourseSelectionScreen({
    super.key,
    required this.roundType,
  });

  @override
  State<FieldCourseSelectionScreen> createState() =>
      _FieldCourseSelectionScreenState();
}

class _FieldCourseSelectionScreenState
    extends State<FieldCourseSelectionScreen> {
  List<model.FieldCourse> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final provider = context.read<FieldCourseProvider>();
    final courses = await provider.getCoursesByRoundType(widget.roundType);

    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select ${widget.roundType.displayName} Course'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _courses.isEmpty
              ? _buildEmptyState()
              : _buildCourseList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.landscape_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No saved courses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Create a new course by selecting\n"New Course" on the previous screen',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    // Group courses by venue
    final Map<String?, List<model.FieldCourse>> coursesByVenue = {};
    for (final course in _courses) {
      coursesByVenue.putIfAbsent(course.venueId, () => []).add(course);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return _CourseCard(
          course: course,
          onTap: () => Navigator.pop(context, course),
          onDelete: () => _deleteCourse(course),
        );
      },
    );
  }

  Future<void> _deleteCourse(model.FieldCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text('Are you sure you want to delete "${course.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<FieldCourseProvider>();
      await provider.deleteCourse(course.id);
      await _loadCourses();
    }
  }
}

class _CourseCard extends StatelessWidget {
  final model.FieldCourse course;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Course icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: const Icon(
                  Icons.landscape,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Course info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _buildInfoChip(
                          '${course.targetCount} targets',
                          context,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (course.isComplete)
                          _buildInfoChip('Complete', context, isGold: true)
                        else
                          _buildInfoChip(
                            '${course.targets.length}/${course.targetCount} defined',
                            context,
                          ),
                      ],
                    ),
                    if (course.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        course.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, BuildContext context, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isGold
            ? AppColors.gold.withOpacity(0.2)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isGold ? AppColors.gold : AppColors.textSecondary,
            ),
      ),
    );
  }
}
