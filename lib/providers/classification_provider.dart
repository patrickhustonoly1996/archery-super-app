import 'package:flutter/foundation.dart';
import '../db/database.dart';
import '../models/classification.dart';
import '../models/user_profile.dart';
import '../services/classification_service.dart';

/// Manages classification state and provides access to classification data
class ClassificationProvider extends ChangeNotifier {
  final AppDatabase _db;
  late final ClassificationService _classificationService;

  ClassificationProvider(this._db) {
    _classificationService = ClassificationService(_db);
  }

  // Cached data
  List<Classification> _outdoorClassifications = [];
  List<Classification> _indoorClassifications = [];
  Classification? _highestOutdoor;
  Classification? _highestIndoor;
  bool _isLoaded = false;

  // Getters
  List<Classification> get outdoorClassifications => _outdoorClassifications;
  List<Classification> get indoorClassifications => _indoorClassifications;
  Classification? get highestOutdoorClassification => _highestOutdoor;
  Classification? get highestIndoorClassification => _highestIndoor;
  bool get isLoaded => _isLoaded;
  ClassificationService get service => _classificationService;

  /// Check if there are any classifications
  bool get hasClassifications =>
      _outdoorClassifications.isNotEmpty || _indoorClassifications.isNotEmpty;

  /// Check if there are any claimable classifications
  bool get hasClaimableClassifications {
    return _outdoorClassifications.any((c) => _classificationService.isClassificationClaimable(c)) ||
        _indoorClassifications.any((c) => _classificationService.isClassificationClaimable(c));
  }

  /// Get claimable outdoor classifications
  List<Classification> get claimableOutdoorClassifications {
    return _outdoorClassifications
        .where((c) => _classificationService.isClassificationClaimable(c))
        .toList();
  }

  /// Get claimable indoor classifications
  List<Classification> get claimableIndoorClassifications {
    return _indoorClassifications
        .where((c) => _classificationService.isClassificationClaimable(c))
        .toList();
  }

  /// Load classifications for a profile
  Future<void> loadClassifications(String profileId) async {
    try {
      _outdoorClassifications = await _classificationService.getClassifications(
        profileId,
        scope: ClassificationScope.outdoor,
      );
      _indoorClassifications = await _classificationService.getClassifications(
        profileId,
        scope: ClassificationScope.indoor,
      );

      _highestOutdoor = await _classificationService.getHighestClaimed(
        profileId,
        ClassificationScope.outdoor,
      );
      _highestIndoor = await _classificationService.getHighestClaimed(
        profileId,
        ClassificationScope.indoor,
      );

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading classifications: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Claim a classification
  Future<void> claimClassification(String classificationId, String profileId) async {
    try {
      await _classificationService.claimClassification(classificationId);
      await loadClassifications(profileId);
    } catch (e) {
      debugPrint('Error claiming classification: $e');
      rethrow;
    }
  }

  /// Check and record a potential qualifying score after session completion
  ///
  /// This should be called after a session is completed to check if the score
  /// qualifies for any classifications.
  ///
  /// Returns the classification that was updated/created, or null if the score
  /// doesn't qualify for anything.
  Future<Classification?> checkAndRecordScore({
    required String profileId,
    required int handicap,
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
    required String sessionId,
    required int score,
    required String roundId,
    required bool isIndoor,
  }) async {
    // Check what classification this handicap qualifies for
    final classificationCode = isIndoor
        ? _classificationService
            .getIndoorClassificationForHandicap(
              handicap: handicap,
              bowstyle: bowstyle,
              ageCategory: ageCategory,
              gender: gender,
            )
            ?.code
        : _classificationService
            .getOutdoorClassificationForHandicap(
              handicap: handicap,
              bowstyle: bowstyle,
              ageCategory: ageCategory,
              gender: gender,
            )
            ?.code;

    if (classificationCode == null) {
      return null;
    }

    // For outdoor MB+ classifications, check if it's a prestige round
    if (!isIndoor && _classificationService.requiresPrestigeRound(classificationCode)) {
      if (!_classificationService.isPrestigeRound(roundId)) {
        // Score qualifies but not on a prestige round
        // We could still record it for lower classifications
        // For now, skip recording for MB+
        return null;
      }
    }

    // Record the qualifying score
    final classification = await _classificationService.recordQualifyingScore(
      profileId: profileId,
      classificationCode: classificationCode,
      scope: isIndoor ? ClassificationScope.indoor : ClassificationScope.outdoor,
      bowstyle: bowstyle,
      sessionId: sessionId,
      score: score,
      roundId: roundId,
    );

    if (classification != null) {
      await loadClassifications(profileId);
    }

    return classification;
  }

  /// Get all thresholds for a given configuration
  Map<String, int> getThresholds({
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
    required bool isIndoor,
  }) {
    return _classificationService.getAllThresholds(
      bowstyle: bowstyle,
      ageCategory: ageCategory,
      gender: gender,
      isIndoor: isIndoor,
    );
  }

  /// Get requirements text for the next classification
  String getNextClassificationRequirements({
    required String? currentClassificationCode,
    required String bowstyle,
    required AgeCategory ageCategory,
    required Gender gender,
    required bool isIndoor,
  }) {
    return _classificationService.getNextClassificationRequirements(
      currentClassificationCode: currentClassificationCode,
      bowstyle: bowstyle,
      ageCategory: ageCategory,
      gender: gender,
      isIndoor: isIndoor,
    );
  }

  /// Clear cached data
  void clear() {
    _outdoorClassifications = [];
    _indoorClassifications = [];
    _highestOutdoor = null;
    _highestIndoor = null;
    _isLoaded = false;
    notifyListeners();
  }
}
