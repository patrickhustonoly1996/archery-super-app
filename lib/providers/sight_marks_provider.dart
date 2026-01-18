import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../models/sight_mark.dart' as model;
import '../models/weather_conditions.dart';
import '../utils/unique_id.dart';
import '../utils/sight_mark_calculator.dart';

class SightMarksProvider extends ChangeNotifier {
  final AppDatabase _db;

  SightMarksProvider(this._db);

  // Cached marks by bow ID
  final Map<String, List<model.SightMark>> _marksByBow = {};

  // Cached preferences by bow ID
  final Map<String, model.SightMarkPreferences> _prefsByBow = {};

  /// Get all cached marks for a bow
  List<model.SightMark> getMarksForBow(String bowId) {
    return _marksByBow[bowId] ?? [];
  }

  /// Get preferences for a bow
  model.SightMarkPreferences? getPreferencesForBow(String bowId) {
    return _prefsByBow[bowId];
  }

  /// Load sight marks for a specific bow
  Future<void> loadMarksForBow(String bowId) async {
    final dbMarks = await _db.getSightMarksForBow(bowId);
    _marksByBow[bowId] = dbMarks.map(_dbToModel).toList();

    final dbPrefs = await _db.getSightMarkPreferences(bowId);
    if (dbPrefs != null) {
      _prefsByBow[bowId] = model.SightMarkPreferences(
        bowId: dbPrefs.bowId,
        notationStyle: model.SightNotationStyle.fromString(dbPrefs.notationStyle),
        decimalPlaces: dbPrefs.decimalPlaces,
      );
    }

    notifyListeners();
  }

  /// Clear cache for a bow
  void clearCacheForBow(String bowId) {
    _marksByBow.remove(bowId);
    _prefsByBow.remove(bowId);
  }

  /// Add a new sight mark
  Future<String> addSightMark({
    required String bowId,
    required double distance,
    required model.DistanceUnit unit,
    required String sightValue,
    WeatherConditions? weather,
    double? elevationDelta,
    double? slopeAngle,
    String? sessionId,
    int? endNumber,
    int? shotCount,
    double? confidenceScore,
  }) async {
    final id = UniqueId.withPrefix('sm');

    await _db.insertSightMark(SightMarksCompanion.insert(
      id: id,
      bowId: bowId,
      distance: distance,
      unit: Value(unit.toDbString()),
      sightValue: sightValue,
      weatherData: Value(weather?.toJson()),
      elevationDelta: Value(elevationDelta),
      slopeAngle: Value(slopeAngle),
      sessionId: Value(sessionId),
      endNumber: Value(endNumber),
      shotCount: Value(shotCount),
      confidenceScore: Value(confidenceScore),
    ));

    await loadMarksForBow(bowId);
    return id;
  }

  /// Update an existing sight mark
  Future<void> updateSightMark({
    required String id,
    required String bowId,
    double? distance,
    model.DistanceUnit? unit,
    String? sightValue,
    WeatherConditions? weather,
    double? elevationDelta,
    double? slopeAngle,
    int? shotCount,
    double? confidenceScore,
  }) async {
    final existing = await _db.getSightMark(id);
    if (existing == null) return;

    await _db.updateSightMark(SightMarksCompanion(
      id: Value(id),
      bowId: Value(bowId),
      distance: Value(distance ?? existing.distance),
      unit: Value(unit?.toDbString() ?? existing.unit),
      sightValue: Value(sightValue ?? existing.sightValue),
      weatherData: Value(weather?.toJson() ?? existing.weatherData),
      elevationDelta: Value(elevationDelta ?? existing.elevationDelta),
      slopeAngle: Value(slopeAngle ?? existing.slopeAngle),
      sessionId: Value(existing.sessionId),
      endNumber: Value(existing.endNumber),
      shotCount: Value(shotCount ?? existing.shotCount),
      confidenceScore: Value(confidenceScore ?? existing.confidenceScore),
      recordedAt: Value(existing.recordedAt),
      updatedAt: Value(DateTime.now()),
    ));

    await loadMarksForBow(bowId);
  }

  /// Delete a sight mark (soft delete)
  Future<void> deleteSightMark(String id, String bowId) async {
    await _db.softDeleteSightMark(id);
    await loadMarksForBow(bowId);
  }

  /// Restore a soft-deleted sight mark
  Future<void> restoreSightMark(String id, String bowId) async {
    await _db.restoreSightMark(id);
    await loadMarksForBow(bowId);
  }

  /// Permanently delete a sight mark
  Future<void> permanentlyDeleteSightMark(String id, String bowId) async {
    await _db.deleteSightMark(id);
    await loadMarksForBow(bowId);
  }

  /// Set preferences for a bow
  Future<void> setPreferences({
    required String bowId,
    model.SightNotationStyle? notationStyle,
    int? decimalPlaces,
  }) async {
    await _db.setSightMarkPreferences(
      bowId: bowId,
      notationStyle: notationStyle?.toDbString(),
      decimalPlaces: decimalPlaces,
    );

    await loadMarksForBow(bowId);
  }

  // ===========================================================================
  // INTERPOLATION & PREDICTION
  // ===========================================================================

  /// Get exact mark or interpolated prediction for a distance
  /// Uses quadratic curve fitting with 3+ marks (matches ballistic reality),
  /// falls back to linear interpolation with 2 marks.
  ///
  /// Future enhancement: crowdsourced sight mark data from thousands of
  /// archers could provide accurate predictions for new users based on
  /// bow type, poundage, and arrow specs.
  model.PredictedSightMark? getPredictedMark({
    required String bowId,
    required double distance,
    required model.DistanceUnit unit,
  }) {
    final marks = getMarksForBow(bowId);
    if (marks.isEmpty) return null;

    // Use the calculator for smart prediction
    return SightMarkCalculator.predict(
      marks: marks,
      targetDistance: distance,
      unit: unit,
    );
  }

  /// Get curve coefficients for visualization (if 3+ marks available)
  /// Returns [a, b, c] where sightMark = a*distance² + b*distance + c
  List<double>? getCurveCoefficients(String bowId, model.DistanceUnit unit) {
    final marks = getMarksForBow(bowId);
    return SightMarkCalculator.getCurveCoefficients(marks, unit);
  }

  /// Get all predictions for common distances
  List<model.PredictedSightMark> getPredictionsForCommonDistances({
    required String bowId,
    required model.DistanceUnit unit,
  }) {
    final distances = unit == model.DistanceUnit.meters
        ? [18.0, 25.0, 30.0, 40.0, 50.0, 60.0, 70.0, 90.0]
        : [20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 100.0];

    return distances
        .map((d) => getPredictedMark(bowId: bowId, distance: d, unit: unit))
        .whereType<model.PredictedSightMark>()
        .toList();
  }

  // ===========================================================================
  // SIMILAR BOW SUGGESTIONS
  // ===========================================================================

  /// Find marks from similar bows (same type, similar poundage)
  Future<List<model.SightMark>> getSuggestionsFromSimilarBows({
    required String bowId,
    required double distance,
    required model.DistanceUnit unit,
    double poundageTolerance = 4.0, // lbs
  }) async {
    final targetBow = await _db.getBow(bowId);
    if (targetBow == null) return [];

    final allBows = await _db.getAllBows();
    final similarBows = allBows.where((b) =>
        b.id != bowId &&
        b.bowType == targetBow.bowType &&
        b.poundage != null &&
        targetBow.poundage != null &&
        (b.poundage! - targetBow.poundage!).abs() <= poundageTolerance);

    final suggestions = <model.SightMark>[];
    for (final bow in similarBows) {
      final mark = await _db.getLatestSightMarkAtDistance(
        bow.id,
        distance,
        unit.toDbString(),
      );
      if (mark != null) {
        suggestions.add(_dbToModel(mark));
      }
    }

    return suggestions;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  model.SightMark _dbToModel(SightMark db) {
    return model.SightMark(
      id: db.id,
      bowId: db.bowId,
      distance: db.distance,
      unit: model.DistanceUnit.fromString(db.unit),
      sightValue: db.sightValue,
      weather: db.weatherData != null
          ? WeatherConditions.fromJson(db.weatherData)
          : null,
      elevationDelta: db.elevationDelta,
      slopeAngle: db.slopeAngle,
      sessionId: db.sessionId,
      endNumber: db.endNumber,
      shotCount: db.shotCount,
      confidenceScore: db.confidenceScore,
      recordedAt: db.recordedAt,
      updatedAt: db.updatedAt,
      deletedAt: db.deletedAt,
    );
  }

  /// Format a sight value according to bow preferences
  String formatSightValue(String bowId, double value) {
    final prefs = getPreferencesForBow(bowId);
    final decimals = prefs?.decimalPlaces ?? 2;
    return value.toStringAsFixed(decimals);
  }
}
