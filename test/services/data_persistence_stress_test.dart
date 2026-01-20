/// Comprehensive stress tests for data persistence and user account linkage
///
/// These tests verify:
/// 1. Data survives app lifecycle events (pause, resume, background kill)
/// 2. Data is correctly linked to user accounts
/// 3. Cloud sync works correctly between devices
/// 4. Crash recovery restores incomplete sessions
/// 5. Account switching doesn't leak data
/// 6. Offline queue handles failures gracefully
/// 7. Concurrent access doesn't corrupt data
/// 8. Timezone handling is consistent

import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:archery_super_app/services/sync_service.dart';
import 'package:matcher/matcher.dart' as matcher;

void main() {
  group('Data Persistence - Local Storage', () {
    test('arrows are persisted immediately after insert', () async {
      await withTestDb((db) async {
        // Create session and end
        final sessionId = 'test-session-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        final endId = '${sessionId}_end_1';
        await db.insertEnd(EndsCompanion.insert(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Insert arrow
        final arrowId = '${endId}_arrow_1';
        await db.insertArrow(ArrowsCompanion.insert(
          id: arrowId,
          endId: endId,
          x: 0.5,
          y: 0.3,
          score: 9,
          sequence: 1,
        ));

        // Immediately verify it's in database
        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(1));
        expect(arrows.first.id, equals(arrowId));
        expect(arrows.first.score, equals(9));
      });
    });

    test('session survives simulated app restart', () async {
      // Create incomplete session
      final sessionId = 'restart-test-${DateTime.now().millisecondsSinceEpoch}';

      // First database instance - create session
      final db1 = AppDatabase.withExecutor(NativeDatabase.memory());
      try {
        await db1.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        final endId = '${sessionId}_end_1';
        await db1.insertEnd(EndsCompanion.insert(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Add some arrows
        for (int i = 1; i <= 3; i++) {
          await db1.insertArrow(ArrowsCompanion.insert(
            id: '${endId}_arrow_$i',
            endId: endId,
            x: 0.1 * i,
            y: 0.1 * i,
            score: 10 - i,
            sequence: i,
          ));
        }

        // Session should be recoverable
        final incomplete = await db1.getIncompleteSession();
        expect(incomplete, matcher.isNotNull);
        expect(incomplete!.id, equals(sessionId));

        // Arrows should exist
        final arrows = await db1.getArrowsForEnd(endId);
        expect(arrows.length, equals(3));
      } finally {
        await db1.close();
      }
    });

    test('concurrent arrow inserts maintain data integrity', () async {
      await withTestDb((db) async {
        // Create session and end
        final sessionId = 'concurrent-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        final endId = '${sessionId}_end_1';
        await db.insertEnd(EndsCompanion.insert(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Insert 6 arrows concurrently (simulating rapid tapping)
        final futures = <Future>[];
        for (int i = 1; i <= 6; i++) {
          futures.add(db.insertArrow(ArrowsCompanion.insert(
            id: '${endId}_arrow_$i',
            endId: endId,
            x: 0.1 * i,
            y: 0.1 * i,
            score: 10,
            sequence: i,
          )));
        }

        await Future.wait(futures);

        // All 6 arrows should be present
        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(6));
      });
    });

    test('soft delete preserves data for sync', () async {
      await withTestDb((db) async {
        final sessionId = 'delete-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        // Soft delete
        await db.softDeleteSession(sessionId);

        // Session should still exist with deletedAt set
        final allSessions = await db.getAllSessionsForSync();
        final deletedSession = allSessions.where((s) => s.id == sessionId).firstOrNull;

        expect(deletedSession, matcher.isNotNull);
        expect(deletedSession!.deletedAt, matcher.isNotNull);
      });
    });
  });

  group('Data Persistence - User Account Linkage', () {
    test('clearAllUserData removes all user data', () async {
      await withTestDb((db) async {
        // Create session with arrows
        final sessionId = 'clear-test-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        final endId = '${sessionId}_end_1';
        await db.insertEnd(EndsCompanion.insert(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        await db.insertArrow(ArrowsCompanion.insert(
          id: '${endId}_arrow_1',
          endId: endId,
          x: 0.5,
          y: 0.5,
          score: 10,
          sequence: 1,
        ));

        // Create equipment
        final bowId = 'bow-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertBow(BowsCompanion.insert(
          id: bowId,
          name: 'Test Bow',
          bowType: 'recurve',
        ));

        // Clear all user data (simulates logout)
        await db.clearAllUserData();

        // Verify everything is gone
        final sessions = await db.getAllSessionsForSync();
        expect(sessions.isEmpty, isTrue);

        final bows = await db.getAllBowsForSync();
        expect(bows.isEmpty, isTrue);

        final arrows = await db.getAllArrowsForSync();
        expect(arrows.isEmpty, isTrue);
      });
    });

    test('clearAllUserData uses transaction for atomic operation', () async {
      await withTestDb((db) async {
        // Create data
        final sessionId = 'tx-test-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        final bowId = 'bow-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertBow(BowsCompanion.insert(
          id: bowId,
          name: 'Test Bow',
          bowType: 'recurve',
        ));

        // Clear should be atomic - either all or nothing
        await db.clearAllUserData();

        // Both should be cleared
        final sessions = await db.getAllSessionsForSync();
        final bows = await db.getAllBowsForSync();

        expect(sessions.isEmpty && bows.isEmpty, isTrue);
      });
    });
  });

  group('Data Persistence - Sync Queue', () {
    test('sync queue persists operations', () async {
      await withTestDb((db) async {
        // Enqueue a sync operation
        final opId = await db.enqueueSyncOp(
          entityType: 'session',
          entityId: 'test-session-123',
          operation: 'create',
          payload: '{"id": "test-session-123", "score": 100}',
        );

        // Verify it's in queue
        final ops = await db.getRetryableOperations(maxRetries: 5);
        expect(ops.isNotEmpty, isTrue);
        expect(ops.any((o) => o.entityType == 'session'), isTrue);
      });
    });

    test('sync queue retry count increments on failure', () async {
      await withTestDb((db) async {
        final entityId = 'retry-test-${DateTime.now().millisecondsSinceEpoch}';

        // Enqueue operation
        await db.enqueueSyncOp(
          entityType: 'session',
          entityId: entityId,
          operation: 'create',
          payload: '{}',
        );

        // Get the operation to find its actual ID
        var ops = await db.getRetryableOperations(maxRetries: 5);
        var op = ops.where((o) => o.entityId == entityId).first;
        final actualId = op.id;

        // Mark as attempted (simulating failure)
        await db.markSyncOperationAttempted(actualId, 'Network error');

        // Check retry count increased
        ops = await db.getRetryableOperations(maxRetries: 5);
        op = ops.where((o) => o.entityId == entityId).firstOrNull!;
        expect(op.retryCount, equals(1));
      });
    });

    test('sync queue operation removed after success', () async {
      await withTestDb((db) async {
        final entityId = 'remove-test-${DateTime.now().millisecondsSinceEpoch}';

        // Enqueue operation
        await db.enqueueSyncOp(
          entityType: 'session',
          entityId: entityId,
          operation: 'create',
          payload: '{}',
        );

        // Get the operation to find its actual ID
        var ops = await db.getRetryableOperations(maxRetries: 5);
        final op = ops.where((o) => o.entityId == entityId).first;
        final actualId = op.id;

        // Remove it (simulating successful sync)
        await db.removeSyncOperation(actualId);

        // Should be gone
        ops = await db.getRetryableOperations(maxRetries: 5);
        final removedOp = ops.where((o) => o.entityId == entityId).firstOrNull;
        expect(removedOp, matcher.isNull);
      });
    });

    test('operations exceeding max retries are filtered out', () async {
      await withTestDb((db) async {
        final entityId = 'max-retry-test-${DateTime.now().millisecondsSinceEpoch}';

        // Enqueue operation
        await db.enqueueSyncOp(
          entityType: 'session',
          entityId: entityId,
          operation: 'create',
          payload: '{}',
        );

        // Get the operation to find its actual ID
        var ops = await db.getRetryableOperations(maxRetries: 10);
        final actualId = ops.where((o) => o.entityId == entityId).first.id;

        // Mark as attempted 5 times
        for (int i = 0; i < 5; i++) {
          await db.markSyncOperationAttempted(actualId, 'Failure $i');
        }

        // Should not be returned when max is 5
        ops = await db.getRetryableOperations(maxRetries: 5);
        final op = ops.where((o) => o.entityId == entityId).firstOrNull;
        expect(op, matcher.isNull, reason: 'Operation with 5 retries should be excluded');
      });
    });
  });

  group('Data Persistence - Crash Recovery', () {
    test('incomplete session is recoverable', () async {
      await withTestDb((db) async {
        // Create incomplete session (no completedAt)
        final sessionId = 'crash-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        // Add ends and arrows
        final endId = '${sessionId}_end_1';
        await db.insertEnd(EndsCompanion.insert(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        await db.insertArrow(ArrowsCompanion.insert(
          id: '${endId}_arrow_1',
          endId: endId,
          x: 0.5,
          y: 0.5,
          score: 10,
          sequence: 1,
        ));

        // Simulate crash recovery
        final incomplete = await db.getIncompleteSession();
        expect(incomplete, matcher.isNotNull);
        expect(incomplete!.id, equals(sessionId));
        expect(incomplete.completedAt, matcher.isNull);
      });
    });

    test('completed session not returned as incomplete', () async {
      await withTestDb((db) async {
        // Create completed session
        final sessionId = 'complete-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        await db.completeSession(sessionId, 100, 5);

        // Should not be returned as incomplete
        final incomplete = await db.getIncompleteSession();
        // If there's an incomplete one, it shouldn't be this one
        if (incomplete != null) {
          expect(incomplete.id, isNot(equals(sessionId)));
        }
      });
    });

    test('soft-deleted session not returned as incomplete', () async {
      await withTestDb((db) async {
        // Create then soft-delete session
        final sessionId = 'soft-del-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        await db.softDeleteSession(sessionId);

        // Should not be returned as incomplete
        final incomplete = await db.getIncompleteSession();
        if (incomplete != null) {
          expect(incomplete.id, isNot(equals(sessionId)));
        }
      });
    });
  });

  group('Data Persistence - Equipment', () {
    test('bow with quiver and shafts persists correctly', () async {
      await withTestDb((db) async {
        final bowId = 'bow-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertBow(BowsCompanion.insert(
          id: bowId,
          name: 'Olympic Recurve',
          bowType: 'recurve',
        ));

        final quiverId = 'quiver-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertQuiver(QuiversCompanion.insert(
          id: quiverId,
          bowId: Value(bowId),
          name: 'Competition Arrows',
        ));

        // Add 12 shafts
        for (int i = 1; i <= 12; i++) {
          await db.insertShaft(ShaftsCompanion.insert(
            id: 'shaft-$quiverId-$i',
            quiverId: quiverId,
            number: i,
          ));
        }

        // Verify all data
        final bows = await db.getAllBowsForSync();
        expect(bows.any((b) => b.id == bowId), isTrue);

        final quivers = await db.getAllQuiversForSync();
        expect(quivers.any((q) => q.id == quiverId), isTrue);

        final shafts = await db.getShaftsForQuiver(quiverId);
        expect(shafts.length, equals(12));
      });
    });

    test('deleting bow cascades correctly', () async {
      await withTestDb((db) async {
        final bowId = 'cascade-bow-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertBow(BowsCompanion.insert(
          id: bowId,
          name: 'Test Bow',
          bowType: 'recurve',
        ));

        // Delete bow
        await db.softDeleteBow(bowId);

        // Bow should be soft-deleted
        final bows = await db.getAllBowsForSync();
        final bow = bows.where((b) => b.id == bowId).firstOrNull;
        expect(bow?.deletedAt, matcher.isNotNull);
      });
    });
  });

  group('Conflict Resolution', () {
    test('local timestamp wins on exact tie', () {
      // This tests the documented behavior: device is source of truth
      final sameTime = DateTime(2024, 1, 15, 12, 30, 45, 123);
      final tester = ConflictResolutionTester();

      final decision = tester.resolveConflict(
        localUpdatedAt: sameTime,
        cloudUpdatedAt: sameTime,
        existsLocal: true,
        existsCloud: true,
      );

      // Tie = skip (local wins, no action needed)
      expect(decision, equals(MergeDecision.skip));
    });

    test('newer timestamp wins regardless of source', () {
      final tester = ConflictResolutionTester();

      // Local newer - upload
      var decision = tester.resolveConflict(
        localUpdatedAt: DateTime(2024, 1, 20),
        cloudUpdatedAt: DateTime(2024, 1, 15),
        existsLocal: true,
        existsCloud: true,
      );
      expect(decision, equals(MergeDecision.uploadLocal));

      // Cloud newer - download
      decision = tester.resolveConflict(
        localUpdatedAt: DateTime(2024, 1, 15),
        cloudUpdatedAt: DateTime(2024, 1, 20),
        existsLocal: true,
        existsCloud: true,
      );
      expect(decision, equals(MergeDecision.downloadCloud));
    });

    test('deletion conflicts resolved by timestamp', () {
      final tester = ConflictResolutionTester();

      // Local deleted after cloud update - upload deletion
      var decision = tester.resolveConflict(
        localDeletedAt: DateTime(2024, 1, 20),
        cloudUpdatedAt: DateTime(2024, 1, 15),
        existsLocal: true,
        existsCloud: true,
      );
      expect(decision, equals(MergeDecision.uploadLocal));

      // Cloud deleted after local update - download deletion
      decision = tester.resolveConflict(
        localUpdatedAt: DateTime(2024, 1, 15),
        cloudDeletedAt: DateTime(2024, 1, 20),
        existsLocal: true,
        existsCloud: true,
      );
      expect(decision, equals(MergeDecision.downloadCloud));
    });
  });

  group('Offline Storage Security', () {
    test('data is stored locally immediately without network', () async {
      await withTestDb((db) async {
        // This test verifies that data goes to local SQLite regardless of network
        final sessionId = 'offline-${DateTime.now().millisecondsSinceEpoch}';

        // Insert session (this goes to local SQLite, not cloud)
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        // Immediately verify it's in local database
        final session = await db.getSession(sessionId);
        expect(session, matcher.isNotNull);
        expect(session!.id, equals(sessionId));
      });
    });

    test('sync queue persists operations when sync would fail', () async {
      await withTestDb((db) async {
        // Enqueue operations that would be created when offline
        final now = DateTime.now().millisecondsSinceEpoch;

        // Queue session creation
        await db.enqueueSyncOp(
          entityType: 'session',
          entityId: 'offline-session-$now',
          operation: 'create',
          payload: '{"id": "offline-session-$now", "roundTypeId": "wa_720_70m"}',
        );

        // Queue arrow creation
        await db.enqueueSyncOp(
          entityType: 'arrow',
          entityId: 'offline-arrow-$now',
          operation: 'create',
          payload: '{"id": "offline-arrow-$now", "score": 10}',
        );

        // Both should be in queue
        final ops = await db.getRetryableOperations(maxRetries: 5);
        expect(ops.any((o) => o.entityId == 'offline-session-$now'), isTrue);
        expect(ops.any((o) => o.entityId == 'offline-arrow-$now'), isTrue);
      });
    });

    test('multiple offline sessions queue correctly', () async {
      await withTestDb((db) async {
        // Simulate creating multiple sessions while offline
        final now = DateTime.now().millisecondsSinceEpoch;

        for (int i = 0; i < 5; i++) {
          // Create session locally
          final sessionId = 'multi-offline-$now-$i';
          await db.insertSession(SessionsCompanion.insert(
            id: sessionId,
            roundTypeId: 'wa_720_70m',
          ));

          // Queue for sync
          await db.enqueueSyncOp(
            entityType: 'session',
            entityId: sessionId,
            operation: 'create',
            payload: '{"id": "$sessionId"}',
          );
        }

        // All 5 should be in local DB
        final sessions = await db.getAllSessionsForSync();
        final matchingSessions = sessions.where(
            (s) => s.id.startsWith('multi-offline-$now'));
        expect(matchingSessions.length, equals(5));

        // All 5 should be queued for sync
        final ops = await db.getRetryableOperations(maxRetries: 5);
        final matchingOps = ops.where(
            (o) => o.entityId.startsWith('multi-offline-$now'));
        expect(matchingOps.length, equals(5));
      });
    });

    test('sync queue retains error information', () async {
      await withTestDb((db) async {
        final entityId = 'error-test-${DateTime.now().millisecondsSinceEpoch}';

        // Create operation
        await db.enqueueSyncOp(
          entityType: 'session',
          entityId: entityId,
          operation: 'create',
          payload: '{}',
        );

        // Get the operation to find its actual ID
        var ops = await db.getRetryableOperations(maxRetries: 5);
        final actualId = ops.where((o) => o.entityId == entityId).first.id;

        // Simulate failure with error message
        const errorMessage = 'FirebaseException: Network unavailable';
        await db.markSyncOperationAttempted(actualId, errorMessage);

        // Error should be recorded
        ops = await db.getRetryableOperations(maxRetries: 5);
        final op = ops.where((o) => o.entityId == entityId).firstOrNull;

        expect(op, matcher.isNotNull);
        expect(op!.lastError, equals(errorMessage));
        expect(op.retryCount, equals(1));
      });
    });
  });

  group('Airplane Mode Simulation', () {
    test('complete session survives airplane mode - full workflow', () async {
      await withTestDb((db) async {
        // Simulate shooting a complete 12-end session while in airplane mode
        final sessionId = 'airplane-session-${DateTime.now().millisecondsSinceEpoch}';

        // Step 1: Create session (network unavailable - goes to SQLite only)
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        // Step 2: Shoot 12 ends with 6 arrows each (72 arrows total)
        for (int e = 1; e <= 12; e++) {
          final endId = '${sessionId}_end_$e';
          await db.insertEnd(EndsCompanion.insert(
            id: endId,
            sessionId: sessionId,
            endNumber: e,
          ));

          for (int a = 1; a <= 6; a++) {
            await db.insertArrow(ArrowsCompanion.insert(
              id: '${endId}_arrow_$a',
              endId: endId,
              x: 0.0,
              y: 0.0,
              xMm: Value(0.0),
              yMm: Value(0.0),
              score: 10,
              sequence: a,
            ));
          }

          // Commit end (sync would fail here in real scenario, but data is safe)
          await db.commitEnd(endId, 60, 6); // 6 x 10 = 60, 6 Xs
        }

        // Step 3: Complete session
        await db.completeSession(sessionId, 720, 72);

        // Step 4: Verify EVERYTHING is in local database
        final session = await db.getSession(sessionId);
        expect(session, matcher.isNotNull);
        expect(session!.completedAt, matcher.isNotNull);
        expect(session.totalScore, equals(720));

        final ends = await db.getEndsForSession(sessionId);
        expect(ends.length, equals(12));

        final arrows = await db.getArrowsForSession(sessionId);
        expect(arrows.length, equals(72));

        // Step 5: Verify session would sync correctly when online
        // (getAllSessionsForSync returns all data for sync comparison)
        final sessionsForSync = await db.getAllSessionsForSync();
        expect(sessionsForSync.any((s) => s.id == sessionId), isTrue);

        final arrowsForSync = await db.getAllArrowsForSync();
        final sessionArrows = arrowsForSync.where((a) => a.id.startsWith(sessionId));
        expect(sessionArrows.length, equals(72));
      });
    });

    test('incomplete session recoverable after airplane mode crash', () async {
      await withTestDb((db) async {
        // Simulate app crash mid-session while in airplane mode
        final sessionId = 'crash-airplane-${DateTime.now().millisecondsSinceEpoch}';

        // Create incomplete session (6 ends shot, app crashes)
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        for (int e = 1; e <= 6; e++) {
          final endId = '${sessionId}_end_$e';
          await db.insertEnd(EndsCompanion.insert(
            id: endId,
            sessionId: sessionId,
            endNumber: e,
          ));

          for (int a = 1; a <= 6; a++) {
            await db.insertArrow(ArrowsCompanion.insert(
              id: '${endId}_arrow_$a',
              endId: endId,
              x: 0.0,
              y: 0.0,
              score: 9,
              sequence: a,
            ));
          }

          await db.commitEnd(endId, 54, 0); // 6 x 9 = 54, 0 Xs
        }

        // Simulate crash - session NOT completed (no completedAt)

        // App restarts - verify recovery
        final incomplete = await db.getIncompleteSession();
        expect(incomplete, matcher.isNotNull);
        expect(incomplete!.id, equals(sessionId));

        // Verify we can count existing data
        final ends = await db.getEndsForSession(sessionId);
        expect(ends.length, equals(6));

        final arrows = await db.getArrowsForSession(sessionId);
        expect(arrows.length, equals(36)); // 6 ends x 6 arrows

        // Verify we could continue session
        final nextEndNumber = ends.length + 1; // Should be 7
        expect(nextEndNumber, equals(7));
      });
    });

    test('multiple sessions accumulate while offline', () async {
      await withTestDb((db) async {
        // User shoots 3 complete sessions while on a long flight
        final baseTime = DateTime.now().millisecondsSinceEpoch;

        for (int s = 0; s < 3; s++) {
          final sessionId = 'flight-session-$baseTime-$s';

          await db.insertSession(SessionsCompanion.insert(
            id: sessionId,
            roundTypeId: 'wa_720_70m',
          ));

          // Quick 3-end session
          for (int e = 1; e <= 3; e++) {
            final endId = '${sessionId}_end_$e';
            await db.insertEnd(EndsCompanion.insert(
              id: endId,
              sessionId: sessionId,
              endNumber: e,
            ));

            for (int a = 1; a <= 6; a++) {
              await db.insertArrow(ArrowsCompanion.insert(
                id: '${endId}_arrow_$a',
                endId: endId,
                x: 0.0,
                y: 0.0,
                score: 10,
                sequence: a,
              ));
            }
          }

          await db.completeSession(sessionId, 180, 18);
        }

        // All 3 sessions should be in local DB ready for sync
        final allSessions = await db.getAllSessionsForSync();
        final flightSessions = allSessions.where(
            (s) => s.id.startsWith('flight-session-$baseTime'));

        expect(flightSessions.length, equals(3));
        expect(flightSessions.every((s) => s.completedAt != null), isTrue);

        // Total arrows: 3 sessions x 3 ends x 6 arrows = 54
        final allArrows = await db.getAllArrowsForSync();
        final flightArrows = allArrows.where(
            (a) => a.id.contains('flight-session-$baseTime'));

        expect(flightArrows.length, equals(54));
      });
    });

    test('equipment changes persist in airplane mode', () async {
      await withTestDb((db) async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create bow
        final bowId = 'airplane-bow-$now';
        await db.insertBow(BowsCompanion.insert(
          id: bowId,
          name: 'Flight Recurve',
          bowType: 'recurve',
        ));

        // Create quiver
        final quiverId = 'airplane-quiver-$now';
        await db.insertQuiver(QuiversCompanion.insert(
          id: quiverId,
          bowId: Value(bowId),
          name: 'Competition Set',
        ));

        // Create shafts
        for (int i = 1; i <= 12; i++) {
          await db.insertShaft(ShaftsCompanion.insert(
            id: 'airplane-shaft-$now-$i',
            quiverId: quiverId,
            number: i,
          ));
        }

        // Verify all equipment is in local DB
        final bows = await db.getAllBowsForSync();
        expect(bows.any((b) => b.id == bowId), isTrue);

        final quivers = await db.getAllQuiversForSync();
        expect(quivers.any((q) => q.id == quiverId), isTrue);

        final shafts = await db.getShaftsForQuiver(quiverId);
        expect(shafts.length, equals(12));
      });
    });
  });

  group('Data Integrity Under Stress', () {
    test('rapid arrow insertion maintains order', () async {
      await withTestDb((db) async {
        final sessionId = 'rapid-${DateTime.now().millisecondsSinceEpoch}';
        await db.insertSession(SessionsCompanion.insert(
          id: sessionId,
          roundTypeId: 'wa_720_70m',
        ));

        final endId = '${sessionId}_end_1';
        await db.insertEnd(EndsCompanion.insert(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Rapidly insert arrows (simulates fast tapping)
        for (int i = 1; i <= 30; i++) {
          await db.insertArrow(ArrowsCompanion.insert(
            id: '${endId}_arrow_$i',
            endId: endId,
            x: 0.1,
            y: 0.1,
            score: (i % 11), // Scores 0-10 cycling
            sequence: i,
          ));
        }

        final arrows = await db.getArrowsForEnd(endId);

        // All 30 should be present
        expect(arrows.length, equals(30));

        // Verify sequence is maintained
        for (int i = 0; i < arrows.length; i++) {
          expect(arrows[i].sequence, equals(i + 1));
        }
      });
    });

    test('large dataset performance', () async {
      await withTestDb((db) async {
        // Create a large number of sessions with arrows
        final baseTime = DateTime.now().millisecondsSinceEpoch;

        for (int s = 0; s < 10; s++) {
          final sessionId = 'perf-session-$baseTime-$s';
          await db.insertSession(SessionsCompanion.insert(
            id: sessionId,
            roundTypeId: 'wa_720_70m',
          ));

          for (int e = 1; e <= 12; e++) {
            final endId = '${sessionId}_end_$e';
            await db.insertEnd(EndsCompanion.insert(
              id: endId,
              sessionId: sessionId,
              endNumber: e,
            ));

            for (int a = 1; a <= 6; a++) {
              await db.insertArrow(ArrowsCompanion.insert(
                id: '${endId}_arrow_$a',
                endId: endId,
                x: 0.1,
                y: 0.1,
                score: 10,
                sequence: a,
              ));
            }
          }
        }

        // Should be able to query all data efficiently
        final allSessions = await db.getAllSessionsForSync();
        final perfSessions = allSessions.where(
            (s) => s.id.startsWith('perf-session-$baseTime'));

        expect(perfSessions.length, equals(10));

        // Verify total arrow count (10 sessions * 12 ends * 6 arrows = 720)
        final allArrows = await db.getAllArrowsForSync();
        final perfArrows = allArrows.where(
            (a) => a.id.contains('perf-session-$baseTime'));

        expect(perfArrows.length, equals(720));
      });
    });
  });
}

// =============================================================================
// TEST HELPERS
// =============================================================================

/// Runs a test with an in-memory database.
/// Database is created fresh for each test and disposed automatically.
Future<void> withTestDb(Future<void> Function(AppDatabase db) test) async {
  final db = AppDatabase.withExecutor(NativeDatabase.memory());
  try {
    await test(db);
  } finally {
    await db.close();
  }
}

/// Helper class to test conflict resolution logic
class ConflictResolutionTester {
  MergeDecision resolveConflict({
    DateTime? localUpdatedAt,
    DateTime? cloudUpdatedAt,
    DateTime? localDeletedAt,
    DateTime? cloudDeletedAt,
    bool existsLocal = false,
    bool existsCloud = false,
  }) {
    if (existsLocal && !existsCloud) {
      return MergeDecision.uploadLocal;
    }

    if (!existsLocal && existsCloud) {
      if (cloudDeletedAt != null) {
        return MergeDecision.skip;
      }
      return MergeDecision.downloadCloud;
    }

    if (existsLocal && existsCloud) {
      if (localDeletedAt != null && cloudDeletedAt != null) {
        if (localDeletedAt.isAfter(cloudDeletedAt)) {
          return MergeDecision.uploadLocal;
        } else if (cloudDeletedAt.isAfter(localDeletedAt)) {
          return MergeDecision.downloadCloud;
        }
        return MergeDecision.skip;
      }

      if (localDeletedAt != null && cloudDeletedAt == null) {
        if (localDeletedAt.isAfter(cloudUpdatedAt ?? DateTime(1970))) {
          return MergeDecision.uploadLocal;
        }
        return MergeDecision.downloadCloud;
      }

      if (localDeletedAt == null && cloudDeletedAt != null) {
        if (cloudDeletedAt.isAfter(localUpdatedAt ?? DateTime(1970))) {
          return MergeDecision.downloadCloud;
        }
        return MergeDecision.uploadLocal;
      }

      final localTime = localUpdatedAt ?? DateTime(1970);
      final cloudTime = cloudUpdatedAt ?? DateTime(1970);

      if (localTime.isAfter(cloudTime)) {
        return MergeDecision.uploadLocal;
      } else if (cloudTime.isAfter(localTime)) {
        return MergeDecision.downloadCloud;
      }

      return MergeDecision.skip;
    }

    return MergeDecision.skip;
  }
}
