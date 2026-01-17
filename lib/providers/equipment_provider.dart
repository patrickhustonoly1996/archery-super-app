import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../utils/unique_id.dart';
import '../utils/statistics.dart';
import '../models/bow_specifications.dart';
import '../models/arrow_specifications.dart';
import '../models/kit_snapshot.dart' as model;

class EquipmentProvider extends ChangeNotifier {
  final AppDatabase _db;

  EquipmentProvider(this._db);

  // Cached lists
  List<Bow> _bows = [];
  List<Quiver> _quivers = [];
  final Map<String, List<Shaft>> _shaftsByQuiver = {};

  List<Bow> get bows => _bows;
  List<Quiver> get quivers => _quivers;

  List<Shaft> getShaftsForQuiver(String quiverId) {
    return _shaftsByQuiver[quiverId] ?? [];
  }

  /// Load all equipment
  Future<void> loadEquipment() async {
    _bows = await _db.getAllBows();
    _quivers = await _db.getAllQuivers();

    // Load shafts for each quiver
    _shaftsByQuiver.clear();
    for (final quiver in _quivers) {
      _shaftsByQuiver[quiver.id] = await _db.getShaftsForQuiver(quiver.id);
    }

    notifyListeners();
  }

  /// Create a new bow
  Future<void> createBow({
    required String name,
    required String bowType,
    String? settings,
    bool setAsDefault = false,
  }) async {
    final bowId = UniqueId.generate();

    await _db.insertBow(BowsCompanion.insert(
      id: bowId,
      name: name,
      bowType: bowType,
      settings: Value(settings),
      isDefault: Value(setAsDefault),
    ));

    if (setAsDefault) {
      await _db.setDefaultBow(bowId);
    }

    await loadEquipment();
  }

  /// Create a new quiver with shafts
  Future<void> createQuiver({
    required String name,
    String? bowId,
    int shaftCount = 12,
    bool setAsDefault = false,
  }) async {
    final quiverId = UniqueId.generate();

    await _db.insertQuiver(QuiversCompanion.insert(
      id: quiverId,
      name: name,
      bowId: Value(bowId),
      shaftCount: Value(shaftCount),
      isDefault: Value(setAsDefault),
    ));

    // Create shafts for the quiver
    for (int i = 1; i <= shaftCount; i++) {
      final shaftId = '${quiverId}_shaft_$i';
      await _db.insertShaft(ShaftsCompanion.insert(
        id: shaftId,
        quiverId: quiverId,
        number: i,
      ));
    }

    if (setAsDefault) {
      await _db.setDefaultQuiver(quiverId);
    }

    await loadEquipment();
  }

  /// Update bow
  Future<void> updateBow({
    required String id,
    String? name,
    String? bowType,
    String? settings,
  }) async {
    final bow = await _db.getBow(id);
    if (bow == null) return;

    await _db.updateBow(BowsCompanion(
      id: Value(id),
      name: Value(name ?? bow.name),
      bowType: Value(bowType ?? bow.bowType),
      settings: Value(settings ?? bow.settings),
      isDefault: Value(bow.isDefault),
      createdAt: Value(bow.createdAt),
      updatedAt: Value(DateTime.now()),
    ));

    await loadEquipment();
  }

  /// Update quiver
  Future<void> updateQuiver({
    required String id,
    String? name,
    String? bowId,
    String? settings,
  }) async {
    final quiver = await _db.getQuiver(id);
    if (quiver == null) return;

    await _db.updateQuiver(QuiversCompanion(
      id: Value(id),
      name: Value(name ?? quiver.name),
      bowId: Value(bowId ?? quiver.bowId),
      shaftCount: Value(quiver.shaftCount),
      settings: Value(settings ?? quiver.settings),
      isDefault: Value(quiver.isDefault),
      createdAt: Value(quiver.createdAt),
      updatedAt: Value(DateTime.now()),
    ));

    await loadEquipment();
  }

  /// Retire/unretire shaft
  Future<void> toggleShaftRetirement(String shaftId, bool retire) async {
    if (retire) {
      await _db.retireShaft(shaftId);
    } else {
      await _db.unretireShaft(shaftId);
    }
    await loadEquipment();
  }

  /// Update shaft notes
  Future<void> updateShaftNotes(String shaftId, String notes) async {
    final shaft = await _db.getShaft(shaftId);
    if (shaft == null) return;

    await _db.updateShaft(ShaftsCompanion(
      id: Value(shaftId),
      notes: Value(notes),
    ));

    await loadEquipment();
  }

  /// Update shaft specifications
  Future<void> updateShaftSpecs({
    required String shaftId,
    int? spine,
    double? lengthInches,
    int? pointWeight,
    String? fletchingType,
    String? fletchingColor,
    String? nockColor,
    String? notes,
  }) async {
    final shaft = await _db.getShaft(shaftId);
    if (shaft == null) return;

    await _db.updateShaft(ShaftsCompanion(
      id: Value(shaftId),
      spine: Value(spine),
      lengthInches: Value(lengthInches),
      pointWeight: Value(pointWeight),
      fletchingType: Value(fletchingType),
      fletchingColor: Value(fletchingColor),
      nockColor: Value(nockColor),
      notes: Value(notes),
    ));

    await loadEquipment();
  }

  /// Batch update shaft specifications for multiple shafts
  Future<void> batchUpdateShaftSpecs({
    required List<String> shaftIds,
    int? spine,
    double? lengthInches,
    int? pointWeight,
    String? fletchingType,
    String? fletchingColor,
    String? nockColor,
  }) async {
    for (final shaftId in shaftIds) {
      final shaft = await _db.getShaft(shaftId);
      if (shaft == null) continue;

      await _db.updateShaft(ShaftsCompanion(
        id: Value(shaftId),
        spine: Value(spine),
        lengthInches: Value(lengthInches),
        pointWeight: Value(pointWeight),
        fletchingType: Value(fletchingType),
        fletchingColor: Value(fletchingColor),
        nockColor: Value(nockColor),
      ));
    }

    await loadEquipment();
  }

  /// Set default bow
  Future<void> setDefaultBow(String bowId) async {
    await _db.setDefaultBow(bowId);
    await loadEquipment();
  }

  /// Set default quiver
  Future<void> setDefaultQuiver(String quiverId) async {
    await _db.setDefaultQuiver(quiverId);
    await loadEquipment();
  }

  /// Soft delete bow (for undo support)
  Future<void> deleteBow(String bowId) async {
    await _db.softDeleteBow(bowId);
    await loadEquipment();
  }

  /// Restore soft-deleted bow
  Future<void> restoreBow(String bowId) async {
    await _db.restoreBow(bowId);
    await loadEquipment();
  }

  /// Permanently delete bow
  Future<void> permanentlyDeleteBow(String bowId) async {
    await _db.deleteBow(bowId);
    await loadEquipment();
  }

  /// Soft delete quiver (for undo support)
  Future<void> deleteQuiver(String quiverId) async {
    await _db.softDeleteQuiver(quiverId);
    await loadEquipment();
  }

  /// Restore soft-deleted quiver
  Future<void> restoreQuiver(String quiverId) async {
    await _db.restoreQuiver(quiverId);
    await loadEquipment();
  }

  /// Permanently delete quiver
  Future<void> permanentlyDeleteQuiver(String quiverId) async {
    await _db.deleteQuiver(quiverId);
    await loadEquipment();
  }

  // ===========================================================================
  // KIT SNAPSHOTS
  // ===========================================================================

  /// Check if a score is in the top 20% of historical scores for the same round
  /// Returns null if not enough data (<5 sessions)
  Future<bool?> isTopPercentileScore(int score, String roundTypeId) async {
    final historicalScores = await _db.getCompletedSessionScoresForRound(roundTypeId);
    return isTopPercentile(score, historicalScores, topPercent: 20);
  }

  /// Save a kit snapshot for a notable score
  Future<void> saveKitSnapshot({
    required String sessionId,
    required String? bowId,
    required String? quiverId,
    required int score,
    required int maxScore,
    required String roundName,
    required String reason,
    String? notes,
  }) async {
    final bow = bowId != null ? await _db.getBow(bowId) : null;
    final quiver = quiverId != null ? await _db.getQuiver(quiverId) : null;

    final bowSpecs = bow?.settings != null
        ? BowSpecifications.fromJson(bow!.settings)
        : null;
    final arrowSpecs = quiver?.settings != null
        ? ArrowSpecifications.fromJson(quiver!.settings)
        : null;

    await _db.insertKitSnapshot(KitSnapshotsCompanion.insert(
      id: UniqueId.generate(),
      sessionId: Value(sessionId),
      bowId: Value(bowId),
      quiverId: Value(quiverId),
      snapshotDate: DateTime.now(),
      score: Value(score),
      maxScore: Value(maxScore),
      roundName: Value(roundName),
      reason: Value(reason),
      bowName: Value(bow?.name),
      bowType: Value(bow?.bowType),
      bowSettings: Value(bowSpecs?.toJson()),
      quiverName: Value(quiver?.name),
      arrowSettings: Value(arrowSpecs?.toJson()),
      notes: Value(notes),
    ));
  }

  /// Get all kit snapshots
  Future<List<model.KitSnapshot>> getAllKitSnapshots() async {
    final snapshots = await _db.getAllKitSnapshots();
    return snapshots.map(_dbToModelKitSnapshot).toList();
  }

  /// Get kit snapshots for a specific bow
  Future<List<model.KitSnapshot>> getKitSnapshotsForBow(String bowId) async {
    final snapshots = await _db.getKitSnapshotsForBow(bowId);
    return snapshots.map(_dbToModelKitSnapshot).toList();
  }

  /// Delete a kit snapshot
  Future<void> deleteKitSnapshot(String id) async {
    await _db.deleteKitSnapshot(id);
  }

  /// Convert database KitSnapshot to model KitSnapshot
  model.KitSnapshot _dbToModelKitSnapshot(KitSnapshot db) {
    return model.KitSnapshot(
      id: db.id,
      sessionId: db.sessionId,
      bowId: db.bowId,
      quiverId: db.quiverId,
      snapshotDate: db.snapshotDate,
      score: db.score,
      maxScore: db.maxScore,
      roundName: db.roundName,
      reason: db.reason,
      bowName: db.bowName,
      bowType: db.bowType,
      bowSpecs: db.bowSettings != null
          ? BowSpecifications.fromJson(db.bowSettings)
          : null,
      quiverName: db.quiverName,
      arrowSpecs: db.arrowSettings != null
          ? ArrowSpecifications.fromJson(db.arrowSettings)
          : null,
      notes: db.notes,
    );
  }
}
