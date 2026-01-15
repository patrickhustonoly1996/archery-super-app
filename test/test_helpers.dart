/// Test Helpers and Fixtures for Archery Super App
///
/// This file provides reusable test utilities, mock data factories,
/// and common test patterns used across all test files.
///
/// Usage:
///   import '../test_helpers.dart';
///
/// Pattern: Follow the existing test patterns in arrow_coordinate_test.dart
/// and target_coordinate_system_test.dart for consistency.

import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/models/arrow_coordinate.dart';
import 'package:archery_super_app/utils/volume_calculator.dart';

// =============================================================================
// ARROW FACTORIES
// =============================================================================

/// Creates a fake Arrow for testing with mm coordinates.
/// Uses the mm-based coordinate system as primary (preferred).
Arrow createFakeArrow({
  required String id,
  required double xMm,
  required double yMm,
  required int score,
  bool isX = false,
  int? shaftNumber,
  int faceSizeCm = 40,
  String endId = 'test-end',
  int faceIndex = 0,
  int sequence = 1,
}) {
  // Calculate normalized coordinates from mm for legacy compatibility
  final radiusMm = faceSizeCm * 5.0;
  final normalizedX = xMm / radiusMm;
  final normalizedY = yMm / radiusMm;

  return Arrow(
    id: id,
    endId: endId,
    faceIndex: faceIndex,
    xMm: xMm,
    yMm: yMm,
    x: normalizedX,
    y: normalizedY,
    score: score,
    isX: isX,
    sequence: sequence,
    shaftNumber: shaftNumber,
    createdAt: DateTime.now(),
  );
}

/// Creates a fake Arrow using normalized coordinates (legacy path).
/// Use for testing backward compatibility with old data.
Arrow createFakeArrowNormalized({
  required String id,
  required double x,
  required double y,
  required int score,
  bool isX = false,
  int? shaftNumber,
  String endId = 'test-end',
  int faceIndex = 0,
  int sequence = 1,
}) {
  return Arrow(
    id: id,
    endId: endId,
    faceIndex: faceIndex,
    xMm: 0.0, // Zero mm coordinates = legacy mode
    yMm: 0.0,
    x: x,
    y: y,
    score: score,
    isX: isX,
    sequence: sequence,
    shaftNumber: shaftNumber,
    createdAt: DateTime.now(),
  );
}

/// Creates multiple arrows at varying distances from center.
/// Useful for testing group analysis and spread calculations.
List<Arrow> createArrowGroup({
  required int count,
  double centerXMm = 0,
  double centerYMm = 0,
  double spreadMm = 20,
  int baseScore = 10,
  int faceSizeCm = 40,
}) {
  final arrows = <Arrow>[];
  for (int i = 0; i < count; i++) {
    // Distribute arrows in a circle around center
    final angle = (i / count) * 2 * 3.14159;
    final distance = spreadMm * (0.5 + (i % 3) * 0.25);
    final xMm = centerXMm + distance * (i.isEven ? 1 : -1) * (i % 2 == 0 ? 0.7 : 0.3);
    final yMm = centerYMm + distance * (i.isOdd ? 1 : -1) * (i % 2 == 1 ? 0.7 : 0.3);

    arrows.add(createFakeArrow(
      id: 'arrow_$i',
      xMm: xMm,
      yMm: yMm,
      score: baseScore - (i ~/ 4), // Vary scores slightly
      isX: i == 0 && baseScore == 10,
      faceSizeCm: faceSizeCm,
      sequence: i + 1,
    ));
  }
  return arrows;
}

// =============================================================================
// VOLUME DATA FACTORIES
// =============================================================================

/// Creates a list of DailyVolume entries for testing EMA calculations.
List<DailyVolume> createVolumeData({
  required int days,
  int baseArrows = 100,
  int variance = 20,
  DateTime? startDate,
}) {
  final start = startDate ?? DateTime.now().subtract(Duration(days: days));
  final data = <DailyVolume>[];

  for (int i = 0; i < days; i++) {
    // Create realistic training pattern (more on some days, less on others)
    final dayOfWeek = (start.add(Duration(days: i))).weekday;
    final isRestDay = dayOfWeek == 7; // Sunday rest
    final arrows = isRestDay ? 0 : baseArrows + (variance * (i % 5 - 2));

    data.add(DailyVolume(
      date: start.add(Duration(days: i)),
      arrowCount: arrows.clamp(0, 300),
    ));
  }

  return data;
}

/// Creates steady volume data (constant arrows per day).
List<DailyVolume> createSteadyVolumeData({
  required int days,
  required int arrowsPerDay,
  DateTime? startDate,
}) {
  final start = startDate ?? DateTime.now().subtract(Duration(days: days));
  return List.generate(days, (i) => DailyVolume(
    date: start.add(Duration(days: i)),
    arrowCount: arrowsPerDay,
  ));
}

/// Creates volume data with a ramp-up pattern.
List<DailyVolume> createRampUpVolumeData({
  required int days,
  int startArrows = 50,
  int endArrows = 150,
  DateTime? startDate,
}) {
  final start = startDate ?? DateTime.now().subtract(Duration(days: days));
  final increment = (endArrows - startArrows) / (days - 1);

  return List.generate(days, (i) => DailyVolume(
    date: start.add(Duration(days: i)),
    arrowCount: (startArrows + increment * i).round(),
  ));
}

// =============================================================================
// SESSION FACTORIES
// =============================================================================

/// Creates a fake Session for testing.
Session createFakeSession({
  required String id,
  required String roundTypeId,
  int totalScore = 0,
  int totalXs = 0,
  String sessionType = 'practice',
  DateTime? startedAt,
  DateTime? completedAt,
  String? bowId,
  String? quiverId,
  bool shaftTaggingEnabled = false,
}) {
  return Session(
    id: id,
    roundTypeId: roundTypeId,
    totalScore: totalScore,
    totalXs: totalXs,
    sessionType: sessionType,
    startedAt: startedAt ?? DateTime.now(),
    completedAt: completedAt,
    location: null,
    bowId: bowId,
    quiverId: quiverId,
    shaftTaggingEnabled: shaftTaggingEnabled,
  );
}

/// Creates a fake RoundType for testing.
RoundType createFakeRoundType({
  required String id,
  required String name,
  int arrowsPerEnd = 3,
  int totalEnds = 10,
  int maxScore = 300,
  int faceSize = 40,
  int faceCount = 1,
  bool isIndoor = true,
  String category = 'wa_indoor',
  int distance = 18,
}) {
  return RoundType(
    id: id,
    name: name,
    category: category,
    distance: distance,
    arrowsPerEnd: arrowsPerEnd,
    totalEnds: totalEnds,
    maxScore: maxScore,
    faceSize: faceSize,
    faceCount: faceCount,
    isIndoor: isIndoor,
  );
}

/// Creates a fake End for testing.
End createFakeEnd({
  required String id,
  required String sessionId,
  required int endNumber,
  int endScore = 0,
  int endXs = 0,
  String status = 'active', // 'active' or 'committed'
}) {
  return End(
    id: id,
    sessionId: sessionId,
    endNumber: endNumber,
    endScore: endScore,
    endXs: endXs,
    status: status,
    createdAt: DateTime.now(),
    committedAt: status == 'committed' ? DateTime.now() : null,
  );
}

// =============================================================================
// COORDINATE HELPERS
// =============================================================================

/// Creates an ArrowCoordinate at a specific score ring center.
ArrowCoordinate createCoordinateAtScore(int score, {int faceSizeCm = 40}) {
  // Map score to approximate distance from center
  // Ring boundaries: X=5%, 10=10%, 9=20%, 8=30%, etc.
  final radiusMm = faceSizeCm * 5.0;
  double distancePercent;

  switch (score) {
    case 10:
      distancePercent = 0.05; // X ring
      break;
    case 9:
      distancePercent = 0.15;
      break;
    case 8:
      distancePercent = 0.25;
      break;
    case 7:
      distancePercent = 0.35;
      break;
    case 6:
      distancePercent = 0.45;
      break;
    case 5:
      distancePercent = 0.55;
      break;
    case 4:
      distancePercent = 0.65;
      break;
    case 3:
      distancePercent = 0.75;
      break;
    case 2:
      distancePercent = 0.85;
      break;
    case 1:
      distancePercent = 0.95;
      break;
    default:
      distancePercent = 1.1; // Miss
  }

  final xMm = distancePercent * radiusMm;
  return ArrowCoordinate(xMm: xMm, yMm: 0, faceSizeCm: faceSizeCm);
}

// =============================================================================
// MATCHERS AND ASSERTIONS
// =============================================================================

/// Custom matcher for ArrowCoordinate approximate equality.
Matcher coordinateCloseTo(ArrowCoordinate expected, {double tolerance = 0.01}) {
  return predicate<ArrowCoordinate>(
    (actual) =>
        (actual.xMm - expected.xMm).abs() < tolerance &&
        (actual.yMm - expected.yMm).abs() < tolerance,
    'coordinate close to (${expected.xMm}, ${expected.yMm}) within $tolerance',
  );
}

/// Asserts that a value is within a percentage of expected.
void expectWithinPercent(num actual, num expected, double percent, {String? reason}) {
  final tolerance = expected.abs() * (percent / 100);
  expect(
    (actual - expected).abs() <= tolerance,
    isTrue,
    reason: reason ?? 'Expected $actual to be within $percent% of $expected',
  );
}

/// Asserts that a list is sorted in ascending order.
void expectSorted<T extends Comparable>(List<T> list, {String? reason}) {
  for (int i = 1; i < list.length; i++) {
    expect(
      list[i].compareTo(list[i - 1]) >= 0,
      isTrue,
      reason: reason ?? 'List not sorted at index $i',
    );
  }
}

// =============================================================================
// TEST GROUP HELPERS
// =============================================================================

/// Standard face sizes for parameterized tests.
const List<int> standardFaceSizes = [40, 60, 80, 122];

/// Standard EMA periods for volume testing.
const List<int> standardEmaPeriods = [7, 28, 90];

/// Common handicap test cases (roundTypeId, score, expectedHandicap).
const List<(String, int, int)> handicapTestCases = [
  ('wa_720_70m', 660, 3),
  ('wa_720_70m', 600, 24),
  ('wa_720_70m', 500, 54),
  ('wa_18m', 580, 2),
  ('wa_18m', 550, 21),
  ('portsmouth', 550, 21),
];

// =============================================================================
// DOCUMENTATION
// =============================================================================

/// Test file naming convention:
///   test/<category>/<source_file>_test.dart
///
/// Categories:
///   - models/     - Data models (Arrow, ArrowCoordinate, etc.)
///   - utils/      - Utility classes (calculators, helpers)
///   - widgets/    - Widget tests
///   - providers/  - State management tests
///   - services/   - Service layer tests
///   - db/         - Database operation tests
///   - integration/ - End-to-end flow tests
///
/// Test naming convention:
///   group('ClassName', () {
///     group('methodName', () {
///       test('does X when Y', () { ... });
///     });
///   });
///
/// Required test categories for each source file:
///   1. Happy path (normal operation)
///   2. Edge cases (boundaries, limits)
///   3. Error handling (invalid inputs)
///   4. State transitions (if stateful)
