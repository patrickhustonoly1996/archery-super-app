import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../models/angle_correction_profile.dart' as model;
import '../models/user_profile.dart';
import '../models/sight_mark.dart';
import '../utils/unique_id.dart';
import '../utils/angle_sight_mark_calculator.dart';

/// Provider for angle-based sight mark calculations and learning.
///
/// Manages angle correction profiles per bow, including:
/// - Arrow speed estimation from equipment
/// - Angle-corrected sight mark calculations
/// - Learning from actual field results
class AngleSightMarkProvider extends ChangeNotifier {
  final AppDatabase _db;

  AngleSightMarkProvider(this._db);

  // Cached profiles by bow ID
  final Map<String, model.AngleCorrectionProfile> _profilesByBow = {};

  /// Get cached profile for a bow (may be null if not loaded)
  model.AngleCorrectionProfile? getProfileForBow(String bowId) {
    return _profilesByBow[bowId];
  }

  /// Load or create angle correction profile for a bow
  Future<model.AngleCorrectionProfile> loadProfileForBow(
    String bowId, {
    BowType? bowType,
    double? poundage,
    double? drawLength,
  }) async {
    final dbProfile = await _db.getAngleCorrectionProfile(bowId);

    if (dbProfile != null) {
      final profile = _dbToModel(dbProfile);
      _profilesByBow[bowId] = profile;
      notifyListeners();
      return profile;
    }

    // Create default profile
    double arrowSpeed = 220.0; // Default moderate speed
    if (bowType != null && poundage != null) {
      arrowSpeed = AngleSightMarkCalculator.estimateArrowSpeed(
        bowType: bowType,
        poundage: poundage,
        drawLength: drawLength,
      );
    }

    final profile = model.AngleCorrectionProfile.defaultForSpeed(
      id: UniqueId.withPrefix('acp'),
      bowId: bowId,
      arrowSpeedFps: arrowSpeed,
    );

    // Save to database
    await _db.upsertAngleCorrectionProfile(
      id: profile.id,
      bowId: profile.bowId,
      arrowSpeedFps: profile.arrowSpeedFps,
      uphillFactor: profile.uphillFactor,
      downhillFactor: profile.downhillFactor,
      uphillDataPoints: profile.uphillDataPoints,
      downhillDataPoints: profile.downhillDataPoints,
      confidenceScore: profile.confidenceScore,
    );

    _profilesByBow[bowId] = profile;
    notifyListeners();
    return profile;
  }

  /// Get sight mark for a specific angle.
  ///
  /// Uses learned factors if available, otherwise calculates from defaults.
  Future<double> getSightMarkForAngle({
    required String bowId,
    required double flatSightMark,
    required double angleDegrees,
    BowType? bowType,
    double? poundage,
    double? drawLength,
  }) async {
    var profile = _profilesByBow[bowId];
    if (profile == null) {
      profile = await loadProfileForBow(
        bowId,
        bowType: bowType,
        poundage: poundage,
        drawLength: drawLength,
      );
    }

    // Use learned factors if available, otherwise use speed-based calculation
    if (profile.hasLearnedData) {
      return _calculateWithLearnedFactors(
        flatSightMark: flatSightMark,
        angleDegrees: angleDegrees,
        uphillFactor: profile.uphillFactor,
        downhillFactor: profile.downhillFactor,
      );
    }

    return AngleSightMarkCalculator.getSightMarkForAngle(
      flatSightMark: flatSightMark,
      angleDegrees: angleDegrees,
      arrowSpeedFps: profile.arrowSpeedFps,
    );
  }

  /// Generate full angle table for a distance.
  Future<List<AngleTableEntry>> getAngleTable({
    required String bowId,
    required double flatSightMark,
    BowType? bowType,
    double? poundage,
    double? drawLength,
    List<double>? angles,
  }) async {
    var profile = _profilesByBow[bowId];
    if (profile == null) {
      profile = await loadProfileForBow(
        bowId,
        bowType: bowType,
        poundage: poundage,
        drawLength: drawLength,
      );
    }

    return AngleSightMarkCalculator.generateAngleTable(
      flatSightMark: flatSightMark,
      arrowSpeedFps: profile.arrowSpeedFps,
      angles: angles,
    );
  }

  /// Record an actual result for learning.
  ///
  /// When the actual sight mark differs from the prediction,
  /// the profile's factors are adjusted to improve future predictions.
  Future<void> recordActualResult({
    required String bowId,
    required double angleDegrees,
    required double predictedMark,
    required double actualMark,
  }) async {
    var profile = _profilesByBow[bowId];
    if (profile == null) {
      profile = await loadProfileForBow(bowId);
    }

    // Apply learning
    final updatedProfile = profile.applyLearning(
      actualMark: actualMark,
      predictedMark: predictedMark,
      angleDegrees: angleDegrees,
    );

    // Save to database
    await _db.upsertAngleCorrectionProfile(
      id: updatedProfile.id,
      bowId: updatedProfile.bowId,
      arrowSpeedFps: updatedProfile.arrowSpeedFps,
      uphillFactor: updatedProfile.uphillFactor,
      downhillFactor: updatedProfile.downhillFactor,
      uphillDataPoints: updatedProfile.uphillDataPoints,
      downhillDataPoints: updatedProfile.downhillDataPoints,
      confidenceScore: updatedProfile.confidenceScore,
    );

    _profilesByBow[bowId] = updatedProfile;
    notifyListeners();
  }

  /// Update arrow speed for a bow.
  ///
  /// If [recalculateDefaults] is true, resets factors to new defaults.
  /// Otherwise keeps learned factors if they exist.
  Future<void> updateArrowSpeed(
    String bowId,
    double arrowSpeedFps, {
    bool recalculateDefaults = false,
  }) async {
    var profile = _profilesByBow[bowId];
    if (profile == null) {
      profile = await loadProfileForBow(bowId);
    }

    model.AngleCorrectionProfile updatedProfile;
    if (recalculateDefaults || !profile.hasLearnedData) {
      updatedProfile = profile.withUpdatedSpeed(arrowSpeedFps).resetToDefaults();
    } else {
      updatedProfile = profile.copyWith(arrowSpeedFps: arrowSpeedFps);
    }

    // Save to database
    await _db.upsertAngleCorrectionProfile(
      id: updatedProfile.id,
      bowId: updatedProfile.bowId,
      arrowSpeedFps: updatedProfile.arrowSpeedFps,
      uphillFactor: updatedProfile.uphillFactor,
      downhillFactor: updatedProfile.downhillFactor,
      uphillDataPoints: updatedProfile.uphillDataPoints,
      downhillDataPoints: updatedProfile.downhillDataPoints,
      confidenceScore: updatedProfile.confidenceScore,
    );

    _profilesByBow[bowId] = updatedProfile;
    notifyListeners();
  }

  /// Reset profile to defaults (clears learned data).
  Future<void> resetProfile(String bowId) async {
    var profile = _profilesByBow[bowId];
    if (profile == null) {
      profile = await loadProfileForBow(bowId);
    }

    final resetProfile = profile.resetToDefaults();

    await _db.upsertAngleCorrectionProfile(
      id: resetProfile.id,
      bowId: resetProfile.bowId,
      arrowSpeedFps: resetProfile.arrowSpeedFps,
      uphillFactor: resetProfile.uphillFactor,
      downhillFactor: resetProfile.downhillFactor,
      uphillDataPoints: resetProfile.uphillDataPoints,
      downhillDataPoints: resetProfile.downhillDataPoints,
      confidenceScore: resetProfile.confidenceScore,
    );

    _profilesByBow[bowId] = resetProfile;
    notifyListeners();
  }

  /// Delete profile for a bow.
  Future<void> deleteProfile(String bowId) async {
    await _db.deleteAngleCorrectionProfile(bowId);
    _profilesByBow.remove(bowId);
    notifyListeners();
  }

  /// Clear cache for a bow.
  void clearCacheForBow(String bowId) {
    _profilesByBow.remove(bowId);
  }

  /// Calculate sight mark with learned factors.
  double _calculateWithLearnedFactors({
    required double flatSightMark,
    required double angleDegrees,
    required double uphillFactor,
    required double downhillFactor,
  }) {
    if (angleDegrees == 0) return flatSightMark;

    if (angleDegrees < 0) {
      // UPHILL
      return flatSightMark - (angleDegrees.abs() * uphillFactor);
    } else {
      // DOWNHILL
      return flatSightMark - (angleDegrees * downhillFactor);
    }
  }

  /// Convert database model to domain model.
  model.AngleCorrectionProfile _dbToModel(AngleCorrectionProfile dbProfile) {
    return model.AngleCorrectionProfile(
      id: dbProfile.id,
      bowId: dbProfile.bowId,
      arrowSpeedFps: dbProfile.arrowSpeedFps,
      uphillFactor: dbProfile.uphillFactor,
      downhillFactor: dbProfile.downhillFactor,
      uphillDataPoints: dbProfile.uphillDataPoints,
      downhillDataPoints: dbProfile.downhillDataPoints,
      confidenceScore: dbProfile.confidenceScore,
      lastUpdated: dbProfile.lastUpdated,
    );
  }
}
