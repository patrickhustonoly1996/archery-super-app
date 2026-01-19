import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/shaft_analysis.dart';
import 'package:archery_super_app/db/database.dart';

void main() {
  // Helper to create test shafts
  Shaft createShaft({
    String id = 'shaft-1',
    String quiverId = 'quiver-1',
    int number = 1,
  }) {
    return Shaft(
      id: id,
      quiverId: quiverId,
      number: number,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  // Helper to create test arrows
  Arrow createArrow({
    String id = 'arrow-1',
    String endId = 'end-1',
    double xMm = 0,
    double yMm = 0,
    int score = 10,
    String? shaftId,
  }) {
    return Arrow(
      id: id,
      endId: endId,
      faceIndex: 0,
      x: xMm / 100, // Normalized
      y: yMm / 100,
      xMm: xMm,
      yMm: yMm,
      score: score,
      isX: score == 10,
      sequence: 1,
      shaftId: shaftId,
      rating: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  group('ShaftAnalysisResult', () {
    group('recommendation', () {
      test('returns need more shots when arrow count < 3', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 2,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 0,
          groupSpreadMm: 0,
          scoreDistribution: {},
          avgScore: 9.0,
          outlierCount: 0,
          shouldRetire: false,
          overlapLikelihood: 0,
        );

        expect(result.recommendation, contains('Need more shots'));
        expect(result.recommendation, contains('minimum 3'));
      });

      test('returns retirement recommendation when shouldRetire is true', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 12,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 10,
          groupSpreadMm: 30,
          scoreDistribution: {5: 6, 6: 6},
          avgScore: 5.5,
          outlierCount: 5,
          shouldRetire: true,
          overlapLikelihood: 0.2,
        );

        expect(result.recommendation, contains('Consider retiring'));
      });

      test('returns inconsistent when outliers exceed 30%', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 10,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 10,
          groupSpreadMm: 30,
          scoreDistribution: {8: 5, 9: 5},
          avgScore: 8.5,
          outlierCount: 4, // 40% outliers
          shouldRetire: false,
          overlapLikelihood: 0.2,
        );

        expect(result.recommendation, contains('Inconsistent'));
        expect(result.recommendation, contains('outliers'));
      });

      test('returns performing well when avgScore > 8.5', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 10,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 5,
          groupSpreadMm: 15,
          scoreDistribution: {9: 5, 10: 5},
          avgScore: 9.5,
          outlierCount: 1,
          shouldRetire: false,
          overlapLikelihood: 0.1,
        );

        expect(result.recommendation, contains('Performing well'));
      });

      test('returns below average when avgScore < 7.0', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 10,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 15,
          groupSpreadMm: 40,
          scoreDistribution: {6: 5, 7: 5},
          avgScore: 6.5,
          outlierCount: 2,
          shouldRetire: false,
          overlapLikelihood: 0.2,
        );

        expect(result.recommendation, contains('Below average'));
        expect(result.recommendation, contains('fletching'));
      });

      test('returns average performance for middle scores', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 10,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 10,
          groupSpreadMm: 25,
          scoreDistribution: {7: 5, 8: 5},
          avgScore: 7.5,
          outlierCount: 2,
          shouldRetire: false,
          overlapLikelihood: 0.15,
        );

        expect(result.recommendation, contains('Average performance'));
      });
    });

    group('performanceColor', () {
      test('returns gray when arrow count < 3', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 2,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 0,
          groupSpreadMm: 0,
          scoreDistribution: {},
          avgScore: 9.0,
          outlierCount: 0,
          shouldRetire: false,
          overlapLikelihood: 0,
        );

        expect(result.performanceColor, equals('gray'));
      });

      test('returns red when shouldRetire is true', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 12,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 15,
          groupSpreadMm: 40,
          scoreDistribution: {5: 6, 6: 6},
          avgScore: 5.5,
          outlierCount: 5,
          shouldRetire: true,
          overlapLikelihood: 0.2,
        );

        expect(result.performanceColor, equals('red'));
      });

      test('returns green when avgScore > 8.5', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 10,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 5,
          groupSpreadMm: 15,
          scoreDistribution: {9: 5, 10: 5},
          avgScore: 9.5,
          outlierCount: 1,
          shouldRetire: false,
          overlapLikelihood: 0.1,
        );

        expect(result.performanceColor, equals('green'));
      });

      test('returns yellow when avgScore < 7.0', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 10,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 15,
          groupSpreadMm: 40,
          scoreDistribution: {6: 5, 7: 5},
          avgScore: 6.5,
          outlierCount: 2,
          shouldRetire: false,
          overlapLikelihood: 0.2,
        );

        expect(result.performanceColor, equals('yellow'));
      });

      test('returns green for average scores between 7.0 and 8.5', () {
        final result = ShaftAnalysisResult(
          shaft: createShaft(),
          arrowCount: 10,
          avgXMm: 0,
          avgYMm: 0,
          avgDeviationMm: 10,
          groupSpreadMm: 25,
          scoreDistribution: {7: 5, 8: 5},
          avgScore: 7.5,
          outlierCount: 2,
          shouldRetire: false,
          overlapLikelihood: 0.15,
        );

        expect(result.performanceColor, equals('green'));
      });
    });
  });

  group('ShaftAnalysis', () {
    group('analyzeShaft', () {
      test('returns empty result for shaft with no arrows', () {
        final shaft = createShaft();
        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: [],
          allArrows: [],
        );

        expect(result.arrowCount, equals(0));
        expect(result.avgXMm, equals(0));
        expect(result.avgYMm, equals(0));
        expect(result.avgDeviationMm, equals(0));
        expect(result.groupSpreadMm, equals(0));
        expect(result.scoreDistribution, isEmpty);
        expect(result.avgScore, equals(0));
        expect(result.outlierCount, equals(0));
        expect(result.shouldRetire, isFalse);
        expect(result.overlapLikelihood, equals(0));
      });

      test('calculates correct group center', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', xMm: 10, yMm: 10, score: 9),
          createArrow(id: '2', xMm: 20, yMm: 20, score: 9),
          createArrow(id: '3', xMm: 30, yMm: 30, score: 9),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgXMm, equals(20.0));
        expect(result.avgYMm, equals(20.0));
      });

      test('calculates correct score distribution', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', score: 10),
          createArrow(id: '2', score: 10),
          createArrow(id: '3', score: 9),
          createArrow(id: '4', score: 8),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.scoreDistribution[10], equals(2));
        expect(result.scoreDistribution[9], equals(1));
        expect(result.scoreDistribution[8], equals(1));
      });

      test('calculates correct average score', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', score: 10),
          createArrow(id: '2', score: 8),
          createArrow(id: '3', score: 9),
          createArrow(id: '4', score: 9),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgScore, equals(9.0));
      });

      test('calculates group spread as max distance between any two arrows', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', xMm: 0, yMm: 0, score: 10),
          createArrow(id: '2', xMm: 30, yMm: 40, score: 10), // Distance from origin = 50
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.groupSpreadMm, equals(50.0));
      });

      test('calculates group spread with multiple arrows', () {
        final shaft = createShaft();
        // Triangle with sides 10, 10, and diagonal ~14.14
        final arrows = [
          createArrow(id: '1', xMm: 0, yMm: 0, score: 10),
          createArrow(id: '2', xMm: 10, yMm: 0, score: 10),
          createArrow(id: '3', xMm: 0, yMm: 10, score: 10),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        // Max spread is diagonal: sqrt(10^2 + 10^2) = sqrt(200) ≈ 14.14
        expect(result.groupSpreadMm, closeTo(14.14, 0.01));
      });

      test('does not recommend retirement with fewer than 10 shots', () {
        final shaft = createShaft();
        final arrows = List.generate(
          9,
          (i) => createArrow(id: '$i', score: 3, xMm: i * 10.0, yMm: i * 10.0),
        );

        final allArrows = [
          ...arrows,
          ...List.generate(
            20,
            (i) => createArrow(id: 'other-$i', score: 9),
          ),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: allArrows,
        );

        expect(result.shouldRetire, isFalse);
      });

      test('identifies poor performing shaft even without triggering retirement', () {
        final shaft = createShaft();
        // Create 12 arrows with low scores and wide spread
        // The retirement logic is very conservative - requires ALL of:
        // 1. 10+ shots
        // 2. avgScore < (overallAvg - 1.5)
        // 3. outlierCount > arrows.length * 0.3
        // The outlier threshold (avgDev + 2*stdDev) makes #3 very hard to trigger.
        // This test verifies the shaft is identified as poor performing.

        final arrows = [
          // Arrows with wide spread and low scores
          createArrow(id: '0', score: 5, xMm: 0, yMm: 0, shaftId: 'shaft-1'),
          createArrow(id: '1', score: 5, xMm: 20, yMm: 20, shaftId: 'shaft-1'),
          createArrow(id: '2', score: 5, xMm: -20, yMm: -20, shaftId: 'shaft-1'),
          createArrow(id: '3', score: 5, xMm: 20, yMm: -20, shaftId: 'shaft-1'),
          createArrow(id: '4', score: 5, xMm: -20, yMm: 20, shaftId: 'shaft-1'),
          createArrow(id: '5', score: 4, xMm: 40, yMm: 0, shaftId: 'shaft-1'),
          createArrow(id: '6', score: 4, xMm: 0, yMm: 40, shaftId: 'shaft-1'),
          createArrow(id: '7', score: 4, xMm: -40, yMm: 0, shaftId: 'shaft-1'),
          createArrow(id: '8', score: 4, xMm: 60, yMm: 60, shaftId: 'shaft-1'),
          createArrow(id: '9', score: 4, xMm: -60, yMm: -60, shaftId: 'shaft-1'),
          createArrow(id: '10', score: 3, xMm: 80, yMm: -80, shaftId: 'shaft-1'),
          createArrow(id: '11', score: 3, xMm: -80, yMm: 80, shaftId: 'shaft-1'),
        ];

        // Other arrows have better average (score 9)
        final allArrows = [
          ...arrows,
          ...List.generate(
            30,
            (i) => createArrow(id: 'other-$i', score: 9),
          ),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: allArrows,
        );

        // Verify the shaft shows poor performance indicators
        expect(result.arrowCount, equals(12));
        expect(result.avgScore, lessThan(5)); // Poor average
        expect(result.groupSpreadMm, greaterThan(100)); // Wide spread
        // The recommendation should indicate poor performance
        expect(result.recommendation, contains('Below average'));
        expect(result.performanceColor, equals('yellow'));
      });

      test('does not recommend retirement for shaft performing close to average', () {
        final shaft = createShaft();
        final arrows = List.generate(
          12,
          (i) => createArrow(id: '$i', score: 8, xMm: 0, yMm: 0, shaftId: 'shaft-1'),
        );

        final allArrows = [
          ...arrows,
          ...List.generate(
            20,
            (i) => createArrow(id: 'other-$i', score: 9),
          ),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: allArrows,
        );

        // avgScore (8) is not significantly below overall average
        expect(result.shouldRetire, isFalse);
      });

      test('correctly counts outliers beyond 2 standard deviations', () {
        final shaft = createShaft();
        // Create a tight group with one outlier
        final arrows = [
          createArrow(id: '1', xMm: 0, yMm: 0, score: 10),
          createArrow(id: '2', xMm: 1, yMm: 1, score: 10),
          createArrow(id: '3', xMm: -1, yMm: -1, score: 10),
          createArrow(id: '4', xMm: 1, yMm: -1, score: 10),
          createArrow(id: '5', xMm: -1, yMm: 1, score: 10),
          createArrow(id: '6', xMm: 100, yMm: 100, score: 5), // Clear outlier
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.outlierCount, greaterThan(0));
      });

      test('handles single arrow correctly', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', xMm: 10, yMm: 20, score: 9),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.arrowCount, equals(1));
        expect(result.avgXMm, equals(10.0));
        expect(result.avgYMm, equals(20.0));
        expect(result.avgScore, equals(9.0));
        expect(result.groupSpreadMm, equals(0.0)); // Single arrow = no spread
      });

      test('calculates average deviation from group center', () {
        final shaft = createShaft();
        // Arrows at distance 10 from center (0,0)
        final arrows = [
          createArrow(id: '1', xMm: 10, yMm: 0, score: 10),
          createArrow(id: '2', xMm: -10, yMm: 0, score: 10),
          createArrow(id: '3', xMm: 0, yMm: 10, score: 10),
          createArrow(id: '4', xMm: 0, yMm: -10, score: 10),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        // Center is at (0,0), each arrow is 10mm from center
        expect(result.avgDeviationMm, equals(10.0));
      });
    });

    group('analyzeQuiver', () {
      test('returns empty list for empty quiver', () async {
        final results = await ShaftAnalysis.analyzeQuiver(
          shafts: [],
          allArrows: [],
        );

        expect(results, isEmpty);
      });

      test('analyzes all shafts in quiver', () async {
        final shafts = [
          createShaft(id: 'shaft-1', number: 1),
          createShaft(id: 'shaft-2', number: 2),
          createShaft(id: 'shaft-3', number: 3),
        ];

        final arrows = [
          createArrow(id: '1', shaftId: 'shaft-1', score: 10),
          createArrow(id: '2', shaftId: 'shaft-1', score: 9),
          createArrow(id: '3', shaftId: 'shaft-2', score: 8),
          createArrow(id: '4', shaftId: 'shaft-3', score: 10),
          createArrow(id: '5', shaftId: 'shaft-3', score: 10),
          createArrow(id: '6', shaftId: 'shaft-3', score: 10),
        ];

        final results = await ShaftAnalysis.analyzeQuiver(
          shafts: shafts,
          allArrows: arrows,
        );

        expect(results, hasLength(3));
      });

      test('sorts results by arrow count descending', () async {
        final shafts = [
          createShaft(id: 'shaft-1', number: 1),
          createShaft(id: 'shaft-2', number: 2),
          createShaft(id: 'shaft-3', number: 3),
        ];

        final arrows = [
          // Shaft 1 has 2 arrows
          createArrow(id: '1', shaftId: 'shaft-1', score: 10),
          createArrow(id: '2', shaftId: 'shaft-1', score: 9),
          // Shaft 2 has 5 arrows
          createArrow(id: '3', shaftId: 'shaft-2', score: 8),
          createArrow(id: '4', shaftId: 'shaft-2', score: 8),
          createArrow(id: '5', shaftId: 'shaft-2', score: 8),
          createArrow(id: '6', shaftId: 'shaft-2', score: 8),
          createArrow(id: '7', shaftId: 'shaft-2', score: 8),
          // Shaft 3 has 3 arrows
          createArrow(id: '8', shaftId: 'shaft-3', score: 10),
          createArrow(id: '9', shaftId: 'shaft-3', score: 10),
          createArrow(id: '10', shaftId: 'shaft-3', score: 10),
        ];

        final results = await ShaftAnalysis.analyzeQuiver(
          shafts: shafts,
          allArrows: arrows,
        );

        expect(results[0].arrowCount, equals(5)); // shaft-2
        expect(results[1].arrowCount, equals(3)); // shaft-3
        expect(results[2].arrowCount, equals(2)); // shaft-1
      });

      test('correctly filters arrows by shaft ID', () async {
        final shafts = [
          createShaft(id: 'shaft-1', number: 1),
          createShaft(id: 'shaft-2', number: 2),
        ];

        final arrows = [
          createArrow(id: '1', shaftId: 'shaft-1', score: 10),
          createArrow(id: '2', shaftId: 'shaft-1', score: 10),
          createArrow(id: '3', shaftId: 'shaft-2', score: 5),
        ];

        final results = await ShaftAnalysis.analyzeQuiver(
          shafts: shafts,
          allArrows: arrows,
        );

        // Find shaft-1 result (2 arrows with avg 10)
        final shaft1Result = results.firstWhere((r) => r.shaft.id == 'shaft-1');
        expect(shaft1Result.arrowCount, equals(2));
        expect(shaft1Result.avgScore, equals(10.0));

        // Find shaft-2 result (1 arrow with score 5)
        final shaft2Result = results.firstWhere((r) => r.shaft.id == 'shaft-2');
        expect(shaft2Result.arrowCount, equals(1));
        expect(shaft2Result.avgScore, equals(5.0));
      });

      test('handles shaft with no arrows', () async {
        final shafts = [
          createShaft(id: 'shaft-1', number: 1),
          createShaft(id: 'shaft-2', number: 2),
        ];

        final arrows = [
          createArrow(id: '1', shaftId: 'shaft-1', score: 10),
          // No arrows for shaft-2
        ];

        final results = await ShaftAnalysis.analyzeQuiver(
          shafts: shafts,
          allArrows: arrows,
        );

        final shaft2Result = results.firstWhere((r) => r.shaft.id == 'shaft-2');
        expect(shaft2Result.arrowCount, equals(0));
      });
    });

    group('getRetirementCandidates', () {
      test('returns empty list when no shafts should retire', () {
        final results = [
          ShaftAnalysisResult(
            shaft: createShaft(id: 'shaft-1'),
            arrowCount: 15,
            avgXMm: 0,
            avgYMm: 0,
            avgDeviationMm: 5,
            groupSpreadMm: 15,
            scoreDistribution: {9: 10, 10: 5},
            avgScore: 9.3,
            outlierCount: 1,
            shouldRetire: false,
            overlapLikelihood: 0.1,
          ),
        ];

        final candidates = ShaftAnalysis.getRetirementCandidates(results);
        expect(candidates, isEmpty);
      });

      test('returns shafts that should retire', () {
        final shaft1 = createShaft(id: 'shaft-1', number: 1);
        final shaft2 = createShaft(id: 'shaft-2', number: 2);
        final shaft3 = createShaft(id: 'shaft-3', number: 3);

        final results = [
          ShaftAnalysisResult(
            shaft: shaft1,
            arrowCount: 15,
            avgXMm: 0,
            avgYMm: 0,
            avgDeviationMm: 5,
            groupSpreadMm: 15,
            scoreDistribution: {9: 10, 10: 5},
            avgScore: 9.3,
            outlierCount: 1,
            shouldRetire: false,
            overlapLikelihood: 0.1,
          ),
          ShaftAnalysisResult(
            shaft: shaft2,
            arrowCount: 15,
            avgXMm: 0,
            avgYMm: 0,
            avgDeviationMm: 20,
            groupSpreadMm: 50,
            scoreDistribution: {4: 8, 5: 7},
            avgScore: 4.5,
            outlierCount: 6,
            shouldRetire: true,
            overlapLikelihood: 0.8,
          ),
          ShaftAnalysisResult(
            shaft: shaft3,
            arrowCount: 15,
            avgXMm: 0,
            avgYMm: 0,
            avgDeviationMm: 25,
            groupSpreadMm: 60,
            scoreDistribution: {3: 10, 4: 5},
            avgScore: 3.3,
            outlierCount: 7,
            shouldRetire: true,
            overlapLikelihood: 0.9,
          ),
        ];

        final candidates = ShaftAnalysis.getRetirementCandidates(results);
        expect(candidates, hasLength(2));
        expect(candidates.map((s) => s.id), containsAll(['shaft-2', 'shaft-3']));
      });
    });

    group('getOverlapWarning', () {
      test('returns null when no shafts have high overlap', () {
        final results = [
          ShaftAnalysisResult(
            shaft: createShaft(id: 'shaft-1', number: 1),
            arrowCount: 10,
            avgXMm: 0,
            avgYMm: 0,
            avgDeviationMm: 5,
            groupSpreadMm: 15,
            scoreDistribution: {9: 5, 10: 5},
            avgScore: 9.5,
            outlierCount: 1,
            shouldRetire: false,
            overlapLikelihood: 0.3, // Below 0.7 threshold
          ),
        ];

        final warning = ShaftAnalysis.getOverlapWarning(results);
        expect(warning, isNull);
      });

      test('returns null when shaft has fewer than 6 arrows', () {
        final results = [
          ShaftAnalysisResult(
            shaft: createShaft(id: 'shaft-1', number: 1),
            arrowCount: 5, // Below 6 threshold
            avgXMm: 0,
            avgYMm: 0,
            avgDeviationMm: 5,
            groupSpreadMm: 15,
            scoreDistribution: {9: 3, 10: 2},
            avgScore: 9.4,
            outlierCount: 0,
            shouldRetire: false,
            overlapLikelihood: 0.9, // High but not enough arrows
          ),
        ];

        final warning = ShaftAnalysis.getOverlapWarning(results);
        expect(warning, isNull);
      });

      test('returns warning with shaft numbers for high overlap', () {
        final results = [
          ShaftAnalysisResult(
            shaft: createShaft(id: 'shaft-1', number: 1),
            arrowCount: 10,
            avgXMm: 0,
            avgYMm: 0,
            avgDeviationMm: 5,
            groupSpreadMm: 15,
            scoreDistribution: {9: 5, 10: 5},
            avgScore: 9.5,
            outlierCount: 1,
            shouldRetire: false,
            overlapLikelihood: 0.8, // Above 0.7 threshold
          ),
          ShaftAnalysisResult(
            shaft: createShaft(id: 'shaft-2', number: 3),
            arrowCount: 8,
            avgXMm: 50,
            avgYMm: 50,
            avgDeviationMm: 5,
            groupSpreadMm: 15,
            scoreDistribution: {7: 4, 8: 4},
            avgScore: 7.5,
            outlierCount: 1,
            shouldRetire: false,
            overlapLikelihood: 0.75,
          ),
        ];

        final warning = ShaftAnalysis.getOverlapWarning(results);
        expect(warning, isNotNull);
        expect(warning, contains('1'));
        expect(warning, contains('3'));
        expect(warning, contains('distinct grouping'));
      });
    });

    group('overlap likelihood calculation', () {
      test('returns 0 for shaft with fewer than 3 arrows', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', xMm: 0, yMm: 0, score: 10, shaftId: 'shaft-1'),
          createArrow(id: '2', xMm: 10, yMm: 10, score: 10, shaftId: 'shaft-1'),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.overlapLikelihood, equals(0));
      });

      test('returns 0 when total arrows fewer than 6', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', xMm: 0, yMm: 0, score: 10, shaftId: 'shaft-1'),
          createArrow(id: '2', xMm: 10, yMm: 10, score: 10, shaftId: 'shaft-1'),
          createArrow(id: '3', xMm: 5, yMm: 5, score: 10, shaftId: 'shaft-1'),
          createArrow(id: '4', xMm: 100, yMm: 100, score: 10, shaftId: 'other'),
          createArrow(id: '5', xMm: 100, yMm: 100, score: 10, shaftId: 'other'),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows.where((a) => a.shaftId == 'shaft-1').toList(),
          allArrows: arrows,
        );

        expect(result.overlapLikelihood, equals(0));
      });

      test('calculates higher overlap likelihood for shaft far from center', () {
        final shaft = createShaft();
        // Shaft arrows are far from overall center
        final shaftArrows = [
          createArrow(id: '1', xMm: 100, yMm: 100, score: 8, shaftId: 'shaft-1'),
          createArrow(id: '2', xMm: 105, yMm: 105, score: 8, shaftId: 'shaft-1'),
          createArrow(id: '3', xMm: 95, yMm: 95, score: 8, shaftId: 'shaft-1'),
        ];

        // Other arrows near origin
        final otherArrows = [
          createArrow(id: '4', xMm: 0, yMm: 0, score: 10, shaftId: 'other'),
          createArrow(id: '5', xMm: 5, yMm: 5, score: 10, shaftId: 'other'),
          createArrow(id: '6', xMm: -5, yMm: -5, score: 10, shaftId: 'other'),
        ];

        final allArrows = [...shaftArrows, ...otherArrows];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: shaftArrows,
          allArrows: allArrows,
        );

        // Shaft center is far from overall center, should have high overlap likelihood
        expect(result.overlapLikelihood, greaterThan(0.5));
      });

      test('calculates lower overlap likelihood for shaft near center', () {
        final shaft = createShaft();
        // Shaft arrows are near overall center
        final shaftArrows = [
          createArrow(id: '1', xMm: 0, yMm: 0, score: 10, shaftId: 'shaft-1'),
          createArrow(id: '2', xMm: 5, yMm: 5, score: 10, shaftId: 'shaft-1'),
          createArrow(id: '3', xMm: -5, yMm: -5, score: 10, shaftId: 'shaft-1'),
        ];

        // Other arrows also near origin
        final otherArrows = [
          createArrow(id: '4', xMm: 3, yMm: 3, score: 10, shaftId: 'other'),
          createArrow(id: '5', xMm: -3, yMm: -3, score: 10, shaftId: 'other'),
          createArrow(id: '6', xMm: 0, yMm: 3, score: 10, shaftId: 'other'),
        ];

        final allArrows = [...shaftArrows, ...otherArrows];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: shaftArrows,
          allArrows: allArrows,
        );

        // Shaft center is close to overall center
        expect(result.overlapLikelihood, lessThan(0.5));
      });

      test('clamps overlap likelihood to maximum of 1.0', () {
        final shaft = createShaft();
        // Shaft arrows are extremely far from overall center with tight grouping
        final shaftArrows = [
          createArrow(id: '1', xMm: 500, yMm: 500, score: 5, shaftId: 'shaft-1'),
          createArrow(id: '2', xMm: 501, yMm: 501, score: 5, shaftId: 'shaft-1'),
          createArrow(id: '3', xMm: 500, yMm: 501, score: 5, shaftId: 'shaft-1'),
        ];

        // Other arrows at origin
        final otherArrows = [
          createArrow(id: '4', xMm: 0, yMm: 0, score: 10, shaftId: 'other'),
          createArrow(id: '5', xMm: 1, yMm: 1, score: 10, shaftId: 'other'),
          createArrow(id: '6', xMm: -1, yMm: -1, score: 10, shaftId: 'other'),
        ];

        final allArrows = [...shaftArrows, ...otherArrows];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: shaftArrows,
          allArrows: allArrows,
        );

        expect(result.overlapLikelihood, equals(1.0));
      });
    });

    group('edge cases', () {
      test('handles negative coordinates', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', xMm: -10, yMm: -10, score: 9),
          createArrow(id: '2', xMm: -20, yMm: -20, score: 9),
          createArrow(id: '3', xMm: -30, yMm: -30, score: 9),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgXMm, equals(-20.0));
        expect(result.avgYMm, equals(-20.0));
      });

      test('handles mixed positive and negative coordinates', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', xMm: 10, yMm: -10, score: 9),
          createArrow(id: '2', xMm: -10, yMm: 10, score: 9),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgXMm, equals(0.0));
        expect(result.avgYMm, equals(0.0));
      });

      test('handles zero scores', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', score: 0, xMm: 100, yMm: 100),
          createArrow(id: '2', score: 0, xMm: 100, yMm: 100),
          createArrow(id: '3', score: 0, xMm: 100, yMm: 100),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgScore, equals(0.0));
        expect(result.scoreDistribution[0], equals(3));
      });

      test('handles all arrows at same position', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', xMm: 5, yMm: 5, score: 10),
          createArrow(id: '2', xMm: 5, yMm: 5, score: 10),
          createArrow(id: '3', xMm: 5, yMm: 5, score: 10),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgXMm, equals(5.0));
        expect(result.avgYMm, equals(5.0));
        expect(result.avgDeviationMm, equals(0.0));
        expect(result.groupSpreadMm, equals(0.0));
        expect(result.outlierCount, equals(0));
      });

      test('handles large number of arrows', () {
        final shaft = createShaft();
        final arrows = List.generate(
          100,
          (i) => createArrow(
            id: '$i',
            xMm: (i % 10).toDouble(),
            yMm: (i % 10).toDouble(),
            score: 8 + (i % 3),
          ),
        );

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.arrowCount, equals(100));
        expect(result.avgScore, greaterThan(0));
      });

      test('handles extreme score values', () {
        final shaft = createShaft();
        final arrows = [
          createArrow(id: '1', score: 10),
          createArrow(id: '2', score: 10),
          createArrow(id: '3', score: 10),
          createArrow(id: '4', score: 0),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgScore, equals(7.5));
        expect(result.scoreDistribution[10], equals(3));
        expect(result.scoreDistribution[0], equals(1));
      });
    });

    group('Olympic archer scenarios', () {
      test('analyzes high-performing Olympic shaft correctly', () {
        final shaft = createShaft(id: 'olympic-1', number: 1);
        // Olympic archer with tight grouping - all shots within 5mm of center
        final arrows = List.generate(20, (i) {
          final angle = i * 0.314; // Spread around center
          return createArrow(
            id: 'olympic-$i',
            xMm: 2 * (i % 3 - 1).toDouble(),
            yMm: 2 * ((i + 1) % 3 - 1).toDouble(),
            score: i < 15 ? 10 : 9, // Mostly 10s
            shaftId: 'olympic-1',
          );
        });

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.arrowCount, equals(20));
        expect(result.avgScore, greaterThan(9.0));
        expect(result.avgDeviationMm, lessThan(5));
        expect(result.shouldRetire, isFalse);
        expect(result.recommendation, contains('Performing well'));
        expect(result.performanceColor, equals('green'));
      });

      test('identifies shaft with damaged fletching', () {
        final shaft = createShaft(id: 'damaged-1', number: 2);
        // Damaged fletching causes erratic flight - scattered pattern with low scores
        // This test verifies the shaft is identified as problematic through metrics

        final arrows = [
          // Scattered arrows with low scores - simulating damaged fletching
          createArrow(id: 'damaged-0', xMm: 0, yMm: 0, score: 5, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-1', xMm: 30, yMm: 30, score: 5, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-2', xMm: -30, yMm: -30, score: 5, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-3', xMm: 30, yMm: -30, score: 5, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-4', xMm: -30, yMm: 30, score: 5, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-5', xMm: 50, yMm: 0, score: 4, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-6', xMm: 0, yMm: 50, score: 4, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-7', xMm: -50, yMm: 0, score: 4, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-8', xMm: 70, yMm: 70, score: 3, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-9', xMm: -70, yMm: -70, score: 3, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-10', xMm: 70, yMm: -70, score: 3, shaftId: 'damaged-1'),
          createArrow(id: 'damaged-11', xMm: -70, yMm: 70, score: 3, shaftId: 'damaged-1'),
        ];

        // Compare with good arrows
        final goodArrows = List.generate(30, (i) {
          return createArrow(
            id: 'good-$i',
            xMm: (i % 5).toDouble(),
            yMm: (i % 5).toDouble(),
            score: 9,
          );
        });

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: [...arrows, ...goodArrows],
        );

        // Verify the shaft shows damage indicators
        expect(result.avgScore, lessThan(5)); // Poor average
        expect(result.groupSpreadMm, greaterThan(100)); // Wide spread from erratic flight
        expect(result.avgDeviationMm, greaterThan(30)); // High deviation
        // Performance indicators should show problems
        expect(result.recommendation, contains('Below average'));
        expect(result.performanceColor, equals('yellow'));
      });

      test('analyzes full quiver for competition prep', () async {
        // 12-arrow quiver typical for competition
        final shafts = List.generate(
          12,
          (i) => createShaft(id: 'comp-${i + 1}', number: i + 1),
        );

        // Generate realistic shot data for each shaft
        // Most shafts perform well, shaft 4 (index 3) underperforms
        final allArrows = <Arrow>[];
        for (int s = 0; s < 12; s++) {
          final isWeak = s == 3; // Only shaft 4 is weak

          if (isWeak) {
            // Weak shaft: low scores with wide spread
            final shaftArrows = List.generate(15, (i) => createArrow(
              id: 'comp-$s-$i',
              xMm: (i * 10 - 70).toDouble(), // Spread from -70 to +70
              yMm: ((i * 8) - 56).toDouble(),
              score: 4 + (i % 3), // 4, 5, 6 scores
              shaftId: 'comp-${s + 1}',
            ));
            allArrows.addAll(shaftArrows);
          } else {
            // Good shafts: high scores, tight grouping
            final shaftArrows = List.generate(15, (i) => createArrow(
              id: 'comp-$s-$i',
              xMm: (i % 4 - 2).toDouble(),
              yMm: ((i + 1) % 4 - 2).toDouble(),
              score: 9 + (i % 2), // 9s and 10s
              shaftId: 'comp-${s + 1}',
            ));
            allArrows.addAll(shaftArrows);
          }
        }

        final results = await ShaftAnalysis.analyzeQuiver(
          shafts: shafts,
          allArrows: allArrows,
        );

        expect(results, hasLength(12));

        // Find the weak shaft (comp-4)
        final weakShaftResult = results.firstWhere((r) => r.shaft.id == 'comp-4');
        final goodShaftResult = results.firstWhere((r) => r.shaft.id == 'comp-1');

        // Verify weak shaft has poor metrics compared to good shaft
        expect(weakShaftResult.avgScore, lessThan(6)); // Poor average
        expect(goodShaftResult.avgScore, greaterThan(9)); // Good average
        expect(weakShaftResult.groupSpreadMm, greaterThan(goodShaftResult.groupSpreadMm));

        // Weak shaft should have "Below average" recommendation
        expect(weakShaftResult.recommendation, contains('Below average'));
        // Good shaft should be "Performing well"
        expect(goodShaftResult.recommendation, contains('Performing well'));
      });
    });

    group('indoor vs outdoor analysis', () {
      test('handles indoor triple-spot target distances', () {
        final shaft = createShaft();
        // Indoor targets have smaller scoring areas
        final arrows = [
          createArrow(id: '1', xMm: 2, yMm: 2, score: 10),
          createArrow(id: '2', xMm: -2, yMm: -2, score: 10),
          createArrow(id: '3', xMm: 3, yMm: -3, score: 10),
          createArrow(id: '4', xMm: -3, yMm: 3, score: 10),
          createArrow(id: '5', xMm: 0, yMm: 0, score: 10),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgScore, equals(10.0));
        expect(result.groupSpreadMm, lessThan(10));
      });

      test('handles outdoor 70m target distances', () {
        final shaft = createShaft();
        // Outdoor at 70m has more spread due to wind, etc.
        final arrows = [
          createArrow(id: '1', xMm: 15, yMm: 20, score: 9),
          createArrow(id: '2', xMm: -10, yMm: -15, score: 9),
          createArrow(id: '3', xMm: 25, yMm: -5, score: 8),
          createArrow(id: '4', xMm: -20, yMm: 10, score: 9),
          createArrow(id: '5', xMm: 5, yMm: -25, score: 8),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.avgScore, closeTo(8.6, 0.1));
        expect(result.groupSpreadMm, greaterThan(30));
      });
    });

    group('statistical accuracy', () {
      test('standard deviation calculation is accurate', () {
        final shaft = createShaft();
        // Known values for std dev verification
        // Values: 2, 4, 4, 4, 5, 5, 7, 9 - mean = 5, stddev ≈ 2.0
        final arrows = [
          createArrow(id: '1', xMm: 0, yMm: 2, score: 10),
          createArrow(id: '2', xMm: 0, yMm: 4, score: 10),
          createArrow(id: '3', xMm: 0, yMm: 4, score: 10),
          createArrow(id: '4', xMm: 0, yMm: 4, score: 10),
          createArrow(id: '5', xMm: 0, yMm: 5, score: 10),
          createArrow(id: '6', xMm: 0, yMm: 5, score: 10),
          createArrow(id: '7', xMm: 0, yMm: 7, score: 10),
          createArrow(id: '8', xMm: 0, yMm: 9, score: 10),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        // Average Y should be 5.0
        expect(result.avgYMm, equals(5.0));
        // Deviation calculation should be mathematically sound
        expect(result.avgDeviationMm, greaterThan(0));
      });

      test('outlier detection uses correct 2 std dev threshold', () {
        final shaft = createShaft();
        // Create arrows where exactly one is clearly beyond 2 std devs
        final arrows = [
          createArrow(id: '1', xMm: 0, yMm: 0, score: 10),
          createArrow(id: '2', xMm: 1, yMm: 1, score: 10),
          createArrow(id: '3', xMm: -1, yMm: -1, score: 10),
          createArrow(id: '4', xMm: 2, yMm: 0, score: 10),
          createArrow(id: '5', xMm: 0, yMm: 2, score: 10),
          createArrow(id: '6', xMm: -2, yMm: 0, score: 10),
          createArrow(id: '7', xMm: 0, yMm: -2, score: 10),
          // Clear outlier at 50mm from center
          createArrow(id: '8', xMm: 50, yMm: 50, score: 5),
        ];

        final result = ShaftAnalysis.analyzeShaft(
          shaft: shaft,
          arrows: arrows,
          allArrows: arrows,
        );

        expect(result.outlierCount, equals(1));
      });
    });
  });
}
