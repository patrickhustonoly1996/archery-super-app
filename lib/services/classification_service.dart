import 'package:drift/drift.dart' show Value;

import '../models/classification.dart';
import '../models/user_profile.dart';
import '../db/database.dart';
import '../utils/unique_id.dart';

/// Service for AGB classification calculations
///
/// Calculations based on archeryutils:
/// threshold = datum + (ageStep × 3) + genderAdj + (classIndex × 7)
class ClassificationService {
  final AppDatabase _db;

  ClassificationService(this._db);

  /// Gender adjustment for female archers
  static const int genderAdjustmentFemale = 7;

  // ===========================================================================
  // THRESHOLD CALCULATIONS
  // ===========================================================================

  /// Calculate the handicap threshold for a classification
  ///
  /// Parameters:
  /// - [classification]: The classification level (GMB, MB, B1, etc.)
  /// - [bowstyle]: The bow type (recurve, compound, barebow, longbow, traditional)
  /// - [ageCategory]: The archer's age category
  /// - [gender]: The archer's gender
  /// - [isIndoor]: Whether this is for indoor classification
  int calculateThreshold({
    required int classIndex,
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
    bool isIndoor = false,
  }) {
    // Get the bowstyle datum
    final datum = isIndoor
        ? IndoorBowstyleDatum.forBowstyle(bowstyle)
        : BowstyleDatum.forBowstyle(bowstyle);

    // Gender adjustment
    final genderAdj = gender == Gender.female ? genderAdjustmentFemale : 0;

    // Calculate threshold
    // threshold = datum + (ageStep × 3) + genderAdj + (classIndex × 7)
    return datum + (ageCategory.ageStep * 3) + genderAdj + (classIndex * 7);
  }

  /// Get the outdoor classification threshold for a given level
  int getOutdoorThreshold({
    required OutdoorClassification classification,
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
  }) {
    return calculateThreshold(
      classIndex: classification.classIndex,
      bowstyle: bowstyle,
      ageCategory: ageCategory,
      gender: gender,
      isIndoor: false,
    );
  }

  /// Get the indoor classification threshold for a given level
  int getIndoorThreshold({
    required IndoorClassification classification,
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
  }) {
    return calculateThreshold(
      classIndex: classification.classIndex,
      bowstyle: bowstyle,
      ageCategory: ageCategory,
      gender: gender,
      isIndoor: true,
    );
  }

  // ===========================================================================
  // CLASSIFICATION CHECKING
  // ===========================================================================

  /// Check what outdoor classification a handicap qualifies for
  ///
  /// Returns the highest classification the handicap meets, or null if none.
  /// Note: handicap must be LESS THAN OR EQUAL TO threshold to qualify.
  OutdoorClassification? getOutdoorClassificationForHandicap({
    required int handicap,
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
  }) {
    // Check from highest (GMB) to lowest (A3)
    for (final classification in OutdoorClassification.values) {
      final threshold = getOutdoorThreshold(
        classification: classification,
        bowstyle: bowstyle,
        ageCategory: ageCategory,
        gender: gender,
      );

      if (handicap <= threshold) {
        return classification;
      }
    }
    return null;
  }

  /// Check what indoor classification a handicap qualifies for
  IndoorClassification? getIndoorClassificationForHandicap({
    required int handicap,
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
  }) {
    for (final classification in IndoorClassification.values) {
      final threshold = getIndoorThreshold(
        classification: classification,
        bowstyle: bowstyle,
        ageCategory: ageCategory,
        gender: gender,
      );

      if (handicap <= threshold) {
        return classification;
      }
    }
    return null;
  }

  /// Check if a round is valid for MB+ classifications
  bool isPrestigeRound(String roundId) {
    return PrestigeRounds.isPrestigeRound(roundId);
  }

  /// Check if a classification requires a prestige round
  bool requiresPrestigeRound(String classificationCode) {
    // GMB and MB require prestige rounds
    return classificationCode == 'GMB' || classificationCode == 'MB';
  }

  // ===========================================================================
  // DATABASE OPERATIONS
  // ===========================================================================

  /// Record a qualifying score for a classification
  ///
  /// This handles the logic of:
  /// - Creating a new classification record if this is the first qualifying score
  /// - Updating an existing record if this is the second qualifying score
  ///
  /// Returns the classification record, or null if the score doesn't qualify.
  Future<Classification?> recordQualifyingScore({
    required String profileId,
    required String classificationCode,
    required ClassificationScope scope,
    required String bowstyle,
    required String sessionId,
    required int score,
    required String roundId,
  }) async {
    // Check if we already have a classification record for this
    final existing = await _db.getClassificationForProfileAndCode(
      profileId,
      classificationCode,
      scope.value,
      bowstyle,
    );

    if (existing == null) {
      // First qualifying score - create new record
      final id = UniqueId.withPrefix('class');
      await _db.insertClassification(
        ClassificationsCompanion.insert(
          id: id,
          profileId: profileId,
          classification: classificationCode,
          classificationScope: scope.value,
          bowstyle: bowstyle,
          firstSessionId: Value(sessionId),
          firstAchievedAt: Value(DateTime.now()),
          firstScore: Value(score),
          firstRoundId: Value(roundId),
        ),
      );
      return _db.getClassification(id);
    } else if (existing.secondSessionId == null) {
      // Second qualifying score - update existing record
      // Don't count the same session twice
      if (existing.firstSessionId == sessionId) {
        return existing;
      }

      await _db.updateClassificationSecondScore(
        classificationId: existing.id,
        sessionId: sessionId,
        score: score,
        roundId: roundId,
      );
      return _db.getClassification(existing.id);
    }

    // Already have two qualifying scores
    return existing;
  }

  /// Check if a classification is complete (has two qualifying scores)
  bool isClassificationComplete(Classification classification) {
    return classification.firstSessionId != null &&
        classification.secondSessionId != null;
  }

  /// Check if a classification is claimable (complete but not claimed)
  bool isClassificationClaimable(Classification classification) {
    return isClassificationComplete(classification) && !classification.isClaimed;
  }

  /// Get all classifications for a profile, optionally filtered by scope
  Future<List<Classification>> getClassifications(
    String profileId, {
    ClassificationScope? scope,
  }) async {
    if (scope != null) {
      return _db.getClassificationsByScope(profileId, scope.value);
    }
    return _db.getClassificationsForProfile(profileId);
  }

  /// Get the highest claimed classification for a profile and scope
  Future<Classification?> getHighestClaimed(
    String profileId,
    ClassificationScope scope,
  ) async {
    return _db.getHighestClaimedClassification(profileId, scope.value);
  }

  /// Claim a classification
  Future<void> claimClassification(String classificationId) async {
    await _db.claimClassification(classificationId);
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Get a human-readable description of what's needed for next classification
  String getNextClassificationRequirements({
    required String? currentClassificationCode,
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
    required bool isIndoor,
  }) {
    if (isIndoor) {
      final current = currentClassificationCode != null
          ? IndoorClassification.fromString(currentClassificationCode)
          : null;
      final next = current?.nextHigher ?? IndoorClassification.archerThird;

      final threshold = getIndoorThreshold(
        classification: next,
        bowstyle: bowstyle,
        ageCategory: ageCategory,
        gender: gender,
      );

      return 'Achieve handicap $threshold or better twice to earn ${next.displayName}';
    } else {
      final current = currentClassificationCode != null
          ? OutdoorClassification.fromString(currentClassificationCode)
          : null;
      final next = current?.nextHigher ?? OutdoorClassification.archerThird;

      final threshold = getOutdoorThreshold(
        classification: next,
        bowstyle: bowstyle,
        ageCategory: ageCategory,
        gender: gender,
      );

      String requirements = 'Achieve handicap $threshold or better twice';
      if (next.requiresPrestigeRound) {
        requirements += ' on a prestige round (York, Hereford, WA 1440, etc.)';
      }
      requirements += ' to earn ${next.displayName}';

      return requirements;
    }
  }

  /// Get all classification thresholds for a given configuration
  Map<String, int> getAllThresholds({
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
    required bool isIndoor,
  }) {
    final thresholds = <String, int>{};

    if (isIndoor) {
      for (final c in IndoorClassification.values) {
        thresholds[c.code] = getIndoorThreshold(
          classification: c,
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
        );
      }
    } else {
      for (final c in OutdoorClassification.values) {
        thresholds[c.code] = getOutdoorThreshold(
          classification: c,
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
        );
      }
    }

    return thresholds;
  }
}
