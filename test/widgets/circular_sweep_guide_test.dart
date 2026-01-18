import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/widgets/circular_sweep_guide.dart';

void main() {
  group('CircularSweepGuide', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CircularSweepGuide(
                  progress: 0.0,
                  isScanning: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularSweepGuide), findsOneWidget);
    });

    testWidgets('renders with progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CircularSweepGuide(
                  progress: 0.5,
                  isScanning: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularSweepGuide), findsOneWidget);
    });

    testWidgets('renders in complete state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CircularSweepGuide(
                  progress: 1.0,
                  isScanning: false,
                  isComplete: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularSweepGuide), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: CircularSweepGuide(
                  progress: 0.0,
                  isScanning: false,
                  size: 200,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularSweepGuide), findsOneWidget);
    });
  });

  group('ScanInstructionOverlay', () {
    testWidgets('shows TAP TO START when idle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScanInstructionOverlay(
              isScanning: false,
              isComplete: false,
              progress: 0.0,
              framesCollected: 0,
            ),
          ),
        ),
      );

      expect(find.text('TAP TO START SCAN'), findsOneWidget);
    });

    testWidgets('shows progress when scanning', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScanInstructionOverlay(
              isScanning: true,
              isComplete: false,
              progress: 0.5,
              framesCollected: 5,
            ),
          ),
        ),
      );

      expect(find.text('Keep moving slowly...'), findsOneWidget);
      expect(find.text('50% · 5 frames'), findsOneWidget);
    });

    testWidgets('shows SCAN COMPLETE when done', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScanInstructionOverlay(
              isScanning: false,
              isComplete: true,
              progress: 1.0,
              framesCollected: 8,
            ),
          ),
        ),
      );

      expect(find.text('SCAN COMPLETE'), findsOneWidget);
    });
  });
}
