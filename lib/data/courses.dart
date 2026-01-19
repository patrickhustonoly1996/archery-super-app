import '../models/course.dart';

/// All available courses in the app
/// Video IDs are placeholders - Patrick will provide actual Bunny Stream IDs
const List<Course> allCourses = [
  plottingCourse,
  aiming3dCourse,
];

/// Plotting Course - Free for all users
const Course plottingCourse = Course(
  id: 'plotting',
  title: 'PLOTTING',
  subtitle: 'Arrow plotting fundamentals',
  description: 'Learn how to accurately plot your arrows on target faces, '
      'understand groupings, and use plotting data to improve your shooting. '
      'This course covers manual plotting technique and interpreting your results.',
  thumbnailAsset: 'assets/images/course_plotting.png',
  accessType: CourseAccessType.free,
  lessons: [
    Lesson(
      id: 'plotting_01',
      title: 'Introduction to Plotting',
      description: 'Why plotting matters and what you\'ll learn in this course.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_01', // Patrick will provide
      durationSeconds: 180,
      orderIndex: 0,
      isFree: true,
    ),
    Lesson(
      id: 'plotting_02',
      title: 'Understanding the Target Face',
      description: 'Ring values, scoring zones, and how to read your groups.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_02',
      durationSeconds: 300,
      orderIndex: 1,
      isFree: true,
    ),
    Lesson(
      id: 'plotting_03',
      title: 'Manual Plotting Technique',
      description: 'How to accurately mark arrow positions on your plotting sheet.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_03',
      durationSeconds: 420,
      orderIndex: 2,
      isFree: true,
    ),
    Lesson(
      id: 'plotting_04',
      title: 'Reading Your Groups',
      description: 'What your arrow patterns tell you about your shooting.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_04',
      durationSeconds: 360,
      orderIndex: 3,
      isFree: true,
    ),
    Lesson(
      id: 'plotting_05',
      title: 'Making Adjustments',
      description: 'Using plotting data to make informed sight and form adjustments.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_05',
      durationSeconds: 480,
      orderIndex: 4,
      isFree: true,
    ),
  ],
);

/// 3D Aiming Course - One-time purchase (legacy users get free)
const Course aiming3dCourse = Course(
  id: '3d_aiming',
  title: '3D AIMING',
  subtitle: 'Visual aiming system mastery',
  description: 'Master the art of aiming with this comprehensive course on '
      'the 3D aiming system. Learn to see depth, control your float, and '
      'execute consistent shots under pressure.',
  thumbnailAsset: 'assets/images/course_3d_aiming.png',
  accessType: CourseAccessType.purchase,
  price: 12.0,
  stripePriceId: 'price_1Sr3GJRpdm3uvDfuhGWLxEx3',
  lessons: [
    Lesson(
      id: '3d_aiming_01',
      title: 'Introduction to 3D Aiming',
      description: 'What 3D aiming is and why it works.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_3D_01',
      durationSeconds: 240,
      orderIndex: 0,
      isFree: true, // Preview available
    ),
    Lesson(
      id: '3d_aiming_02',
      title: 'Seeing Depth at Full Draw',
      description: 'Training your eye to perceive depth while aiming.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_3D_02',
      durationSeconds: 420,
      orderIndex: 1,
    ),
    Lesson(
      id: '3d_aiming_03',
      title: 'Float Control',
      description: 'Understanding and managing your sight picture movement.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_3D_03',
      durationSeconds: 480,
      orderIndex: 2,
    ),
    Lesson(
      id: '3d_aiming_04',
      title: 'Execution Under Pressure',
      description: 'Maintaining 3D aiming focus in competition.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_3D_04',
      durationSeconds: 360,
      orderIndex: 3,
    ),
    Lesson(
      id: '3d_aiming_05',
      title: 'Practice Drills',
      description: 'Exercises to develop and reinforce 3D aiming skills.',
      bunnyVideoId: 'PLACEHOLDER_VIDEO_ID_3D_05',
      durationSeconds: 540,
      orderIndex: 4,
    ),
  ],
);

// ===========================================================================
// FUTURE COURSES (Structure only - videos to be added)
// ===========================================================================

/// Huston School courses - structure placeholder
/// These will be populated when Patrick uploads coaching videos
const List<Course> hustonSchoolCourses = [
  // Course(
  //   id: 'hs_shot_cycle',
  //   title: 'THE SHOT CYCLE',
  //   subtitle: 'Building your process',
  //   description: 'Comprehensive breakdown of the Olympic recurve shot cycle.',
  //   thumbnailAsset: 'assets/images/course_shot_cycle.png',
  //   accessType: CourseAccessType.hustonSchool,
  //   lessons: [],
  // ),
  // Course(
  //   id: 'hs_mental_game',
  //   title: 'MENTAL GAME',
  //   subtitle: 'Competition mindset',
  //   description: 'Psychological techniques for peak performance.',
  //   thumbnailAsset: 'assets/images/course_mental.png',
  //   accessType: CourseAccessType.hustonSchool,
  //   lessons: [],
  // ),
];

/// Get course by ID
Course? getCourseById(String id) {
  try {
    return allCourses.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

/// Get lesson by ID within a course
Lesson? getLessonById(String courseId, String lessonId) {
  final course = getCourseById(courseId);
  if (course == null) return null;
  try {
    return course.lessons.firstWhere((l) => l.id == lessonId);
  } catch (_) {
    return null;
  }
}
