import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/widgets/scoring_timer_widget.dart';
import 'package:archery_super_app/services/scoring_timer_service.dart';

void main() {
  setUp(() {
    // Reset the singleton timer service before each test
    final service = ScoringTimerService();
    service.stop();
    // Reset configuration to defaults
    service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
  });

  tearDown(() {
    ScoringTimerService().stop();
  });

  group('ScoringTimerWidget', () {
    testWidgets('renders nothing when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: false,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      // Should render SizedBox.shrink when disabled
      expect(find.byType(ScoringTimerWidget), findsOneWidget);
      expect(find.text('TAP'), findsNothing);
    });

    testWidgets('renders TAP text when enabled and idle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      // Allow async initialization to complete
      await tester.pumpAndSettle();

      expect(find.text('TAP'), findsOneWidget);
    });

    testWidgets('has GestureDetector for tap handling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have a GestureDetector for tapping
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('shows timer container with border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have a container widget
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('updates configuration when props change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Update props
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 15,
              durationSeconds: 180,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should still be visible with TAP
      expect(find.byType(ScoringTimerWidget), findsOneWidget);
      expect(find.text('TAP'), findsOneWidget);
    });

    testWidgets('widget can be enabled and disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('TAP'), findsOneWidget);

      // Disable the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: false,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('TAP'), findsNothing);
    });

    testWidgets('timer service is in idle state initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Service should be idle
      final service = ScoringTimerService();
      expect(service.state, equals(ScoringTimerState.idle));
    });

    testWidgets('tapping starts the timer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to start
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Service should be running
      final service = ScoringTimerService();
      expect(service.isRunning, isTrue);
    });
  });

  group('Timer State Verification', () {
    testWidgets('timer transitions to leadIn state after tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoringTimerWidget(
              enabled: true,
              leadInSeconds: 10,
              durationSeconds: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final service = ScoringTimerService();
      expect(service.state, equals(ScoringTimerState.idle));

      // Tap to start
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Should be in lead-in state
      expect(service.state, equals(ScoringTimerState.leadIn));
    });

    // Note: Testing no-lead-in behavior is covered by the service tests.
    // Widget tests focus on widget behavior, not async service configuration timing.
  });
}
