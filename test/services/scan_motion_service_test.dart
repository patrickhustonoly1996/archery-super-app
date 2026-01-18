import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/services/scan_motion_service.dart';

void main() {
  group('SimulatedScanMotionService', () {
    late SimulatedScanMotionService service;

    setUp(() {
      service = SimulatedScanMotionService();
    });

    tearDown(() {
      service.dispose();
    });

    test('starts with zero progress', () {
      expect(service.progress, equals(0.0));
      expect(service.isMoving, isFalse);
    });

    test('reports progress updates during simulated scan', () async {
      final progressUpdates = <double>[];

      service.onProgressUpdate = (progress, velocity) {
        progressUpdates.add(progress);
      };

      await service.startTracking();

      // Wait for some simulated progress
      await Future.delayed(const Duration(milliseconds: 300));

      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.last, greaterThan(0.0));

      service.stopTracking();
    });

    test('calls onScanComplete when full rotation achieved', () async {
      final completer = Completer<void>();

      service.onScanComplete = () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      };

      await service.startTracking();

      // Wait for completion (simulated scan takes ~2.5 seconds)
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('Scan did not complete in time'),
      );

      expect(service.progress, equals(1.0));
    });

    test('stopTracking halts progress', () async {
      await service.startTracking();

      // Wait briefly
      await Future.delayed(const Duration(milliseconds: 200));
      service.stopTracking();

      final progressAtStop = service.progress;

      // Wait more and verify no change
      await Future.delayed(const Duration(milliseconds: 200));

      // Progress shouldn't change after stopping
      expect(service.progress, equals(progressAtStop));
    });
  });

  group('ScanMotionService constants', () {
    test('full rotation is 2π radians', () {
      expect(ScanMotionService.kFullRotation, closeTo(6.283, 0.001));
    });

    test('min angular velocity is reasonable threshold', () {
      expect(ScanMotionService.kMinAngularVelocity, greaterThan(0));
      expect(ScanMotionService.kMinAngularVelocity, lessThan(1.0));
    });

    test('max angular velocity is reasonable for warnings', () {
      expect(ScanMotionService.kMaxAngularVelocity, greaterThan(1.0));
      expect(ScanMotionService.kMaxAngularVelocity, lessThan(5.0));
    });
  });
}
