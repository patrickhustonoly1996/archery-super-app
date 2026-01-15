/// Mock database for testing providers and services
///
/// This provides a simple in-memory mock of the AppDatabase for testing
/// without requiring actual SQLite/Drift infrastructure.
library;

import 'package:archery_super_app/db/database.dart';
import 'package:drift/drift.dart';

/// Simple test data classes that mirror database types
class TestSession {
  final String id;
  final String roundTypeId;
  final String sessionType;
  final String? location;
  final String? notes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalScore;
  final int totalXs;
  final String? bowId;
  final String? quiverId;
  final bool shaftTaggingEnabled;

  TestSession({
    required this.id,
    required this.roundTypeId,
    this.sessionType = 'practice',
    this.location,
    this.notes,
    DateTime? startedAt,
    this.completedAt,
    this.totalScore = 0,
    this.totalXs = 0,
    this.bowId,
    this.quiverId,
    this.shaftTaggingEnabled = false,
  }) : startedAt = startedAt ?? DateTime.now();
}

class TestEnd {
  final String id;
  final String sessionId;
  final int endNumber;
  final int endScore;
  final int endXs;
  final String status;
  final DateTime? committedAt;
  final DateTime createdAt;

  TestEnd({
    required this.id,
    required this.sessionId,
    required this.endNumber,
    this.endScore = 0,
    this.endXs = 0,
    this.status = 'active',
    this.committedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class TestArrow {
  final String id;
  final String endId;
  final int faceIndex;
  final double x;
  final double y;
  final double xMm;
  final double yMm;
  final int score;
  final bool isX;
  final int sequence;
  final int? shaftNumber;
  final DateTime createdAt;

  TestArrow({
    required this.id,
    required this.endId,
    this.faceIndex = 0,
    this.x = 0.0,
    this.y = 0.0,
    this.xMm = 0.0,
    this.yMm = 0.0,
    required this.score,
    this.isX = false,
    required this.sequence,
    this.shaftNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class TestRoundType {
  final String id;
  final String name;
  final String category;
  final int distance;
  final int faceSize;
  final int arrowsPerEnd;
  final int totalEnds;
  final int maxScore;
  final bool isIndoor;
  final int faceCount;

  TestRoundType({
    required this.id,
    required this.name,
    required this.category,
    required this.distance,
    required this.faceSize,
    required this.arrowsPerEnd,
    required this.totalEnds,
    required this.maxScore,
    required this.isIndoor,
    this.faceCount = 1,
  });
}

class TestImportedScore {
  final String id;
  final DateTime date;
  final String roundName;
  final int score;
  final int? xCount;
  final String? location;
  final String? notes;
  final String sessionType;
  final String source;
  final DateTime importedAt;

  TestImportedScore({
    required this.id,
    required this.date,
    required this.roundName,
    required this.score,
    this.xCount,
    this.location,
    this.notes,
    this.sessionType = 'competition',
    this.source = 'manual',
    DateTime? importedAt,
  }) : importedAt = importedAt ?? DateTime.now();
}

class TestBow {
  final String id;
  final String name;
  final String bowType;
  final String? settings;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestBow({
    required this.id,
    required this.name,
    required this.bowType,
    this.settings,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

class TestQuiver {
  final String id;
  final String? bowId;
  final String name;
  final int shaftCount;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestQuiver({
    required this.id,
    this.bowId,
    required this.name,
    this.shaftCount = 12,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

class TestShaft {
  final String id;
  final String quiverId;
  final int number;
  final String? diameter;
  final String? notes;
  final DateTime createdAt;
  final DateTime? retiredAt;

  TestShaft({
    required this.id,
    required this.quiverId,
    required this.number,
    this.diameter,
    this.notes,
    DateTime? createdAt,
    this.retiredAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class TestVolumeEntry {
  final String id;
  final DateTime date;
  final int arrowCount;
  final String? title;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestVolumeEntry({
    required this.id,
    required this.date,
    required this.arrowCount,
    this.title,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

class TestOlyTrainingLog {
  final String id;
  final String? sessionTemplateId;
  final String sessionVersion;
  final String sessionName;
  final int plannedDurationSeconds;
  final int actualDurationSeconds;
  final int plannedExercises;
  final int completedExercises;
  final int totalHoldSeconds;
  final int totalRestSeconds;
  final int? feedbackShaking;
  final int? feedbackStructure;
  final int? feedbackRest;
  final String? progressionSuggestion;
  final String? suggestedNextVersion;
  final String? notes;
  final DateTime startedAt;
  final DateTime completedAt;

  TestOlyTrainingLog({
    required this.id,
    this.sessionTemplateId,
    required this.sessionVersion,
    required this.sessionName,
    required this.plannedDurationSeconds,
    required this.actualDurationSeconds,
    required this.plannedExercises,
    required this.completedExercises,
    required this.totalHoldSeconds,
    required this.totalRestSeconds,
    this.feedbackShaking,
    this.feedbackStructure,
    this.feedbackRest,
    this.progressionSuggestion,
    this.suggestedNextVersion,
    this.notes,
    required this.startedAt,
    required this.completedAt,
  });
}

/// Mock implementation of AppDatabase for testing
///
/// This stores data in-memory using simple Lists and Maps,
/// allowing tests to run without actual database infrastructure.
class MockAppDatabase {
  // In-memory storage
  final List<TestSession> _sessions = [];
  final List<TestEnd> _ends = [];
  final List<TestArrow> _arrows = [];
  final List<TestRoundType> _roundTypes = [];
  final List<TestImportedScore> _importedScores = [];
  final List<TestBow> _bows = [];
  final List<TestQuiver> _quivers = [];
  final List<TestShaft> _shafts = [];
  final List<TestVolumeEntry> _volumeEntries = [];
  final List<TestOlyTrainingLog> _olyTrainingLogs = [];
  final Map<String, String> _preferences = {};

  // ============================================================================
  // ROUND TYPES
  // ============================================================================

  Future<List<TestRoundType>> getAllRoundTypes() async => List.from(_roundTypes);

  Future<TestRoundType?> getRoundType(String id) async {
    try {
      return _roundTypes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void seedRoundType(TestRoundType roundType) {
    _roundTypes.add(roundType);
  }

  // ============================================================================
  // SESSIONS
  // ============================================================================

  Future<List<TestSession>> getAllSessions() async {
    final sorted = List<TestSession>.from(_sessions);
    sorted.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted;
  }

  Future<List<TestSession>> getCompletedSessions() async {
    final completed = _sessions.where((s) => s.completedAt != null).toList();
    completed.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return completed;
  }

  Future<TestSession?> getSession(String id) async {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TestSession?> getIncompleteSession() async {
    try {
      return _sessions.firstWhere((s) => s.completedAt == null);
    } catch (_) {
      return null;
    }
  }

  Future<int> insertSession(TestSession session) async {
    _sessions.add(session);
    return 1;
  }

  Future<int> deleteSession(String sessionId) async {
    final endIds = _ends.where((e) => e.sessionId == sessionId).map((e) => e.id).toList();
    _arrows.removeWhere((a) => endIds.contains(a.endId));
    _ends.removeWhere((e) => e.sessionId == sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
    return 1;
  }

  Future<int> completeSession(String sessionId, int totalScore, int totalXs) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      final old = _sessions[index];
      _sessions[index] = TestSession(
        id: old.id,
        roundTypeId: old.roundTypeId,
        sessionType: old.sessionType,
        location: old.location,
        notes: old.notes,
        startedAt: old.startedAt,
        completedAt: DateTime.now(),
        totalScore: totalScore,
        totalXs: totalXs,
        bowId: old.bowId,
        quiverId: old.quiverId,
        shaftTaggingEnabled: old.shaftTaggingEnabled,
      );
      return 1;
    }
    return 0;
  }

  // ============================================================================
  // ENDS
  // ============================================================================

  Future<List<TestEnd>> getEndsForSession(String sessionId) async {
    final sessionEnds = _ends.where((e) => e.sessionId == sessionId).toList();
    sessionEnds.sort((a, b) => a.endNumber.compareTo(b.endNumber));
    return sessionEnds;
  }

  Future<TestEnd?> getEnd(String id) async {
    try {
      return _ends.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TestEnd?> getCurrentEnd(String sessionId) async {
    try {
      return _ends.firstWhere(
        (e) => e.sessionId == sessionId && e.status == 'active',
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> insertEnd(TestEnd end) async {
    _ends.add(end);
    return 1;
  }

  Future<int> commitEnd(String endId, int score, int xs) async {
    final index = _ends.indexWhere((e) => e.id == endId);
    if (index >= 0) {
      final old = _ends[index];
      _ends[index] = TestEnd(
        id: old.id,
        sessionId: old.sessionId,
        endNumber: old.endNumber,
        endScore: score,
        endXs: xs,
        status: 'committed',
        committedAt: DateTime.now(),
        createdAt: old.createdAt,
      );
      return 1;
    }
    return 0;
  }

  // ============================================================================
  // ARROWS
  // ============================================================================

  Future<List<TestArrow>> getArrowsForEnd(String endId) async {
    final endArrows = _arrows.where((a) => a.endId == endId).toList();
    endArrows.sort((a, b) => a.sequence.compareTo(b.sequence));
    return endArrows;
  }

  Future<List<TestArrow>> getArrowsForSession(String sessionId) async {
    final sessionEnds = await getEndsForSession(sessionId);
    final endIds = sessionEnds.map((e) => e.id).toSet();
    final sessionArrows = _arrows.where((a) => endIds.contains(a.endId)).toList();
    sessionArrows.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sessionArrows;
  }

  Future<int> insertArrow(TestArrow arrow) async {
    _arrows.add(arrow);
    return 1;
  }

  Future<int> deleteArrow(String arrowId) async {
    _arrows.removeWhere((a) => a.id == arrowId);
    return 1;
  }

  Future<int> deleteLastArrowInEnd(String endId) async {
    final endArrows = await getArrowsForEnd(endId);
    if (endArrows.isEmpty) return 0;
    return deleteArrow(endArrows.last.id);
  }

  // ============================================================================
  // IMPORTED SCORES
  // ============================================================================

  Future<List<TestImportedScore>> getAllImportedScores() async {
    final sorted = List<TestImportedScore>.from(_importedScores);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  Future<int> insertImportedScore(TestImportedScore score) async {
    _importedScores.add(score);
    return 1;
  }

  Future<int> deleteImportedScore(String id) async {
    _importedScores.removeWhere((s) => s.id == id);
    return 1;
  }

  Future<bool> isDuplicateScore(DateTime date, int score) async {
    return _importedScores.any((s) =>
      s.date == date && s.score == score
    );
  }

  // ============================================================================
  // USER PREFERENCES
  // ============================================================================

  Future<String?> getPreference(String key) async => _preferences[key];

  Future<void> setPreference(String key, String value) async {
    _preferences[key] = value;
  }

  Future<bool> getBoolPreference(String key, {bool defaultValue = false}) async {
    final value = _preferences[key];
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> setBoolPreference(String key, bool value) async {
    _preferences[key] = value.toString();
  }

  // ============================================================================
  // BOWS
  // ============================================================================

  Future<List<TestBow>> getAllBows() async {
    final sorted = List<TestBow>.from(_bows);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<TestBow?> getBow(String id) async {
    try {
      return _bows.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TestBow?> getDefaultBow() async {
    try {
      return _bows.firstWhere((b) => b.isDefault);
    } catch (_) {
      return null;
    }
  }

  Future<int> insertBow(TestBow bow) async {
    _bows.add(bow);
    return 1;
  }

  Future<int> setDefaultBow(String bowId) async {
    for (int i = 0; i < _bows.length; i++) {
      final old = _bows[i];
      _bows[i] = TestBow(
        id: old.id,
        name: old.name,
        bowType: old.bowType,
        settings: old.settings,
        isDefault: old.id == bowId,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
    }
    return 1;
  }

  // ============================================================================
  // QUIVERS
  // ============================================================================

  Future<List<TestQuiver>> getAllQuivers() async {
    final sorted = List<TestQuiver>.from(_quivers);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<TestQuiver?> getQuiver(String id) async {
    try {
      return _quivers.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TestQuiver?> getDefaultQuiver() async {
    try {
      return _quivers.firstWhere((q) => q.isDefault);
    } catch (_) {
      return null;
    }
  }

  Future<int> insertQuiver(TestQuiver quiver) async {
    _quivers.add(quiver);
    return 1;
  }

  // ============================================================================
  // SHAFTS
  // ============================================================================

  Future<List<TestShaft>> getShaftsForQuiver(String quiverId) async {
    final quiverShafts = _shafts
        .where((s) => s.quiverId == quiverId && s.retiredAt == null)
        .toList();
    quiverShafts.sort((a, b) => a.number.compareTo(b.number));
    return quiverShafts;
  }

  Future<int> insertShaft(TestShaft shaft) async {
    _shafts.add(shaft);
    return 1;
  }

  // ============================================================================
  // VOLUME ENTRIES
  // ============================================================================

  Future<List<TestVolumeEntry>> getAllVolumeEntries() async {
    final sorted = List<TestVolumeEntry>.from(_volumeEntries);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  Future<TestVolumeEntry?> getVolumeEntryForDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    try {
      return _volumeEntries.firstWhere(
        (v) => v.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
               v.date.isBefore(dayEnd),
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> insertVolumeEntry(TestVolumeEntry entry) async {
    _volumeEntries.add(entry);
    return 1;
  }

  Future<int> deleteVolumeEntry(String id) async {
    _volumeEntries.removeWhere((v) => v.id == id);
    return 1;
  }

  // ============================================================================
  // OLY TRAINING LOGS
  // ============================================================================

  Future<List<TestOlyTrainingLog>> getAllOlyTrainingLogs() async {
    final sorted = List<TestOlyTrainingLog>.from(_olyTrainingLogs);
    sorted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted;
  }

  Future<int> insertOlyTrainingLog(TestOlyTrainingLog log) async {
    _olyTrainingLogs.add(log);
    return 1;
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  /// Clear all test data
  void clear() {
    _sessions.clear();
    _ends.clear();
    _arrows.clear();
    _roundTypes.clear();
    _importedScores.clear();
    _bows.clear();
    _quivers.clear();
    _shafts.clear();
    _volumeEntries.clear();
    _olyTrainingLogs.clear();
    _preferences.clear();
  }

  /// Seed standard round types for testing
  void seedStandardRoundTypes() {
    _roundTypes.addAll([
      TestRoundType(
        id: 'wa720_70m',
        name: 'WA 720 (70m)',
        category: 'wa_outdoor',
        distance: 70,
        faceSize: 122,
        arrowsPerEnd: 6,
        totalEnds: 12,
        maxScore: 720,
        isIndoor: false,
      ),
      TestRoundType(
        id: 'wa720_60m',
        name: 'WA 720 (60m)',
        category: 'wa_outdoor',
        distance: 60,
        faceSize: 122,
        arrowsPerEnd: 6,
        totalEnds: 12,
        maxScore: 720,
        isIndoor: false,
      ),
      TestRoundType(
        id: 'portsmouth',
        name: 'Portsmouth',
        category: 'wa_indoor',
        distance: 18,
        faceSize: 60,
        arrowsPerEnd: 3,
        totalEnds: 20,
        maxScore: 600,
        isIndoor: true,
      ),
      TestRoundType(
        id: 'wa_18m',
        name: 'WA 18m',
        category: 'wa_indoor',
        distance: 18,
        faceSize: 40,
        arrowsPerEnd: 3,
        totalEnds: 20,
        maxScore: 600,
        isIndoor: true,
      ),
    ]);
  }
}
