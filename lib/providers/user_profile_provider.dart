import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import '../db/database.dart';
import '../models/user_profile.dart';
import '../services/sync_service.dart';
import '../utils/unique_id.dart';

/// Manages user profile state
class UserProfileProvider extends ChangeNotifier {
  final AppDatabase _db;

  UserProfileProvider(this._db);

  // Cached profile data
  UserProfile? _profile;
  List<Federation> _federations = [];
  bool _isLoaded = false;

  // Getters
  UserProfile? get profile => _profile;
  List<Federation> get federations => _federations;
  bool get isLoaded => _isLoaded;
  bool get hasProfile => _profile != null;

  // Convenience getters
  String? get name => _profile?.name;
  String? get clubName => _profile?.clubName;
  BowType get primaryBowType => BowType.fromString(_profile?.primaryBowType ?? 'recurve');
  Handedness get handedness => Handedness.fromString(_profile?.handedness ?? 'right');
  int? get yearsShootingStart => _profile?.yearsShootingStart;
  double get shootingFrequency => _profile?.shootingFrequency ?? 3.0;
  List<CompetitionLevel> get competitionLevels =>
      CompetitionLevel.fromJsonList(_profile?.competitionLevels);
  String? get notes => _profile?.notes;

  // Classification-related getters
  Gender? get gender => Gender.fromStringNullable(_profile?.gender);
  DateTime? get dateOfBirth => _profile?.dateOfBirth;

  /// Get the archer's age category based on date of birth
  /// Returns null if date of birth is not set
  AgeCategory? get ageCategory {
    final dob = dateOfBirth;
    if (dob == null) return null;
    return AgeCategory.fromDateOfBirth(dob);
  }

  /// Check if the profile has classification-related fields set
  bool get hasClassificationInfo => gender != null && dateOfBirth != null;

  /// Calculate years of experience
  int? get yearsExperience {
    if (yearsShootingStart == null) return null;
    return DateTime.now().year - yearsShootingStart!;
  }

  /// Get primary federation (if any)
  Federation? get primaryFederation {
    try {
      return _federations.firstWhere((f) => f.isPrimary);
    } catch (_) {
      return _federations.isNotEmpty ? _federations.first : null;
    }
  }

  /// Load profile from database
  Future<void> loadProfile() async {
    try {
      _profile = await _db.getUserProfile();

      if (_profile != null) {
        _federations = await _db.getFederationsForProfile(_profile!.id);
      } else {
        _federations = [];
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Create or update the user profile
  Future<void> saveProfile({
    String? name,
    String? clubName,
    BowType? bowType,
    Handedness? handedness,
    int? yearsShootingStart,
    double? shootingFrequency,
    List<CompetitionLevel>? competitionLevels,
    Gender? gender,
    DateTime? dateOfBirth,
    String? notes,
  }) async {
    try {
      final profileId = _profile?.id ?? UniqueId.withPrefix('profile');

      final companion = UserProfilesCompanion(
        id: Value(profileId),
        name: name != null ? Value(name) : const Value.absent(),
        clubName: clubName != null ? Value(clubName) : const Value.absent(),
        primaryBowType: bowType != null ? Value(bowType.value) : const Value.absent(),
        handedness: handedness != null ? Value(handedness.value) : const Value.absent(),
        yearsShootingStart: yearsShootingStart != null
            ? Value(yearsShootingStart)
            : const Value.absent(),
        shootingFrequency: shootingFrequency != null
            ? Value(shootingFrequency)
            : const Value.absent(),
        competitionLevels: competitionLevels != null
            ? Value(CompetitionLevel.toJsonList(competitionLevels))
            : const Value.absent(),
        gender: gender != null ? Value(gender.value) : const Value.absent(),
        dateOfBirth: dateOfBirth != null ? Value(dateOfBirth) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );

      await _db.upsertUserProfile(companion);
      await loadProfile();
      _triggerCloudBackup();
    } catch (e) {
      debugPrint('Error saving profile: $e');
      rethrow;
    }
  }

  /// Update just the bow type
  Future<void> updateBowType(BowType bowType) async {
    await saveProfile(bowType: bowType);
  }

  /// Update just the handedness
  Future<void> updateHandedness(Handedness handedness) async {
    await saveProfile(handedness: handedness);
  }

  // ===========================================================================
  // FEDERATIONS
  // ===========================================================================

  /// Add a new federation membership
  Future<void> addFederation({
    required String federationName,
    String? membershipNumber,
    String? cardImagePath,
    DateTime? expiryDate,
    bool isPrimary = false,
  }) async {
    if (_profile == null) {
      // Create profile first if it doesn't exist
      await saveProfile();
    }

    final federationId = UniqueId.withPrefix('fed');

    await _db.insertFederation(FederationsCompanion.insert(
      id: federationId,
      profileId: _profile!.id,
      federationName: federationName,
      membershipNumber: Value(membershipNumber),
      cardImagePath: Value(cardImagePath),
      expiryDate: Value(expiryDate),
      isPrimary: Value(isPrimary),
    ));

    // If this is marked as primary, update others
    if (isPrimary) {
      await _db.setPrimaryFederation(federationId, _profile!.id);
    }

    await loadProfile();
    _triggerCloudBackup();
  }

  /// Update an existing federation
  Future<void> updateFederation({
    required String federationId,
    String? federationName,
    String? membershipNumber,
    String? cardImagePath,
    DateTime? expiryDate,
    bool? isPrimary,
  }) async {
    final existing = await _db.getFederation(federationId);
    if (existing == null) return;

    await _db.updateFederation(FederationsCompanion(
      id: Value(federationId),
      profileId: Value(existing.profileId),
      federationName: federationName != null ? Value(federationName) : Value(existing.federationName),
      membershipNumber: membershipNumber != null ? Value(membershipNumber) : Value(existing.membershipNumber),
      cardImagePath: cardImagePath != null ? Value(cardImagePath) : Value(existing.cardImagePath),
      expiryDate: expiryDate != null ? Value(expiryDate) : Value(existing.expiryDate),
      isPrimary: isPrimary != null ? Value(isPrimary) : Value(existing.isPrimary),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));

    // If this is marked as primary, update others
    if (isPrimary == true) {
      await _db.setPrimaryFederation(federationId, existing.profileId);
    }

    await loadProfile();
    _triggerCloudBackup();
  }

  /// Delete a federation
  Future<void> deleteFederation(String federationId) async {
    await _db.deleteFederation(federationId);
    await loadProfile();
    _triggerCloudBackup();
  }

  /// Set a federation as primary
  Future<void> setPrimaryFederation(String federationId) async {
    if (_profile == null) return;
    await _db.setPrimaryFederation(federationId, _profile!.id);
    await loadProfile();
    _triggerCloudBackup();
  }

  // ===========================================================================
  // CLOUD BACKUP
  // ===========================================================================

  void _triggerCloudBackup() {
    // SyncService handles its own error handling and retry logic
    SyncService().syncAll();
  }
}
