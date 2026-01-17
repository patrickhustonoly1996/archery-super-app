import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../utils/unique_id.dart';

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
}
