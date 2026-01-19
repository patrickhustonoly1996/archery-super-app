/// Tests for TrainingSessionService
///
/// These tests verify the training session service's wake lock management
/// and session state tracking.
///
/// The service is a singleton that:
/// - Tracks whether a training session is active
/// - Manages device wake lock (keeps screen on during training)
/// - Handles platform exceptions gracefully for tests/unsupported platforms
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/training_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrainingSessionService', () {
    late TrainingSessionService service;

    setUp(() {
      service = TrainingSessionService();
      // Reset state by ending any active session
      // Since it's a singleton, we need to clean up between tests
    });

    tearDown(() async {
      // Ensure session is ended after each test
      await service.endSession();
    });

    group('singleton pattern', () {
      test('factory constructor returns same instance', () {
        final instance1 = TrainingSessionService();
        final instance2 = TrainingSessionService();

        expect(identical(instance1, instance2), isTrue);
      });

      test('multiple calls return identical instance', () {
        final instances = List.generate(5, (_) => TrainingSessionService());

        for (int i = 1; i < instances.length; i++) {
          expect(identical(instances[0], instances[i]), isTrue);
        }
      });
    });

    group('isSessionActive', () {
      test('starts as false when no session active', () async {
        // Ensure clean state
        await service.endSession();

        expect(service.isSessionActive, isFalse);
      });

      test('returns true after startSession()', () async {
        await service.endSession(); // Clean state
        await service.startSession();

        expect(service.isSessionActive, isTrue);
      });

      test('returns false after endSession()', () async {
        await service.startSession();
        await service.endSession();

        expect(service.isSessionActive, isFalse);
      });

      test('reflects current session state accurately', () async {
        await service.endSession(); // Start clean

        expect(service.isSessionActive, isFalse);

        await service.startSession();
        expect(service.isSessionActive, isTrue);

        await service.endSession();
        expect(service.isSessionActive, isFalse);

        await service.startSession();
        expect(service.isSessionActive, isTrue);
      });
    });

    group('startSession()', () {
      test('activates session when not active', () async {
        await service.endSession(); // Clean state
        expect(service.isSessionActive, isFalse);

        await service.startSession();

        expect(service.isSessionActive, isTrue);
      });

      test('is idempotent - second call does nothing when already active', () async {
        await service.endSession();
        await service.startSession();
        expect(service.isSessionActive, isTrue);

        // Call again while active
        await service.startSession();

        // Still active, no error
        expect(service.isSessionActive, isTrue);
      });

      test('can be called multiple times safely', () async {
        await service.endSession();

        // Multiple rapid calls should not throw
        await service.startSession();
        await service.startSession();
        await service.startSession();

        expect(service.isSessionActive, isTrue);
      });

      test('completes without error', () async {
        await service.endSession();

        // Should not throw
        expect(() => service.startSession(), returnsNormally);
      });

      test('handles wake lock platform exception gracefully', () async {
        // The service catches PlatformException internally
        // This test verifies the service handles it without propagating errors
        await service.endSession();

        // In test environment, WakelockPlus may throw PlatformException
        // Service should handle this gracefully
        await expectLater(service.startSession(), completes);
        expect(service.isSessionActive, isTrue);
      });
    });

    group('endSession()', () {
      test('deactivates session when active', () async {
        await service.startSession();
        expect(service.isSessionActive, isTrue);

        await service.endSession();

        expect(service.isSessionActive, isFalse);
      });

      test('is idempotent - second call does nothing when already inactive', () async {
        await service.endSession(); // Ensure inactive
        expect(service.isSessionActive, isFalse);

        // Call again while inactive
        await service.endSession();

        // Still inactive, no error
        expect(service.isSessionActive, isFalse);
      });

      test('can be called multiple times safely', () async {
        await service.startSession();
        await service.endSession();

        // Multiple rapid calls should not throw
        await service.endSession();
        await service.endSession();
        await service.endSession();

        expect(service.isSessionActive, isFalse);
      });

      test('completes without error', () async {
        await service.startSession();

        // Should not throw
        expect(() => service.endSession(), returnsNormally);
      });

      test('handles wake lock platform exception gracefully', () async {
        await service.startSession();

        // In test environment, WakelockPlus may throw PlatformException
        // Service should handle this gracefully
        await expectLater(service.endSession(), completes);
        expect(service.isSessionActive, isFalse);
      });
    });

    group('session lifecycle', () {
      test('full session lifecycle works correctly', () async {
        await service.endSession(); // Clean state

        // 1. Start fresh - no session
        expect(service.isSessionActive, isFalse);

        // 2. Start session
        await service.startSession();
        expect(service.isSessionActive, isTrue);

        // 3. End session
        await service.endSession();
        expect(service.isSessionActive, isFalse);
      });

      test('multiple session cycles work correctly', () async {
        await service.endSession(); // Clean state

        for (int i = 0; i < 3; i++) {
          expect(service.isSessionActive, isFalse,
              reason: 'Cycle $i: Should start inactive');

          await service.startSession();
          expect(service.isSessionActive, isTrue,
              reason: 'Cycle $i: Should be active after start');

          await service.endSession();
          expect(service.isSessionActive, isFalse,
              reason: 'Cycle $i: Should be inactive after end');
        }
      });

      test('rapid start/end cycles do not corrupt state', () async {
        await service.endSession(); // Clean state

        // Rapid toggling
        for (int i = 0; i < 10; i++) {
          await service.startSession();
          await service.endSession();
        }

        expect(service.isSessionActive, isFalse);
      });

      test('starting immediately after ending works', () async {
        await service.endSession();
        await service.startSession();
        await service.endSession();
        await service.startSession();

        expect(service.isSessionActive, isTrue);
      });
    });

    group('state consistency', () {
      test('state remains consistent under normal use', () async {
        await service.endSession();

        await service.startSession();
        final stateAfterStart = service.isSessionActive;

        await service.endSession();
        final stateAfterEnd = service.isSessionActive;

        expect(stateAfterStart, isTrue);
        expect(stateAfterEnd, isFalse);
      });

      test('getter returns boolean value', () async {
        // Type check - isSessionActive should always be a bool
        expect(service.isSessionActive, isA<bool>());

        await service.startSession();
        expect(service.isSessionActive, isA<bool>());

        await service.endSession();
        expect(service.isSessionActive, isA<bool>());
      });
    });

    group('edge cases', () {
      test('calling endSession before any startSession works', () async {
        // Fresh service (though singleton may have state from other tests)
        // Calling endSession when already inactive should be safe
        await service.endSession();
        await service.endSession();

        expect(service.isSessionActive, isFalse);
      });

      test('handles start-start-end-end sequence', () async {
        await service.endSession(); // Clean

        await service.startSession();
        await service.startSession(); // No-op, already active
        expect(service.isSessionActive, isTrue);

        await service.endSession();
        await service.endSession(); // No-op, already inactive
        expect(service.isSessionActive, isFalse);
      });

      test('interleaved operations maintain correct state', () async {
        await service.endSession(); // Clean

        // Complex sequence
        await service.startSession(); // active
        expect(service.isSessionActive, isTrue);

        await service.startSession(); // still active (idempotent)
        expect(service.isSessionActive, isTrue);

        await service.endSession(); // inactive
        expect(service.isSessionActive, isFalse);

        await service.endSession(); // still inactive (idempotent)
        expect(service.isSessionActive, isFalse);

        await service.startSession(); // active again
        expect(service.isSessionActive, isTrue);
      });
    });

    group('async behavior', () {
      test('startSession returns Future<void>', () async {
        await service.endSession();
        final result = service.startSession();

        expect(result, isA<Future<void>>());
        await result;
      });

      test('endSession returns Future<void>', () async {
        await service.startSession();
        final result = service.endSession();

        expect(result, isA<Future<void>>());
        await result;
      });

      test('operations can be awaited sequentially', () async {
        await service.endSession();

        await service.startSession();
        expect(service.isSessionActive, isTrue);

        await service.endSession();
        expect(service.isSessionActive, isFalse);
      });

      test('concurrent start calls do not cause issues', () async {
        await service.endSession();

        // Fire multiple starts without awaiting individually
        final futures = [
          service.startSession(),
          service.startSession(),
          service.startSession(),
        ];

        await Future.wait(futures);

        // Session should be active (first one won, others were no-ops)
        expect(service.isSessionActive, isTrue);
      });

      test('concurrent end calls do not cause issues', () async {
        await service.startSession();

        // Fire multiple ends without awaiting individually
        final futures = [
          service.endSession(),
          service.endSession(),
          service.endSession(),
        ];

        await Future.wait(futures);

        // Session should be inactive (first one won, others were no-ops)
        expect(service.isSessionActive, isFalse);
      });
    });

    group('real-world scenarios', () {
      test('archer starts training, completes session', () async {
        await service.endSession(); // Ensure clean state

        // Archer opens training screen
        expect(service.isSessionActive, isFalse);

        // Archer starts bow training
        await service.startSession();
        expect(service.isSessionActive, isTrue);

        // Archer completes training
        await service.endSession();
        expect(service.isSessionActive, isFalse);
      });

      test('archer starts training, phone call interrupts, resumes', () async {
        await service.endSession();

        // Start training
        await service.startSession();
        expect(service.isSessionActive, isTrue);

        // Phone call interrupts - app lifecycle may call endSession
        await service.endSession();
        expect(service.isSessionActive, isFalse);

        // Archer returns, starts new session
        await service.startSession();
        expect(service.isSessionActive, isTrue);

        // Complete the new session
        await service.endSession();
        expect(service.isSessionActive, isFalse);
      });

      test('multiple training types in one app session', () async {
        await service.endSession();

        // Bow training session
        await service.startSession();
        expect(service.isSessionActive, isTrue);
        await service.endSession();
        expect(service.isSessionActive, isFalse);

        // Breath training session
        await service.startSession();
        expect(service.isSessionActive, isTrue);
        await service.endSession();
        expect(service.isSessionActive, isFalse);

        // Another scoring session
        await service.startSession();
        expect(service.isSessionActive, isTrue);
        await service.endSession();
        expect(service.isSessionActive, isFalse);
      });

      test('screen disposed while session active (cleanup)', () async {
        await service.endSession();

        // User starts training
        await service.startSession();
        expect(service.isSessionActive, isTrue);

        // Screen is disposed (user navigates away)
        // dispose() calls endSession()
        await service.endSession();
        expect(service.isSessionActive, isFalse);
      });

      test('duplicate startSession calls from rapid UI taps', () async {
        await service.endSession();

        // User taps start button multiple times rapidly
        await service.startSession();
        await service.startSession();
        await service.startSession();

        expect(service.isSessionActive, isTrue);

        // Only one endSession needed to deactivate
        await service.endSession();
        expect(service.isSessionActive, isFalse);
      });
    });

    group('wake lock purpose', () {
      test('session keeps screen awake for training visibility', () async {
        // This test documents the purpose: during archery training,
        // the screen should stay on so the archer can see timers,
        // breathing guides, and session information without
        // needing to touch the screen.
        await service.endSession();

        // When session starts, wake lock is enabled (screen stays on)
        await service.startSession();
        expect(service.isSessionActive, isTrue);

        // When session ends, wake lock is disabled (normal screen timeout resumes)
        await service.endSession();
        expect(service.isSessionActive, isFalse);
      });
    });
  });
}
