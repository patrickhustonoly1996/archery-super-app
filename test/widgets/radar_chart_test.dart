/// Tests for RadarChart widget
///
/// Tests the radar/spider chart visualization component including
/// data points, multiple datasets, and rendering options.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/widgets/radar_chart.dart';
import 'package:archery_super_app/theme/app_theme.dart';

void main() {
  group('RadarDataPoint', () {
    test('creates with required parameters', () {
      const point = RadarDataPoint(
        label: 'Accuracy',
        value: 0.8,
      );

      expect(point.label, equals('Accuracy'));
      expect(point.value, equals(0.8));
      expect(point.displayValue, isNull);
    });

    test('creates with optional displayValue', () {
      const point = RadarDataPoint(
        label: 'Speed',
        value: 0.6,
        displayValue: '60%',
      );

      expect(point.displayValue, equals('60%'));
    });

    test('value can be 0', () {
      const point = RadarDataPoint(label: 'Test', value: 0.0);
      expect(point.value, equals(0.0));
    });

    test('value can be 1', () {
      const point = RadarDataPoint(label: 'Test', value: 1.0);
      expect(point.value, equals(1.0));
    });
  });

  group('RadarChartData', () {
    test('creates with required points', () {
      const data = RadarChartData(
        points: [
          RadarDataPoint(label: 'A', value: 0.5),
          RadarDataPoint(label: 'B', value: 0.7),
          RadarDataPoint(label: 'C', value: 0.3),
        ],
      );

      expect(data.points.length, equals(3));
      expect(data.label, isNull);
      expect(data.color, equals(AppColors.gold));
      expect(data.showFill, isTrue);
    });

    test('creates with optional label', () {
      const data = RadarChartData(
        label: 'Dataset 1',
        points: [
          RadarDataPoint(label: 'A', value: 0.5),
          RadarDataPoint(label: 'B', value: 0.7),
          RadarDataPoint(label: 'C', value: 0.3),
        ],
      );

      expect(data.label, equals('Dataset 1'));
    });

    test('creates with custom color', () {
      const data = RadarChartData(
        points: [
          RadarDataPoint(label: 'A', value: 0.5),
          RadarDataPoint(label: 'B', value: 0.7),
          RadarDataPoint(label: 'C', value: 0.3),
        ],
        color: Colors.blue,
      );

      expect(data.color, equals(Colors.blue));
    });

    test('creates without fill', () {
      const data = RadarChartData(
        points: [
          RadarDataPoint(label: 'A', value: 0.5),
          RadarDataPoint(label: 'B', value: 0.7),
          RadarDataPoint(label: 'C', value: 0.3),
        ],
        showFill: false,
      );

      expect(data.showFill, isFalse);
    });
  });

  group('RadarChart Widget', () {
    Widget createRadarChart({
      List<RadarChartData>? datasets,
      double size = 200,
      int gridLevels = 5,
      bool showLabels = true,
      bool showValues = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: RadarChart(
              datasets: datasets ?? [
                const RadarChartData(
                  points: [
                    RadarDataPoint(label: 'Accuracy', value: 0.8),
                    RadarDataPoint(label: 'Grouping', value: 0.7),
                    RadarDataPoint(label: 'Consistency', value: 0.9),
                    RadarDataPoint(label: 'Form', value: 0.6),
                    RadarDataPoint(label: 'Mental', value: 0.75),
                  ],
                ),
              ],
              size: size,
              gridLevels: gridLevels,
              showLabels: showLabels,
              showValues: showValues,
            ),
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(createRadarChart());
        expect(find.byType(RadarChart), findsOneWidget);
      });

      testWidgets('renders with CustomPaint', (tester) async {
        await tester.pumpWidget(createRadarChart());
        // The radar chart uses CustomPaint for drawing
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('respects size parameter', (tester) async {
        await tester.pumpWidget(createRadarChart(size: 300));

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(RadarChart),
            matching: find.byType(SizedBox),
          ),
        );

        expect(sizedBox.width, equals(300));
        expect(sizedBox.height, equals(300));
      });

      testWidgets('uses default size of 200', (tester) async {
        await tester.pumpWidget(createRadarChart());

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(RadarChart),
            matching: find.byType(SizedBox),
          ),
        );

        expect(sizedBox.width, equals(200));
        expect(sizedBox.height, equals(200));
      });
    });

    group('Empty States', () {
      testWidgets('shows "No data" for empty datasets', (tester) async {
        await tester.pumpWidget(createRadarChart(datasets: []));
        expect(find.text('No data'), findsOneWidget);
      });

      testWidgets('shows "No data" for empty points', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [const RadarChartData(points: [])],
        ));
        expect(find.text('No data'), findsOneWidget);
      });
    });

    group('Data Visualization', () {
      testWidgets('renders with 3 data points (minimum)', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [
            const RadarChartData(
              points: [
                RadarDataPoint(label: 'A', value: 0.5),
                RadarDataPoint(label: 'B', value: 0.7),
                RadarDataPoint(label: 'C', value: 0.3),
              ],
            ),
          ],
        ));

        expect(find.byType(RadarChart), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('renders with 6 data points', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [
            const RadarChartData(
              points: [
                RadarDataPoint(label: 'A', value: 0.5),
                RadarDataPoint(label: 'B', value: 0.7),
                RadarDataPoint(label: 'C', value: 0.3),
                RadarDataPoint(label: 'D', value: 0.8),
                RadarDataPoint(label: 'E', value: 0.6),
                RadarDataPoint(label: 'F', value: 0.4),
              ],
            ),
          ],
        ));

        expect(find.byType(RadarChart), findsOneWidget);
      });

      testWidgets('renders with multiple datasets', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [
            const RadarChartData(
              label: 'Current',
              points: [
                RadarDataPoint(label: 'A', value: 0.8),
                RadarDataPoint(label: 'B', value: 0.7),
                RadarDataPoint(label: 'C', value: 0.9),
              ],
              color: AppColors.gold,
            ),
            const RadarChartData(
              label: 'Target',
              points: [
                RadarDataPoint(label: 'A', value: 1.0),
                RadarDataPoint(label: 'B', value: 1.0),
                RadarDataPoint(label: 'C', value: 1.0),
              ],
              color: Colors.grey,
              showFill: false,
            ),
          ],
        ));

        expect(find.byType(RadarChart), findsOneWidget);
      });
    });

    group('Grid Levels', () {
      testWidgets('renders with default 5 grid levels', (tester) async {
        await tester.pumpWidget(createRadarChart(gridLevels: 5));
        expect(find.byType(RadarChart), findsOneWidget);
      });

      testWidgets('renders with 3 grid levels', (tester) async {
        await tester.pumpWidget(createRadarChart(gridLevels: 3));
        expect(find.byType(RadarChart), findsOneWidget);
      });

      testWidgets('renders with 10 grid levels', (tester) async {
        await tester.pumpWidget(createRadarChart(gridLevels: 10));
        expect(find.byType(RadarChart), findsOneWidget);
      });
    });

    group('Labels', () {
      testWidgets('renders with labels shown', (tester) async {
        await tester.pumpWidget(createRadarChart(showLabels: true));
        expect(find.byType(RadarChart), findsOneWidget);
      });

      testWidgets('renders with labels hidden', (tester) async {
        await tester.pumpWidget(createRadarChart(showLabels: false));
        expect(find.byType(RadarChart), findsOneWidget);
      });
    });

    group('Values', () {
      testWidgets('renders with values shown', (tester) async {
        await tester.pumpWidget(createRadarChart(
          showValues: true,
          datasets: [
            const RadarChartData(
              points: [
                RadarDataPoint(label: 'A', value: 0.8, displayValue: '80%'),
                RadarDataPoint(label: 'B', value: 0.7, displayValue: '70%'),
                RadarDataPoint(label: 'C', value: 0.6, displayValue: '60%'),
              ],
            ),
          ],
        ));
        expect(find.byType(RadarChart), findsOneWidget);
      });

      testWidgets('renders with values hidden', (tester) async {
        await tester.pumpWidget(createRadarChart(showValues: false));
        expect(find.byType(RadarChart), findsOneWidget);
      });
    });

    group('Value Clamping', () {
      testWidgets('handles values above 1.0', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [
            const RadarChartData(
              points: [
                RadarDataPoint(label: 'A', value: 1.5), // Above max
                RadarDataPoint(label: 'B', value: 0.7),
                RadarDataPoint(label: 'C', value: 0.3),
              ],
            ),
          ],
        ));

        // Should render without error (value clamped to 1.0)
        expect(find.byType(RadarChart), findsOneWidget);
      });

      testWidgets('handles values below 0.0', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [
            const RadarChartData(
              points: [
                RadarDataPoint(label: 'A', value: -0.5), // Below min
                RadarDataPoint(label: 'B', value: 0.7),
                RadarDataPoint(label: 'C', value: 0.3),
              ],
            ),
          ],
        ));

        // Should render without error (value clamped to 0.0)
        expect(find.byType(RadarChart), findsOneWidget);
      });
    });

    group('Archery Performance Profile', () {
      testWidgets('renders archery-specific performance metrics', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [
            const RadarChartData(
              label: 'Current Performance',
              points: [
                RadarDataPoint(label: 'Accuracy', value: 0.85, displayValue: '85%'),
                RadarDataPoint(label: 'Grouping', value: 0.78, displayValue: '78%'),
                RadarDataPoint(label: 'Consistency', value: 0.92, displayValue: '92%'),
                RadarDataPoint(label: 'Form', value: 0.70, displayValue: '70%'),
                RadarDataPoint(label: 'Mental', value: 0.80, displayValue: '80%'),
                RadarDataPoint(label: 'Fitness', value: 0.65, displayValue: '65%'),
              ],
            ),
          ],
          size: 300,
          showLabels: true,
          showValues: true,
        ));

        expect(find.byType(RadarChart), findsOneWidget);
      });
    });

    group('Color Variations', () {
      testWidgets('renders with gold color (default)', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [
            const RadarChartData(
              points: [
                RadarDataPoint(label: 'A', value: 0.5),
                RadarDataPoint(label: 'B', value: 0.7),
                RadarDataPoint(label: 'C', value: 0.3),
              ],
              color: AppColors.gold,
            ),
          ],
        ));
        expect(find.byType(RadarChart), findsOneWidget);
      });

      testWidgets('renders with custom color', (tester) async {
        await tester.pumpWidget(createRadarChart(
          datasets: [
            const RadarChartData(
              points: [
                RadarDataPoint(label: 'A', value: 0.5),
                RadarDataPoint(label: 'B', value: 0.7),
                RadarDataPoint(label: 'C', value: 0.3),
              ],
              color: Colors.red,
            ),
          ],
        ));
        expect(find.byType(RadarChart), findsOneWidget);
      });
    });
  });
}
