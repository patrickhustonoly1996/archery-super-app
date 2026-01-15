/// Tests for MockFirestoreSyncService
///
/// These tests verify the cloud backup/restore mock behavior,
/// documenting expected sync patterns and error handling.
import 'package:flutter_test/flutter_test.dart';
import '../mocks/mock_database.dart';
import '../mocks/mock_firestore_service.dart';

void main() {
  group('MockFirestoreSyncService', () {
    late MockFirestoreSyncService syncService;
    late MockAppDatabase mockDb;

    setUp(() {
      syncService = MockFirestoreSyncService();
      mockDb = MockAppDatabase();
      mockDb.seedStandardRoundTypes();
    });

    tearDown(() {
      syncService.clear();
      mockDb.clear();
    });

    group('Authentication State', () {
      test('starts unauthenticated', () {
        expect(syncService.isAuthenticated, isFalse);
        expect(syncService.userId, isNull);
      });

      test('setUserId makes service authenticated', () {
        syncService.setUserId('user123');

        expect(syncService.isAuthenticated, isTrue);
        expect(syncService.userId, equals('user123'));
      });

      test('setUserId with null makes service unauthenticated', () {
        syncService.setUserId('user123');
        syncService.setUserId(null);

        expect(syncService.isAuthenticated, isFalse);
      });
    });

    group('Imported Scores Backup/Restore', () {
      test('backupImportedScores does nothing when unauthenticated', () async {
        final scores = [
          TestImportedScore(
            id: 'score1',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
        ];

        await syncService.backupImportedScores(scores);

        final cloudCounts = syncService.getCloudDataCounts();
        expect(cloudCounts['importedScores'], equals(0));
      });

      test('backupImportedScores stores scores when authenticated', () async {
        syncService.setUserId('user123');
        final scores = [
          TestImportedScore(
            id: 'score1',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
          TestImportedScore(
            id: 'score2',
            date: DateTime(2024, 1, 20),
            roundName: 'Portsmouth',
            score: 580,
          ),
        ];

        await syncService.backupImportedScores(scores);

        final cloudCounts = syncService.getCloudDataCounts();
        expect(cloudCounts['importedScores'], equals(2));
      });

      test('restoreImportedScores returns empty when unauthenticated', () async {
        final result = await syncService.restoreImportedScores();
        expect(result, isEmpty);
      });

      test('restoreImportedScores returns backed up scores', () async {
        syncService.setUserId('user123');
        final scores = [
          TestImportedScore(
            id: 'score1',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
        ];
        await syncService.backupImportedScores(scores);

        final restored = await syncService.restoreImportedScores();

        expect(restored.length, equals(1));
        expect(restored[0]['id'], equals('score1'));
        expect(restored[0]['score'], equals(650));
      });
    });

    group('Session Backup/Restore', () {
      test('backupSession stores session with ends and arrows', () async {
        syncService.setUserId('user123');
        final session = TestSession(
          id: 'session1',
          roundTypeId: 'wa720_70m',
          totalScore: 650,
          completedAt: DateTime.now(),
        );
        final ends = [
          TestEnd(id: 'end1', sessionId: 'session1', endNumber: 1, endScore: 54),
          TestEnd(id: 'end2', sessionId: 'session1', endNumber: 2, endScore: 56),
        ];
        final arrows = [
          TestArrow(id: 'arrow1', endId: 'end1', score: 9, sequence: 1),
          TestArrow(id: 'arrow2', endId: 'end1', score: 10, sequence: 2, isX: true),
        ];

        await syncService.backupSession(session, ends, arrows);

        final cloudCounts = syncService.getCloudDataCounts();
        expect(cloudCounts['sessions'], equals(1));

        final restored = await syncService.restoreSessions();
        expect(restored[0]['ends'], hasLength(2));
        expect(restored[0]['arrows'], hasLength(2));
      });

      test('backupSession replaces existing session', () async {
        syncService.setUserId('user123');
        final session1 = TestSession(
          id: 'session1',
          roundTypeId: 'wa720_70m',
          totalScore: 650,
        );
        await syncService.backupSession(session1, [], []);

        final session1Updated = TestSession(
          id: 'session1',
          roundTypeId: 'wa720_70m',
          totalScore: 680, // Updated score
        );
        await syncService.backupSession(session1Updated, [], []);

        final restored = await syncService.restoreSessions();
        expect(restored.length, equals(1));
        expect(restored[0]['totalScore'], equals(680));
      });
    });

    group('Equipment Backup/Restore', () {
      test('backupEquipment stores bows, quivers, and shafts', () async {
        syncService.setUserId('user123');
        final bows = [
          TestBow(id: 'bow1', name: 'Competition Bow', bowType: 'recurve'),
        ];
        final quivers = [
          TestQuiver(id: 'quiver1', bowId: 'bow1', name: 'Main Quiver'),
        ];
        final shafts = [
          TestShaft(id: 'shaft1', quiverId: 'quiver1', number: 1),
          TestShaft(id: 'shaft2', quiverId: 'quiver1', number: 2),
        ];

        await syncService.backupEquipment(
          bows: bows,
          quivers: quivers,
          shafts: shafts,
        );

        final restored = await syncService.restoreEquipment();
        expect(restored, isNotNull);
        expect((restored!['bows'] as List).length, equals(1));
        expect((restored['quivers'] as List).length, equals(1));
        expect((restored['shafts'] as List).length, equals(2));
      });
    });

    group('Volume Entries Backup/Restore', () {
      test('backupVolumeEntries stores training volume', () async {
        syncService.setUserId('user123');
        final entries = [
          TestVolumeEntry(
            id: 'vol1',
            date: DateTime(2024, 1, 15),
            arrowCount: 144,
          ),
          TestVolumeEntry(
            id: 'vol2',
            date: DateTime(2024, 1, 16),
            arrowCount: 72,
          ),
        ];

        await syncService.backupVolumeEntries(entries);

        final cloudCounts = syncService.getCloudDataCounts();
        expect(cloudCounts['volumeEntries'], equals(2));
      });

      test('restoreVolumeEntries returns backed up entries', () async {
        syncService.setUserId('user123');
        final entries = [
          TestVolumeEntry(
            id: 'vol1',
            date: DateTime(2024, 1, 15),
            arrowCount: 144,
            title: 'Training Session',
          ),
        ];
        await syncService.backupVolumeEntries(entries);

        final restored = await syncService.restoreVolumeEntries();

        expect(restored.length, equals(1));
        expect(restored[0]['arrowCount'], equals(144));
        expect(restored[0]['title'], equals('Training Session'));
      });
    });

    group('OLY Training Logs Backup/Restore', () {
      test('backupOlyTrainingLogs stores training logs', () async {
        syncService.setUserId('user123');
        final logs = [
          TestOlyTrainingLog(
            id: 'log1',
            sessionVersion: '1.5',
            sessionName: 'Session 1.5',
            plannedDurationSeconds: 1800,
            actualDurationSeconds: 1750,
            plannedExercises: 10,
            completedExercises: 10,
            totalHoldSeconds: 600,
            totalRestSeconds: 1150,
            startedAt: DateTime(2024, 1, 15, 10, 0),
            completedAt: DateTime(2024, 1, 15, 10, 30),
          ),
        ];

        await syncService.backupOlyTrainingLogs(logs);

        final cloudCounts = syncService.getCloudDataCounts();
        expect(cloudCounts['olyLogs'], equals(1));
      });

      test('restoreOlyTrainingLogs returns backed up logs', () async {
        syncService.setUserId('user123');
        final logs = [
          TestOlyTrainingLog(
            id: 'log1',
            sessionVersion: '1.5',
            sessionName: 'Session 1.5',
            plannedDurationSeconds: 1800,
            actualDurationSeconds: 1750,
            plannedExercises: 10,
            completedExercises: 10,
            totalHoldSeconds: 600,
            totalRestSeconds: 1150,
            feedbackShaking: 3,
            startedAt: DateTime(2024, 1, 15, 10, 0),
            completedAt: DateTime(2024, 1, 15, 10, 30),
          ),
        ];
        await syncService.backupOlyTrainingLogs(logs);

        final restored = await syncService.restoreOlyTrainingLogs();

        expect(restored.length, equals(1));
        expect(restored[0]['sessionVersion'], equals('1.5'));
        expect(restored[0]['feedbackShaking'], equals(3));
      });
    });

    group('Full Backup/Restore', () {
      test('backupAllData backs up all data types', () async {
        syncService.setUserId('user123');

        // Populate mock database
        await mockDb.insertImportedScore(TestImportedScore(
          id: 'score1',
          date: DateTime(2024, 1, 15),
          roundName: 'WA 720',
          score: 650,
        ));
        await mockDb.insertVolumeEntry(TestVolumeEntry(
          id: 'vol1',
          date: DateTime(2024, 1, 15),
          arrowCount: 144,
        ));

        await syncService.backupAllData(mockDb);

        final counts = syncService.getCloudDataCounts();
        expect(counts['importedScores'], equals(1));
        expect(counts['volumeEntries'], equals(1));
      });

      test('hasCloudData returns false when no data', () async {
        syncService.setUserId('user123');

        final hasData = await syncService.hasCloudData();
        expect(hasData, isFalse);
      });

      test('hasCloudData returns true after backup', () async {
        syncService.setUserId('user123');
        await syncService.backupImportedScores([
          TestImportedScore(
            id: 'score1',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
        ]);

        final hasData = await syncService.hasCloudData();
        expect(hasData, isTrue);
      });

      test('getLastBackupTime returns timestamp after backup', () async {
        syncService.setUserId('user123');

        final beforeBackup = await syncService.getLastBackupTime();
        expect(beforeBackup, isNull);

        await syncService.backupImportedScores([
          TestImportedScore(
            id: 'score1',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
        ]);

        final afterBackup = await syncService.getLastBackupTime();
        expect(afterBackup, isNotNull);
      });

      test('restoreAllData restores to empty database', () async {
        syncService.setUserId('user123');

        // Backup some data
        await syncService.backupImportedScores([
          TestImportedScore(
            id: 'score1',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
        ]);
        await syncService.backupVolumeEntries([
          TestVolumeEntry(
            id: 'vol1',
            date: DateTime(2024, 1, 15),
            arrowCount: 144,
          ),
        ]);

        // Restore to empty mock database
        final result = await syncService.restoreAllData(mockDb);

        expect(result.success, isTrue);
        expect(result.importedScoresRestored, equals(1));
        expect(result.volumeEntriesRestored, equals(1));
        expect(result.totalRestored, equals(2));
      });

      test('restoreAllData skips when local database has data', () async {
        syncService.setUserId('user123');

        // Add data to local database first
        await mockDb.insertImportedScore(TestImportedScore(
          id: 'local_score',
          date: DateTime(2024, 2, 1),
          roundName: 'Portsmouth',
          score: 580,
        ));

        // Backup different data to cloud
        await syncService.backupImportedScores([
          TestImportedScore(
            id: 'cloud_score',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
        ]);

        // Restore should not overwrite local data
        final result = await syncService.restoreAllData(mockDb);

        expect(result.importedScoresRestored, equals(0));

        final localScores = await mockDb.getAllImportedScores();
        expect(localScores.length, equals(1));
        expect(localScores[0].id, equals('local_score'));
      });

      test('restoreAllData returns failure when unauthenticated', () async {
        final result = await syncService.restoreAllData(mockDb);

        expect(result.success, isFalse);
        expect(result.message, contains('Not authenticated'));
      });
    });

    group('Error Handling', () {
      test('network error throws exception', () async {
        syncService.setUserId('user123');
        syncService.simulateNetworkError = true;

        expect(
          () => syncService.backupImportedScores([]),
          throwsException,
        );
      });

      test('resetErrors clears error flags', () {
        syncService.simulateNetworkError = true;
        syncService.simulateAuthError = true;

        syncService.resetErrors();

        expect(syncService.simulateNetworkError, isFalse);
        expect(syncService.simulateAuthError, isFalse);
      });

      test('clearCloudData removes all backed up data', () async {
        syncService.setUserId('user123');
        await syncService.backupImportedScores([
          TestImportedScore(
            id: 'score1',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
        ]);

        syncService.clearCloudData();

        final counts = syncService.getCloudDataCounts();
        expect(counts['importedScores'], equals(0));
      });

      test('clear resets all state', () async {
        syncService.setUserId('user123');
        // Backup first, then set error flag
        await syncService.backupImportedScores([
          TestImportedScore(
            id: 'score1',
            date: DateTime(2024, 1, 15),
            roundName: 'WA 720',
            score: 650,
          ),
        ]);
        syncService.simulateNetworkError = true;

        syncService.clear();

        expect(syncService.userId, isNull);
        expect(syncService.simulateNetworkError, isFalse);
        final counts = syncService.getCloudDataCounts();
        expect(counts['importedScores'], equals(0));
      });
    });
  });
}
