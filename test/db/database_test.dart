import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:matcher/matcher.dart' as matcher;
import '../test_helpers.dart';

/// Database Test Infrastructure
///
/// Provides in-memory database testing for all database operations.
/// Uses helper methods and fixtures to simplify test creation.
///
/// Usage:
///   await withTestDb((db) async {
///     // Your test code with database
///   });

void main() {
  group('Database Test Infrastructure', () {
    test('creates in-memory database successfully', () async {
      await withTestDb((db) async {
        expect(db, matcher.isNotNull);
        expect(db.schemaVersion, equals(6));
      });
    });

    test('database starts empty (no sessions)', () async {
      await withTestDb((db) async {
        final sessions = await db.getAllSessions();
        expect(sessions, isEmpty);
      });
    });

    test('round types are seeded on creation', () async {
      await withTestDb((db) async {
        final roundTypes = await db.getAllRoundTypes();
        expect(roundTypes, isNotEmpty);

        // Verify WA 18m exists
        final wa18 = await db.getRoundType('wa_18_60');
        expect(wa18, matcher.isNotNull);
        expect(wa18!.maxScore, equals(600));
      });
    });

    test('OLY training data is seeded on creation', () async {
      await withTestDb((db) async {
        final templates = await db.getAllOlySessionTemplates();
        expect(templates, isNotEmpty);

        final exerciseTypes = await db.getAllOlyExerciseTypes();
        expect(exerciseTypes, isNotEmpty);
      });
    });
  });

  group('Session Operations', () {
    test('inserts and retrieves session', () async {
      await withTestDb((db) async {
        final sessionId = 'test_session_1';
        final session = createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        );

        await db.insertSession(session);

        final retrieved = await db.getSession(sessionId);
        expect(retrieved, matcher.isNotNull);
        expect(retrieved!.id, equals(sessionId));
        expect(retrieved.roundTypeId, equals('wa_18_60'));
      });
    });

    test('gets incomplete session', () async {
      await withTestDb((db) async {
        final session = createTestSession(
          id: 'incomplete_session',
          roundTypeId: 'wa_18_60',
        );
        await db.insertSession(session);

        final incomplete = await db.getIncompleteSession();
        expect(incomplete, matcher.isNotNull);
        expect(incomplete!.id, equals('incomplete_session'));
        expect(incomplete.completedAt, matcher.isNull);
      });
    });

    test('completes session with score', () async {
      await withTestDb((db) async {
        final sessionId = 'session_to_complete';
        final session = createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        );
        await db.insertSession(session);

        await db.completeSession(sessionId, 580, 25);

        final completed = await db.getSession(sessionId);
        expect(completed, matcher.isNotNull);
        expect(completed!.completedAt, matcher.isNotNull);
        expect(completed.totalScore, equals(580));
        expect(completed.totalXs, equals(25));
      });
    });

    test('gets completed sessions only', () async {
      await withTestDb((db) async {
        // Create incomplete session
        await db.insertSession(createTestSession(
          id: 'incomplete',
          roundTypeId: 'wa_18_60',
        ));

        // Create completed session
        final completedId = 'completed';
        await db.insertSession(createTestSession(
          id: completedId,
          roundTypeId: 'wa_18_60',
        ));
        await db.completeSession(completedId, 500, 10);

        final completed = await db.getCompletedSessions();
        expect(completed.length, equals(1));
        expect(completed[0].id, equals(completedId));
      });
    });

    test('deletes session cascades to ends and arrows', () async {
      await withTestDb((db) async {
        final sessionId = 'session_to_delete';

        // Create session with end and arrows
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        await db.insertArrow(createTestArrow(
          id: 'arrow_1',
          endId: endId,
          xMm: 10,
          yMm: 5,
          score: 10,
        ));

        // Delete session
        await db.deleteSession(sessionId);

        // Verify cascade
        final session = await db.getSession(sessionId);
        expect(session, matcher.isNull);

        final ends = await db.getEndsForSession(sessionId);
        expect(ends, isEmpty);

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows, isEmpty);
      });
    });

    test('updates session with equipment', () async {
      await withTestDb((db) async {
        final sessionId = 'session_with_equipment';
        final session = createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        );
        await db.insertSession(session);

        // Create equipment
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'quiver_1';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
        ));

        // Update session with equipment using update statement
        await (db.update(db.sessions)..where((t) => t.id.equals(sessionId))).write(
          SessionsCompanion(
            bowId: Value(bowId),
            quiverId: Value(quiverId),
            shaftTaggingEnabled: const Value(true),
          ),
        );

        final updated = await db.getSession(sessionId);
        expect(updated!.bowId, equals(bowId));
        expect(updated.quiverId, equals(quiverId));
        expect(updated.shaftTaggingEnabled, isTrue);
      });
    });

    test('getSession returns null for missing ID', () async {
      await withTestDb((db) async {
        final session = await db.getSession('nonexistent_id');
        expect(session, matcher.isNull);
      });
    });

    test('getAllSessions returns all sessions ordered by date descending', () async {
      await withTestDb((db) async {
        final now = DateTime.now();

        // Insert sessions with different start times
        await db.insertSession(createTestSessionWithDate(
          id: 'session_1',
          roundTypeId: 'wa_18_60',
          startedAt: now.subtract(const Duration(days: 3)),
        ));

        await db.insertSession(createTestSessionWithDate(
          id: 'session_2',
          roundTypeId: 'wa_18_60',
          startedAt: now.subtract(const Duration(days: 1)),
        ));

        await db.insertSession(createTestSessionWithDate(
          id: 'session_3',
          roundTypeId: 'wa_18_60',
          startedAt: now.subtract(const Duration(days: 2)),
        ));

        final sessions = await db.getAllSessions();

        expect(sessions.length, equals(3));
        // Most recent first (descending order)
        expect(sessions[0].id, equals('session_2'));
        expect(sessions[1].id, equals('session_3'));
        expect(sessions[2].id, equals('session_1'));
      });
    });

    test('getSessionsByDateRange filters correctly', () async {
      await withTestDb((db) async {
        final baseDate = DateTime(2024, 1, 15);

        // Insert sessions across multiple dates
        await db.insertSession(createTestSessionWithDate(
          id: 'session_1',
          roundTypeId: 'wa_18_60',
          startedAt: DateTime(2024, 1, 10),
        ));

        await db.insertSession(createTestSessionWithDate(
          id: 'session_2',
          roundTypeId: 'wa_18_60',
          startedAt: DateTime(2024, 1, 15),
        ));

        await db.insertSession(createTestSessionWithDate(
          id: 'session_3',
          roundTypeId: 'wa_18_60',
          startedAt: DateTime(2024, 1, 20),
        ));

        await db.insertSession(createTestSessionWithDate(
          id: 'session_4',
          roundTypeId: 'wa_18_60',
          startedAt: DateTime(2024, 1, 25),
        ));

        // Query sessions between Jan 15 and Jan 20 (inclusive)
        final rangeStart = DateTime(2024, 1, 15);
        final rangeEnd = DateTime(2024, 1, 20, 23, 59, 59);
        final sessions = await db.getSessionsByDateRange(rangeStart, rangeEnd);

        expect(sessions.length, equals(2));
        expect(sessions.any((s) => s.id == 'session_2'), isTrue);
        expect(sessions.any((s) => s.id == 'session_3'), isTrue);
        expect(sessions.any((s) => s.id == 'session_1'), isFalse);
        expect(sessions.any((s) => s.id == 'session_4'), isFalse);
      });
    });

    test('getSessionsByDateRange returns empty for no matches', () async {
      await withTestDb((db) async {
        await db.insertSession(createTestSessionWithDate(
          id: 'session_1',
          roundTypeId: 'wa_18_60',
          startedAt: DateTime(2024, 1, 10),
        ));

        final rangeStart = DateTime(2024, 2, 1);
        final rangeEnd = DateTime(2024, 2, 28);
        final sessions = await db.getSessionsByDateRange(rangeStart, rangeEnd);

        expect(sessions, isEmpty);
      });
    });
  });

  group('End Operations', () {
    test('inserts and retrieves end', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        final retrieved = await db.getEnd(endId);
        expect(retrieved, matcher.isNotNull);
        expect(retrieved!.id, equals(endId));
        expect(retrieved.sessionId, equals(sessionId));
        expect(retrieved.endNumber, equals(1));
      });
    });

    test('gets ends for session in order', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        // Insert ends out of order
        await db.insertEnd(createTestEnd(
          id: 'end_3',
          sessionId: sessionId,
          endNumber: 3,
        ));
        await db.insertEnd(createTestEnd(
          id: 'end_1',
          sessionId: sessionId,
          endNumber: 1,
        ));
        await db.insertEnd(createTestEnd(
          id: 'end_2',
          sessionId: sessionId,
          endNumber: 2,
        ));

        final ends = await db.getEndsForSession(sessionId);
        expect(ends.length, equals(3));
        expect(ends[0].endNumber, equals(1));
        expect(ends[1].endNumber, equals(2));
        expect(ends[2].endNumber, equals(3));
      });
    });

    test('gets current active end', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        // Insert committed end
        await db.insertEnd(createTestEnd(
          id: 'end_1',
          sessionId: sessionId,
          endNumber: 1,
          status: 'committed',
        ));

        // Insert active end
        await db.insertEnd(createTestEnd(
          id: 'end_2',
          sessionId: sessionId,
          endNumber: 2,
          status: 'active',
        ));

        final currentEnd = await db.getCurrentEnd(sessionId);
        expect(currentEnd, matcher.isNotNull);
        expect(currentEnd!.id, equals('end_2'));
        expect(currentEnd.status, equals('active'));
      });
    });

    test('updates end score', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        await db.updateEndScore(endId, 28, 1);

        final updated = await db.getEnd(endId);
        expect(updated!.endScore, equals(28));
        expect(updated.endXs, equals(1));
      });
    });

    test('commits end with timestamp', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        await db.commitEnd(endId, 30, 2);

        final committed = await db.getEnd(endId);
        expect(committed!.status, equals('committed'));
        expect(committed.endScore, equals(30));
        expect(committed.endXs, equals(2));
        expect(committed.committedAt, matcher.isNotNull);
      });
    });
  });

  group('Arrow Operations', () {
    test('inserts and retrieves arrow with mm coordinates', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        final arrowId = 'arrow_1';
        await db.insertArrow(createTestArrow(
          id: arrowId,
          endId: endId,
          xMm: 50.5,
          yMm: -30.2,
          score: 8,
        ));

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(1));
        expect(arrows[0].id, equals(arrowId));
        expect(arrows[0].xMm, equals(50.5));
        expect(arrows[0].yMm, equals(-30.2));
        expect(arrows[0].score, equals(8));
      });
    });

    test('gets arrows for end in sequence order', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Insert arrows out of order
        await db.insertArrow(createTestArrow(
          id: 'arrow_3',
          endId: endId,
          xMm: 30,
          yMm: 0,
          score: 9,
          sequence: 3,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_1',
          endId: endId,
          xMm: 10,
          yMm: 0,
          score: 10,
          sequence: 1,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_2',
          endId: endId,
          xMm: 20,
          yMm: 0,
          score: 9,
          sequence: 2,
        ));

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(3));
        expect(arrows[0].sequence, equals(1));
        expect(arrows[1].sequence, equals(2));
        expect(arrows[2].sequence, equals(3));
      });
    });

    test('gets all arrows for session', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        // Create two ends with arrows
        final end1Id = 'end_1';
        await db.insertEnd(createTestEnd(
          id: end1Id,
          sessionId: sessionId,
          endNumber: 1,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_1',
          endId: end1Id,
          xMm: 10,
          yMm: 0,
          score: 10,
        ));

        final end2Id = 'end_2';
        await db.insertEnd(createTestEnd(
          id: end2Id,
          sessionId: sessionId,
          endNumber: 2,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_2',
          endId: end2Id,
          xMm: 20,
          yMm: 0,
          score: 9,
        ));

        final arrows = await db.getArrowsForSession(sessionId);
        expect(arrows.length, equals(2));
      });
    });

    test('deletes arrow by id', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        final arrowId = 'arrow_to_delete';
        await db.insertArrow(createTestArrow(
          id: arrowId,
          endId: endId,
          xMm: 10,
          yMm: 0,
          score: 10,
        ));

        await db.deleteArrow(arrowId);

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows, isEmpty);
      });
    });

    test('deletes last arrow in end', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Add 3 arrows
        await db.insertArrow(createTestArrow(
          id: 'arrow_1',
          endId: endId,
          xMm: 10,
          yMm: 0,
          score: 10,
          sequence: 1,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_2',
          endId: endId,
          xMm: 20,
          yMm: 0,
          score: 9,
          sequence: 2,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_3',
          endId: endId,
          xMm: 30,
          yMm: 0,
          score: 9,
          sequence: 3,
        ));

        await db.deleteLastArrowInEnd(endId);

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(2));
        expect(arrows.last.id, equals('arrow_2'));
      });
    });

    test('stores shaft number on arrow', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        await db.insertArrow(createTestArrow(
          id: 'arrow_1',
          endId: endId,
          xMm: 10,
          yMm: 0,
          score: 10,
          shaftNumber: 3,
        ));

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows[0].shaftNumber, equals(3));
      });
    });

    test('stores X flag correctly', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        await db.insertArrow(createTestArrow(
          id: 'arrow_1',
          endId: endId,
          xMm: 5,
          yMm: 0,
          score: 10,
          isX: true,
        ));

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows[0].isX, isTrue);
      });
    });

    test('handles tri-spot face indices', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_trispot',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Insert arrows on different faces
        await db.insertArrow(createTestArrow(
          id: 'arrow_1',
          endId: endId,
          xMm: 10,
          yMm: 0,
          score: 10,
          faceIndex: 0,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_2',
          endId: endId,
          xMm: 20,
          yMm: 0,
          score: 9,
          faceIndex: 1,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_3',
          endId: endId,
          xMm: 30,
          yMm: 0,
          score: 9,
          faceIndex: 2,
        ));

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows[0].faceIndex, equals(0));
        expect(arrows[1].faceIndex, equals(1));
        expect(arrows[2].faceIndex, equals(2));
      });
    });

    test('validates score range 0-10', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Test valid score range (0-10)
        for (int score = 0; score <= 10; score++) {
          await db.insertArrow(createTestArrow(
            id: 'arrow_score_$score',
            endId: endId,
            xMm: 10.0,
            yMm: 0.0,
            score: score,
            sequence: score + 1,
          ));
        }

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(11));

        // Verify all scores are in valid range
        for (final arrow in arrows) {
          expect(arrow.score, greaterThanOrEqualTo(0));
          expect(arrow.score, lessThanOrEqualTo(10));
        }
      });
    });

    test('updates arrow position and score', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        final arrowId = 'arrow_to_update';
        await db.insertArrow(createTestArrow(
          id: arrowId,
          endId: endId,
          xMm: 10.0,
          yMm: 5.0,
          score: 9,
        ));

        // Update position and score
        final radiusMm = 40 * 5.0;
        final newXMm = 50.5;
        final newYMm = -30.2;
        await db.updateArrow(
          arrowId,
          ArrowsCompanion(
            xMm: Value(newXMm),
            yMm: Value(newYMm),
            x: Value(newXMm / radiusMm),
            y: Value(newYMm / radiusMm),
            score: const Value(8),
          ),
        );

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(1));
        expect(arrows[0].xMm, equals(50.5));
        expect(arrows[0].yMm, equals(-30.2));
        expect(arrows[0].score, equals(8));
      });
    });

    test('deletes all arrows for session (bulk delete)', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        // Create multiple ends with arrows
        final end1Id = 'end_1';
        await db.insertEnd(createTestEnd(
          id: end1Id,
          sessionId: sessionId,
          endNumber: 1,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_1',
          endId: end1Id,
          xMm: 10,
          yMm: 0,
          score: 10,
          sequence: 1,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_2',
          endId: end1Id,
          xMm: 20,
          yMm: 0,
          score: 9,
          sequence: 2,
        ));

        final end2Id = 'end_2';
        await db.insertEnd(createTestEnd(
          id: end2Id,
          sessionId: sessionId,
          endNumber: 2,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_3',
          endId: end2Id,
          xMm: 30,
          yMm: 0,
          score: 9,
          sequence: 1,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_4',
          endId: end2Id,
          xMm: 40,
          yMm: 0,
          score: 8,
          sequence: 2,
        ));

        // Verify arrows exist
        final arrowsBeforeDelete = await db.getArrowsForSession(sessionId);
        expect(arrowsBeforeDelete.length, equals(4));

        // Delete all arrows for session
        final deletedCount = await db.deleteArrowsForSession(sessionId);
        expect(deletedCount, equals(4));

        // Verify all arrows deleted
        final arrowsAfterDelete = await db.getArrowsForSession(sessionId);
        expect(arrowsAfterDelete, isEmpty);

        // Verify ends still exist (not cascade deleted)
        final ends = await db.getEndsForSession(sessionId);
        expect(ends.length, equals(2));
      });
    });

    test('deleteArrowsForSession returns 0 for session with no ends', () async {
      await withTestDb((db) async {
        final sessionId = 'empty_session';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final deletedCount = await db.deleteArrowsForSession(sessionId);
        expect(deletedCount, equals(0));
      });
    });
  });

  group('Equipment Operations', () {
    test('inserts and retrieves bow', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(
          id: bowId,
          name: 'Test Recurve',
          bowType: 'recurve',
        ));

        final bow = await db.getBow(bowId);
        expect(bow, matcher.isNotNull);
        expect(bow!.name, equals('Test Recurve'));
        expect(bow.bowType, equals('recurve'));
      });
    });

    test('sets and gets default bow', () async {
      await withTestDb((db) async {
        final bow1Id = 'bow_1';
        await db.insertBow(createTestBow(id: bow1Id, name: 'Bow 1'));

        final bow2Id = 'bow_2';
        await db.insertBow(createTestBow(id: bow2Id, name: 'Bow 2'));

        await db.setDefaultBow(bow1Id);

        var defaultBow = await db.getDefaultBow();
        expect(defaultBow!.id, equals(bow1Id));

        // Change default
        await db.setDefaultBow(bow2Id);
        defaultBow = await db.getDefaultBow();
        expect(defaultBow!.id, equals(bow2Id));

        // Verify only one is default
        final bow1 = await db.getBow(bow1Id);
        expect(bow1!.isDefault, isFalse);
      });
    });

    test('inserts and retrieves quiver', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'quiver_1';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
          shaftCount: 12,
        ));

        final quiver = await db.getQuiver(quiverId);
        expect(quiver, matcher.isNotNull);
        expect(quiver!.name, equals('Test Quiver'));
        expect(quiver.bowId, equals(bowId));
        expect(quiver.shaftCount, equals(12));
      });
    });

    test('gets quivers for specific bow', () async {
      await withTestDb((db) async {
        final bow1Id = 'bow_1';
        await db.insertBow(createTestBow(id: bow1Id, name: 'Bow 1'));

        final bow2Id = 'bow_2';
        await db.insertBow(createTestBow(id: bow2Id, name: 'Bow 2'));

        await db.insertQuiver(createTestQuiver(
          id: 'quiver_1',
          name: 'Quiver 1',
          bowId: bow1Id,
        ));
        await db.insertQuiver(createTestQuiver(
          id: 'quiver_2',
          name: 'Quiver 2',
          bowId: bow1Id,
        ));
        await db.insertQuiver(createTestQuiver(
          id: 'quiver_3',
          name: 'Quiver 3',
          bowId: bow2Id,
        ));

        final bow1Quivers = await db.getQuiversForBow(bow1Id);
        expect(bow1Quivers.length, equals(2));
      });
    });

    test('sets default quiver', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'quiver_1';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
        ));

        await db.setDefaultQuiver(quiverId);

        final defaultQuiver = await db.getDefaultQuiver();
        expect(defaultQuiver!.id, equals(quiverId));
      });
    });

    test('creates and retrieves shafts for quiver', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'quiver_1';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
          shaftCount: 12,
        ));

        // Create shafts
        for (int i = 1; i <= 12; i++) {
          await db.insertShaft(createTestShaft(
            id: 'shaft_$i',
            quiverId: quiverId,
            number: i,
          ));
        }

        final shafts = await db.getShaftsForQuiver(quiverId);
        expect(shafts.length, equals(12));
        expect(shafts[0].number, equals(1));
        expect(shafts[11].number, equals(12));
      });
    });

    test('retires and unretires shaft', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'quiver_1';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
        ));

        final shaftId = 'shaft_1';
        await db.insertShaft(createTestShaft(
          id: shaftId,
          quiverId: quiverId,
          number: 1,
        ));

        // Retire shaft
        await db.retireShaft(shaftId);

        var shafts = await db.getShaftsForQuiver(quiverId);
        expect(shafts, isEmpty); // Active shafts only

        var allShafts = await db.getAllShaftsForQuiver(quiverId);
        expect(allShafts.length, equals(1));
        expect(allShafts[0].retiredAt, matcher.isNotNull);

        // Unretire shaft
        await db.unretireShaft(shaftId);

        shafts = await db.getShaftsForQuiver(quiverId);
        expect(shafts.length, equals(1));
        expect(shafts[0].retiredAt, matcher.isNull);
      });
    });

    test('gets all bows', () async {
      await withTestDb((db) async {
        await db.insertBow(createTestBow(id: 'bow_1', name: 'Bow 1'));
        await db.insertBow(createTestBow(id: 'bow_2', name: 'Bow 2'));
        await db.insertBow(createTestBow(id: 'bow_3', name: 'Bow 3'));

        final bows = await db.getAllBows();
        expect(bows.length, equals(3));
        // Verify all bows are returned
        final names = bows.map((b) => b.name).toList();
        expect(names, containsAll(['Bow 1', 'Bow 2', 'Bow 3']));
      });
    });

    test('updates bow successfully', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(
          id: bowId,
          name: 'Original Name',
          bowType: 'recurve',
        ));

        // Update the bow
        final bow = await db.getBow(bowId);
        final updated = bow!.toCompanion(false).copyWith(
          name: const Value('Updated Name'),
          settings: const Value('{"tiller": "1/8"}'),
        );
        await db.updateBow(updated);

        final updatedBow = await db.getBow(bowId);
        expect(updatedBow!.name, equals('Updated Name'));
        expect(updatedBow.settings, equals('{"tiller": "1/8"}'));
        expect(updatedBow.bowType, equals('recurve')); // Unchanged
      });
    });

    test('gets all quivers', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        await db.insertQuiver(createTestQuiver(
          id: 'quiver_1',
          name: 'Quiver 1',
          bowId: bowId,
        ));
        await db.insertQuiver(createTestQuiver(
          id: 'quiver_2',
          name: 'Quiver 2',
          bowId: bowId,
        ));

        final quivers = await db.getAllQuivers();
        expect(quivers.length, equals(2));
        // Verify all quivers are returned
        final names = quivers.map((q) => q.name).toList();
        expect(names, containsAll(['Quiver 1', 'Quiver 2']));
      });
    });

    test('updates quiver successfully', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'quiver_1';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Original Quiver',
          bowId: bowId,
          shaftCount: 12,
        ));

        // Update the quiver
        final quiver = await db.getQuiver(quiverId);
        final updated = quiver!.toCompanion(false).copyWith(
          name: const Value('Updated Quiver'),
          shaftCount: const Value(6),
        );
        await db.updateQuiver(updated);

        final updatedQuiver = await db.getQuiver(quiverId);
        expect(updatedQuiver!.name, equals('Updated Quiver'));
        expect(updatedQuiver.shaftCount, equals(6));
      });
    });

    test('gets single shaft by id', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'quiver_1';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
        ));

        final shaftId = 'shaft_1';
        await db.insertShaft(createTestShaft(
          id: shaftId,
          quiverId: quiverId,
          number: 1,
          diameter: '1816',
          notes: 'Test shaft',
        ));

        final shaft = await db.getShaft(shaftId);
        expect(shaft, matcher.isNotNull);
        expect(shaft!.number, equals(1));
        expect(shaft.diameter, equals('1816'));
        expect(shaft.notes, equals('Test shaft'));
      });
    });

    test('updates shaft successfully', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'quiver_1';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
        ));

        final shaftId = 'shaft_1';
        await db.insertShaft(createTestShaft(
          id: shaftId,
          quiverId: quiverId,
          number: 1,
          diameter: '1816',
        ));

        // Update the shaft
        final shaft = await db.getShaft(shaftId);
        final updated = shaft!.toCompanion(false).copyWith(
          diameter: const Value('2314'),
          notes: const Value('Replaced nock'),
        );
        await db.updateShaft(updated);

        final updatedShaft = await db.getShaft(shaftId);
        expect(updatedShaft!.diameter, equals('2314'));
        expect(updatedShaft.notes, equals('Replaced nock'));
        expect(updatedShaft.number, equals(1)); // Unchanged
      });
    });
  });

  group('Volume Entry Operations', () {
    test('inserts and retrieves volume entry', () async {
      await withTestDb((db) async {
        final date = DateTime(2024, 1, 15);
        await db.insertVolumeEntry(createTestVolumeEntry(
          id: 'vol_1',
          date: date,
          arrowCount: 150,
        ));

        final entries = await db.getAllVolumeEntries();
        expect(entries.length, equals(1));
        expect(entries[0].arrowCount, equals(150));
      });
    });

    test('gets volume entries in date range', () async {
      await withTestDb((db) async {
        final start = DateTime(2024, 1, 1);

        // Insert entries across multiple days
        for (int i = 0; i < 30; i++) {
          await db.insertVolumeEntry(createTestVolumeEntry(
            id: 'vol_$i',
            date: start.add(Duration(days: i)),
            arrowCount: 100 + i,
          ));
        }

        // Query specific range
        final rangeStart = DateTime(2024, 1, 10);
        final rangeEnd = DateTime(2024, 1, 20);
        final entries = await db.getVolumeEntriesInRange(rangeStart, rangeEnd);

        expect(entries.length, equals(11)); // 10-20 inclusive
      });
    });

    test('gets volume entry for specific date', () async {
      await withTestDb((db) async {
        final date = DateTime(2024, 1, 15, 10, 30); // With time
        await db.insertVolumeEntry(createTestVolumeEntry(
          id: 'vol_1',
          date: date,
          arrowCount: 150,
        ));

        // Query by date (time should not matter)
        final queryDate = DateTime(2024, 1, 15, 18, 0);
        final entry = await db.getVolumeEntryForDate(queryDate);

        expect(entry, matcher.isNotNull);
        expect(entry!.arrowCount, equals(150));
      });
    });

    test('sets volume for date (upsert)', () async {
      await withTestDb((db) async {
        final date = DateTime(2024, 1, 15);

        // First insert
        await db.setVolumeForDate(date, 100, title: 'Training');

        var entry = await db.getVolumeEntryForDate(date);
        expect(entry!.arrowCount, equals(100));
        expect(entry.title, equals('Training'));

        // Update same date
        await db.setVolumeForDate(date, 150, title: 'Training Updated');

        entry = await db.getVolumeEntryForDate(date);
        expect(entry!.arrowCount, equals(150));
        expect(entry.title, equals('Training Updated'));

        // Verify only one entry exists
        final all = await db.getAllVolumeEntries();
        expect(all.length, equals(1));
      });
    });

    test('deletes volume entry', () async {
      await withTestDb((db) async {
        final entryId = 'vol_to_delete';
        await db.insertVolumeEntry(createTestVolumeEntry(
          id: entryId,
          date: DateTime.now(),
          arrowCount: 100,
        ));

        await db.deleteVolumeEntry(entryId);

        final entries = await db.getAllVolumeEntries();
        expect(entries, isEmpty);
      });
    });
  });

  group('Imported Score Operations', () {
    test('inserts and retrieves imported score', () async {
      await withTestDb((db) async {
        final date = DateTime(2024, 1, 15);
        await db.insertImportedScore(createTestImportedScore(
          id: 'import_1',
          date: date,
          roundName: 'WA 720 70m',
          score: 650,
          xCount: 30,
        ));

        final scores = await db.getAllImportedScores();
        expect(scores.length, equals(1));
        expect(scores[0].score, equals(650));
        expect(scores[0].xCount, equals(30));
      });
    });

    test('checks for duplicate scores', () async {
      await withTestDb((db) async {
        final date = DateTime(2024, 1, 15);
        await db.insertImportedScore(createTestImportedScore(
          id: 'import_1',
          date: date,
          roundName: 'WA 720 70m',
          score: 650,
        ));

        final isDupe = await db.isDuplicateScore(date, 650);
        expect(isDupe, isTrue);

        final isNotDupe = await db.isDuplicateScore(date, 660);
        expect(isNotDupe, isFalse);
      });
    });

    test('checks for duplicate with round name', () async {
      await withTestDb((db) async {
        final date = DateTime(2024, 1, 15);
        await db.insertImportedScore(createTestImportedScore(
          id: 'import_1',
          date: date,
          roundName: 'WA 720 70m',
          score: 650,
        ));

        final isDupe = await db.isDuplicateScoreWithRound(date, 650, 'WA 720 70m');
        expect(isDupe, isTrue);

        final isNotDupe = await db.isDuplicateScoreWithRound(date, 650, 'WA 720 60m');
        expect(isNotDupe, isFalse);
      });
    });

    test('deletes imported score', () async {
      await withTestDb((db) async {
        final scoreId = 'import_to_delete';
        await db.insertImportedScore(createTestImportedScore(
          id: scoreId,
          date: DateTime.now(),
          roundName: 'Test Round',
          score: 500,
        ));

        await db.deleteImportedScore(scoreId);

        final scores = await db.getAllImportedScores();
        expect(scores, isEmpty);
      });
    });
  });

  group('User Preferences Operations', () {
    test('sets and gets string preference', () async {
      await withTestDb((db) async {
        await db.setPreference('theme', 'dark');

        final value = await db.getPreference('theme');
        expect(value, equals('dark'));
      });
    });

    test('updates existing preference', () async {
      await withTestDb((db) async {
        await db.setPreference('theme', 'dark');
        await db.setPreference('theme', 'light');

        final value = await db.getPreference('theme');
        expect(value, equals('light'));
      });
    });

    test('returns null for missing preference', () async {
      await withTestDb((db) async {
        final value = await db.getPreference('nonexistent');
        expect(value, matcher.isNull);
      });
    });

    test('sets and gets bool preference', () async {
      await withTestDb((db) async {
        await db.setBoolPreference('notifications', true);

        final value = await db.getBoolPreference('notifications');
        expect(value, isTrue);
      });
    });

    test('returns default for missing bool preference', () async {
      await withTestDb((db) async {
        final value = await db.getBoolPreference('nonexistent', defaultValue: false);
        expect(value, isFalse);
      });
    });
  });

  group('Round Type Operations', () {
    test('gets all round types', () async {
      await withTestDb((db) async {
        final roundTypes = await db.getAllRoundTypes();
        expect(roundTypes, isNotEmpty);
      });
    });

    test('gets specific round type', () async {
      await withTestDb((db) async {
        final wa18 = await db.getRoundType('wa_18_60');
        expect(wa18, matcher.isNotNull);
        expect(wa18!.name, contains('18'));
        expect(wa18.maxScore, equals(600));
      });
    });

    test('gets round types by category', () async {
      await withTestDb((db) async {
        final waIndoor = await db.getRoundTypesByCategory('wa_indoor');
        expect(waIndoor, isNotEmpty);

        for (final round in waIndoor) {
          expect(round.category, equals('wa_indoor'));
          expect(round.isIndoor, isTrue);
        }
      });
    });
  });

  group('OLY Training Operations', () {
    test('gets all exercise types', () async {
      await withTestDb((db) async {
        final types = await db.getAllOlyExerciseTypes();
        expect(types, isNotEmpty);
      });
    });

    test('gets all session templates', () async {
      await withTestDb((db) async {
        final templates = await db.getAllOlySessionTemplates();
        expect(templates, isNotEmpty);
      });
    });

    test('gets session template by version', () async {
      await withTestDb((db) async {
        final template = await db.getOlySessionTemplateByVersion('1.0');
        expect(template, matcher.isNotNull);
        expect(template!.version, equals('1.0'));
      });
    });

    test('gets exercises for session template', () async {
      await withTestDb((db) async {
        final template = await db.getOlySessionTemplateByVersion('1.0');
        expect(template, matcher.isNotNull);

        final exercises = await db.getOlySessionExercises(template!.id);
        expect(exercises, isNotEmpty);
      });
    });

    test('inserts and retrieves training log', () async {
      await withTestDb((db) async {
        final logId = 'log_1';
        final now = DateTime.now();

        await db.insertOlyTrainingLog(createTestOlyTrainingLog(
          id: logId,
          sessionVersion: '1.0',
          completedAt: now,
        ));

        final log = await db.getOlyTrainingLog(logId);
        expect(log, matcher.isNotNull);
        expect(log!.sessionVersion, equals('1.0'));
      });
    });

    test('ensures user training progress exists', () async {
      await withTestDb((db) async {
        await db.ensureUserTrainingProgressExists();

        final progress = await db.getUserTrainingProgress();
        expect(progress, matcher.isNotNull);
        expect(progress!.id, equals('user_progress'));
      });
    });

    test('updates progress after session', () async {
      await withTestDb((db) async {
        await db.ensureUserTrainingProgressExists();

        await db.updateProgressAfterSession(
          completedVersion: '1.0',
          suggestedNextVersion: '1.5',
          progressionSuggestion: 'progress',
        );

        final progress = await db.getUserTrainingProgress();
        expect(progress!.currentLevel, equals('1.5'));
        expect(progress.sessionsAtCurrentLevel, equals(1));
        expect(progress.lastSessionVersion, equals('1.0'));
        expect(progress.totalSessionsCompleted, equals(1));
      });
    });
  });

  group('Data Integrity - Foreign Keys', () {
    test('session references valid round type', () async {
      await withTestDb((db) async {
        final sessionId = 'test_session';
        final roundTypeId = 'wa_18_60';

        // Create session with valid round type
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: roundTypeId,
        ));

        final session = await db.getSession(sessionId);
        expect(session, matcher.isNotNull);
        expect(session!.roundTypeId, equals(roundTypeId));

        // Verify round type exists
        final roundType = await db.getRoundType(roundTypeId);
        expect(roundType, matcher.isNotNull);
      });
    });

    test('end references valid session', () async {
      await withTestDb((db) async {
        final sessionId = 'test_session';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'test_end';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        final end = await db.getEnd(endId);
        expect(end, matcher.isNotNull);
        expect(end!.sessionId, equals(sessionId));

        // Verify session exists
        final session = await db.getSession(sessionId);
        expect(session, matcher.isNotNull);
      });
    });

    test('arrow references valid end', () async {
      await withTestDb((db) async {
        final sessionId = 'test_session';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'test_end';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        final arrowId = 'test_arrow';
        await db.insertArrow(createTestArrow(
          id: arrowId,
          endId: endId,
          xMm: 10,
          yMm: 0,
          score: 10,
        ));

        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(1));
        expect(arrows[0].endId, equals(endId));

        // Verify end exists
        final end = await db.getEnd(endId);
        expect(end, matcher.isNotNull);
      });
    });

    test('quiver references valid bow', () async {
      await withTestDb((db) async {
        final bowId = 'test_bow';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'test_quiver';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
        ));

        final quiver = await db.getQuiver(quiverId);
        expect(quiver, matcher.isNotNull);
        expect(quiver!.bowId, equals(bowId));

        // Verify bow exists
        final bow = await db.getBow(bowId);
        expect(bow, matcher.isNotNull);
      });
    });

    test('shaft references valid quiver', () async {
      await withTestDb((db) async {
        final bowId = 'test_bow';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiverId = 'test_quiver';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Test Quiver',
          bowId: bowId,
        ));

        final shaftId = 'test_shaft';
        await db.insertShaft(createTestShaft(
          id: shaftId,
          quiverId: quiverId,
          number: 1,
        ));

        final shaft = await db.getShaft(shaftId);
        expect(shaft, matcher.isNotNull);
        expect(shaft!.quiverId, equals(quiverId));

        // Verify quiver exists
        final quiver = await db.getQuiver(quiverId);
        expect(quiver, matcher.isNotNull);
      });
    });

    test('session with valid equipment foreign keys', () async {
      await withTestDb((db) async {
        // Create valid equipment
        final bowId = 'valid_bow';
        await db.insertBow(createTestBow(id: bowId, name: 'Valid Bow'));

        final quiverId = 'valid_quiver';
        await db.insertQuiver(createTestQuiver(
          id: quiverId,
          name: 'Valid Quiver',
          bowId: bowId,
        ));

        // Session with valid equipment should succeed
        final sessionId = 'valid_session';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        await (db.update(db.sessions)..where((t) => t.id.equals(sessionId))).write(
          SessionsCompanion(
            bowId: Value(bowId),
            quiverId: Value(quiverId),
          ),
        );

        final session = await db.getSession(sessionId);
        expect(session!.bowId, equals(bowId));
        expect(session.quiverId, equals(quiverId));

        // Verify equipment exists
        final bow = await db.getBow(bowId);
        final quiver = await db.getQuiver(quiverId);
        expect(bow, matcher.isNotNull);
        expect(quiver, matcher.isNotNull);
      });
    });
  });

  group('Data Integrity - Cascade Deletes', () {
    test('deleting session cascades to ends and arrows', () async {
      await withTestDb((db) async {
        final sessionId = 'cascade_session';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        // Create 3 ends with arrows
        for (int i = 1; i <= 3; i++) {
          final endId = 'end_$i';
          await db.insertEnd(createTestEnd(
            id: endId,
            sessionId: sessionId,
            endNumber: i,
          ));

          // 3 arrows per end
          for (int j = 1; j <= 3; j++) {
            await db.insertArrow(createTestArrow(
              id: 'arrow_${i}_$j',
              endId: endId,
              xMm: 10.0 * j,
              yMm: 0,
              score: 10 - j,
              sequence: j,
            ));
          }
        }

        // Verify data exists
        final endsBefore = await db.getEndsForSession(sessionId);
        expect(endsBefore.length, equals(3));
        final arrowsBefore = await db.getArrowsForSession(sessionId);
        expect(arrowsBefore.length, equals(9));

        // Delete session
        await db.deleteSession(sessionId);

        // Verify cascade delete
        final session = await db.getSession(sessionId);
        expect(session, matcher.isNull);

        final endsAfter = await db.getEndsForSession(sessionId);
        expect(endsAfter, isEmpty);

        final arrowsAfter = await db.getArrowsForSession(sessionId);
        expect(arrowsAfter, isEmpty);
      });
    });

    test('deleting bow preserves sessions (nullable FK)', () async {
      await withTestDb((db) async {
        final bowId = 'bow_to_delete';
        await db.insertBow(createTestBow(id: bowId, name: 'Bow to Delete'));

        final sessionId = 'session_with_bow';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        // Link session to bow
        await (db.update(db.sessions)..where((t) => t.id.equals(sessionId))).write(
          SessionsCompanion(bowId: Value(bowId)),
        );

        var session = await db.getSession(sessionId);
        expect(session!.bowId, equals(bowId));

        // Delete bow
        await (db.delete(db.bows)..where((t) => t.id.equals(bowId))).go();

        // Session should still exist (bow FK is nullable)
        session = await db.getSession(sessionId);
        expect(session, matcher.isNotNull);
        expect(session!.id, equals(sessionId));
      });
    });

    test('session cascade delete verified end-to-end', () async {
      await withTestDb((db) async {
        final sessionId = 'cascade_test_session';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        // Create 2 ends with 3 arrows each
        for (int i = 1; i <= 2; i++) {
          final endId = 'end_cascade_$i';
          await db.insertEnd(createTestEnd(
            id: endId,
            sessionId: sessionId,
            endNumber: i,
          ));

          for (int j = 1; j <= 3; j++) {
            await db.insertArrow(createTestArrow(
              id: 'arrow_cascade_${i}_$j',
              endId: endId,
              xMm: 10.0 * j,
              yMm: 0,
              score: 10 - j,
              sequence: j,
            ));
          }
        }

        // Verify data structure before delete
        final endsBefore = await db.getEndsForSession(sessionId);
        expect(endsBefore.length, equals(2));
        final arrowsBefore = await db.getArrowsForSession(sessionId);
        expect(arrowsBefore.length, equals(6));

        // Delete session using the database method
        await db.deleteSession(sessionId);

        // Verify cascade worked (both ends and arrows should be gone)
        final session = await db.getSession(sessionId);
        expect(session, matcher.isNull);

        final endsAfter = await db.getEndsForSession(sessionId);
        expect(endsAfter, isEmpty);

        final arrowsAfter = await db.getArrowsForSession(sessionId);
        expect(arrowsAfter, isEmpty);
      });
    });
  });

  group('Data Integrity - Orphaned Records', () {
    test('no orphaned ends exist after session delete', () async {
      await withTestDb((db) async {
        final session1Id = 'session_1';
        final session2Id = 'session_2';

        await db.insertSession(createTestSession(
          id: session1Id,
          roundTypeId: 'wa_18_60',
        ));
        await db.insertSession(createTestSession(
          id: session2Id,
          roundTypeId: 'wa_18_60',
        ));

        // Create ends for both sessions
        await db.insertEnd(createTestEnd(
          id: 'end_s1_1',
          sessionId: session1Id,
          endNumber: 1,
        ));
        await db.insertEnd(createTestEnd(
          id: 'end_s2_1',
          sessionId: session2Id,
          endNumber: 1,
        ));

        // Delete first session
        await db.deleteSession(session1Id);

        // Verify no orphaned ends (query all ends directly)
        final allEnds = await (db.select(db.ends)).get();
        expect(allEnds.length, equals(1));
        expect(allEnds[0].sessionId, equals(session2Id));
      });
    });

    test('deleting end removes only its arrows', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final end1Id = 'end_1';
        final end2Id = 'end_2';
        await db.insertEnd(createTestEnd(
          id: end1Id,
          sessionId: sessionId,
          endNumber: 1,
        ));
        await db.insertEnd(createTestEnd(
          id: end2Id,
          sessionId: sessionId,
          endNumber: 2,
        ));

        // Create arrows for both ends
        await db.insertArrow(createTestArrow(
          id: 'arrow_e1_1',
          endId: end1Id,
          xMm: 10,
          yMm: 0,
          score: 10,
        ));
        await db.insertArrow(createTestArrow(
          id: 'arrow_e2_1',
          endId: end2Id,
          xMm: 20,
          yMm: 0,
          score: 9,
        ));

        // Delete first end
        await (db.delete(db.ends)..where((t) => t.id.equals(end1Id))).go();

        // Verify end deleted
        final end1 = await db.getEnd(end1Id);
        expect(end1, matcher.isNull);

        // Verify only arrows from end2 remain (validates no orphans)
        final arrowsForEnd2 = await db.getArrowsForEnd(end2Id);
        expect(arrowsForEnd2.length, equals(1));
        expect(arrowsForEnd2[0].endId, equals(end2Id));
      });
    });

    test('deleting quiver removes only its shafts', () async {
      await withTestDb((db) async {
        final bowId = 'bow_1';
        await db.insertBow(createTestBow(id: bowId, name: 'Test Bow'));

        final quiver1Id = 'quiver_1';
        final quiver2Id = 'quiver_2';
        await db.insertQuiver(createTestQuiver(
          id: quiver1Id,
          name: 'Quiver 1',
          bowId: bowId,
        ));
        await db.insertQuiver(createTestQuiver(
          id: quiver2Id,
          name: 'Quiver 2',
          bowId: bowId,
        ));

        // Create shafts for both quivers
        await db.insertShaft(createTestShaft(
          id: 'shaft_q1_1',
          quiverId: quiver1Id,
          number: 1,
        ));
        await db.insertShaft(createTestShaft(
          id: 'shaft_q2_1',
          quiverId: quiver2Id,
          number: 1,
        ));

        // Delete first quiver
        await (db.delete(db.quivers)..where((t) => t.id.equals(quiver1Id))).go();

        // Verify quiver deleted
        final quiver1 = await db.getQuiver(quiver1Id);
        expect(quiver1, matcher.isNull);

        // Verify only shafts from quiver2 remain (validates no orphans)
        final shaftsForQuiver2 = await db.getShaftsForQuiver(quiver2Id);
        expect(shaftsForQuiver2.length, equals(1));
        expect(shaftsForQuiver2[0].quiverId, equals(quiver2Id));
      });
    });
  });

  group('Data Integrity - Concurrent Access', () {
    test('handles concurrent arrow inserts to same end', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        final endId = 'end_1';
        await db.insertEnd(createTestEnd(
          id: endId,
          sessionId: sessionId,
          endNumber: 1,
        ));

        // Simulate concurrent arrow inserts
        final futures = <Future>[];
        for (int i = 1; i <= 6; i++) {
          futures.add(
            db.insertArrow(createTestArrow(
              id: 'arrow_$i',
              endId: endId,
              xMm: 10.0 * i,
              yMm: 0,
              score: 10 - (i ~/ 2),
              sequence: i,
            )),
          );
        }

        // Wait for all inserts
        await Future.wait(futures);

        // Verify all arrows were inserted
        final arrows = await db.getArrowsForEnd(endId);
        expect(arrows.length, equals(6));
      });
    });

    test('handles concurrent session completions', () async {
      await withTestDb((db) async {
        final session1Id = 'session_1';
        final session2Id = 'session_2';

        await db.insertSession(createTestSession(
          id: session1Id,
          roundTypeId: 'wa_18_60',
        ));
        await db.insertSession(createTestSession(
          id: session2Id,
          roundTypeId: 'wa_18_60',
        ));

        // Complete both sessions concurrently
        await Future.wait([
          db.completeSession(session1Id, 580, 25),
          db.completeSession(session2Id, 560, 20),
        ]);

        // Verify both completed
        final session1 = await db.getSession(session1Id);
        final session2 = await db.getSession(session2Id);

        expect(session1!.completedAt, matcher.isNotNull);
        expect(session1.totalScore, equals(580));
        expect(session2!.completedAt, matcher.isNotNull);
        expect(session2.totalScore, equals(560));
      });
    });

    test('handles concurrent preference updates', () async {
      await withTestDb((db) async {
        // Set initial preference
        await db.setPreference('counter', '0');

        // Simulate concurrent updates (last write wins)
        final futures = <Future>[];
        for (int i = 1; i <= 10; i++) {
          futures.add(db.setPreference('counter', i.toString()));
        }

        await Future.wait(futures);

        // One of the values should be stored (last write wins)
        final value = await db.getPreference('counter');
        expect(value, matcher.isNotNull);
        expect(int.parse(value!), greaterThanOrEqualTo(1));
        expect(int.parse(value), lessThanOrEqualTo(10));
      });
    });

    test('handles concurrent equipment creation', () async {
      await withTestDb((db) async {
        // Create multiple bows concurrently
        final futures = <Future>[];
        for (int i = 1; i <= 5; i++) {
          futures.add(
            db.insertBow(createTestBow(
              id: 'bow_$i',
              name: 'Bow $i',
            )),
          );
        }

        await Future.wait(futures);

        // Verify all bows created
        final bows = await db.getAllBows();
        expect(bows.length, equals(5));
      });
    });

    test('transaction rollback on error maintains integrity', () async {
      await withTestDb((db) async {
        final sessionId = 'session_1';
        await db.insertSession(createTestSession(
          id: sessionId,
          roundTypeId: 'wa_18_60',
        ));

        try {
          await db.transaction(() async {
            // Insert valid end
            final endId = 'end_1';
            await db.insertEnd(createTestEnd(
              id: endId,
              sessionId: sessionId,
              endNumber: 1,
            ));

            // Force a constraint violation (duplicate primary key)
            await db.insertEnd(createTestEnd(
              id: endId, // Same ID - will fail on primary key constraint
              sessionId: sessionId,
              endNumber: 2,
            ));
          });
          fail('Transaction should have failed');
        } catch (e) {
          // Expected failure on duplicate primary key
        }

        // Verify transaction was rolled back (no end should exist)
        final ends = await db.getEndsForSession(sessionId);
        expect(ends, isEmpty);
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

/// Creates a test SessionsCompanion
SessionsCompanion createTestSession({
  required String id,
  required String roundTypeId,
  String sessionType = 'practice',
  String? location,
  String? notes,
  String? bowId,
  String? quiverId,
  bool shaftTaggingEnabled = false,
}) {
  return SessionsCompanion.insert(
    id: id,
    roundTypeId: roundTypeId,
    sessionType: Value(sessionType),
    location: Value(location),
    notes: Value(notes),
    bowId: Value(bowId),
    quiverId: Value(quiverId),
    shaftTaggingEnabled: Value(shaftTaggingEnabled),
  );
}

/// Creates a test SessionsCompanion with specific start date
SessionsCompanion createTestSessionWithDate({
  required String id,
  required String roundTypeId,
  required DateTime startedAt,
  String sessionType = 'practice',
  String? location,
  String? notes,
  String? bowId,
  String? quiverId,
  bool shaftTaggingEnabled = false,
}) {
  return SessionsCompanion.insert(
    id: id,
    roundTypeId: roundTypeId,
    startedAt: Value(startedAt),
    sessionType: Value(sessionType),
    location: Value(location),
    notes: Value(notes),
    bowId: Value(bowId),
    quiverId: Value(quiverId),
    shaftTaggingEnabled: Value(shaftTaggingEnabled),
  );
}

/// Creates a test EndsCompanion
EndsCompanion createTestEnd({
  required String id,
  required String sessionId,
  required int endNumber,
  int endScore = 0,
  int endXs = 0,
  String status = 'active',
}) {
  return EndsCompanion.insert(
    id: id,
    sessionId: sessionId,
    endNumber: endNumber,
    endScore: Value(endScore),
    endXs: Value(endXs),
    status: Value(status),
  );
}

/// Creates a test ArrowsCompanion
ArrowsCompanion createTestArrow({
  required String id,
  required String endId,
  required double xMm,
  required double yMm,
  required int score,
  bool isX = false,
  int faceIndex = 0,
  int sequence = 1,
  int? shaftNumber,
}) {
  // Calculate normalized coordinates (40cm face)
  final radiusMm = 40 * 5.0;
  final normalizedX = xMm / radiusMm;
  final normalizedY = yMm / radiusMm;

  return ArrowsCompanion.insert(
    id: id,
    endId: endId,
    xMm: Value(xMm),
    yMm: Value(yMm),
    x: normalizedX,
    y: normalizedY,
    score: score,
    isX: Value(isX),
    faceIndex: Value(faceIndex),
    sequence: sequence,
    shaftNumber: Value(shaftNumber),
  );
}

/// Creates a test BowsCompanion
BowsCompanion createTestBow({
  required String id,
  required String name,
  String bowType = 'recurve',
  String? settings,
  bool isDefault = false,
}) {
  return BowsCompanion.insert(
    id: id,
    name: name,
    bowType: bowType,
    settings: Value(settings),
    isDefault: Value(isDefault),
  );
}

/// Creates a test QuiversCompanion
QuiversCompanion createTestQuiver({
  required String id,
  required String name,
  String? bowId,
  int shaftCount = 12,
  bool isDefault = false,
}) {
  return QuiversCompanion.insert(
    id: id,
    name: name,
    bowId: Value(bowId),
    shaftCount: Value(shaftCount),
    isDefault: Value(isDefault),
  );
}

/// Creates a test ShaftsCompanion
ShaftsCompanion createTestShaft({
  required String id,
  required String quiverId,
  required int number,
  String? diameter,
  String? notes,
}) {
  return ShaftsCompanion.insert(
    id: id,
    quiverId: quiverId,
    number: number,
    diameter: Value(diameter),
    notes: Value(notes),
  );
}

/// Creates a test VolumeEntriesCompanion
VolumeEntriesCompanion createTestVolumeEntry({
  required String id,
  required DateTime date,
  required int arrowCount,
  String? title,
  String? notes,
}) {
  return VolumeEntriesCompanion.insert(
    id: id,
    date: date,
    arrowCount: arrowCount,
    title: Value(title),
    notes: Value(notes),
  );
}

/// Creates a test ImportedScoresCompanion
ImportedScoresCompanion createTestImportedScore({
  required String id,
  required DateTime date,
  required String roundName,
  required int score,
  int? xCount,
  String? location,
  String? notes,
  String sessionType = 'competition',
  String source = 'manual',
}) {
  return ImportedScoresCompanion.insert(
    id: id,
    date: date,
    roundName: roundName,
    score: score,
    xCount: Value(xCount),
    location: Value(location),
    notes: Value(notes),
    sessionType: Value(sessionType),
    source: Value(source),
  );
}

/// Creates a test OlyTrainingLogsCompanion
OlyTrainingLogsCompanion createTestOlyTrainingLog({
  required String id,
  required String sessionVersion,
  String? sessionTemplateId,
  String sessionName = 'Test Session',
  int plannedDurationSeconds = 1200,
  int actualDurationSeconds = 1150,
  int plannedExercises = 5,
  int completedExercises = 5,
  int totalHoldSeconds = 600,
  int totalRestSeconds = 550,
  int? feedbackShaking,
  int? feedbackStructure,
  int? feedbackRest,
  String? progressionSuggestion,
  String? suggestedNextVersion,
  String? notes,
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  final now = DateTime.now();
  return OlyTrainingLogsCompanion.insert(
    id: id,
    sessionTemplateId: Value(sessionTemplateId),
    sessionVersion: sessionVersion,
    sessionName: sessionName,
    plannedDurationSeconds: plannedDurationSeconds,
    actualDurationSeconds: actualDurationSeconds,
    plannedExercises: plannedExercises,
    completedExercises: completedExercises,
    totalHoldSeconds: totalHoldSeconds,
    totalRestSeconds: totalRestSeconds,
    feedbackShaking: Value(feedbackShaking),
    feedbackStructure: Value(feedbackStructure),
    feedbackRest: Value(feedbackRest),
    progressionSuggestion: Value(progressionSuggestion),
    suggestedNextVersion: Value(suggestedNextVersion),
    notes: Value(notes),
    startedAt: startedAt ?? now,
    completedAt: completedAt ?? now,
  );
}
