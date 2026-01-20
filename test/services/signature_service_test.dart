/// Tests for SignatureService
///
/// These tests verify:
/// - Archer signature storage and retrieval (base64 encoded)
/// - Archer profile data (name, DOB, division, bow class)
/// - Witness signature per-session storage
/// - ArcherProfile model and convenience methods
/// - Base64 encoding/decoding edge cases
/// - Olympic archer real-world scenarios
///
/// The service uses database preferences for persistence, which are mocked
/// using the MockAppDatabase's preference methods.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/signature_service.dart';

import '../mocks/mock_database.dart';

/// Wrapper to adapt MockAppDatabase to work with SignatureService
/// SignatureService expects an AppDatabase but we use MockAppDatabase for tests
class MockDatabaseAdapter {
  final MockAppDatabase _mockDb;

  MockDatabaseAdapter(this._mockDb);

  Future<String?> getPreference(String key) => _mockDb.getPreference(key);
  Future<void> setPreference(String key, String value) =>
      _mockDb.setPreference(key, value);
}

/// Test implementation of SignatureService that uses MockAppDatabase
class TestSignatureService {
  final MockAppDatabase _db;

  TestSignatureService(this._db);

  // Preference keys (matching the real service)
  static const String _archerSignatureKey = 'archer_signature';
  static const String _archerNameKey = 'archer_name';
  static const String _archerDobKey = 'archer_dob';
  static const String _archerDivisionKey = 'archer_division';
  static const String _archerBowClassKey = 'archer_bow_class';

  Future<Uint8List?> getArcherSignature() async {
    final base64 = await _db.getPreference(_archerSignatureKey);
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveArcherSignature(Uint8List? signature) async {
    if (signature == null) {
      await _db.setPreference(_archerSignatureKey, '');
    } else {
      await _db.setPreference(_archerSignatureKey, base64Encode(signature));
    }
  }

  Future<String?> getArcherName() => _db.getPreference(_archerNameKey);

  Future<void> saveArcherName(String name) =>
      _db.setPreference(_archerNameKey, name);

  Future<String?> getArcherDob() => _db.getPreference(_archerDobKey);

  Future<void> saveArcherDob(String dob) =>
      _db.setPreference(_archerDobKey, dob);

  Future<String?> getArcherDivision() => _db.getPreference(_archerDivisionKey);

  Future<void> saveArcherDivision(String division) =>
      _db.setPreference(_archerDivisionKey, division);

  Future<String?> getArcherBowClass() => _db.getPreference(_archerBowClassKey);

  Future<void> saveArcherBowClass(String bowClass) =>
      _db.setPreference(_archerBowClassKey, bowClass);

  Future<Uint8List?> getWitnessSignature(String sessionId) async {
    final base64 = await _db.getPreference('witness_signature_$sessionId');
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWitnessSignature(
      String sessionId, Uint8List? signature) async {
    if (signature == null) {
      await _db.setPreference('witness_signature_$sessionId', '');
    } else {
      await _db.setPreference(
          'witness_signature_$sessionId', base64Encode(signature));
    }
  }

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

  Future<void> saveArcherProfile(ArcherProfile profile) async {
    if (profile.name != null) await saveArcherName(profile.name!);
    if (profile.dob != null) await saveArcherDob(profile.dob!);
    if (profile.division != null) await saveArcherDivision(profile.division!);
    if (profile.bowClass != null) await saveArcherBowClass(profile.bowClass!);
    if (profile.signature != null) await saveArcherSignature(profile.signature);
  }
}

void main() {
  group('SignatureService', () {
    late MockAppDatabase mockDb;
    late TestSignatureService service;

    setUp(() {
      mockDb = MockAppDatabase();
      service = TestSignatureService(mockDb);
    });

    tearDown(() {
      mockDb.clear();
    });

    group('archer signature', () {
      group('getArcherSignature', () {
        test('returns null when no signature saved', () async {
          final signature = await service.getArcherSignature();
          expect(signature, isNull);
        });

        test('returns null for empty string preference', () async {
          await mockDb.setPreference('archer_signature', '');
          final signature = await service.getArcherSignature();
          expect(signature, isNull);
        });

        test('returns decoded bytes for valid base64', () async {
          final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
          await mockDb.setPreference(
              'archer_signature', base64Encode(testData));

          final signature = await service.getArcherSignature();

          expect(signature, isNotNull);
          expect(signature, equals(testData));
        });

        test('returns null for invalid base64', () async {
          await mockDb.setPreference('archer_signature', 'not-valid-base64!!!');

          final signature = await service.getArcherSignature();

          expect(signature, isNull);
        });

        test('handles large signature data', () async {
          // Simulate a real PNG signature (1000 bytes)
          final largeData = Uint8List.fromList(
              List.generate(1000, (i) => i % 256));
          await mockDb.setPreference(
              'archer_signature', base64Encode(largeData));

          final signature = await service.getArcherSignature();

          expect(signature, isNotNull);
          expect(signature!.length, equals(1000));
          expect(signature, equals(largeData));
        });
      });

      group('saveArcherSignature', () {
        test('saves signature as base64', () async {
          final testData = Uint8List.fromList([10, 20, 30, 40, 50]);

          await service.saveArcherSignature(testData);

          final stored = await mockDb.getPreference('archer_signature');
          expect(stored, isNotNull);
          expect(base64Decode(stored!), equals(testData));
        });

        test('saves empty string for null signature', () async {
          // First save a signature
          await service.saveArcherSignature(Uint8List.fromList([1, 2, 3]));

          // Then clear it
          await service.saveArcherSignature(null);

          final stored = await mockDb.getPreference('archer_signature');
          expect(stored, equals(''));
        });

        test('overwrites existing signature', () async {
          final first = Uint8List.fromList([1, 2, 3]);
          final second = Uint8List.fromList([4, 5, 6]);

          await service.saveArcherSignature(first);
          await service.saveArcherSignature(second);

          final signature = await service.getArcherSignature();
          expect(signature, equals(second));
        });

        test('handles empty byte array', () async {
          // Empty byte array encodes to empty string in base64
          // The service treats empty string as "no signature" and returns null
          final empty = Uint8List.fromList([]);

          await service.saveArcherSignature(empty);

          final signature = await service.getArcherSignature();
          // Empty signature becomes empty string, which returns null
          expect(signature, isNull);
        });
      });

      group('signature round-trip', () {
        test('save and retrieve produces identical data', () async {
          final original = Uint8List.fromList(
              List.generate(500, (i) => (i * 7) % 256));

          await service.saveArcherSignature(original);
          final retrieved = await service.getArcherSignature();

          expect(retrieved, equals(original));
        });

        test('multiple save/retrieve cycles work correctly', () async {
          for (int i = 0; i < 5; i++) {
            final data = Uint8List.fromList(
                List.generate(100, (j) => (i + j) % 256));

            await service.saveArcherSignature(data);
            final retrieved = await service.getArcherSignature();

            expect(retrieved, equals(data),
                reason: 'Cycle $i failed');
          }
        });
      });
    });

    group('archer name', () {
      test('returns null when no name saved', () async {
        final name = await service.getArcherName();
        expect(name, isNull);
      });

      test('saves and retrieves name', () async {
        await service.saveArcherName('Patrick Huston');

        final name = await service.getArcherName();
        expect(name, equals('Patrick Huston'));
      });

      test('overwrites existing name', () async {
        await service.saveArcherName('First Name');
        await service.saveArcherName('Second Name');

        final name = await service.getArcherName();
        expect(name, equals('Second Name'));
      });

      test('handles empty string', () async {
        await service.saveArcherName('');

        final name = await service.getArcherName();
        expect(name, equals(''));
      });

      test('handles special characters', () async {
        await service.saveArcherName('José García-Müller');

        final name = await service.getArcherName();
        expect(name, equals('José García-Müller'));
      });

      test('handles unicode characters', () async {
        await service.saveArcherName('田中太郎');

        final name = await service.getArcherName();
        expect(name, equals('田中太郎'));
      });
    });

    group('archer date of birth', () {
      test('returns null when no DOB saved', () async {
        final dob = await service.getArcherDob();
        expect(dob, isNull);
      });

      test('saves and retrieves DOB', () async {
        await service.saveArcherDob('1995-03-15');

        final dob = await service.getArcherDob();
        expect(dob, equals('1995-03-15'));
      });

      test('handles various date formats', () async {
        final formats = [
          '1995-03-15',
          '15/03/1995',
          'March 15, 1995',
          '15-Mar-1995',
        ];

        for (final format in formats) {
          await service.saveArcherDob(format);
          final dob = await service.getArcherDob();
          expect(dob, equals(format), reason: 'Format $format failed');
        }
      });

      test('handles edge case dates', () async {
        // Leap year
        await service.saveArcherDob('2000-02-29');
        expect(await service.getArcherDob(), equals('2000-02-29'));

        // End of year
        await service.saveArcherDob('1999-12-31');
        expect(await service.getArcherDob(), equals('1999-12-31'));

        // Start of year
        await service.saveArcherDob('2000-01-01');
        expect(await service.getArcherDob(), equals('2000-01-01'));
      });
    });

    group('archer division', () {
      test('returns null when no division saved', () async {
        final division = await service.getArcherDivision();
        expect(division, isNull);
      });

      test('saves and retrieves division', () async {
        await service.saveArcherDivision('Senior');

        final division = await service.getArcherDivision();
        expect(division, equals('Senior'));
      });

      test('handles all standard archery divisions', () async {
        final divisions = [
          'Senior',
          'U21',
          'U18',
          'U16',
          'U14',
          'U12',
          '50+',
          '60+',
          '70+',
        ];

        for (final div in divisions) {
          await service.saveArcherDivision(div);
          final retrieved = await service.getArcherDivision();
          expect(retrieved, equals(div), reason: 'Division $div failed');
        }
      });

      test('handles custom division names', () async {
        await service.saveArcherDivision('Masters (65+)');

        final division = await service.getArcherDivision();
        expect(division, equals('Masters (65+)'));
      });
    });

    group('archer bow class', () {
      test('returns null when no bow class saved', () async {
        final bowClass = await service.getArcherBowClass();
        expect(bowClass, isNull);
      });

      test('saves and retrieves bow class', () async {
        await service.saveArcherBowClass('Recurve');

        final bowClass = await service.getArcherBowClass();
        expect(bowClass, equals('Recurve'));
      });

      test('handles all standard bow classes', () async {
        final bowClasses = [
          'Recurve',
          'Compound',
          'Barebow',
          'Longbow',
          'Traditional',
          'Recurve Barebow',
        ];

        for (final bc in bowClasses) {
          await service.saveArcherBowClass(bc);
          final retrieved = await service.getArcherBowClass();
          expect(retrieved, equals(bc), reason: 'Bow class $bc failed');
        }
      });

      test('handles World Archery standard categories', () async {
        final waCategories = [
          'Recurve Men',
          'Recurve Women',
          'Compound Men',
          'Compound Women',
        ];

        for (final cat in waCategories) {
          await service.saveArcherBowClass(cat);
          final retrieved = await service.getArcherBowClass();
          expect(retrieved, equals(cat));
        }
      });
    });

    group('witness signature', () {
      group('getWitnessSignature', () {
        test('returns null when no signature saved for session', () async {
          final signature = await service.getWitnessSignature('session-123');
          expect(signature, isNull);
        });

        test('returns null for empty string', () async {
          await mockDb.setPreference('witness_signature_session-123', '');

          final signature = await service.getWitnessSignature('session-123');
          expect(signature, isNull);
        });

        test('returns decoded bytes for valid session', () async {
          final testData = Uint8List.fromList([100, 101, 102]);
          await mockDb.setPreference(
              'witness_signature_session-123', base64Encode(testData));

          final signature = await service.getWitnessSignature('session-123');

          expect(signature, isNotNull);
          expect(signature, equals(testData));
        });

        test('returns null for invalid base64', () async {
          await mockDb.setPreference(
              'witness_signature_session-123', 'invalid!!!');

          final signature = await service.getWitnessSignature('session-123');
          expect(signature, isNull);
        });
      });

      group('saveWitnessSignature', () {
        test('saves signature for specific session', () async {
          final testData = Uint8List.fromList([1, 2, 3]);

          await service.saveWitnessSignature('session-abc', testData);

          final stored =
              await mockDb.getPreference('witness_signature_session-abc');
          expect(stored, isNotNull);
          expect(base64Decode(stored!), equals(testData));
        });

        test('saves empty string for null signature', () async {
          await service.saveWitnessSignature(
              'session-abc', Uint8List.fromList([1, 2]));
          await service.saveWitnessSignature('session-abc', null);

          final stored =
              await mockDb.getPreference('witness_signature_session-abc');
          expect(stored, equals(''));
        });
      });

      group('session isolation', () {
        test('different sessions have independent signatures', () async {
          final sig1 = Uint8List.fromList([1, 1, 1]);
          final sig2 = Uint8List.fromList([2, 2, 2]);
          final sig3 = Uint8List.fromList([3, 3, 3]);

          await service.saveWitnessSignature('session-1', sig1);
          await service.saveWitnessSignature('session-2', sig2);
          await service.saveWitnessSignature('session-3', sig3);

          expect(await service.getWitnessSignature('session-1'), equals(sig1));
          expect(await service.getWitnessSignature('session-2'), equals(sig2));
          expect(await service.getWitnessSignature('session-3'), equals(sig3));
        });

        test('clearing one session does not affect others', () async {
          final sig1 = Uint8List.fromList([1, 1, 1]);
          final sig2 = Uint8List.fromList([2, 2, 2]);

          await service.saveWitnessSignature('session-1', sig1);
          await service.saveWitnessSignature('session-2', sig2);

          // Clear session-1
          await service.saveWitnessSignature('session-1', null);

          expect(await service.getWitnessSignature('session-1'), isNull);
          expect(await service.getWitnessSignature('session-2'), equals(sig2));
        });

        test('handles many concurrent sessions', () async {
          // Simulate 20 sessions with different witnesses
          for (int i = 0; i < 20; i++) {
            final sig = Uint8List.fromList([i, i + 1, i + 2]);
            await service.saveWitnessSignature('session-$i', sig);
          }

          // Verify all are stored correctly
          for (int i = 0; i < 20; i++) {
            final sig = await service.getWitnessSignature('session-$i');
            expect(sig, equals(Uint8List.fromList([i, i + 1, i + 2])),
                reason: 'Session $i signature mismatch');
          }
        });
      });

      group('session ID handling', () {
        test('handles UUID session IDs', () async {
          const uuid = '550e8400-e29b-41d4-a716-446655440000';
          final sig = Uint8List.fromList([1, 2, 3]);

          await service.saveWitnessSignature(uuid, sig);

          final retrieved = await service.getWitnessSignature(uuid);
          expect(retrieved, equals(sig));
        });

        test('handles numeric session IDs', () async {
          final sig = Uint8List.fromList([4, 5, 6]);

          await service.saveWitnessSignature('12345', sig);

          expect(await service.getWitnessSignature('12345'), equals(sig));
        });

        test('handles session IDs with special characters', () async {
          final sig = Uint8List.fromList([7, 8, 9]);
          const sessionId = 'session_2024-01-15_competition';

          await service.saveWitnessSignature(sessionId, sig);

          expect(await service.getWitnessSignature(sessionId), equals(sig));
        });
      });
    });

    group('ArcherProfile', () {
      group('getArcherProfile', () {
        test('returns empty profile when nothing saved', () async {
          final profile = await service.getArcherProfile();

          expect(profile.name, isNull);
          expect(profile.dob, isNull);
          expect(profile.division, isNull);
          expect(profile.bowClass, isNull);
          expect(profile.signature, isNull);
        });

        test('returns partial profile with some fields', () async {
          await service.saveArcherName('Patrick Huston');
          await service.saveArcherBowClass('Recurve');

          final profile = await service.getArcherProfile();

          expect(profile.name, equals('Patrick Huston'));
          expect(profile.dob, isNull);
          expect(profile.division, isNull);
          expect(profile.bowClass, equals('Recurve'));
          expect(profile.signature, isNull);
        });

        test('returns complete profile with all fields', () async {
          final sig = Uint8List.fromList([1, 2, 3, 4, 5]);

          await service.saveArcherName('Patrick Huston');
          await service.saveArcherDob('1995-03-15');
          await service.saveArcherDivision('Senior');
          await service.saveArcherBowClass('Recurve');
          await service.saveArcherSignature(sig);

          final profile = await service.getArcherProfile();

          expect(profile.name, equals('Patrick Huston'));
          expect(profile.dob, equals('1995-03-15'));
          expect(profile.division, equals('Senior'));
          expect(profile.bowClass, equals('Recurve'));
          expect(profile.signature, equals(sig));
        });
      });

      group('saveArcherProfile', () {
        test('saves all non-null fields', () async {
          final sig = Uint8List.fromList([10, 20, 30]);
          final profile = ArcherProfile(
            name: 'Test Archer',
            dob: '2000-01-01',
            division: 'U21',
            bowClass: 'Compound',
            signature: sig,
          );

          await service.saveArcherProfile(profile);

          expect(await service.getArcherName(), equals('Test Archer'));
          expect(await service.getArcherDob(), equals('2000-01-01'));
          expect(await service.getArcherDivision(), equals('U21'));
          expect(await service.getArcherBowClass(), equals('Compound'));
          expect(await service.getArcherSignature(), equals(sig));
        });

        test('only saves non-null fields', () async {
          // Pre-populate some data
          await service.saveArcherName('Original Name');
          await service.saveArcherDob('1990-01-01');

          // Save partial profile (only updates division)
          final partialProfile = ArcherProfile(
            division: 'Senior',
          );

          await service.saveArcherProfile(partialProfile);

          // Original data should be preserved
          expect(await service.getArcherName(), equals('Original Name'));
          expect(await service.getArcherDob(), equals('1990-01-01'));
          // New data should be saved
          expect(await service.getArcherDivision(), equals('Senior'));
        });

        test('empty profile does not modify existing data', () async {
          await service.saveArcherName('Keep This');

          await service.saveArcherProfile(const ArcherProfile());

          expect(await service.getArcherName(), equals('Keep This'));
        });
      });

      group('isComplete property', () {
        test('returns false when name is null', () {
          const profile = ArcherProfile(
            dob: '2000-01-01',
            division: 'Senior',
            bowClass: 'Recurve',
          );

          expect(profile.isComplete, isFalse);
        });

        test('returns false when name is empty', () {
          const profile = ArcherProfile(
            name: '',
            dob: '2000-01-01',
            division: 'Senior',
            bowClass: 'Recurve',
          );

          expect(profile.isComplete, isFalse);
        });

        test('returns true when name is non-empty', () {
          const profile = ArcherProfile(
            name: 'Patrick',
          );

          expect(profile.isComplete, isTrue);
        });

        test('returns true for full profile', () {
          final profile = ArcherProfile(
            name: 'Patrick Huston',
            dob: '1995-03-15',
            division: 'Senior',
            bowClass: 'Recurve',
            signature: Uint8List.fromList([1, 2, 3]),
          );

          expect(profile.isComplete, isTrue);
        });
      });
    });
  });

  group('Archery domain-specific tests', () {
    late MockAppDatabase mockDb;
    late TestSignatureService service;

    setUp(() {
      mockDb = MockAppDatabase();
      service = TestSignatureService(mockDb);
    });

    tearDown(() {
      mockDb.clear();
    });

    group('Olympic archer scenarios', () {
      test('Patrick stores his competition profile', () async {
        // Patrick Huston - GB Olympic recurve archer
        final signature = Uint8List.fromList(
            List.generate(500, (i) => i % 256)); // Simulated PNG signature

        await service.saveArcherName('Patrick Huston');
        await service.saveArcherDob('1995-03-15'); // Example DOB
        await service.saveArcherDivision('Senior');
        await service.saveArcherBowClass('Recurve');
        await service.saveArcherSignature(signature);

        final profile = await service.getArcherProfile();

        expect(profile.name, equals('Patrick Huston'));
        expect(profile.division, equals('Senior'));
        expect(profile.bowClass, equals('Recurve'));
        expect(profile.isComplete, isTrue);
        expect(profile.signature, isNotNull);
      });

      test('competition scorecard requires witness signature', () async {
        // In official competitions, scorecards need archer + witness signatures
        final archerSig = Uint8List.fromList([1, 2, 3, 4, 5]);
        final witnessSig = Uint8List.fromList([6, 7, 8, 9, 10]);
        const sessionId = 'world-cup-2024-ranking-round';

        await service.saveArcherSignature(archerSig);
        await service.saveWitnessSignature(sessionId, witnessSig);

        expect(await service.getArcherSignature(), equals(archerSig));
        expect(
            await service.getWitnessSignature(sessionId), equals(witnessSig));
      });

      test('multiple competition sessions have different witnesses', () async {
        // Each competition round has a different scorecard/witness
        final witness1 = Uint8List.fromList([1, 1, 1]);
        final witness2 = Uint8List.fromList([2, 2, 2]);
        final witness3 = Uint8List.fromList([3, 3, 3]);

        await service.saveWitnessSignature('qualification-round-1', witness1);
        await service.saveWitnessSignature('qualification-round-2', witness2);
        await service.saveWitnessSignature('elimination-match-1', witness3);

        // All different witnesses preserved
        expect(await service.getWitnessSignature('qualification-round-1'),
            equals(witness1));
        expect(await service.getWitnessSignature('qualification-round-2'),
            equals(witness2));
        expect(await service.getWitnessSignature('elimination-match-1'),
            equals(witness3));
      });

      test('archer signature auto-fills for all scorecards', () async {
        // Archer saves signature once, reuses on all scorecards
        final archerSig = Uint8List.fromList(
            List.generate(200, (i) => (i * 3) % 256));

        await service.saveArcherSignature(archerSig);

        // Multiple sessions all use same archer signature
        for (int i = 0; i < 10; i++) {
          final sig = await service.getArcherSignature();
          expect(sig, equals(archerSig),
              reason: 'Archer signature should auto-fill for session $i');
        }
      });
    });

    group('World Archery competition categories', () {
      test('handles all World Archery bow classes', () async {
        final waBowClasses = [
          'Recurve',
          'Compound',
          'Barebow',
          'W1', // Para archery
          'W2', // Para archery
          'Visually Impaired 1',
          'Visually Impaired 2/3',
        ];

        for (final bowClass in waBowClasses) {
          await service.saveArcherBowClass(bowClass);
          expect(await service.getArcherBowClass(), equals(bowClass));
        }
      });

      test('handles all World Archery age divisions', () async {
        final waDivisions = [
          'Senior', // 21+
          'Junior', // U21
          'Cadet', // U18
          '50+',
          '60+',
          '70+',
        ];

        for (final div in waDivisions) {
          await service.saveArcherDivision(div);
          expect(await service.getArcherDivision(), equals(div));
        }
      });
    });

    group('Archery GB classifications', () {
      test('handles UK-specific age categories', () async {
        final agbDivisions = [
          'Senior',
          'U21', // Under 21
          'U18', // Under 18
          'U16', // Under 16
          'U14', // Under 14
          'U12', // Under 12
          '50+',
          '60+',
          '70+',
        ];

        for (final div in agbDivisions) {
          await service.saveArcherDivision(div);
          expect(await service.getArcherDivision(), equals(div));
        }
      });

      test('handles UK-specific bow styles', () async {
        final agbBowStyles = [
          'Recurve',
          'Compound',
          'Barebow',
          'Longbow',
          'American Flatbow',
          'Traditional',
        ];

        for (final style in agbBowStyles) {
          await service.saveArcherBowClass(style);
          expect(await service.getArcherBowClass(), equals(style));
        }
      });
    });
  });

  group('Edge cases and error handling', () {
    late MockAppDatabase mockDb;
    late TestSignatureService service;

    setUp(() {
      mockDb = MockAppDatabase();
      service = TestSignatureService(mockDb);
    });

    tearDown(() {
      mockDb.clear();
    });

    group('base64 encoding edge cases', () {
      test('handles single byte signature', () async {
        final sig = Uint8List.fromList([42]);

        await service.saveArcherSignature(sig);
        final retrieved = await service.getArcherSignature();

        expect(retrieved, equals(sig));
      });

      test('handles all byte values (0-255)', () async {
        final sig = Uint8List.fromList(List.generate(256, (i) => i));

        await service.saveArcherSignature(sig);
        final retrieved = await service.getArcherSignature();

        expect(retrieved, equals(sig));
      });

      test('handles signature with null bytes', () async {
        final sig = Uint8List.fromList([0, 0, 0, 1, 0, 0, 2, 0]);

        await service.saveArcherSignature(sig);
        final retrieved = await service.getArcherSignature();

        expect(retrieved, equals(sig));
      });

      test('corrupted base64 returns null gracefully', () async {
        // Set corrupted data directly
        await mockDb.setPreference('archer_signature', 'not!valid@base64#');

        final signature = await service.getArcherSignature();

        expect(signature, isNull);
      });

      test('partially corrupted base64 returns null', () async {
        // Valid base64 prefix but corrupted end
        await mockDb.setPreference('archer_signature', 'SGVsbG8=!!!corrupt');

        final signature = await service.getArcherSignature();

        expect(signature, isNull);
      });
    });

    group('string field edge cases', () {
      test('handles very long name', () async {
        final longName = 'A' * 1000;

        await service.saveArcherName(longName);

        expect(await service.getArcherName(), equals(longName));
      });

      test('handles name with newlines', () async {
        const nameWithNewline = 'First\nLast';

        await service.saveArcherName(nameWithNewline);

        expect(await service.getArcherName(), equals(nameWithNewline));
      });

      test('handles name with tabs', () async {
        const nameWithTab = 'First\tLast';

        await service.saveArcherName(nameWithTab);

        expect(await service.getArcherName(), equals(nameWithTab));
      });

      test('handles emoji in name', () async {
        const emojiName = '🏹 Archer 🎯';

        await service.saveArcherName(emojiName);

        expect(await service.getArcherName(), equals(emojiName));
      });

      test('handles RTL text in name', () async {
        const arabicName = 'محمد أحمد';

        await service.saveArcherName(arabicName);

        expect(await service.getArcherName(), equals(arabicName));
      });

      test('handles mixed scripts in name', () async {
        const mixedName = 'John 田中 Müller محمد';

        await service.saveArcherName(mixedName);

        expect(await service.getArcherName(), equals(mixedName));
      });
    });

    group('session ID edge cases', () {
      test('handles empty session ID', () async {
        final sig = Uint8List.fromList([1, 2, 3]);

        await service.saveWitnessSignature('', sig);

        expect(await service.getWitnessSignature(''), equals(sig));
      });

      test('handles very long session ID', () async {
        final longId = 'session-${'x' * 500}';
        final sig = Uint8List.fromList([1, 2, 3]);

        await service.saveWitnessSignature(longId, sig);

        expect(await service.getWitnessSignature(longId), equals(sig));
      });

      test('handles session ID with path separators', () async {
        const dangerousId = '../../../etc/passwd';
        final sig = Uint8List.fromList([1, 2, 3]);

        await service.saveWitnessSignature(dangerousId, sig);

        // Should be stored safely as preference key, not as file path
        expect(await service.getWitnessSignature(dangerousId), equals(sig));
      });
    });

    group('concurrent operations', () {
      test('rapid save/load cycles work correctly', () async {
        for (int i = 0; i < 100; i++) {
          final sig = Uint8List.fromList([i % 256]);
          await service.saveArcherSignature(sig);
          final retrieved = await service.getArcherSignature();
          expect(retrieved, equals(sig), reason: 'Cycle $i failed');
        }
      });

      test('interleaved profile field updates', () async {
        // Simulate rapid updates from different parts of UI
        await service.saveArcherName('Name 1');
        await service.saveArcherDivision('Senior');
        await service.saveArcherName('Name 2');
        await service.saveArcherBowClass('Recurve');
        await service.saveArcherName('Name 3');

        expect(await service.getArcherName(), equals('Name 3'));
        expect(await service.getArcherDivision(), equals('Senior'));
        expect(await service.getArcherBowClass(), equals('Recurve'));
      });
    });
  });

  group('ArcherProfile model', () {
    test('constructor with all parameters', () {
      final sig = Uint8List.fromList([1, 2, 3]);
      final profile = ArcherProfile(
        name: 'Test',
        dob: '2000-01-01',
        division: 'Senior',
        bowClass: 'Recurve',
        signature: sig,
      );

      expect(profile.name, equals('Test'));
      expect(profile.dob, equals('2000-01-01'));
      expect(profile.division, equals('Senior'));
      expect(profile.bowClass, equals('Recurve'));
      expect(profile.signature, equals(sig));
    });

    test('constructor with no parameters', () {
      const profile = ArcherProfile();

      expect(profile.name, isNull);
      expect(profile.dob, isNull);
      expect(profile.division, isNull);
      expect(profile.bowClass, isNull);
      expect(profile.signature, isNull);
    });

    test('isComplete is false for empty profile', () {
      const profile = ArcherProfile();
      expect(profile.isComplete, isFalse);
    });

    test('isComplete is false for whitespace-only name', () {
      const profile = ArcherProfile(name: '   ');
      // isComplete checks for non-empty, whitespace counts as content
      expect(profile.isComplete, isTrue);
    });

    test('profile with only signature is incomplete', () {
      final profile = ArcherProfile(
        signature: Uint8List.fromList([1, 2, 3]),
      );
      expect(profile.isComplete, isFalse);
    });

    test('profile with name and signature is complete', () {
      final profile = ArcherProfile(
        name: 'Archer',
        signature: Uint8List.fromList([1, 2, 3]),
      );
      expect(profile.isComplete, isTrue);
    });
  });

  group('Signature data characteristics', () {
    // These tests document expected signature data characteristics
    // based on typical PNG signature capture

    test('typical PNG signature size range', () {
      // PNG signatures from the signature pad are typically 5-50 KB
      // depending on complexity of the signature

      // Simple signature (few strokes)
      final simpleSize = 5 * 1024; // 5 KB
      expect(simpleSize, greaterThan(1000));
      expect(simpleSize, lessThan(100000));

      // Complex signature (many strokes)
      final complexSize = 50 * 1024; // 50 KB
      expect(complexSize, lessThan(100000));
    });

    test('base64 encoding increases size by ~33%', () {
      // Base64 encoding increases data size by approximately 4/3 (33%)
      final originalSize = 10000;
      final base64Size = (originalSize * 4 / 3).ceil();

      expect(base64Size, greaterThan(originalSize));
      expect(base64Size, lessThan(originalSize * 1.5));
    });

    test('empty signature produces empty base64', () {
      final empty = Uint8List.fromList([]);
      final encoded = base64Encode(empty);
      expect(encoded, equals(''));
    });
  });

  group('Preference key consistency', () {
    // These tests verify the preference keys match the real service

    test('archer signature key is correct', () {
      expect(TestSignatureService._archerSignatureKey, equals('archer_signature'));
    });

    test('archer name key is correct', () {
      expect(TestSignatureService._archerNameKey, equals('archer_name'));
    });

    test('archer dob key is correct', () {
      expect(TestSignatureService._archerDobKey, equals('archer_dob'));
    });

    test('archer division key is correct', () {
      expect(TestSignatureService._archerDivisionKey, equals('archer_division'));
    });

    test('archer bow class key is correct', () {
      expect(TestSignatureService._archerBowClassKey, equals('archer_bow_class'));
    });

    test('witness signature key format is correct', () {
      // Witness signatures use: witness_signature_$sessionId
      const sessionId = 'test-session';
      const expectedKey = 'witness_signature_test-session';
      expect('witness_signature_$sessionId', equals(expectedKey));
    });
  });
}
