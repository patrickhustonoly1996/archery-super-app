import 'dart:convert';
import 'dart:typed_data';
import '../db/database.dart';

/// Service for managing archer and witness signatures.
/// Archer signatures are stored persistently and auto-fill.
/// Witness signatures are stored per-session.
class SignatureService {
  final AppDatabase _db;

  SignatureService(this._db);

  // Preference keys
  static const String _archerSignatureKey = 'archer_signature';
  static const String _archerNameKey = 'archer_name';
  static const String _archerDobKey = 'archer_dob';
  static const String _archerDivisionKey = 'archer_division';
  static const String _archerBowClassKey = 'archer_bow_class';

  /// Get the saved archer signature (auto-fills after first save).
  Future<Uint8List?> getArcherSignature() async {
    final base64 = await _db.getPreference(_archerSignatureKey);
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  /// Save the archer's signature for auto-fill.
  Future<void> saveArcherSignature(Uint8List? signature) async {
    if (signature == null) {
      await _db.setPreference(_archerSignatureKey, '');
    } else {
      await _db.setPreference(_archerSignatureKey, base64Encode(signature));
    }
  }

  /// Get the saved archer name.
  Future<String?> getArcherName() => _db.getPreference(_archerNameKey);

  /// Save the archer name.
  Future<void> saveArcherName(String name) =>
      _db.setPreference(_archerNameKey, name);

  /// Get the saved archer date of birth.
  Future<String?> getArcherDob() => _db.getPreference(_archerDobKey);

  /// Save the archer date of birth.
  Future<void> saveArcherDob(String dob) =>
      _db.setPreference(_archerDobKey, dob);

  /// Get the saved archer division (Senior, U21, etc).
  Future<String?> getArcherDivision() => _db.getPreference(_archerDivisionKey);

  /// Save the archer division.
  Future<void> saveArcherDivision(String division) =>
      _db.setPreference(_archerDivisionKey, division);

  /// Get the saved archer bow class (Recurve, Compound, etc).
  Future<String?> getArcherBowClass() => _db.getPreference(_archerBowClassKey);

  /// Save the archer bow class.
  Future<void> saveArcherBowClass(String bowClass) =>
      _db.setPreference(_archerBowClassKey, bowClass);

  /// Get a witness signature for a specific session.
  Future<Uint8List?> getWitnessSignature(String sessionId) async {
    final base64 = await _db.getPreference('witness_signature_$sessionId');
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  /// Save a witness signature for a specific session.
  Future<void> saveWitnessSignature(String sessionId, Uint8List? signature) async {
    if (signature == null) {
      await _db.setPreference('witness_signature_$sessionId', '');
    } else {
      await _db.setPreference('witness_signature_$sessionId', base64Encode(signature));
    }
  }

  /// Get all archer profile data at once.
  Future<ArcherProfile> getArcherProfile() async {
    final name = await getArcherName();
    final dob = await getArcherDob();
    final division = await getArcherDivision();
    final bowClass = await getArcherBowClass();
    final signature = await getArcherSignature();
    return ArcherProfile(
      name: name,
      dob: dob,
      division: division,
      bowClass: bowClass,
      signature: signature,
    );
  }

  /// Save all archer profile data at once.
  Future<void> saveArcherProfile(ArcherProfile profile) async {
    if (profile.name != null) await saveArcherName(profile.name!);
    if (profile.dob != null) await saveArcherDob(profile.dob!);
    if (profile.division != null) await saveArcherDivision(profile.division!);
    if (profile.bowClass != null) await saveArcherBowClass(profile.bowClass!);
    if (profile.signature != null) await saveArcherSignature(profile.signature);
  }
}

/// Archer profile data container.
class ArcherProfile {
  final String? name;
  final String? dob;
  final String? division;
  final String? bowClass;
  final Uint8List? signature;

  const ArcherProfile({
    this.name,
    this.dob,
    this.division,
    this.bowClass,
    this.signature,
  });

  bool get isComplete => name != null && name!.isNotEmpty;
}
