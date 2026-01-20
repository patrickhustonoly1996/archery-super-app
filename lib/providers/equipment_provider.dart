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

  // Cached defaults
  Bow? _defaultBow;
  Quiver? _defaultQuiver;

  List<Bow> get bows => _bows;
  List<Quiver> get quivers => _quivers;
  Bow? get defaultBow => _defaultBow;
  Quiver? get defaultQuiver => _defaultQuiver;

  List<Shaft> getShaftsForQuiver(String quiverId) {
    return _shaftsByQuiver[quiverId] ?? [];
  }

  /// Load all equipment
  Future<void> loadEquipment() async {
    _bows = await _db.getAllBows();
    _quivers = await _db.getAllQuivers();

    // Load defaults
    _defaultBow = await _db.getDefaultBow();
    _defaultQuiver = await _db.getDefaultQuiver();

    // Load shafts for each quiver (parallel for performance)
    _shaftsByQuiver.clear();
    await Future.wait(
      _quivers.map((quiver) async {
        _shaftsByQuiver[quiver.id] = await _db.getShaftsForQuiver(quiver.id);
      }),
    );

    notifyListeners();
  }

  /// Get a specific bow by ID
  Future<Bow?> getBow(String id) async {
    return await _db.getBow(id);
  }

  /// Create a new bow with all tuning data
  Future<String> createBow({
    required String name,
    required String bowType,
    String? settings,
    bool setAsDefault = false,
    // Equipment details
    String? riserModel,
    DateTime? riserPurchaseDate,
    String? limbModel,
    DateTime? limbPurchaseDate,
    double? poundage,
    // Tuning settings
    double? tillerTop,
    double? tillerBottom,
    double? braceHeight,
    double? nockingPointHeight,
    double? buttonPosition,
    String? buttonTension,
    double? clickerPosition,
  }) async {
    final bowId = UniqueId.generate();

    await _db.insertBow(BowsCompanion.insert(
      id: bowId,
      name: name,
      bowType: bowType,
      settings: Value(settings),
      isDefault: Value(setAsDefault),
      riserModel: Value(riserModel),
      riserPurchaseDate: Value(riserPurchaseDate),
      limbModel: Value(limbModel),
      limbPurchaseDate: Value(limbPurchaseDate),
      poundage: Value(poundage),
      tillerTop: Value(tillerTop),
      tillerBottom: Value(tillerBottom),
      braceHeight: Value(braceHeight),
      nockingPointHeight: Value(nockingPointHeight),
      buttonPosition: Value(buttonPosition),
      buttonTension: Value(buttonTension),
      clickerPosition: Value(clickerPosition),
    ));

    if (setAsDefault) {
      await _db.setDefaultBow(bowId);
    }

    await loadEquipment();
    return bowId;
  }

  /// Create a new quiver with shafts (atomically in a transaction)
  Future<void> createQuiver({
    required String name,
    String? bowId,
    int shaftCount = 12,
    bool setAsDefault = false,
  }) async {
    final quiverId = UniqueId.generate();

    // Build shaft companions list
    final shaftsList = <ShaftsCompanion>[];
    for (int i = 1; i <= shaftCount; i++) {
      shaftsList.add(ShaftsCompanion.insert(
        id: '${quiverId}_shaft_$i',
        quiverId: quiverId,
        number: i,
      ));
    }

    // Create quiver and shafts atomically
    await _db.createQuiverWithShafts(
      quiver: QuiversCompanion.insert(
        id: quiverId,
        name: name,
        bowId: Value(bowId),
        shaftCount: Value(shaftCount),
        isDefault: Value(setAsDefault),
      ),
      shaftsList: shaftsList,
    );

    if (setAsDefault) {
      await _db.setDefaultQuiver(quiverId);
    }

    await loadEquipment();
  }

  /// Update bow with all tuning data
  Future<void> updateBow({
    required String id,
    String? name,
    String? bowType,
    String? settings,
    // Equipment details
    String? riserModel,
    DateTime? riserPurchaseDate,
    String? limbModel,
    DateTime? limbPurchaseDate,
    double? poundage,
    // Tuning settings
    double? tillerTop,
    double? tillerBottom,
    double? braceHeight,
    double? nockingPointHeight,
    double? buttonPosition,
    String? buttonTension,
    double? clickerPosition,
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
      // Equipment details
      riserModel: Value(riserModel ?? bow.riserModel),
      riserPurchaseDate: Value(riserPurchaseDate ?? bow.riserPurchaseDate),
      limbModel: Value(limbModel ?? bow.limbModel),
      limbPurchaseDate: Value(limbPurchaseDate ?? bow.limbPurchaseDate),
      poundage: Value(poundage ?? bow.poundage),
      // Tuning settings
      tillerTop: Value(tillerTop ?? bow.tillerTop),
      tillerBottom: Value(tillerBottom ?? bow.tillerBottom),
      braceHeight: Value(braceHeight ?? bow.braceHeight),
      nockingPointHeight: Value(nockingPointHeight ?? bow.nockingPointHeight),
      buttonPosition: Value(buttonPosition ?? bow.buttonPosition),
      buttonTension: Value(buttonTension ?? bow.buttonTension),
      clickerPosition: Value(clickerPosition ?? bow.clickerPosition),
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
    // New v14 fields
    double? totalWeight,
    String? pointType,
    String? nockBrand,
    String? fletchingSize,
    double? fletchingAngle,
    bool? hasWrap,
    String? wrapColor,
    DateTime? purchaseDate,
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
      totalWeight: Value(totalWeight),
      pointType: Value(pointType),
      nockBrand: Value(nockBrand),
      fletchingSize: Value(fletchingSize),
      fletchingAngle: Value(fletchingAngle),
      hasWrap: Value(hasWrap),
      wrapColor: Value(wrapColor),
      purchaseDate: Value(purchaseDate),
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
    // New v14 fields
    double? totalWeight,
    String? pointType,
    String? nockBrand,
    String? fletchingSize,
    double? fletchingAngle,
    bool? hasWrap,
    String? wrapColor,
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
        totalWeight: Value(totalWeight),
        pointType: Value(pointType),
        nockBrand: Value(nockBrand),
        fletchingSize: Value(fletchingSize),
        fletchingAngle: Value(fletchingAngle),
        hasWrap: Value(hasWrap),
        wrapColor: Value(wrapColor),
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
  // STABILIZERS
  // ===========================================================================

  /// Get stabilizers for a bow
  Future<List<Stabilizer>> getStabilizersForBow(String bowId) async {
    return (_db.select(_db.stabilizers)
          ..where((t) => t.bowId.equals(bowId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Create a new stabilizer setup
  Future<String> createStabilizer({
    required String bowId,
    String? name,
    // Long rod
    String? longRodModel,
    double? longRodLength,
    double? longRodWeight,
    String? longRodWeights,
    // Left side rod
    String? leftSideRodModel,
    double? leftSideRodLength,
    double? leftSideRodWeight,
    String? leftWeights,
    double? leftAngleHorizontal,
    double? leftAngleVertical,
    // Right side rod
    String? rightSideRodModel,
    double? rightSideRodLength,
    double? rightSideRodWeight,
    String? rightWeights,
    double? rightAngleHorizontal,
    double? rightAngleVertical,
    // Legacy (kept for compatibility)
    String? sideRodModel,
    double? sideRodLength,
    double? sideRodWeight,
    // Other
    double? extenderLength,
    String? vbarModel,
    double? vbarAngleHorizontal,
    double? vbarAngleVertical,
    String? weightArrangement,
    String? damperModel,
    String? damperPositions,
    String? setupPhotoPath,
    String? notes,
  }) async {
    final id = UniqueId.generate();
    await _db.into(_db.stabilizers).insert(StabilizersCompanion.insert(
      id: id,
      bowId: bowId,
      name: Value(name),
      longRodModel: Value(longRodModel),
      longRodLength: Value(longRodLength),
      longRodWeight: Value(longRodWeight),
      longRodWeights: Value(longRodWeights),
      leftSideRodModel: Value(leftSideRodModel),
      leftSideRodLength: Value(leftSideRodLength),
      leftSideRodWeight: Value(leftSideRodWeight),
      leftWeights: Value(leftWeights),
      leftAngleHorizontal: Value(leftAngleHorizontal),
      leftAngleVertical: Value(leftAngleVertical),
      rightSideRodModel: Value(rightSideRodModel),
      rightSideRodLength: Value(rightSideRodLength),
      rightSideRodWeight: Value(rightSideRodWeight),
      rightWeights: Value(rightWeights),
      rightAngleHorizontal: Value(rightAngleHorizontal),
      rightAngleVertical: Value(rightAngleVertical),
      sideRodModel: Value(sideRodModel),
      sideRodLength: Value(sideRodLength),
      sideRodWeight: Value(sideRodWeight),
      extenderLength: Value(extenderLength),
      vbarModel: Value(vbarModel),
      vbarAngleHorizontal: Value(vbarAngleHorizontal),
      vbarAngleVertical: Value(vbarAngleVertical),
      weightArrangement: Value(weightArrangement),
      damperModel: Value(damperModel),
      damperPositions: Value(damperPositions),
      setupPhotoPath: Value(setupPhotoPath),
      notes: Value(notes),
    ));
    return id;
  }

  /// Update a stabilizer setup
  Future<void> updateStabilizer({
    required String id,
    String? name,
    // Long rod
    String? longRodModel,
    double? longRodLength,
    double? longRodWeight,
    String? longRodWeights,
    // Left side rod
    String? leftSideRodModel,
    double? leftSideRodLength,
    double? leftSideRodWeight,
    String? leftWeights,
    double? leftAngleHorizontal,
    double? leftAngleVertical,
    // Right side rod
    String? rightSideRodModel,
    double? rightSideRodLength,
    double? rightSideRodWeight,
    String? rightWeights,
    double? rightAngleHorizontal,
    double? rightAngleVertical,
    // Legacy
    String? sideRodModel,
    double? sideRodLength,
    double? sideRodWeight,
    // Other
    double? extenderLength,
    String? vbarModel,
    double? vbarAngleHorizontal,
    double? vbarAngleVertical,
    String? weightArrangement,
    String? damperModel,
    String? damperPositions,
    String? setupPhotoPath,
    String? notes,
  }) async {
    await (_db.update(_db.stabilizers)..where((t) => t.id.equals(id))).write(
      StabilizersCompanion(
        name: Value(name),
        longRodModel: Value(longRodModel),
        longRodLength: Value(longRodLength),
        longRodWeight: Value(longRodWeight),
        longRodWeights: Value(longRodWeights),
        leftSideRodModel: Value(leftSideRodModel),
        leftSideRodLength: Value(leftSideRodLength),
        leftSideRodWeight: Value(leftSideRodWeight),
        leftWeights: Value(leftWeights),
        leftAngleHorizontal: Value(leftAngleHorizontal),
        leftAngleVertical: Value(leftAngleVertical),
        rightSideRodModel: Value(rightSideRodModel),
        rightSideRodLength: Value(rightSideRodLength),
        rightSideRodWeight: Value(rightSideRodWeight),
        rightWeights: Value(rightWeights),
        rightAngleHorizontal: Value(rightAngleHorizontal),
        rightAngleVertical: Value(rightAngleVertical),
        sideRodModel: Value(sideRodModel),
        sideRodLength: Value(sideRodLength),
        sideRodWeight: Value(sideRodWeight),
        extenderLength: Value(extenderLength),
        vbarModel: Value(vbarModel),
        vbarAngleHorizontal: Value(vbarAngleHorizontal),
        vbarAngleVertical: Value(vbarAngleVertical),
        weightArrangement: Value(weightArrangement),
        damperModel: Value(damperModel),
        damperPositions: Value(damperPositions),
        setupPhotoPath: Value(setupPhotoPath),
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a stabilizer setup
  Future<void> deleteStabilizer(String id) async {
    await (_db.delete(_db.stabilizers)..where((t) => t.id.equals(id))).go();
  }

  // ===========================================================================
  // BOW STRINGS
  // ===========================================================================

  /// Get strings for a bow
  Future<List<BowString>> getStringsForBow(String bowId) async {
    return (_db.select(_db.bowStrings)
          ..where((t) => t.bowId.equals(bowId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Create a new bow string
  Future<String> createBowString({
    required String bowId,
    String? name,
    String? material,
    int? strandCount,
    String? servingMaterial,
    double? stringLength,
    String? color,
    DateTime? purchaseDate,
    String? notes,
  }) async {
    final id = UniqueId.generate();
    await _db.into(_db.bowStrings).insert(BowStringsCompanion.insert(
      id: id,
      bowId: bowId,
      name: Value(name),
      material: Value(material),
      strandCount: Value(strandCount),
      servingMaterial: Value(servingMaterial),
      stringLength: Value(stringLength),
      color: Value(color),
      purchaseDate: Value(purchaseDate),
      notes: Value(notes),
    ));
    return id;
  }

  /// Update a bow string
  Future<void> updateBowString({
    required String id,
    String? name,
    String? material,
    int? strandCount,
    String? servingMaterial,
    double? stringLength,
    String? color,
    bool? isActive,
    DateTime? purchaseDate,
    DateTime? retiredAt,
    String? notes,
  }) async {
    await (_db.update(_db.bowStrings)..where((t) => t.id.equals(id))).write(
      BowStringsCompanion(
        name: Value(name),
        material: Value(material),
        strandCount: Value(strandCount),
        servingMaterial: Value(servingMaterial),
        stringLength: Value(stringLength),
        color: Value(color),
        isActive: Value(isActive ?? true),
        purchaseDate: Value(purchaseDate),
        retiredAt: Value(retiredAt),
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a bow string
  Future<void> deleteBowString(String id) async {
    await (_db.delete(_db.bowStrings)..where((t) => t.id.equals(id))).go();
  }

  /// Set a string as active (retire others)
  Future<void> setActiveString(String bowId, String stringId) async {
    // Deactivate all strings for this bow
    await (_db.update(_db.bowStrings)..where((t) => t.bowId.equals(bowId)))
        .write(const BowStringsCompanion(isActive: Value(false)));
    // Activate the selected string
    await (_db.update(_db.bowStrings)..where((t) => t.id.equals(stringId)))
        .write(const BowStringsCompanion(isActive: Value(true)));
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
