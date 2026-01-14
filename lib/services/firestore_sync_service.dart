import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../db/database.dart';

/// Service to sync local database data to Firestore for cloud backup
/// Ensures data is never lost even if browser cache is cleared
class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  bool get isAuthenticated => _userId != null;

  // Collection references
  DocumentReference<Map<String, dynamic>> get _userDoc {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId);
  }

  // ============================================================================
  // SYNC IMPORTED SCORES
  // ============================================================================

  /// Backup imported scores to Firestore
  Future<void> backupImportedScores(List<ImportedScore> scores) async {
    if (_userId == null || scores.isEmpty) return;

    final batch = _firestore.batch();
    final scoresRef = _userDoc.collection('imported_scores');

    // Use a chunked approach for large lists
    for (final score in scores) {
      batch.set(scoresRef.doc(score.id), {
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

    // Update metadata
    batch.set(_userDoc.collection('metadata').doc('imported_scores'), {
      'lastUpdated': FieldValue.serverTimestamp(),
      'count': scores.length,
    });

    await batch.commit();
  }

  /// Restore imported scores from Firestore
  Future<List<Map<String, dynamic>>> restoreImportedScores() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _userDoc.collection('imported_scores').get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('Error restoring imported scores: $e');
      return [];
    }
  }

  // ============================================================================
  // SYNC SESSIONS (Plotted scores)
  // ============================================================================

  /// Backup a completed session to Firestore
  Future<void> backupSession(Session session, List<End> ends, List<Arrow> arrows) async {
    if (_userId == null) return;

    final sessionData = {
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
        'score': a.score,
        'isX': a.isX,
        'sequence': a.sequence,
        'shaftNumber': a.shaftNumber,
        'createdAt': a.createdAt.toIso8601String(),
      }).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _userDoc.collection('sessions').doc(session.id).set(sessionData);
  }

  /// Get all backed up sessions
  Future<List<Map<String, dynamic>>> restoreSessions() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _userDoc.collection('sessions').get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('Error restoring sessions: $e');
      return [];
    }
  }

  // ============================================================================
  // SYNC EQUIPMENT
  // ============================================================================

  /// Backup equipment (bows, quivers, shafts) to Firestore
  Future<void> backupEquipment({
    required List<Bow> bows,
    required List<Quiver> quivers,
    required List<Shaft> shafts,
  }) async {
    if (_userId == null) return;

    await _userDoc.collection('data').doc('equipment').set({
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
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Restore equipment from Firestore
  Future<Map<String, dynamic>?> restoreEquipment() async {
    if (_userId == null) return null;

    try {
      final doc = await _userDoc.collection('data').doc('equipment').get();
      return doc.data();
    } catch (e) {
      print('Error restoring equipment: $e');
      return null;
    }
  }

  // ============================================================================
  // SYNC VOLUME ENTRIES (Arrow count tracking)
  // ============================================================================

  /// Backup volume entries to Firestore
  Future<void> backupVolumeEntries(List<VolumeEntry> entries) async {
    if (_userId == null || entries.isEmpty) return;

    await _userDoc.collection('data').doc('volume_entries').set({
      'entries': entries.map((e) => {
        'id': e.id,
        'date': e.date.toIso8601String(),
        'arrowCount': e.arrowCount,
        'notes': e.notes,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
      }).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'count': entries.length,
    });
  }

  /// Restore volume entries from Firestore
  Future<List<Map<String, dynamic>>> restoreVolumeEntries() async {
    if (_userId == null) return [];

    try {
      final doc = await _userDoc.collection('data').doc('volume_entries').get();
      if (!doc.exists) return [];
      final data = doc.data();
      return (data?['entries'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print('Error restoring volume entries: $e');
      return [];
    }
  }

  // ============================================================================
  // SYNC OLY TRAINING LOGS (Bow training sessions)
  // ============================================================================

  /// Backup OLY training logs to Firestore
  Future<void> backupOlyTrainingLogs(List<OlyTrainingLog> logs) async {
    if (_userId == null || logs.isEmpty) return;

    await _userDoc.collection('data').doc('oly_training').set({
      'logs': logs.map((l) => {
        'id': l.id,
        'sessionTemplateId': l.sessionTemplateId,
        'sessionVersion': l.sessionVersion,
        'sessionName': l.sessionName,
        'plannedDurationSeconds': l.plannedDurationSeconds,
        'actualDurationSeconds': l.actualDurationSeconds,
        'plannedExercises': l.plannedExercises,
        'completedExercises': l.completedExercises,
        'totalHoldSeconds': l.totalHoldSeconds,
        'totalRestSeconds': l.totalRestSeconds,
        'feedbackShaking': l.feedbackShaking,
        'feedbackStructure': l.feedbackStructure,
        'feedbackRest': l.feedbackRest,
        'progressionSuggestion': l.progressionSuggestion,
        'suggestedNextVersion': l.suggestedNextVersion,
        'notes': l.notes,
        'startedAt': l.startedAt.toIso8601String(),
        'completedAt': l.completedAt.toIso8601String(),
      }).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'count': logs.length,
    });
  }

  /// Restore OLY training logs from Firestore
  Future<List<Map<String, dynamic>>> restoreOlyTrainingLogs() async {
    if (_userId == null) return [];

    try {
      final doc = await _userDoc.collection('data').doc('oly_training').get();
      if (!doc.exists) return [];
      final data = doc.data();
      return (data?['logs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print('Error restoring OLY training logs: $e');
      return [];
    }
  }

  // ============================================================================
  // FULL SYNC OPERATIONS
  // ============================================================================

  /// Backup all user data to Firestore
  Future<void> backupAllData(AppDatabase db) async {
    if (_userId == null) {
      print('Cannot backup: user not authenticated');
      return;
    }

    try {
      print('Starting full backup for user: $_userId');

      // Backup imported scores
      final importedScores = await db.getAllImportedScores();
      if (importedScores.isNotEmpty) {
        await backupImportedScores(importedScores);
        print('Backed up ${importedScores.length} imported scores');
      }

      // Backup completed sessions with their ends and arrows
      final sessions = await db.getCompletedSessions();
      for (final session in sessions) {
        final ends = await db.getEndsForSession(session.id);
        final arrows = <Arrow>[];
        for (final end in ends) {
          final endArrows = await db.getArrowsForEnd(end.id);
          arrows.addAll(endArrows);
        }
        await backupSession(session, ends, arrows);
      }
      print('Backed up ${sessions.length} sessions');

      // Backup equipment
      final bows = await db.getAllBows();
      final quivers = await db.getAllQuivers();
      // Get all shafts across all quivers
      final allShafts = <Shaft>[];
      for (final quiver in quivers) {
        final shafts = await db.getAllShaftsForQuiver(quiver.id);
        allShafts.addAll(shafts);
      }
      await backupEquipment(bows: bows, quivers: quivers, shafts: allShafts);
      print('Backed up equipment: ${bows.length} bows, ${quivers.length} quivers, ${allShafts.length} shafts');

      // Backup volume entries
      final volumeEntries = await db.getAllVolumeEntries();
      if (volumeEntries.isNotEmpty) {
        await backupVolumeEntries(volumeEntries);
        print('Backed up ${volumeEntries.length} volume entries');
      }

      // Backup OLY training logs
      final olyLogs = await db.getAllOlyTrainingLogs();
      if (olyLogs.isNotEmpty) {
        await backupOlyTrainingLogs(olyLogs);
        print('Backed up ${olyLogs.length} OLY training logs');
      }

      // Update last backup timestamp
      await _userDoc.collection('metadata').doc('backup').set({
        'lastBackup': FieldValue.serverTimestamp(),
        'importedScoresCount': importedScores.length,
        'sessionsCount': sessions.length,
        'bowsCount': bows.length,
      });

      print('Full backup completed successfully');
    } catch (e) {
      print('Error during full backup: $e');
      rethrow;
    }
  }

  /// Check when last cloud backup occurred
  Future<DateTime?> getLastBackupTime() async {
    if (_userId == null) return null;

    try {
      final doc = await _userDoc.collection('metadata').doc('backup').get();
      if (!doc.exists) return null;
      final timestamp = doc.data()?['lastBackup'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      print('Error checking backup time: $e');
      return null;
    }
  }

  /// Check if cloud has data for restore
  Future<bool> hasCloudData() async {
    if (_userId == null) return false;

    try {
      final doc = await _userDoc.collection('metadata').doc('backup').get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
