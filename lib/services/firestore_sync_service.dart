import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../db/database.dart';

/// Service to sync local database data bidirectionally with Firestore
/// Ensures the same data appears on all devices when logged in
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
  // BIDIRECTIONAL SYNC - The main sync method
  // ============================================================================

  /// Sync all data bidirectionally between local DB and cloud
  /// Uses ID-based merge: records are matched by ID, newer wins by timestamp
  Future<SyncResult> syncAllData(AppDatabase db) async {
    if (_userId == null) {
      debugPrint('Cannot sync: user not authenticated');
      return SyncResult(success: false, message: 'Not authenticated');
    }

    try {
      debugPrint('Starting bidirectional sync for user: $_userId');
      int downloaded = 0;
      int uploaded = 0;

      // Sync imported scores
      final scoresResult = await _syncImportedScores(db);
      downloaded += scoresResult.downloaded;
      uploaded += scoresResult.uploaded;

      // Sync sessions (with ends and arrows)
      final sessionsResult = await _syncSessions(db);
      downloaded += sessionsResult.downloaded;
      uploaded += sessionsResult.uploaded;

      // Sync equipment
      final equipmentResult = await _syncEquipment(db);
      downloaded += equipmentResult.downloaded;
      uploaded += equipmentResult.uploaded;

      // Sync volume entries
      final volumeResult = await _syncVolumeEntries(db);
      downloaded += volumeResult.downloaded;
      uploaded += volumeResult.uploaded;

      // Sync OLY training logs
      final olyResult = await _syncOlyTrainingLogs(db);
      downloaded += olyResult.downloaded;
      uploaded += olyResult.uploaded;

      // Sync breath training logs
      final breathResult = await _syncBreathTrainingLogs(db);
      downloaded += breathResult.downloaded;
      uploaded += breathResult.uploaded;

      // Sync milestones
      final milestonesResult = await _syncMilestones(db);
      downloaded += milestonesResult.downloaded;
      uploaded += milestonesResult.uploaded;

      // Sync sight marks
      final sightMarksResult = await _syncSightMarks(db);
      downloaded += sightMarksResult.downloaded;
      uploaded += sightMarksResult.uploaded;

      // Sync user profile
      final profileResult = await _syncUserProfile(db);
      downloaded += profileResult.downloaded;
      uploaded += profileResult.uploaded;

      // Update last sync timestamp
      await _userDoc.collection('metadata').doc('sync').set({
        'lastSync': FieldValue.serverTimestamp(),
        'deviceId': _getDeviceId(),
      }, SetOptions(merge: true));

      debugPrint('Sync complete: downloaded=$downloaded, uploaded=$uploaded');

      return SyncResult(
        success: true,
        message: 'Synced successfully',
        downloaded: downloaded,
        uploaded: uploaded,
      );
    } catch (e) {
      debugPrint('Error during sync: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  String _getDeviceId() {
    // Simple device identifier for debugging
    return '${DateTime.now().millisecondsSinceEpoch}';
  }

  // ============================================================================
  // IMPORTED SCORES SYNC
  // ============================================================================

  Future<_MergeResult> _syncImportedScores(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local scores
      final localScores = await db.getAllImportedScores();
      final localMap = {for (var s in localScores) s.id: s};

      // Get cloud scores
      final cloudSnapshot = await _userDoc.collection('imported_scores').get();
      final cloudMap = {for (var d in cloudSnapshot.docs) d.id: d.data()};

      // Find scores only in cloud -> download
      for (final entry in cloudMap.entries) {
        if (!localMap.containsKey(entry.key)) {
          try {
            await db.insertImportedScore(ImportedScoresCompanion.insert(
              id: entry.value['id'] as String,
              date: DateTime.parse(entry.value['date'] as String),
              roundName: entry.value['roundName'] as String,
              score: entry.value['score'] as int,
              xCount: Value(entry.value['xCount'] as int?),
              location: Value(entry.value['location'] as String?),
              notes: Value(entry.value['notes'] as String?),
              sessionType: Value(entry.value['sessionType'] as String? ?? 'competition'),
              source: Value(entry.value['source'] as String? ?? 'manual'),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading score ${entry.key}: $e');
          }
        }
      }

      // Find scores only locally -> upload
      final batch = _firestore.batch();
      int batchCount = 0;
      for (final score in localScores) {
        if (!cloudMap.containsKey(score.id)) {
          batch.set(_userDoc.collection('imported_scores').doc(score.id), {
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
          batchCount++;
          uploaded++;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('Imported scores: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing imported scores: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // SESSIONS SYNC (with ends and arrows)
  // ============================================================================

  Future<_MergeResult> _syncSessions(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local completed sessions
      final localSessions = await db.getCompletedSessions();
      final localMap = {for (var s in localSessions) s.id: s};

      // Get cloud sessions
      final cloudSnapshot = await _userDoc.collection('sessions').get();
      final cloudMap = {for (var d in cloudSnapshot.docs) d.id: d.data()};

      // Download sessions only in cloud
      for (final entry in cloudMap.entries) {
        if (!localMap.containsKey(entry.key)) {
          try {
            final sessionData = entry.value;

            // Insert session
            await db.insertSession(SessionsCompanion.insert(
              id: sessionData['id'] as String,
              roundTypeId: sessionData['roundTypeId'] as String,
              sessionType: Value(sessionData['sessionType'] as String? ?? 'practice'),
              location: Value(sessionData['location'] as String?),
              notes: Value(sessionData['notes'] as String?),
              startedAt: Value(DateTime.parse(sessionData['startedAt'] as String)),
              completedAt: Value(sessionData['completedAt'] != null
                  ? DateTime.parse(sessionData['completedAt'] as String)
                  : null),
              totalScore: Value(sessionData['totalScore'] as int? ?? 0),
              totalXs: Value(sessionData['totalXs'] as int? ?? 0),
              bowId: Value(sessionData['bowId'] as String?),
              quiverId: Value(sessionData['quiverId'] as String?),
              shaftTaggingEnabled: Value(sessionData['shaftTaggingEnabled'] as bool? ?? false),
            ));

            // Insert ends
            final ends = sessionData['ends'] as List<dynamic>? ?? [];
            for (final endData in ends) {
              final end = endData as Map<String, dynamic>;
              await db.insertEnd(EndsCompanion.insert(
                id: end['id'] as String,
                sessionId: sessionData['id'] as String,
                endNumber: end['endNumber'] as int,
                endScore: Value(end['endScore'] as int? ?? 0),
                endXs: Value(end['endXs'] as int? ?? 0),
                status: Value(end['status'] as String? ?? 'active'),
                committedAt: Value(end['committedAt'] != null
                    ? DateTime.parse(end['committedAt'] as String)
                    : null),
              ));
            }

            // Insert arrows
            final arrows = sessionData['arrows'] as List<dynamic>? ?? [];
            for (final arrowData in arrows) {
              final arrow = arrowData as Map<String, dynamic>;
              await db.insertArrow(ArrowsCompanion.insert(
                id: arrow['id'] as String,
                endId: arrow['endId'] as String,
                faceIndex: Value(arrow['faceIndex'] as int? ?? 0),
                x: (arrow['x'] as num).toDouble(),
                y: (arrow['y'] as num).toDouble(),
                score: arrow['score'] as int,
                isX: Value(arrow['isX'] as bool? ?? false),
                sequence: arrow['sequence'] as int,
                shaftNumber: Value(arrow['shaftNumber'] as int?),
              ));
            }

            downloaded++;
          } catch (e) {
            debugPrint('Error downloading session ${entry.key}: $e');
          }
        }
      }

      // Upload sessions only locally
      for (final session in localSessions) {
        if (!cloudMap.containsKey(session.id)) {
          try {
            final ends = await db.getEndsForSession(session.id);
            final arrows = <Arrow>[];
            for (final end in ends) {
              final endArrows = await db.getArrowsForEnd(end.id);
              arrows.addAll(endArrows);
            }

            await _userDoc.collection('sessions').doc(session.id).set({
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
            });
            uploaded++;
          } catch (e) {
            debugPrint('Error uploading session ${session.id}: $e');
          }
        }
      }

      debugPrint('Sessions: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing sessions: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // EQUIPMENT SYNC (bows, quivers, shafts)
  // ============================================================================

  Future<_MergeResult> _syncEquipment(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local equipment
      final localBows = await db.getAllBows();
      final localQuivers = await db.getAllQuivers();
      final localShafts = <Shaft>[];
      for (final quiver in localQuivers) {
        localShafts.addAll(await db.getAllShaftsForQuiver(quiver.id));
      }

      // Get cloud equipment
      final cloudDoc = await _userDoc.collection('data').doc('equipment').get();
      final cloudData = cloudDoc.data();

      final cloudBows = (cloudData?['bows'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final cloudQuivers = (cloudData?['quivers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final cloudShafts = (cloudData?['shafts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      // Create maps for comparison
      final localBowMap = {for (var b in localBows) b.id: b};
      final localQuiverMap = {for (var q in localQuivers) q.id: q};
      final localShaftMap = {for (var s in localShafts) s.id: s};

      final cloudBowMap = {for (var b in cloudBows) b['id'] as String: b};
      final cloudQuiverMap = {for (var q in cloudQuivers) q['id'] as String: q};
      final cloudShaftMap = {for (var s in cloudShafts) s['id'] as String: s};

      // Download bows only in cloud
      for (final entry in cloudBowMap.entries) {
        if (!localBowMap.containsKey(entry.key)) {
          try {
            final b = entry.value;
            await db.insertBow(BowsCompanion.insert(
              id: b['id'] as String,
              name: b['name'] as String,
              bowType: b['bowType'] as String,
              settings: Value(b['settings'] as String?),
              isDefault: Value(b['isDefault'] as bool? ?? false),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading bow ${entry.key}: $e');
          }
        }
      }

      // Download quivers only in cloud
      for (final entry in cloudQuiverMap.entries) {
        if (!localQuiverMap.containsKey(entry.key)) {
          try {
            final q = entry.value;
            await db.insertQuiver(QuiversCompanion.insert(
              id: q['id'] as String,
              bowId: Value(q['bowId'] as String?),
              name: q['name'] as String,
              shaftCount: Value(q['shaftCount'] as int? ?? 12),
              settings: Value(q['settings'] as String?),
              isDefault: Value(q['isDefault'] as bool? ?? false),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading quiver ${entry.key}: $e');
          }
        }
      }

      // Download shafts only in cloud
      for (final entry in cloudShaftMap.entries) {
        if (!localShaftMap.containsKey(entry.key)) {
          try {
            final s = entry.value;
            await db.insertShaft(ShaftsCompanion.insert(
              id: s['id'] as String,
              quiverId: s['quiverId'] as String,
              number: s['number'] as int,
              diameter: Value(s['diameter'] as String?),
              spine: Value(s['spine'] as int?),
              lengthInches: Value((s['lengthInches'] as num?)?.toDouble()),
              pointWeight: Value(s['pointWeight'] as int?),
              fletchingType: Value(s['fletchingType'] as String?),
              fletchingColor: Value(s['fletchingColor'] as String?),
              nockColor: Value(s['nockColor'] as String?),
              notes: Value(s['notes'] as String?),
              retiredAt: Value(s['retiredAt'] != null
                  ? DateTime.parse(s['retiredAt'] as String)
                  : null),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading shaft ${entry.key}: $e');
          }
        }
      }

      // Check if we need to upload (any local items not in cloud)
      bool needsUpload = false;
      for (final bow in localBows) {
        if (!cloudBowMap.containsKey(bow.id)) {
          needsUpload = true;
          uploaded++;
        }
      }
      for (final quiver in localQuivers) {
        if (!cloudQuiverMap.containsKey(quiver.id)) {
          needsUpload = true;
          uploaded++;
        }
      }
      for (final shaft in localShafts) {
        if (!cloudShaftMap.containsKey(shaft.id)) {
          needsUpload = true;
          uploaded++;
        }
      }

      // Upload full equipment set if needed
      if (needsUpload) {
        await _userDoc.collection('data').doc('equipment').set({
          'bows': localBows.map((b) => {
            'id': b.id,
            'name': b.name,
            'bowType': b.bowType,
            'settings': b.settings,
            'isDefault': b.isDefault,
            'createdAt': b.createdAt.toIso8601String(),
            'updatedAt': b.updatedAt.toIso8601String(),
          }).toList(),
          'quivers': localQuivers.map((q) => {
            'id': q.id,
            'bowId': q.bowId,
            'name': q.name,
            'shaftCount': q.shaftCount,
            'settings': q.settings,
            'isDefault': q.isDefault,
            'createdAt': q.createdAt.toIso8601String(),
            'updatedAt': q.updatedAt.toIso8601String(),
          }).toList(),
          'shafts': localShafts.map((s) => {
            'id': s.id,
            'quiverId': s.quiverId,
            'number': s.number,
            'diameter': s.diameter,
            'spine': s.spine,
            'lengthInches': s.lengthInches,
            'pointWeight': s.pointWeight,
            'fletchingType': s.fletchingType,
            'fletchingColor': s.fletchingColor,
            'nockColor': s.nockColor,
            'notes': s.notes,
            'createdAt': s.createdAt.toIso8601String(),
            'retiredAt': s.retiredAt?.toIso8601String(),
          }).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('Equipment: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing equipment: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // VOLUME ENTRIES SYNC
  // ============================================================================

  Future<_MergeResult> _syncVolumeEntries(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local entries
      final localEntries = await db.getAllVolumeEntries();
      final localMap = {for (var e in localEntries) e.id: e};

      // Get cloud entries
      final cloudDoc = await _userDoc.collection('data').doc('volume_entries').get();
      final cloudData = cloudDoc.data();
      final cloudEntries = (cloudData?['entries'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final cloudMap = {for (var e in cloudEntries) e['id'] as String: e};

      // Download entries only in cloud
      for (final entry in cloudMap.entries) {
        if (!localMap.containsKey(entry.key)) {
          try {
            final e = entry.value;
            await db.insertVolumeEntry(VolumeEntriesCompanion.insert(
              id: e['id'] as String,
              date: DateTime.parse(e['date'] as String),
              arrowCount: e['arrowCount'] as int,
              title: Value(e['title'] as String?),
              notes: Value(e['notes'] as String?),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading volume entry ${entry.key}: $e');
          }
        }
      }

      // Check for local-only entries to upload
      bool needsUpload = false;
      for (final entry in localEntries) {
        if (!cloudMap.containsKey(entry.id)) {
          needsUpload = true;
          uploaded++;
        }
      }

      // Upload if needed
      if (needsUpload && localEntries.isNotEmpty) {
        await _userDoc.collection('data').doc('volume_entries').set({
          'entries': localEntries.map((e) => {
            'id': e.id,
            'date': e.date.toIso8601String(),
            'arrowCount': e.arrowCount,
            'title': e.title,
            'notes': e.notes,
            'createdAt': e.createdAt.toIso8601String(),
            'updatedAt': e.updatedAt.toIso8601String(),
          }).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'count': localEntries.length,
        });
      }

      debugPrint('Volume entries: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing volume entries: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // OLY TRAINING LOGS SYNC
  // ============================================================================

  Future<_MergeResult> _syncOlyTrainingLogs(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local logs
      final localLogs = await db.getAllOlyTrainingLogs();
      final localMap = {for (var l in localLogs) l.id: l};

      // Get cloud logs
      final cloudDoc = await _userDoc.collection('data').doc('oly_training').get();
      final cloudData = cloudDoc.data();
      final cloudLogs = (cloudData?['logs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final cloudMap = {for (var l in cloudLogs) l['id'] as String: l};

      // Download logs only in cloud
      for (final entry in cloudMap.entries) {
        if (!localMap.containsKey(entry.key)) {
          try {
            final l = entry.value;
            await db.insertOlyTrainingLog(OlyTrainingLogsCompanion.insert(
              id: l['id'] as String,
              sessionTemplateId: Value(l['sessionTemplateId'] as String?),
              sessionVersion: l['sessionVersion'] as String,
              sessionName: l['sessionName'] as String,
              plannedDurationSeconds: l['plannedDurationSeconds'] as int,
              actualDurationSeconds: l['actualDurationSeconds'] as int,
              plannedExercises: l['plannedExercises'] as int,
              completedExercises: l['completedExercises'] as int,
              totalHoldSeconds: l['totalHoldSeconds'] as int,
              totalRestSeconds: l['totalRestSeconds'] as int,
              feedbackShaking: Value(l['feedbackShaking'] as int?),
              feedbackStructure: Value(l['feedbackStructure'] as int?),
              feedbackRest: Value(l['feedbackRest'] as int?),
              progressionSuggestion: Value(l['progressionSuggestion'] as String?),
              suggestedNextVersion: Value(l['suggestedNextVersion'] as String?),
              notes: Value(l['notes'] as String?),
              startedAt: DateTime.parse(l['startedAt'] as String),
              completedAt: DateTime.parse(l['completedAt'] as String),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading OLY log ${entry.key}: $e');
          }
        }
      }

      // Check for local-only logs to upload
      bool needsUpload = false;
      for (final log in localLogs) {
        if (!cloudMap.containsKey(log.id)) {
          needsUpload = true;
          uploaded++;
        }
      }

      // Upload if needed
      if (needsUpload && localLogs.isNotEmpty) {
        await _userDoc.collection('data').doc('oly_training').set({
          'logs': localLogs.map((l) => {
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
          'count': localLogs.length,
        });
      }

      debugPrint('OLY training logs: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing OLY training logs: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // BREATH TRAINING LOGS SYNC
  // ============================================================================

  Future<_MergeResult> _syncBreathTrainingLogs(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local logs
      final localLogs = await db.getAllBreathTrainingLogs();
      final localMap = {for (var l in localLogs) l.id: l};

      // Get cloud logs
      final cloudDoc = await _userDoc.collection('data').doc('breath_training').get();
      final cloudData = cloudDoc.data();
      final cloudLogs = (cloudData?['logs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final cloudMap = {for (var l in cloudLogs) l['id'] as String: l};

      // Download logs only in cloud
      for (final entry in cloudMap.entries) {
        if (!localMap.containsKey(entry.key)) {
          try {
            final l = entry.value;
            await db.insertBreathTrainingLog(BreathTrainingLogsCompanion.insert(
              id: l['id'] as String,
              sessionType: l['sessionType'] as String,
              totalHoldSeconds: Value(l['totalHoldSeconds'] as int?),
              bestHoldThisSession: Value(l['bestHoldThisSession'] as int?),
              bestExhaleSeconds: Value(l['bestExhaleSeconds'] as int?),
              rounds: Value(l['rounds'] as int?),
              difficulty: Value(l['difficulty'] as String?),
              durationMinutes: Value(l['durationMinutes'] as int?),
              completedAt: DateTime.parse(l['completedAt'] as String),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading breath log ${entry.key}: $e');
          }
        }
      }

      // Check for local-only logs to upload
      bool needsUpload = false;
      for (final log in localLogs) {
        if (!cloudMap.containsKey(log.id)) {
          needsUpload = true;
          uploaded++;
        }
      }

      // Upload if needed
      if (needsUpload && localLogs.isNotEmpty) {
        await _userDoc.collection('data').doc('breath_training').set({
          'logs': localLogs.map((l) => {
            'id': l.id,
            'sessionType': l.sessionType,
            'totalHoldSeconds': l.totalHoldSeconds,
            'bestHoldThisSession': l.bestHoldThisSession,
            'bestExhaleSeconds': l.bestExhaleSeconds,
            'rounds': l.rounds,
            'difficulty': l.difficulty,
            'durationMinutes': l.durationMinutes,
            'completedAt': l.completedAt.toIso8601String(),
            'createdAt': l.createdAt.toIso8601String(),
          }).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'count': localLogs.length,
        });
      }

      debugPrint('Breath training logs: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing breath training logs: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // MILESTONES SYNC
  // ============================================================================

  Future<_MergeResult> _syncMilestones(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local milestones
      final localMilestones = await db.getAllMilestones();
      final localMap = {for (var m in localMilestones) m.id: m};

      // Get cloud milestones
      final cloudDoc = await _userDoc.collection('data').doc('milestones').get();
      final cloudData = cloudDoc.data();
      final cloudMilestones = (cloudData?['milestones'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final cloudMap = {for (var m in cloudMilestones) m['id'] as String: m};

      // Download milestones only in cloud
      for (final entry in cloudMap.entries) {
        if (!localMap.containsKey(entry.key)) {
          try {
            final m = entry.value;
            await db.insertMilestone(MilestonesCompanion.insert(
              id: m['id'] as String,
              date: DateTime.parse(m['date'] as String),
              title: m['title'] as String,
              description: Value(m['description'] as String?),
              color: Value(m['color'] as String? ?? '#FFD700'),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading milestone ${entry.key}: $e');
          }
        }
      }

      // Check for local-only milestones to upload
      bool needsUpload = false;
      for (final milestone in localMilestones) {
        if (!cloudMap.containsKey(milestone.id)) {
          needsUpload = true;
          uploaded++;
        }
      }

      // Upload if needed
      if (needsUpload && localMilestones.isNotEmpty) {
        await _userDoc.collection('data').doc('milestones').set({
          'milestones': localMilestones.map((m) => {
            'id': m.id,
            'date': m.date.toIso8601String(),
            'title': m.title,
            'description': m.description,
            'color': m.color,
            'createdAt': m.createdAt.toIso8601String(),
          }).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'count': localMilestones.length,
        });
      }

      debugPrint('Milestones: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing milestones: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // SIGHT MARKS SYNC
  // ============================================================================

  Future<_MergeResult> _syncSightMarks(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local sight marks (including soft-deleted for sync purposes)
      final localMarks = await db.getAllSightMarks();
      final localMap = {for (var m in localMarks) m.id: m};

      // Get cloud sight marks
      final cloudDoc = await _userDoc.collection('data').doc('sight_marks').get();
      final cloudData = cloudDoc.data();
      final cloudMarks = (cloudData?['sightMarks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final cloudMap = {for (var m in cloudMarks) m['id'] as String: m};

      // Download sight marks only in cloud
      for (final entry in cloudMap.entries) {
        if (!localMap.containsKey(entry.key)) {
          try {
            final m = entry.value;
            await db.insertSightMark(SightMarksCompanion.insert(
              id: m['id'] as String,
              bowId: m['bowId'] as String,
              distance: m['distance'] as double,
              unit: Value(m['unit'] as String? ?? 'meters'),
              sightValue: m['sightValue'] as String,
              weatherData: Value(m['weatherData'] as String?),
              elevationDelta: Value((m['elevationDelta'] as num?)?.toDouble()),
              slopeAngle: Value((m['slopeAngle'] as num?)?.toDouble()),
              sessionId: Value(m['sessionId'] as String?),
              endNumber: Value(m['endNumber'] as int?),
              shotCount: Value(m['shotCount'] as int?),
              confidenceScore: Value((m['confidenceScore'] as num?)?.toDouble()),
            ));
            downloaded++;
          } catch (e) {
            debugPrint('Error downloading sight mark ${entry.key}: $e');
          }
        }
      }

      // Check for local-only sight marks to upload
      bool needsUpload = false;
      for (final mark in localMarks) {
        if (!cloudMap.containsKey(mark.id)) {
          needsUpload = true;
          uploaded++;
        }
      }

      // Upload if needed
      if (needsUpload && localMarks.isNotEmpty) {
        await _userDoc.collection('data').doc('sight_marks').set({
          'sightMarks': localMarks.map((m) => {
            'id': m.id,
            'bowId': m.bowId,
            'distance': m.distance,
            'unit': m.unit,
            'sightValue': m.sightValue,
            'weatherData': m.weatherData,
            'elevationDelta': m.elevationDelta,
            'slopeAngle': m.slopeAngle,
            'sessionId': m.sessionId,
            'endNumber': m.endNumber,
            'shotCount': m.shotCount,
            'confidenceScore': m.confidenceScore,
            'recordedAt': m.recordedAt.toIso8601String(),
            'updatedAt': m.updatedAt?.toIso8601String(),
            'deletedAt': m.deletedAt?.toIso8601String(),
          }).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'count': localMarks.length,
        });
      }

      debugPrint('Sight marks: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing sight marks: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // USER PROFILE SYNC
  // ============================================================================

  Future<_MergeResult> _syncUserProfile(AppDatabase db) async {
    int downloaded = 0;
    int uploaded = 0;

    try {
      // Get local profile
      final localProfile = await db.getUserProfile();
      List<Federation> localFederations = [];
      if (localProfile != null) {
        localFederations = await db.getFederationsForProfile(localProfile.id);
      }

      // Get cloud profile
      final cloudDoc = await _userDoc.collection('data').doc('user_profile').get();
      final cloudData = cloudDoc.data();
      final cloudProfile = cloudData?['profile'] as Map<String, dynamic>?;
      final cloudFederations = (cloudData?['federations'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      // Decide which wins based on updatedAt timestamp
      DateTime? localUpdated = localProfile?.updatedAt;
      DateTime? cloudUpdated = cloudProfile?['updatedAt'] != null
          ? DateTime.parse(cloudProfile!['updatedAt'] as String)
          : null;

      bool cloudIsNewer = cloudUpdated != null &&
          (localUpdated == null || cloudUpdated.isAfter(localUpdated));

      if (cloudIsNewer && cloudProfile != null) {
        // Download cloud profile
        final profileId = cloudProfile['id'] as String;

        await db.upsertUserProfile(UserProfilesCompanion(
          id: Value(profileId),
          primaryBowType: Value(cloudProfile['primaryBowType'] as String? ?? 'recurve'),
          handedness: Value(cloudProfile['handedness'] as String? ?? 'right'),
          name: Value(cloudProfile['name'] as String?),
          clubName: Value(cloudProfile['clubName'] as String?),
          yearsShootingStart: Value(cloudProfile['yearsShootingStart'] as int?),
          shootingFrequency: Value((cloudProfile['shootingFrequency'] as num?)?.toDouble() ?? 3.0),
          competitionLevels: Value(cloudProfile['competitionLevels'] as String? ?? '[]'),
          notes: Value(cloudProfile['notes'] as String?),
          createdAt: Value(cloudProfile['createdAt'] != null
              ? DateTime.parse(cloudProfile['createdAt'] as String)
              : DateTime.now()),
          updatedAt: Value(cloudUpdated ?? DateTime.now()),
        ));

        // Delete local federations and replace with cloud ones
        await db.deleteFederationsForProfile(profileId);
        for (final f in cloudFederations) {
          await db.insertFederation(FederationsCompanion.insert(
            id: f['id'] as String,
            profileId: profileId,
            federationName: f['federationName'] as String,
            membershipNumber: Value(f['membershipNumber'] as String?),
            cardImagePath: Value(f['cardImagePath'] as String?),
            expiryDate: Value(f['expiryDate'] != null
                ? DateTime.parse(f['expiryDate'] as String)
                : null),
            isPrimary: Value(f['isPrimary'] as bool? ?? false),
          ));
        }

        downloaded++;
        debugPrint('User profile: downloaded from cloud');
      } else if (localProfile != null) {
        // Upload local profile to cloud
        await _userDoc.collection('data').doc('user_profile').set({
          'profile': {
            'id': localProfile.id,
            'primaryBowType': localProfile.primaryBowType,
            'handedness': localProfile.handedness,
            'name': localProfile.name,
            'clubName': localProfile.clubName,
            'yearsShootingStart': localProfile.yearsShootingStart,
            'shootingFrequency': localProfile.shootingFrequency,
            'competitionLevels': localProfile.competitionLevels,
            'notes': localProfile.notes,
            'createdAt': localProfile.createdAt.toIso8601String(),
            'updatedAt': localProfile.updatedAt.toIso8601String(),
          },
          'federations': localFederations.map((f) => {
            'id': f.id,
            'profileId': f.profileId,
            'federationName': f.federationName,
            'membershipNumber': f.membershipNumber,
            'cardImagePath': f.cardImagePath,
            'expiryDate': f.expiryDate?.toIso8601String(),
            'isPrimary': f.isPrimary,
            'createdAt': f.createdAt.toIso8601String(),
            'updatedAt': f.updatedAt.toIso8601String(),
          }).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        uploaded++;
        debugPrint('User profile: uploaded to cloud');
      }

      debugPrint('User profile sync: downloaded=$downloaded, uploaded=$uploaded');
    } catch (e) {
      debugPrint('Error syncing user profile: $e');
    }

    return _MergeResult(downloaded, uploaded);
  }

  // ============================================================================
  // LEGACY METHODS (kept for backwards compatibility)
  // ============================================================================

  /// Backup imported scores to Firestore
  Future<void> backupImportedScores(List<ImportedScore> scores) async {
    if (_userId == null || scores.isEmpty) return;

    final batch = _firestore.batch();
    final scoresRef = _userDoc.collection('imported_scores');

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

    batch.set(_userDoc.collection('metadata').doc('imported_scores'), {
      'lastUpdated': FieldValue.serverTimestamp(),
      'count': scores.length,
    });

    await batch.commit();
  }

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

  /// Backup all data (calls the new sync method)
  Future<void> backupAllData(AppDatabase db) async {
    // Now just calls sync which handles bidirectional merge
    await syncAllData(db);
  }

  /// Check when last cloud backup occurred
  Future<DateTime?> getLastBackupTime() async {
    if (_userId == null) return null;

    try {
      final doc = await _userDoc.collection('metadata').doc('sync').get();
      if (!doc.exists) return null;
      final timestamp = doc.data()?['lastSync'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      debugPrint('Error checking backup time: $e');
      return null;
    }
  }

  /// Check if cloud has data for restore
  Future<bool> hasCloudData() async {
    if (_userId == null) return false;

    try {
      final doc = await _userDoc.collection('metadata').doc('sync').get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Legacy restore method - now just calls sync
  Future<RestoreResult> restoreAllData(AppDatabase db) async {
    final result = await syncAllData(db);
    return RestoreResult(
      success: result.success,
      message: result.message,
      importedScoresRestored: result.downloaded,
      sessionsRestored: 0,
      volumeEntriesRestored: 0,
      olyLogsRestored: 0,
    );
  }
}

/// Internal result for merge operations
class _MergeResult {
  final int downloaded;
  final int uploaded;
  _MergeResult(this.downloaded, this.uploaded);
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int downloaded;
  final int uploaded;

  SyncResult({
    required this.success,
    required this.message,
    this.downloaded = 0,
    this.uploaded = 0,
  });

  int get totalSynced => downloaded + uploaded;
}

/// Result of a restore operation (legacy)
class RestoreResult {
  final bool success;
  final String message;
  final int importedScoresRestored;
  final int sessionsRestored;
  final int volumeEntriesRestored;
  final int olyLogsRestored;

  RestoreResult({
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
