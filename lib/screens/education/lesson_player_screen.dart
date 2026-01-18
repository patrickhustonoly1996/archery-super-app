import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../db/database.dart';
import '../../models/course.dart';
import '../../theme/app_theme.dart';

/// Lesson player screen - opens video in browser for MVP
/// Full embedded player will come in future update
class LessonPlayerScreen extends StatefulWidget {
  final Course course;
  final Lesson lesson;

  const LessonPlayerScreen({
    super.key,
    required this.course,
    required this.lesson,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  bool _hasWatchedVideo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          widget.lesson.title,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            color: AppColors.gold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: _openVideoInBrowser,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      size: 64,
                      color: AppColors.gold,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TAP TO WATCH',
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 16,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Opens in browser',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lesson info
            Text(
              widget.lesson.title,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  widget.lesson.formattedDuration,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.lesson.description,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Mark complete button
            if (_hasWatchedVideo)
              ElevatedButton(
                onPressed: _markAsComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'MARK AS COMPLETE',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVideoInBrowser() async {
    // Bunny Stream URL format - Patrick will provide actual library ID
    final videoUrl = 'https://iframe.mediadelivery.net/embed/LIBRARY_ID/${widget.lesson.bunnyVideoId}';

    // For now, just show a placeholder message since we don't have real video IDs
    if (widget.lesson.bunnyVideoId.startsWith('PLACEHOLDER')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video IDs not yet configured. Add Bunny Stream IDs to courses.dart',
              style: TextStyle(fontFamily: AppFonts.body),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _hasWatchedVideo = true);
      return;
    }

    final uri = Uri.parse(videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _hasWatchedVideo = true);
    }
  }

  Future<void> _markAsComplete() async {
    final db = context.read<AppDatabase>();

    await db.upsertLessonProgress(
      courseId: widget.course.id,
      lessonId: widget.lesson.id,
      progressSeconds: widget.lesson.durationSeconds,
      durationSeconds: widget.lesson.durationSeconds,
      isCompleted: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lesson marked as complete!',
            style: TextStyle(fontFamily: AppFonts.body),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
