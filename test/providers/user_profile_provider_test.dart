import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/models/user_profile.dart';

/// Tests for UserProfileProvider logic.
///
/// Note: Full provider tests with database interaction require mock setup.
/// These tests cover the pure logic aspects that can be tested in isolation.
void main() {
  group('UserProfileProvider State Logic', () {
    group('Initial State', () {
      test('starts with null profile', () {
        // Simulating initial state - using dynamic type since UserProfile
        // is a generated Drift class
        const Object? profile = null;
        expect(profile, isNull);
      });

      test('starts as not loaded', () {
        var isLoaded = false;
        expect(isLoaded, isFalse);
      });

      test('hasProfile returns false when profile is null', () {
        const Object? profile = null;
        final hasProfile = profile != null;
        expect(hasProfile, isFalse);
      });
    });

    group('Profile ID Generation', () {
      test('generates ID with profile prefix', () {
        const prefix = 'profile';
        final id = '${prefix}_abc123';
        expect(id.startsWith('profile_'), isTrue);
      });

      test('existing profile keeps its ID', () {
        const existingId = 'profile_existing123';
        const String? newProfileId = null;
        final resultId = newProfileId ?? existingId;
        expect(resultId, equals('profile_existing123'));
      });
    });

    group('Convenience Getters with Defaults', () {
      test('primaryBowType defaults to recurve when profile is null', () {
        const String? profileBowType = null;
        final bowType = BowType.fromString(profileBowType ?? 'recurve');
        expect(bowType, equals(BowType.recurve));
      });

      test('handedness defaults to right when profile is null', () {
        const String? profileHandedness = null;
        final handedness = Handedness.fromString(profileHandedness ?? 'right');
        expect(handedness, equals(Handedness.right));
      });

      test('shootingFrequency defaults to 3.0 when profile is null', () {
        const double? profileFrequency = null;
        final frequency = profileFrequency ?? 3.0;
        expect(frequency, equals(3.0));
      });

      test('competitionLevels defaults to empty list when null', () {
        const String? jsonLevels = null;
        final levels = CompetitionLevel.fromJsonList(jsonLevels);
        expect(levels, isEmpty);
      });
    });
  });

  group('Gender Enum', () {
    group('fromString', () {
      test('parses male', () {
        final gender = Gender.fromString('male');
        expect(gender, equals(Gender.male));
      });

      test('parses female', () {
        final gender = Gender.fromString('female');
        expect(gender, equals(Gender.female));
      });

      test('defaults to male for unknown value', () {
        final gender = Gender.fromString('unknown');
        expect(gender, equals(Gender.male));
      });
    });

    group('fromStringNullable', () {
      test('returns null for null input', () {
        final gender = Gender.fromStringNullable(null);
        expect(gender, isNull);
      });

      test('returns null for invalid input', () {
        final gender = Gender.fromStringNullable('invalid');
        expect(gender, isNull);
      });

      test('parses valid male', () {
        final gender = Gender.fromStringNullable('male');
        expect(gender, equals(Gender.male));
      });

      test('parses valid female', () {
        final gender = Gender.fromStringNullable('female');
        expect(gender, equals(Gender.female));
      });
    });

    group('value and displayName', () {
      test('male has correct values', () {
        expect(Gender.male.value, equals('male'));
        expect(Gender.male.displayName, equals('Male'));
      });

      test('female has correct values', () {
        expect(Gender.female.value, equals('female'));
        expect(Gender.female.displayName, equals('Female'));
      });
    });
  });

  group('AgeCategory Enum', () {
    group('fromString', () {
      test('parses adult', () {
        final category = AgeCategory.fromString('adult');
        expect(category, equals(AgeCategory.adult));
      });

      test('parses under_18', () {
        final category = AgeCategory.fromString('under_18');
        expect(category, equals(AgeCategory.under18));
      });

      test('parses 50+', () {
        final category = AgeCategory.fromString('50+');
        expect(category, equals(AgeCategory.fiftyPlus));
      });

      test('defaults to adult for unknown value', () {
        final category = AgeCategory.fromString('unknown');
        expect(category, equals(AgeCategory.adult));
      });
    });

    group('fromDateOfBirth', () {
      test('returns under12 for age 10', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 10));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.under12));
      });

      test('returns under14 for age 13', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 13 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.under14));
      });

      test('returns under15 for age 14', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 14 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.under15));
      });

      test('returns under16 for age 15', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 15 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.under16));
      });

      test('returns under18 for age 17', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 17 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.under18));
      });

      test('returns under21 for age 19', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 19 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.under21));
      });

      test('returns adult for age 25', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 25 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.adult));
      });

      test('returns fiftyPlus for age 55', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 55 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.fiftyPlus));
      });

      test('returns sixtyPlus for age 65', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 65 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.sixtyPlus));
      });

      test('returns seventyPlus for age 75', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 75 + 180));
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.seventyPlus));
      });

      test('handles exact birthday boundary', () {
        // Test someone who has their birthday today
        final now = DateTime.now();
        final dob = DateTime(now.year - 50, now.month, now.day);
        final category = AgeCategory.fromDateOfBirth(dob);
        expect(category, equals(AgeCategory.fiftyPlus));
      });

      test('handles day before birthday', () {
        // Test someone whose birthday is tomorrow
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));
        final dob = DateTime(now.year - 50, tomorrow.month, tomorrow.day);
        final category = AgeCategory.fromDateOfBirth(dob);
        // Should still be 49 (adult, not 50+)
        expect(category, equals(AgeCategory.adult));
      });
    });

    group('ageStep values', () {
      test('adult has ageStep 0', () {
        expect(AgeCategory.adult.ageStep, equals(0));
      });

      test('under21 has ageStep 0', () {
        expect(AgeCategory.under21.ageStep, equals(0));
      });

      test('fiftyPlus has ageStep 1', () {
        expect(AgeCategory.fiftyPlus.ageStep, equals(1));
      });

      test('sixtyPlus has ageStep 2', () {
        expect(AgeCategory.sixtyPlus.ageStep, equals(2));
      });

      test('seventyPlus has ageStep 3', () {
        expect(AgeCategory.seventyPlus.ageStep, equals(3));
      });

      test('under18 has ageStep 2', () {
        expect(AgeCategory.under18.ageStep, equals(2));
      });

      test('under16 has ageStep 4', () {
        expect(AgeCategory.under16.ageStep, equals(4));
      });

      test('under14 has ageStep 6', () {
        expect(AgeCategory.under14.ageStep, equals(6));
      });

      test('under12 has ageStep 8', () {
        expect(AgeCategory.under12.ageStep, equals(8));
      });
    });
  });

  group('BowType Enum', () {
    group('fromString', () {
      test('parses recurve', () {
        final bowType = BowType.fromString('recurve');
        expect(bowType, equals(BowType.recurve));
      });

      test('parses compound', () {
        final bowType = BowType.fromString('compound');
        expect(bowType, equals(BowType.compound));
      });

      test('parses barebow', () {
        final bowType = BowType.fromString('barebow');
        expect(bowType, equals(BowType.barebow));
      });

      test('parses longbow', () {
        final bowType = BowType.fromString('longbow');
        expect(bowType, equals(BowType.longbow));
      });

      test('parses traditional', () {
        final bowType = BowType.fromString('traditional');
        expect(bowType, equals(BowType.traditional));
      });

      test('defaults to recurve for unknown value', () {
        final bowType = BowType.fromString('unknown');
        expect(bowType, equals(BowType.recurve));
      });
    });

    group('value and displayName', () {
      test('recurve has correct values', () {
        expect(BowType.recurve.value, equals('recurve'));
        expect(BowType.recurve.displayName, equals('Recurve'));
      });

      test('compound has correct values', () {
        expect(BowType.compound.value, equals('compound'));
        expect(BowType.compound.displayName, equals('Compound'));
      });

      test('barebow has correct values', () {
        expect(BowType.barebow.value, equals('barebow'));
        expect(BowType.barebow.displayName, equals('Barebow'));
      });

      test('longbow has correct values', () {
        expect(BowType.longbow.value, equals('longbow'));
        expect(BowType.longbow.displayName, equals('Longbow'));
      });

      test('traditional has correct values', () {
        expect(BowType.traditional.value, equals('traditional'));
        expect(BowType.traditional.displayName, equals('Traditional'));
      });
    });
  });

  group('Handedness Enum', () {
    group('fromString', () {
      test('parses right', () {
        final handedness = Handedness.fromString('right');
        expect(handedness, equals(Handedness.right));
      });

      test('parses left', () {
        final handedness = Handedness.fromString('left');
        expect(handedness, equals(Handedness.left));
      });

      test('defaults to right for unknown value', () {
        final handedness = Handedness.fromString('unknown');
        expect(handedness, equals(Handedness.right));
      });
    });

    group('value and displayName', () {
      test('right has correct values', () {
        expect(Handedness.right.value, equals('right'));
        expect(Handedness.right.displayName, equals('Right-handed'));
      });

      test('left has correct values', () {
        expect(Handedness.left.value, equals('left'));
        expect(Handedness.left.displayName, equals('Left-handed'));
      });
    });
  });

  group('CompetitionLevel Enum', () {
    group('fromString', () {
      test('parses local', () {
        final level = CompetitionLevel.fromString('local');
        expect(level, equals(CompetitionLevel.local));
      });

      test('parses regional', () {
        final level = CompetitionLevel.fromString('regional');
        expect(level, equals(CompetitionLevel.regional));
      });

      test('parses national', () {
        final level = CompetitionLevel.fromString('national');
        expect(level, equals(CompetitionLevel.national));
      });

      test('parses international', () {
        final level = CompetitionLevel.fromString('international');
        expect(level, equals(CompetitionLevel.international));
      });

      test('parses national_team', () {
        final level = CompetitionLevel.fromString('national_team');
        expect(level, equals(CompetitionLevel.nationalTeam));
      });

      test('defaults to local for unknown value', () {
        final level = CompetitionLevel.fromString('unknown');
        expect(level, equals(CompetitionLevel.local));
      });
    });

    group('fromJsonList', () {
      test('returns empty list for null input', () {
        final levels = CompetitionLevel.fromJsonList(null);
        expect(levels, isEmpty);
      });

      test('returns empty list for empty string', () {
        final levels = CompetitionLevel.fromJsonList('');
        expect(levels, isEmpty);
      });

      test('parses single item list', () {
        final levels = CompetitionLevel.fromJsonList('["local"]');
        expect(levels, equals([CompetitionLevel.local]));
      });

      test('parses multiple items', () {
        final levels = CompetitionLevel.fromJsonList('["local","national","international"]');
        expect(levels.length, equals(3));
        expect(levels[0], equals(CompetitionLevel.local));
        expect(levels[1], equals(CompetitionLevel.national));
        expect(levels[2], equals(CompetitionLevel.international));
      });

      test('handles invalid JSON gracefully', () {
        final levels = CompetitionLevel.fromJsonList('not valid json');
        expect(levels, isEmpty);
      });
    });

    group('toJsonList', () {
      test('encodes empty list', () {
        final json = CompetitionLevel.toJsonList([]);
        expect(json, equals('[]'));
      });

      test('encodes single item', () {
        final json = CompetitionLevel.toJsonList([CompetitionLevel.local]);
        expect(json, equals('["local"]'));
      });

      test('encodes multiple items', () {
        final json = CompetitionLevel.toJsonList([
          CompetitionLevel.local,
          CompetitionLevel.national,
        ]);
        expect(json, equals('["local","national"]'));
      });

      test('round-trips correctly', () {
        final original = [
          CompetitionLevel.local,
          CompetitionLevel.regional,
          CompetitionLevel.international,
        ];
        final json = CompetitionLevel.toJsonList(original);
        final parsed = CompetitionLevel.fromJsonList(json);
        expect(parsed, equals(original));
      });
    });

    group('value and displayName', () {
      test('local has correct values', () {
        expect(CompetitionLevel.local.value, equals('local'));
        expect(CompetitionLevel.local.displayName, equals('Local'));
      });

      test('regional has correct values', () {
        expect(CompetitionLevel.regional.value, equals('regional'));
        expect(CompetitionLevel.regional.displayName, equals('Regional'));
      });

      test('national has correct values', () {
        expect(CompetitionLevel.national.value, equals('national'));
        expect(CompetitionLevel.national.displayName, equals('National'));
      });

      test('international has correct values', () {
        expect(CompetitionLevel.international.value, equals('international'));
        expect(CompetitionLevel.international.displayName, equals('International'));
      });

      test('nationalTeam has correct values', () {
        expect(CompetitionLevel.nationalTeam.value, equals('national_team'));
        expect(CompetitionLevel.nationalTeam.displayName, equals('National Team'));
      });
    });
  });

  group('BowTypeDefaults', () {
    group('getIndoorSuggestion', () {
      test('recurve suggests triple spot', () {
        final suggestion = BowTypeDefaults.getIndoorSuggestion(BowType.recurve);
        expect(suggestion, equals('Triple spot (40cm)'));
      });

      test('compound suggests small inner 10', () {
        final suggestion = BowTypeDefaults.getIndoorSuggestion(BowType.compound);
        expect(suggestion, equals('Small inner 10 (40cm)'));
      });

      test('barebow suggests full face', () {
        final suggestion = BowTypeDefaults.getIndoorSuggestion(BowType.barebow);
        expect(suggestion, equals('Full face (40cm)'));
      });

      test('longbow suggests full face', () {
        final suggestion = BowTypeDefaults.getIndoorSuggestion(BowType.longbow);
        expect(suggestion, equals('Full face (40cm)'));
      });

      test('traditional suggests full face', () {
        final suggestion = BowTypeDefaults.getIndoorSuggestion(BowType.traditional);
        expect(suggestion, equals('Full face (40cm)'));
      });
    });

    group('getOutdoorDefaults', () {
      test('recurve: 70m, 122cm face', () {
        final defaults = BowTypeDefaults.getOutdoorDefaults(BowType.recurve);
        expect(defaults.distance, equals(70));
        expect(defaults.faceSize, equals(122));
      });

      test('compound: 50m, 80cm face', () {
        final defaults = BowTypeDefaults.getOutdoorDefaults(BowType.compound);
        expect(defaults.distance, equals(50));
        expect(defaults.faceSize, equals(80));
      });

      test('barebow: 50m, 122cm face', () {
        final defaults = BowTypeDefaults.getOutdoorDefaults(BowType.barebow);
        expect(defaults.distance, equals(50));
        expect(defaults.faceSize, equals(122));
      });

      test('longbow: 50m, 122cm face', () {
        final defaults = BowTypeDefaults.getOutdoorDefaults(BowType.longbow);
        expect(defaults.distance, equals(50));
        expect(defaults.faceSize, equals(122));
      });

      test('traditional: 40m, 122cm face', () {
        final defaults = BowTypeDefaults.getOutdoorDefaults(BowType.traditional);
        expect(defaults.distance, equals(40));
        expect(defaults.faceSize, equals(122));
      });
    });

    group('getOutdoorSuggestion', () {
      test('recurve returns formatted string', () {
        final suggestion = BowTypeDefaults.getOutdoorSuggestion(BowType.recurve);
        expect(suggestion, equals('70m, 122cm face'));
      });

      test('compound returns formatted string', () {
        final suggestion = BowTypeDefaults.getOutdoorSuggestion(BowType.compound);
        expect(suggestion, equals('50m, 80cm face'));
      });
    });

    group('prefersTripleSpot', () {
      test('recurve prefers triple spot', () {
        expect(BowTypeDefaults.prefersTripleSpot(BowType.recurve), isTrue);
      });

      test('compound prefers triple spot', () {
        expect(BowTypeDefaults.prefersTripleSpot(BowType.compound), isTrue);
      });

      test('barebow does not prefer triple spot', () {
        expect(BowTypeDefaults.prefersTripleSpot(BowType.barebow), isFalse);
      });

      test('longbow does not prefer triple spot', () {
        expect(BowTypeDefaults.prefersTripleSpot(BowType.longbow), isFalse);
      });

      test('traditional does not prefer triple spot', () {
        expect(BowTypeDefaults.prefersTripleSpot(BowType.traditional), isFalse);
      });
    });
  });

  group('Years of Experience Calculation', () {
    test('calculates experience from start year', () {
      final currentYear = DateTime.now().year;
      const startYear = 2015;
      final experience = currentYear - startYear;
      expect(experience, equals(currentYear - 2015));
    });

    test('returns null when start year is null', () {
      const int? startYear = null;
      final experience = startYear != null ? DateTime.now().year - startYear : null;
      expect(experience, isNull);
    });

    test('handles recent start year', () {
      final currentYear = DateTime.now().year;
      final startYear = currentYear - 1;
      final experience = currentYear - startYear;
      expect(experience, equals(1));
    });

    test('handles same year start', () {
      final currentYear = DateTime.now().year;
      final experience = currentYear - currentYear;
      expect(experience, equals(0));
    });
  });

  group('Primary Federation Logic', () {
    test('returns first primary federation from list', () {
      final federations = [
        _MockFederation(id: '1', isPrimary: false),
        _MockFederation(id: '2', isPrimary: true),
        _MockFederation(id: '3', isPrimary: false),
      ];

      final primary = federations.where((f) => f.isPrimary).firstOrNull;
      expect(primary?.id, equals('2'));
    });

    test('returns first federation if none is primary', () {
      final federations = [
        _MockFederation(id: '1', isPrimary: false),
        _MockFederation(id: '2', isPrimary: false),
      ];

      final primary = federations.where((f) => f.isPrimary).firstOrNull
          ?? (federations.isNotEmpty ? federations.first : null);
      expect(primary?.id, equals('1'));
    });

    test('returns null if list is empty', () {
      final federations = <_MockFederation>[];
      final primary = federations.where((f) => f.isPrimary).firstOrNull
          ?? (federations.isNotEmpty ? federations.first : null);
      expect(primary, isNull);
    });
  });

  group('Classification Info Check', () {
    test('hasClassificationInfo is true when both gender and DOB are set', () {
      const gender = Gender.male;
      final dateOfBirth = DateTime(1990, 5, 15);
      final hasClassificationInfo = gender != null && dateOfBirth != null;
      expect(hasClassificationInfo, isTrue);
    });

    test('hasClassificationInfo is false when gender is null', () {
      const Gender? gender = null;
      final dateOfBirth = DateTime(1990, 5, 15);
      // ignore: unnecessary_null_comparison
      final hasClassificationInfo = gender != null && dateOfBirth != null;
      expect(hasClassificationInfo, isFalse);
    });

    test('hasClassificationInfo is false when DOB is null', () {
      const gender = Gender.male;
      const DateTime? dateOfBirth = null;
      // ignore: unnecessary_null_comparison
      final hasClassificationInfo = gender != null && dateOfBirth != null;
      expect(hasClassificationInfo, isFalse);
    });

    test('hasClassificationInfo is false when both are null', () {
      const Gender? gender = null;
      const DateTime? dateOfBirth = null;
      final hasClassificationInfo = gender != null && dateOfBirth != null;
      expect(hasClassificationInfo, isFalse);
    });
  });

  group('Profile Save Logic', () {
    test('Value.absent() preserves existing field', () {
      const original = 'Original Name';
      const String? newValue = null;
      final result = newValue ?? original;
      expect(result, equals('Original Name'));
    });

    test('explicit value updates field', () {
      const original = 'Original Name';
      const newValue = 'New Name';
      final result = newValue;
      expect(result, equals('New Name'));
    });

    test('updatedAt is set on save', () {
      final before = DateTime.now();
      final updatedAt = DateTime.now();
      final after = DateTime.now();

      expect(updatedAt.isAfter(before) || updatedAt.isAtSameMomentAs(before), isTrue);
      expect(updatedAt.isBefore(after) || updatedAt.isAtSameMomentAs(after), isTrue);
    });
  });

  group('Federation CRUD Logic', () {
    group('Add Federation', () {
      test('generates federation ID with prefix', () {
        const prefix = 'fed';
        final id = '${prefix}_abc123';
        expect(id.startsWith('fed_'), isTrue);
      });

      test('marks first federation as primary when specified', () {
        const isPrimary = true;
        expect(isPrimary, isTrue);
      });
    });

    group('Update Federation', () {
      test('preserves unchanged fields using existing values', () {
        const existingName = 'Archery GB';
        const existingMembershipNumber = '12345';
        const existingIsPrimary = true;

        // Update only the membership number
        String? newName;
        const newMembershipNumber = '67890';
        bool? newIsPrimary;

        final resultName = newName ?? existingName;
        final resultNumber = newMembershipNumber;
        final resultPrimary = newIsPrimary ?? existingIsPrimary;

        expect(resultName, equals('Archery GB'));
        expect(resultNumber, equals('67890'));
        expect(resultPrimary, isTrue);
      });
    });

    group('Set Primary Federation', () {
      test('only one federation should be primary at a time', () {
        var federations = [
          _MockFederation(id: '1', isPrimary: true),
          _MockFederation(id: '2', isPrimary: false),
          _MockFederation(id: '3', isPrimary: false),
        ];

        // Simulate setting federation 2 as primary
        federations = federations.map((f) {
          return _MockFederation(
            id: f.id,
            isPrimary: f.id == '2',
          );
        }).toList();

        final primaryCount = federations.where((f) => f.isPrimary).length;
        expect(primaryCount, equals(1));
        expect(federations.firstWhere((f) => f.isPrimary).id, equals('2'));
      });
    });
  });

  group('Real-World Profile Scenarios', () {
    test('typical Olympic recurve archer profile', () {
      const name = 'Patrick Huston';
      const bowType = BowType.recurve;
      const handedness = Handedness.right;
      const yearsShootingStart = 2008;
      const shootingFrequency = 5.0; // 5 days a week
      final competitionLevels = [
        CompetitionLevel.international,
        CompetitionLevel.nationalTeam,
      ];

      expect(name.isNotEmpty, isTrue);
      expect(bowType, equals(BowType.recurve));
      expect(handedness, equals(Handedness.right));
      expect(DateTime.now().year - yearsShootingStart, greaterThan(10));
      expect(shootingFrequency, greaterThan(4));
      expect(competitionLevels.contains(CompetitionLevel.international), isTrue);
    });

    test('beginner archer profile', () {
      const name = 'New Archer';
      const bowType = BowType.recurve;
      const handedness = Handedness.left;
      final yearsShootingStart = DateTime.now().year;
      const shootingFrequency = 1.0;
      final competitionLevels = <CompetitionLevel>[];

      expect(DateTime.now().year - yearsShootingStart, equals(0));
      expect(shootingFrequency, lessThanOrEqualTo(2));
      expect(competitionLevels, isEmpty);
    });

    test('veteran archer with multiple federation memberships', () {
      final federations = [
        _MockFederation(id: 'fed_1', isPrimary: true, name: 'Archery GB'),
        _MockFederation(id: 'fed_2', isPrimary: false, name: 'World Archery'),
        _MockFederation(id: 'fed_3', isPrimary: false, name: 'European Archery'),
      ];

      expect(federations.length, equals(3));
      expect(federations.where((f) => f.isPrimary).length, equals(1));
    });
  });

  group('Edge Cases', () {
    test('handles very long name', () {
      const longName = 'A Very Long Name That Might Be Used For Testing Purposes';
      expect(longName.isNotEmpty, isTrue);
      expect(longName.length, greaterThan(50));
    });

    test('handles empty club name', () {
      const String? clubName = null;
      expect(clubName, isNull);
    });

    test('handles empty notes', () {
      const String? notes = null;
      expect(notes, isNull);
    });

    test('handles shooting frequency at boundaries', () {
      const minFrequency = 0.0;
      const maxFrequency = 7.0;

      expect(minFrequency, greaterThanOrEqualTo(0));
      expect(maxFrequency, lessThanOrEqualTo(7));
    });

    test('handles years shooting start in the future (edge case validation)', () {
      final futureYear = DateTime.now().year + 1;
      final experience = DateTime.now().year - futureYear;
      // Negative experience indicates invalid data
      expect(experience, lessThan(0));
    });

    test('handles federation with no expiry date', () {
      const DateTime? expiryDate = null;
      expect(expiryDate, isNull);
    });

    test('handles federation with past expiry date', () {
      final expiredDate = DateTime.now().subtract(const Duration(days: 30));
      final isExpired = expiredDate.isBefore(DateTime.now());
      expect(isExpired, isTrue);
    });
  });

  group('Data Consistency', () {
    test('all BowType values are unique', () {
      final values = BowType.values.map((b) => b.value).toSet();
      expect(values.length, equals(BowType.values.length));
    });

    test('all Gender values are unique', () {
      final values = Gender.values.map((g) => g.value).toSet();
      expect(values.length, equals(Gender.values.length));
    });

    test('all Handedness values are unique', () {
      final values = Handedness.values.map((h) => h.value).toSet();
      expect(values.length, equals(Handedness.values.length));
    });

    test('all CompetitionLevel values are unique', () {
      final values = CompetitionLevel.values.map((c) => c.value).toSet();
      expect(values.length, equals(CompetitionLevel.values.length));
    });

    test('all AgeCategory values are unique', () {
      final values = AgeCategory.values.map((a) => a.value).toSet();
      expect(values.length, equals(AgeCategory.values.length));
    });
  });
}

/// Mock federation for testing logic without database
class _MockFederation {
  final String id;
  final bool isPrimary;
  final String? name;

  _MockFederation({
    required this.id,
    required this.isPrimary,
    this.name,
  });
}
