/// Tests for BreathingVisualizer and BreathTimer widgets
///
/// Tests the breathing animation visualizer and timer display components.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/widgets/breathing_visualizer.dart';

void main() {
  group('BreathPhase', () {
    test('has all expected phases', () {
      expect(BreathPhase.values, contains(BreathPhase.inhale));
      expect(BreathPhase.values, contains(BreathPhase.exhale));
      expect(BreathPhase.values, contains(BreathPhase.hold));
      expect(BreathPhase.values, contains(BreathPhase.idle));
    });

    test('has 4 phases', () {
      expect(BreathPhase.values.length, equals(4));
    });

    test('inhale has index 0', () {
      expect(BreathPhase.inhale.index, equals(0));
    });

    test('exhale has index 1', () {
      expect(BreathPhase.exhale.index, equals(1));
    });

    test('hold has index 2', () {
      expect(BreathPhase.hold.index, equals(2));
    });

    test('idle has index 3', () {
      expect(BreathPhase.idle.index, equals(3));
    });
  });

  group('BreathingVisualizer', () {
    Widget createBreathingVisualizer({
      double progress = 0.0,
      BreathPhase phase = BreathPhase.idle,
      String? centerText,
      String? secondaryText,
      double size = 280,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: BreathingVisualizer(
              progress: progress,
              phase: phase,
              centerText: centerText,
              secondaryText: secondaryText,
              size: size,
            ),
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer());
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('renders with inhale phase', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.inhale,
        ));
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('renders with exhale phase', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.exhale,
        ));
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('renders with hold phase', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.hold,
        ));
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('renders with idle phase', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.idle,
        ));
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });
    });

    group('Center Text', () {
      testWidgets('displays center text when provided', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          centerText: 'Breathe In',
        ));
        expect(find.text('Breathe In'), findsOneWidget);
      });

      testWidgets('displays secondary text when provided', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          centerText: 'Hold',
          secondaryText: '4 seconds',
        ));
        expect(find.text('Hold'), findsOneWidget);
        expect(find.text('4 seconds'), findsOneWidget);
      });

      testWidgets('handles null center text', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          centerText: null,
        ));
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('handles null secondary text', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          centerText: 'Test',
          secondaryText: null,
        ));
        expect(find.text('Test'), findsOneWidget);
      });
    });

    group('Size', () {
      testWidgets('respects size parameter', (tester) async {
        // Use mobile screen size (< 600 width) to test base size
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createBreathingVisualizer(
          size: 200,
        ));

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(BreathingVisualizer),
            matching: find.byType(SizedBox),
          ).first,
        );

        // The outer SizedBox should match the size on mobile
        expect(sizedBox.width, equals(200));
        expect(sizedBox.height, equals(200));
      });

      testWidgets('uses default size of 280', (tester) async {
        // Use mobile screen size (< 600 width) to test base size
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createBreathingVisualizer());

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(BreathingVisualizer),
            matching: find.byType(SizedBox),
          ).first,
        );

        expect(sizedBox.width, equals(280));
        expect(sizedBox.height, equals(280));
      });

      testWidgets('scales up on large screens', (tester) async {
        // Use large screen size (> 600 width) to test scaling
        tester.view.physicalSize = const Size(900, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createBreathingVisualizer(
          size: 200,
        ));

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(BreathingVisualizer),
            matching: find.byType(SizedBox),
          ).first,
        );

        // On large screens, size is scaled up 30%
        expect(sizedBox.width, equals(260)); // 200 * 1.3
        expect(sizedBox.height, equals(260));
      });
    });

    group('Progress', () {
      testWidgets('handles progress at 0', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          progress: 0.0,
          phase: BreathPhase.inhale,
        ));
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('handles progress at 1', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          progress: 1.0,
          phase: BreathPhase.inhale,
        ));
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('handles progress at 0.5', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          progress: 0.5,
          phase: BreathPhase.inhale,
        ));
        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });
    });

    group('Phase Transitions', () {
      testWidgets('handles transition from idle to inhale', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.idle,
        ));
        await tester.pump();

        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.inhale,
        ));
        await tester.pump();

        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('handles transition from inhale to hold', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.inhale,
        ));
        await tester.pump();

        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.hold,
        ));
        await tester.pump();

        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });

      testWidgets('handles transition from hold to exhale', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.hold,
        ));
        await tester.pump();

        await tester.pumpWidget(createBreathingVisualizer(
          phase: BreathPhase.exhale,
        ));
        await tester.pump();

        expect(find.byType(BreathingVisualizer), findsOneWidget);
      });
    });

    group('Visual Elements', () {
      testWidgets('contains circular containers', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer());

        // Should have multiple Container widgets for the circles
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('contains Stack for layering', (tester) async {
        await tester.pumpWidget(createBreathingVisualizer());
        // The visualizer uses Stack for layering circles
        expect(find.byType(Stack), findsWidgets);
      });
    });
  });

  group('BreathTimer', () {
    Widget createBreathTimer({
      required int seconds,
      String? label,
      bool isHighlighted = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: BreathTimer(
              seconds: seconds,
              label: label,
              isHighlighted: isHighlighted,
            ),
          ),
        ),
      );
    }

    group('Time Display', () {
      testWidgets('displays seconds under 60', (tester) async {
        await tester.pumpWidget(createBreathTimer(seconds: 45));
        expect(find.text('45'), findsOneWidget);
      });

      testWidgets('displays minutes and seconds for 60+', (tester) async {
        await tester.pumpWidget(createBreathTimer(seconds: 90));
        expect(find.text('1:30'), findsOneWidget);
      });

      testWidgets('displays zero seconds', (tester) async {
        await tester.pumpWidget(createBreathTimer(seconds: 0));
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('pads seconds with zero for single digits', (tester) async {
        await tester.pumpWidget(createBreathTimer(seconds: 65));
        expect(find.text('1:05'), findsOneWidget);
      });

      testWidgets('handles large times', (tester) async {
        await tester.pumpWidget(createBreathTimer(seconds: 3600)); // 1 hour
        expect(find.text('60:00'), findsOneWidget);
      });
    });

    group('Label', () {
      testWidgets('displays label when provided', (tester) async {
        await tester.pumpWidget(createBreathTimer(
          seconds: 30,
          label: 'Time Remaining',
        ));
        expect(find.text('Time Remaining'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
      });

      testWidgets('works without label', (tester) async {
        await tester.pumpWidget(createBreathTimer(
          seconds: 30,
          label: null,
        ));
        expect(find.text('30'), findsOneWidget);
      });
    });

    group('Highlighting', () {
      testWidgets('renders when not highlighted', (tester) async {
        await tester.pumpWidget(createBreathTimer(
          seconds: 30,
          isHighlighted: false,
        ));
        expect(find.byType(BreathTimer), findsOneWidget);
      });

      testWidgets('renders when highlighted', (tester) async {
        await tester.pumpWidget(createBreathTimer(
          seconds: 30,
          isHighlighted: true,
        ));
        expect(find.byType(BreathTimer), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles exactly 60 seconds', (tester) async {
        await tester.pumpWidget(createBreathTimer(seconds: 60));
        expect(find.text('1:00'), findsOneWidget);
      });

      testWidgets('handles 59 seconds', (tester) async {
        await tester.pumpWidget(createBreathTimer(seconds: 59));
        expect(find.text('59'), findsOneWidget);
      });

      testWidgets('handles single digit seconds with minutes', (tester) async {
        await tester.pumpWidget(createBreathTimer(seconds: 61));
        expect(find.text('1:01'), findsOneWidget);
      });
    });
  });
}
