/// Mock Firestore sync service for testing
///
/// Provides in-memory simulation of cloud backup/restore functionality
/// without requiring actual Firebase infrastructure.
library;

import 'mock_database.dart';

/// Result of a mock restore operation
class MockRestoreResult {
  final bool success;
  final String message;
  final int importedScoresRestored;
  final int sessionsRestored;
  final int volumeEntriesRestored;
  final int olyLogsRestored;

  MockRestoreResult({
    required this.success,
    required this.message,
    this.importedScoresRestored = 0,
    this.sessionsRestored = 0,
    this.volumeEntriesRestored = 0,
    this.olyLogsRestored = 0,
  });

  int get totalRestored =>
      importedScoresRestored + sessionsRestored + volumeEntriesRestored + olyLogsRestored;
}

/// Mock Firestore sync service for testing
///
/// Simulates cloud backup/restore operations using in-memory storage.
class MockFirestoreSyncService {
  String? _userId;
  DateTime? _lastBackupTime;

  // In-memory cloud storage simulation
  final List<Map<String, dynamic>> _cloudImportedScores = [];
  final List<Map<String, dynamic>> _cloudSessions = [];
  final List<Map<String, dynamic>> _cloudVolumeEntries = [];
  final List<Map<String, dynamic>> _cloudOlyLogs = [];
  Map<String, dynamic>? _cloudEquipment;

  // Error simulation flags
  bool simulateNetworkError = false;
  bool simulateAuthError = false;

  /// Set authenticated user ID
  void setUserId(String? userId) {
    _userId = userId;
  }

  /// Get current user ID
  String? get userId => _userId;

  /// Check if authenticated
  bool get isAuthenticated => _userId != null;

  // ============================================================================
  // BACKUP OPERATIONS
  // ============================================================================

  /// Backup imported scores to mock cloud
  Future<void> backupImportedScores(List<TestImportedScore> scores) async {
    _checkErrors();
    if (_userId == null || scores.isEmpty) return;

    _cloudImportedScores.clear();
    for (final score in scores) {
      _cloudImportedScores.add({
        'id': score.id,
        'date': score.date.toIso8601String(),
        'roundName': score.roundName,
        'score': score.score,
        'xCount': score.xCount,
        'location': score.location,
        'notes': score.notes,
        'sessionType': score.sessionType,
        'source': score.source,
        'importedAt': score.importedAt.toIso8601String(),
      });
    }
    _lastBackupTime = DateTime.now();
  }

  /// Restore imported scores from mock cloud
  Future<List<Map<String, dynamic>>> restoreImportedScores() async {
    _checkErrors();
    if (_userId == null) return [];
    return List.from(_cloudImportedScores);
  }

  /// Backup a session to mock cloud
  Future<void> backupSession(
    TestSession session,
    List<TestEnd> ends,
    List<TestArrow> arrows,
  ) async {
    _checkErrors();
    if (_userId == null) return;

    // Remove existing backup of this session
    _cloudSessions.removeWhere((s) => s['id'] == session.id);

    _cloudSessions.add({
      'id': session.id,
      'roundTypeId': session.roundTypeId,
      'sessionType': session.sessionType,
      'location': session.location,
      'notes': session.notes,
      'startedAt': session.startedAt.toIso8601String(),
      'completedAt': session.completedAt?.toIso8601String(),
      'totalScore': session.totalScore,
      'totalXs': session.totalXs,
      'bowId': session.bowId,
      'quiverId': session.quiverId,
      'shaftTaggingEnabled': session.shaftTaggingEnabled,
      'ends': ends.map((e) => {
        'id': e.id,
        'endNumber': e.endNumber,
        'endScore': e.endScore,
        'endXs': e.endXs,
        'status': e.status,
        'committedAt': e.committedAt?.toIso8601String(),
        'createdAt': e.createdAt.toIso8601String(),
      }).toList(),
      'arrows': arrows.map((a) => {
        'id': a.id,
        'endId': a.endId,
        'faceIndex': a.faceIndex,
        'x': a.x,
        'y': a.y,
        'xMm': a.xMm,
        'yMm': a.yMm,
        'score': a.score,
        'isX': a.isX,
        'sequence': a.sequence,
        'shaftNumber': a.shaftNumber,
        'createdAt': a.createdAt.toIso8601String(),
      }).toList(),
    });
    _lastBackupTime = DateTime.now();
  }

  /// Restore sessions from mock cloud
  Future<List<Map<String, dynamic>>> restoreSessions() async {
    _checkErrors();
    if (_userId == null) return [];
    return List.from(_cloudSessions);
  }

  /// Backup equipment to mock cloud
  Future<void> backupEquipment({
    required List<TestBow> bows,
    required List<TestQuiver> quivers,
    required List<TestShaft> shafts,
  }) async {
    _checkErrors();
    if (_userId == null) return;

    _cloudEquipment = {
      'bows': bows.map((b) => {
        'id': b.id,
        'name': b.name,
        'bowType': b.bowType,
        'settings': b.settings,
        'isDefault': b.isDefault,
        'createdAt': b.createdAt.toIso8601String(),
        'updatedAt': b.updatedAt.toIso8601String(),
      }).toList(),
      'quivers': quivers.map((q) => {
        'id': q.id,
        'bowId': q.bowId,
        'name': q.name,
        'shaftCount': q.shaftCount,
        'isDefault': q.isDefault,
        'createdAt': q.createdAt.toIso8601String(),
        'updatedAt': q.updatedAt.toIso8601String(),
      }).toList(),
      'shafts': shafts.map((s) => {
        'id': s.id,
        'quiverId': s.quiverId,
        'number': s.number,
        'diameter': s.diameter,
        'notes': s.notes,
        'createdAt': s.createdAt.toIso8601String(),
        'retiredAt': s.retiredAt?.toIso8601String(),
      }).toList(),
    };
    _lastBackupTime = DateTime.now();
  }

  /// Restore equipment from mock cloud
  Future<Map<String, dynamic>?> restoreEquipment() async {
    _checkErrors();
    if (_userId == null) return null;
    return _cloudEquipment != null ? Map.from(_cloudEquipment!) : null;
  }

  /// Backup volume entries to mock cloud
  Future<void> backupVolumeEntries(List<TestVolumeEntry> entries) async {
    _checkErrors();
    if (_userId == null || entries.isEmpty) return;

    _cloudVolumeEntries.clear();
    for (final entry in entries) {
      _cloudVolumeEntries.add({
        'id': entry.id,
        'date': entry.date.toIso8601String(),
        'arrowCount': entry.arrowCount,
        'title': entry.title,
        'notes': entry.notes,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt.toIso8601String(),
      });
    }
    _lastBackupTime = DateTime.now();
  }

  /// Restore volume entries from mock cloud
  Future<List<Map<String, dynamic>>> restoreVolumeEntries() async {
    _checkErrors();
    if (_userId == null) return [];
    return List.from(_cloudVolumeEntries);
  }

  /// Backup OLY training logs to mock cloud
  Future<void> backupOlyTrainingLogs(List<TestOlyTrainingLog> logs) async {
    _checkErrors();
    if (_userId == null || logs.isEmpty) return;

    _cloudOlyLogs.clear();
    for (final log in logs) {
      _cloudOlyLogs.add({
        'id': log.id,
        'sessionTemplateId': log.sessionTemplateId,
        'sessionVersion': log.sessionVersion,
        'sessionName': log.sessionName,
        'plannedDurationSeconds': log.plannedDurationSeconds,
        'actualDurationSeconds': log.actualDurationSeconds,
        'plannedExercises': log.plannedExercises,
        'completedExercises': log.completedExercises,
        'totalHoldSeconds': log.totalHoldSeconds,
        'totalRestSeconds': log.totalRestSeconds,
        'feedbackShaking': log.feedbackShaking,
        'feedbackStructure': log.feedbackStructure,
        'feedbackRest': log.feedbackRest,
        'progressionSuggestion': log.progressionSuggestion,
        'suggestedNextVersion': log.suggestedNextVersion,
        'notes': log.notes,
        'startedAt': log.startedAt.toIso8601String(),
        'completedAt': log.completedAt.toIso8601String(),
      });
    }
    _lastBackupTime = DateTime.now();
  }

  /// Restore OLY training logs from mock cloud
  Future<List<Map<String, dynamic>>> restoreOlyTrainingLogs() async {
    _checkErrors();
    if (_userId == null) return [];
    return List.from(_cloudOlyLogs);
  }

  // ============================================================================
  // FULL SYNC OPERATIONS
  // ============================================================================

  /// Backup all data from mock database to mock cloud
  Future<void> backupAllData(MockAppDatabase db) async {
    _checkErrors();
    if (_userId == null) return;

    // Backup imported scores
    final importedScores = await db.getAllImportedScores();
    await backupImportedScores(importedScores);

    // Backup sessions
    final sessions = await db.getCompletedSessions();
    for (final session in sessions) {
      final ends = await db.getEndsForSession(session.id);
      final arrows = await db.getArrowsForSession(session.id);
      await backupSession(session, ends, arrows);
    }

    // Backup equipment
    final bows = await db.getAllBows();
    final quivers = await db.getAllQuivers();
    final allShafts = <TestShaft>[];
    for (final quiver in quivers) {
      final shafts = await db.getShaftsForQuiver(quiver.id);
      allShafts.addAll(shafts);
    }
    await backupEquipment(bows: bows, quivers: quivers, shafts: allShafts);

    // Backup volume entries
    final volumeEntries = await db.getAllVolumeEntries();
    await backupVolumeEntries(volumeEntries);

    // Backup OLY logs
    final olyLogs = await db.getAllOlyTrainingLogs();
    await backupOlyTrainingLogs(olyLogs);

    _lastBackupTime = DateTime.now();
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    _checkErrors();
    return _lastBackupTime;
  }

  /// Check if cloud has data
  Future<bool> hasCloudData() async {
    _checkErrors();
    if (_userId == null) return false;
    return _cloudImportedScores.isNotEmpty ||
           _cloudSessions.isNotEmpty ||
           _cloudVolumeEntries.isNotEmpty ||
           _cloudOlyLogs.isNotEmpty;
  }

  /// Restore all data (simplified - returns counts only)
  Future<MockRestoreResult> restoreAllData(MockAppDatabase db) async {
    _checkErrors();
    if (_userId == null) {
      return MockRestoreResult(
        success: false,
        message: 'Not authenticated',
      );
    }

    int importedScoresRestored = 0;
    int sessionsRestored = 0;
    int volumeEntriesRestored = 0;
    int olyLogsRestored = 0;

    // Check if local DB is empty before restoring
    final existingScores = await db.getAllImportedScores();
    final existingSessions = await db.getCompletedSessions();
    final existingVolume = await db.getAllVolumeEntries();
    final existingLogs = await db.getAllOlyTrainingLogs();

    // Restore imported scores if local is empty
    if (existingScores.isEmpty) {
      for (final scoreData in _cloudImportedScores) {
        await db.insertImportedScore(TestImportedScore(
          id: scoreData['id'] as String,
          date: DateTime.parse(scoreData['date'] as String),
          roundName: scoreData['roundName'] as String,
          score: scoreData['score'] as int,
          xCount: scoreData['xCount'] as int?,
          location: scoreData['location'] as String?,
          notes: scoreData['notes'] as String?,
          sessionType: scoreData['sessionType'] as String? ?? 'competition',
          source: scoreData['source'] as String? ?? 'manual',
        ));
        importedScoresRestored++;
      }
    }

    // Restore sessions if local is empty
    if (existingSessions.isEmpty) {
      for (final sessionData in _cloudSessions) {
        final session = TestSession(
          id: sessionData['id'] as String,
          roundTypeId: sessionData['roundTypeId'] as String,
          sessionType: sessionData['sessionType'] as String? ?? 'practice',
          location: sessionData['location'] as String?,
          notes: sessionData['notes'] as String?,
          startedAt: DateTime.parse(sessionData['startedAt'] as String),
          completedAt: sessionData['completedAt'] != null
              ? DateTime.parse(sessionData['completedAt'] as String)
              : null,
          totalScore: sessionData['totalScore'] as int? ?? 0,
          totalXs: sessionData['totalXs'] as int? ?? 0,
        );
        await db.insertSession(session);

        // Insert ends
        final ends = sessionData['ends'] as List<dynamic>? ?? [];
        for (final endData in ends) {
          final end = endData as Map<String, dynamic>;
          await db.insertEnd(TestEnd(
            id: end['id'] as String,
            sessionId: session.id,
            endNumber: end['endNumber'] as int,
            endScore: end['endScore'] as int? ?? 0,
            endXs: end['endXs'] as int? ?? 0,
            status: end['status'] as String? ?? 'committed',
          ));
        }

        // Insert arrows
        final arrows = sessionData['arrows'] as List<dynamic>? ?? [];
        for (final arrowData in arrows) {
          final arrow = arrowData as Map<String, dynamic>;
          await db.insertArrow(TestArrow(
            id: arrow['id'] as String,
            endId: arrow['endId'] as String,
            faceIndex: arrow['faceIndex'] as int? ?? 0,
            x: (arrow['x'] as num).toDouble(),
            y: (arrow['y'] as num).toDouble(),
            xMm: (arrow['xMm'] as num?)?.toDouble() ?? 0.0,
            yMm: (arrow['yMm'] as num?)?.toDouble() ?? 0.0,
            score: arrow['score'] as int,
            isX: arrow['isX'] as bool? ?? false,
            sequence: arrow['sequence'] as int,
            shaftNumber: arrow['shaftNumber'] as int?,
          ));
        }

        sessionsRestored++;
      }
    }

    // Restore volume entries if local is empty
    if (existingVolume.isEmpty) {
      for (final entry in _cloudVolumeEntries) {
        await db.insertVolumeEntry(TestVolumeEntry(
          id: entry['id'] as String,
          date: DateTime.parse(entry['date'] as String),
          arrowCount: entry['arrowCount'] as int,
          title: entry['title'] as String?,
          notes: entry['notes'] as String?,
        ));
        volumeEntriesRestored++;
      }
    }

    // Restore OLY logs if local is empty
    if (existingLogs.isEmpty) {
      for (final logData in _cloudOlyLogs) {
        await db.insertOlyTrainingLog(TestOlyTrainingLog(
          id: logData['id'] as String,
          sessionTemplateId: logData['sessionTemplateId'] as String?,
          sessionVersion: logData['sessionVersion'] as String,
          sessionName: logData['sessionName'] as String,
          plannedDurationSeconds: logData['plannedDurationSeconds'] as int,
          actualDurationSeconds: logData['actualDurationSeconds'] as int,
          plannedExercises: logData['plannedExercises'] as int,
          completedExercises: logData['completedExercises'] as int,
          totalHoldSeconds: logData['totalHoldSeconds'] as int,
          totalRestSeconds: logData['totalRestSeconds'] as int,
          feedbackShaking: logData['feedbackShaking'] as int?,
          feedbackStructure: logData['feedbackStructure'] as int?,
          feedbackRest: logData['feedbackRest'] as int?,
          progressionSuggestion: logData['progressionSuggestion'] as String?,
          suggestedNextVersion: logData['suggestedNextVersion'] as String?,
          notes: logData['notes'] as String?,
          startedAt: DateTime.parse(logData['startedAt'] as String),
          completedAt: DateTime.parse(logData['completedAt'] as String),
        ));
        olyLogsRestored++;
      }
    }

    return MockRestoreResult(
      success: true,
      message: 'Restored ${importedScoresRestored + sessionsRestored + volumeEntriesRestored + olyLogsRestored} items',
      importedScoresRestored: importedScoresRestored,
      sessionsRestored: sessionsRestored,
      volumeEntriesRestored: volumeEntriesRestored,
      olyLogsRestored: olyLogsRestored,
    );
  }

  // ============================================================================
  // TEST HELPERS
  // ============================================================================

  /// Check for simulated errors
  void _checkErrors() {
    if (simulateNetworkError) {
      throw Exception('Network error');
    }
    if (simulateAuthError && _userId == null) {
      throw Exception('User not authenticated');
    }
  }

  /// Reset error simulation flags
  void resetErrors() {
    simulateNetworkError = false;
    simulateAuthError = false;
  }

  /// Clear all cloud data
  void clearCloudData() {
    _cloudImportedScores.clear();
    _cloudSessions.clear();
    _cloudVolumeEntries.clear();
    _cloudOlyLogs.clear();
    _cloudEquipment = null;
    _lastBackupTime = null;
  }

  /// Clear all state
  void clear() {
    _userId = null;
    clearCloudData();
    resetErrors();
  }

  /// Get cloud data counts for verification
  Map<String, int> getCloudDataCounts() {
    return {
      'importedScores': _cloudImportedScores.length,
      'sessions': _cloudSessions.length,
      'volumeEntries': _cloudVolumeEntries.length,
      'olyLogs': _cloudOlyLogs.length,
    };
  }
}
