/// Represents a video lesson within a course
class Lesson {
  final String id;
  final String title;
  final String description;
  final String bunnyVideoId;
  final int durationSeconds;
  final int orderIndex;
  final bool isFree; // Can be previewed without purchase

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.bunnyVideoId,
    required this.durationSeconds,
    required this.orderIndex,
    this.isFree = false,
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    }
    return '${seconds}s';
  }
}

/// Represents a video course
class Course {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String thumbnailAsset; // Asset path or URL
  final List<Lesson> lessons;
  final CourseAccessType accessType;
  final double? price; // For one-time purchases (null if subscription-based)
  final String? stripePriceId; // For one-time purchase products

  const Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.thumbnailAsset,
    required this.lessons,
    required this.accessType,
    this.price,
    this.stripePriceId,
  });

  int get totalDurationSeconds =>
      lessons.fold(0, (sum, lesson) => sum + lesson.durationSeconds);

  String get formattedTotalDuration {
    final totalMinutes = totalDurationSeconds ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  int get lessonCount => lessons.length;
}

/// Determines how a course can be accessed
enum CourseAccessType {
  free,           // Available to everyone (Plotting course)
  purchase,       // One-time purchase (3D Aiming)
  competitor,     // Competitor tier and above
  professional,   // Professional tier and above
  hustonSchool,   // Huston School tier only
}

extension CourseAccessTypeExtension on CourseAccessType {
  String get displayText {
    switch (this) {
      case CourseAccessType.free:
        return 'Free';
      case CourseAccessType.purchase:
        return 'One-time purchase';
      case CourseAccessType.competitor:
        return 'Competitor+';
      case CourseAccessType.professional:
        return 'Professional+';
      case CourseAccessType.hustonSchool:
        return 'Huston School';
    }
  }
}
