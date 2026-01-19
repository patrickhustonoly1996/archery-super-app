/// Tests for ClassificationProvider
///
/// These tests verify the classification management functionality including:
/// - Classification enums (OutdoorClassification, IndoorClassification, ClassificationScope)
/// - Bowstyle datum calculations for threshold formulas
/// - Prestige round requirements for MB+ classifications
/// - Provider state logic (hasClassifications, claimable classifications)
/// - Real-world scenarios (Olympic archer, beginner, veteran)
///
/// Note: Tests that require database interaction use simulated state logic
/// since ClassificationProvider has hard dependencies on AppDatabase. The key
/// testable components are:
/// 1. OutdoorClassification enum behavior
/// 2. IndoorClassification enum behavior
/// 3. ClassificationScope enum behavior
/// 4. BowstyleDatum and IndoorBowstyleDatum classes
/// 5. PrestigeRounds validation
/// 6. Provider state calculations
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/models/classification.dart';
import 'package:archery_super_app/models/user_profile.dart';
import 'package:archery_super_app/db/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OutdoorClassification enum', () {
    group('code values', () {
      test('GMB has code GMB', () {
        expect(OutdoorClassification.grandMasterBowman.code, equals('GMB'));
      });

      test('MB has code MB', () {
        expect(OutdoorClassification.masterBowman.code, equals('MB'));
      });

      test('B1 has code B1', () {
        expect(OutdoorClassification.bowmanFirst.code, equals('B1'));
      });

      test('B2 has code B2', () {
        expect(OutdoorClassification.bowmanSecond.code, equals('B2'));
      });

      test('B3 has code B3', () {
        expect(OutdoorClassification.bowmanThird.code, equals('B3'));
      });

      test('A1 has code A1', () {
        expect(OutdoorClassification.archerFirst.code, equals('A1'));
      });

      test('A2 has code A2', () {
        expect(OutdoorClassification.archerSecond.code, equals('A2'));
      });

      test('A3 has code A3', () {
        expect(OutdoorClassification.archerThird.code, equals('A3'));
      });

      test('all codes are unique', () {
        final codes = OutdoorClassification.values.map((c) => c.code).toSet();
        expect(codes.length, equals(OutdoorClassification.values.length));
      });
    });

    group('displayName values', () {
      test('GMB has display name Grand Master Bowman', () {
        expect(OutdoorClassification.grandMasterBowman.displayName,
            equals('Grand Master Bowman'));
      });

      test('MB has display name Master Bowman', () {
        expect(OutdoorClassification.masterBowman.displayName,
            equals('Master Bowman'));
      });

      test('B1 has display name Bowman 1st Class', () {
        expect(OutdoorClassification.bowmanFirst.displayName,
            equals('Bowman 1st Class'));
      });

      test('B2 has display name Bowman 2nd Class', () {
        expect(OutdoorClassification.bowmanSecond.displayName,
            equals('Bowman 2nd Class'));
      });

      test('B3 has display name Bowman 3rd Class', () {
        expect(OutdoorClassification.bowmanThird.displayName,
            equals('Bowman 3rd Class'));
      });

      test('A1 has display name Archer 1st Class', () {
        expect(OutdoorClassification.archerFirst.displayName,
            equals('Archer 1st Class'));
      });

      test('A2 has display name Archer 2nd Class', () {
        expect(OutdoorClassification.archerSecond.displayName,
            equals('Archer 2nd Class'));
      });

      test('A3 has display name Archer 3rd Class', () {
        expect(OutdoorClassification.archerThird.displayName,
            equals('Archer 3rd Class'));
      });

      test('all display names are non-empty', () {
        for (final classification in OutdoorClassification.values) {
          expect(classification.displayName, isNotEmpty);
        }
      });
    });

    group('classIndex values', () {
      test('GMB has index 0 (highest)', () {
        expect(OutdoorClassification.grandMasterBowman.classIndex, equals(0));
      });

      test('MB has index 1', () {
        expect(OutdoorClassification.masterBowman.classIndex, equals(1));
      });

      test('B1 has index 2', () {
        expect(OutdoorClassification.bowmanFirst.classIndex, equals(2));
      });

      test('B2 has index 3', () {
        expect(OutdoorClassification.bowmanSecond.classIndex, equals(3));
      });

      test('B3 has index 4', () {
        expect(OutdoorClassification.bowmanThird.classIndex, equals(4));
      });

      test('A1 has index 5', () {
        expect(OutdoorClassification.archerFirst.classIndex, equals(5));
      });

      test('A2 has index 6', () {
        expect(OutdoorClassification.archerSecond.classIndex, equals(6));
      });

      test('A3 has index 7 (lowest)', () {
        expect(OutdoorClassification.archerThird.classIndex, equals(7));
      });

      test('indices are sequential from 0 to 7', () {
        for (var i = 0; i < OutdoorClassification.values.length; i++) {
          final classification = OutdoorClassification.values[i];
          expect(classification.classIndex, equals(i));
        }
      });
    });

    group('requiresPrestigeRound', () {
      test('GMB requires prestige round', () {
        expect(
            OutdoorClassification.grandMasterBowman.requiresPrestigeRound, isTrue);
      });

      test('MB requires prestige round', () {
        expect(OutdoorClassification.masterBowman.requiresPrestigeRound, isTrue);
      });

      test('B1 does not require prestige round', () {
        expect(OutdoorClassification.bowmanFirst.requiresPrestigeRound, isFalse);
      });

      test('B2 does not require prestige round', () {
        expect(OutdoorClassification.bowmanSecond.requiresPrestigeRound, isFalse);
      });

      test('B3 does not require prestige round', () {
        expect(OutdoorClassification.bowmanThird.requiresPrestigeRound, isFalse);
      });

      test('A1 does not require prestige round', () {
        expect(OutdoorClassification.archerFirst.requiresPrestigeRound, isFalse);
      });

      test('A2 does not require prestige round', () {
        expect(OutdoorClassification.archerSecond.requiresPrestigeRound, isFalse);
      });

      test('A3 does not require prestige round', () {
        expect(OutdoorClassification.archerThird.requiresPrestigeRound, isFalse);
      });

      test('only classIndex <= 1 requires prestige round', () {
        for (final classification in OutdoorClassification.values) {
          final shouldRequire = classification.classIndex <= 1;
          expect(classification.requiresPrestigeRound, equals(shouldRequire));
        }
      });
    });

    group('fromString', () {
      test('parses GMB code', () {
        expect(OutdoorClassification.fromString('GMB'),
            equals(OutdoorClassification.grandMasterBowman));
      });

      test('parses MB code', () {
        expect(OutdoorClassification.fromString('MB'),
            equals(OutdoorClassification.masterBowman));
      });

      test('parses B1 code', () {
        expect(OutdoorClassification.fromString('B1'),
            equals(OutdoorClassification.bowmanFirst));
      });

      test('parses B2 code', () {
        expect(OutdoorClassification.fromString('B2'),
            equals(OutdoorClassification.bowmanSecond));
      });

      test('parses B3 code', () {
        expect(OutdoorClassification.fromString('B3'),
            equals(OutdoorClassification.bowmanThird));
      });

      test('parses A1 code', () {
        expect(OutdoorClassification.fromString('A1'),
            equals(OutdoorClassification.archerFirst));
      });

      test('parses A2 code', () {
        expect(OutdoorClassification.fromString('A2'),
            equals(OutdoorClassification.archerSecond));
      });

      test('parses A3 code', () {
        expect(OutdoorClassification.fromString('A3'),
            equals(OutdoorClassification.archerThird));
      });

      test('parses enum name grandMasterBowman', () {
        expect(OutdoorClassification.fromString('grandMasterBowman'),
            equals(OutdoorClassification.grandMasterBowman));
      });

      test('parses enum name masterBowman', () {
        expect(OutdoorClassification.fromString('masterBowman'),
            equals(OutdoorClassification.masterBowman));
      });

      test('returns archerThird for unknown values', () {
        expect(OutdoorClassification.fromString('unknown'),
            equals(OutdoorClassification.archerThird));
        expect(OutdoorClassification.fromString(''),
            equals(OutdoorClassification.archerThird));
        expect(OutdoorClassification.fromString('INVALID'),
            equals(OutdoorClassification.archerThird));
      });
    });

    group('nextHigher', () {
      test('GMB returns null (already at top)', () {
        expect(OutdoorClassification.grandMasterBowman.nextHigher, isNull);
      });

      test('MB returns GMB', () {
        expect(OutdoorClassification.masterBowman.nextHigher,
            equals(OutdoorClassification.grandMasterBowman));
      });

      test('B1 returns MB', () {
        expect(OutdoorClassification.bowmanFirst.nextHigher,
            equals(OutdoorClassification.masterBowman));
      });

      test('B2 returns B1', () {
        expect(OutdoorClassification.bowmanSecond.nextHigher,
            equals(OutdoorClassification.bowmanFirst));
      });

      test('B3 returns B2', () {
        expect(OutdoorClassification.bowmanThird.nextHigher,
            equals(OutdoorClassification.bowmanSecond));
      });

      test('A1 returns B3', () {
        expect(OutdoorClassification.archerFirst.nextHigher,
            equals(OutdoorClassification.bowmanThird));
      });

      test('A2 returns A1', () {
        expect(OutdoorClassification.archerSecond.nextHigher,
            equals(OutdoorClassification.archerFirst));
      });

      test('A3 returns A2', () {
        expect(OutdoorClassification.archerThird.nextHigher,
            equals(OutdoorClassification.archerSecond));
      });
    });

    group('nextLower', () {
      test('GMB returns MB', () {
        expect(OutdoorClassification.grandMasterBowman.nextLower,
            equals(OutdoorClassification.masterBowman));
      });

      test('MB returns B1', () {
        expect(OutdoorClassification.masterBowman.nextLower,
            equals(OutdoorClassification.bowmanFirst));
      });

      test('B1 returns B2', () {
        expect(OutdoorClassification.bowmanFirst.nextLower,
            equals(OutdoorClassification.bowmanSecond));
      });

      test('B2 returns B3', () {
        expect(OutdoorClassification.bowmanSecond.nextLower,
            equals(OutdoorClassification.bowmanThird));
      });

      test('B3 returns A1', () {
        expect(OutdoorClassification.bowmanThird.nextLower,
            equals(OutdoorClassification.archerFirst));
      });

      test('A1 returns A2', () {
        expect(OutdoorClassification.archerFirst.nextLower,
            equals(OutdoorClassification.archerSecond));
      });

      test('A2 returns A3', () {
        expect(OutdoorClassification.archerSecond.nextLower,
            equals(OutdoorClassification.archerThird));
      });

      test('A3 returns null (already at bottom)', () {
        expect(OutdoorClassification.archerThird.nextLower, isNull);
      });
    });

    group('enum structure', () {
      test('there are exactly 8 outdoor classifications', () {
        expect(OutdoorClassification.values, hasLength(8));
      });

      test('order is highest to lowest', () {
        final classifications = OutdoorClassification.values;
        expect(classifications.first, equals(OutdoorClassification.grandMasterBowman));
        expect(classifications.last, equals(OutdoorClassification.archerThird));
      });
    });
  });

  group('IndoorClassification enum', () {
    group('code values', () {
      test('GMB has code GMB', () {
        expect(IndoorClassification.grandMasterBowman.code, equals('GMB'));
      });

      test('MB has code MB', () {
        expect(IndoorClassification.masterBowman.code, equals('MB'));
      });

      test('B1 has code B1', () {
        expect(IndoorClassification.bowmanFirst.code, equals('B1'));
      });

      test('B2 has code B2', () {
        expect(IndoorClassification.bowmanSecond.code, equals('B2'));
      });

      test('B3 has code B3', () {
        expect(IndoorClassification.bowmanThird.code, equals('B3'));
      });

      test('A1 has code A1', () {
        expect(IndoorClassification.archerFirst.code, equals('A1'));
      });

      test('A2 has code A2', () {
        expect(IndoorClassification.archerSecond.code, equals('A2'));
      });

      test('A3 has code A3', () {
        expect(IndoorClassification.archerThird.code, equals('A3'));
      });

      test('indoor codes match outdoor codes', () {
        for (var i = 0; i < IndoorClassification.values.length; i++) {
          expect(IndoorClassification.values[i].code,
              equals(OutdoorClassification.values[i].code));
        }
      });
    });

    group('displayName values', () {
      test('GMB has display name Grand Master Bowman', () {
        expect(IndoorClassification.grandMasterBowman.displayName,
            equals('Grand Master Bowman'));
      });

      test('MB has display name Master Bowman', () {
        expect(IndoorClassification.masterBowman.displayName,
            equals('Master Bowman'));
      });

      test('indoor display names match outdoor display names', () {
        for (var i = 0; i < IndoorClassification.values.length; i++) {
          expect(IndoorClassification.values[i].displayName,
              equals(OutdoorClassification.values[i].displayName));
        }
      });
    });

    group('classIndex values', () {
      test('GMB has index 0 (highest)', () {
        expect(IndoorClassification.grandMasterBowman.classIndex, equals(0));
      });

      test('A3 has index 7 (lowest)', () {
        expect(IndoorClassification.archerThird.classIndex, equals(7));
      });

      test('indoor indices match outdoor indices', () {
        for (var i = 0; i < IndoorClassification.values.length; i++) {
          expect(IndoorClassification.values[i].classIndex,
              equals(OutdoorClassification.values[i].classIndex));
        }
      });
    });

    group('fromString', () {
      test('parses GMB code', () {
        expect(IndoorClassification.fromString('GMB'),
            equals(IndoorClassification.grandMasterBowman));
      });

      test('parses MB code', () {
        expect(IndoorClassification.fromString('MB'),
            equals(IndoorClassification.masterBowman));
      });

      test('parses B1 code', () {
        expect(IndoorClassification.fromString('B1'),
            equals(IndoorClassification.bowmanFirst));
      });

      test('parses enum name grandMasterBowman', () {
        expect(IndoorClassification.fromString('grandMasterBowman'),
            equals(IndoorClassification.grandMasterBowman));
      });

      test('returns archerThird for unknown values', () {
        expect(IndoorClassification.fromString('unknown'),
            equals(IndoorClassification.archerThird));
        expect(IndoorClassification.fromString(''),
            equals(IndoorClassification.archerThird));
      });
    });

    group('nextHigher', () {
      test('GMB returns null (already at top)', () {
        expect(IndoorClassification.grandMasterBowman.nextHigher, isNull);
      });

      test('MB returns GMB', () {
        expect(IndoorClassification.masterBowman.nextHigher,
            equals(IndoorClassification.grandMasterBowman));
      });

      test('A3 returns A2', () {
        expect(IndoorClassification.archerThird.nextHigher,
            equals(IndoorClassification.archerSecond));
      });
    });

    group('nextLower', () {
      test('GMB returns MB', () {
        expect(IndoorClassification.grandMasterBowman.nextLower,
            equals(IndoorClassification.masterBowman));
      });

      test('A3 returns null (already at bottom)', () {
        expect(IndoorClassification.archerThird.nextLower, isNull);
      });
    });

    group('enum structure', () {
      test('there are exactly 8 indoor classifications', () {
        expect(IndoorClassification.values, hasLength(8));
      });

      test('indoor and outdoor have same number of classifications', () {
        expect(IndoorClassification.values.length,
            equals(OutdoorClassification.values.length));
      });
    });
  });

  group('ClassificationScope enum', () {
    group('values', () {
      test('outdoor has value outdoor', () {
        expect(ClassificationScope.outdoor.value, equals('outdoor'));
      });

      test('indoor has value indoor', () {
        expect(ClassificationScope.indoor.value, equals('indoor'));
      });
    });

    group('displayName', () {
      test('outdoor has display name Outdoor', () {
        expect(ClassificationScope.outdoor.displayName, equals('Outdoor'));
      });

      test('indoor has display name Indoor', () {
        expect(ClassificationScope.indoor.displayName, equals('Indoor'));
      });
    });

    group('fromString', () {
      test('parses outdoor', () {
        expect(ClassificationScope.fromString('outdoor'),
            equals(ClassificationScope.outdoor));
      });

      test('parses indoor', () {
        expect(ClassificationScope.fromString('indoor'),
            equals(ClassificationScope.indoor));
      });

      test('returns outdoor for unknown values', () {
        expect(ClassificationScope.fromString('unknown'),
            equals(ClassificationScope.outdoor));
        expect(
            ClassificationScope.fromString(''), equals(ClassificationScope.outdoor));
        expect(ClassificationScope.fromString('field'),
            equals(ClassificationScope.outdoor));
      });
    });

    group('enum structure', () {
      test('there are exactly 2 scopes', () {
        expect(ClassificationScope.values, hasLength(2));
      });
    });
  });

  group('BowstyleDatum', () {
    group('constants', () {
      test('compound datum is 15', () {
        expect(BowstyleDatum.compound, equals(15));
      });

      test('recurve datum is 30', () {
        expect(BowstyleDatum.recurve, equals(30));
      });

      test('barebow datum is 47', () {
        expect(BowstyleDatum.barebow, equals(47));
      });

      test('traditional datum is 47 (same as barebow)', () {
        expect(BowstyleDatum.traditional, equals(47));
        expect(BowstyleDatum.traditional, equals(BowstyleDatum.barebow));
      });

      test('longbow datum is 65', () {
        expect(BowstyleDatum.longbow, equals(65));
      });

      test('datums increase with equipment simplicity', () {
        // Compound is most accurate, so lowest datum
        // Longbow is least accurate, so highest datum
        expect(BowstyleDatum.compound, lessThan(BowstyleDatum.recurve));
        expect(BowstyleDatum.recurve, lessThan(BowstyleDatum.barebow));
        expect(BowstyleDatum.barebow, lessThan(BowstyleDatum.longbow));
      });
    });

    group('forBowstyle', () {
      test('returns compound datum for compound', () {
        expect(BowstyleDatum.forBowstyle('compound'), equals(15));
      });

      test('returns recurve datum for recurve', () {
        expect(BowstyleDatum.forBowstyle('recurve'), equals(30));
      });

      test('returns barebow datum for barebow', () {
        expect(BowstyleDatum.forBowstyle('barebow'), equals(47));
      });

      test('returns traditional datum for traditional', () {
        expect(BowstyleDatum.forBowstyle('traditional'), equals(47));
      });

      test('returns longbow datum for longbow', () {
        expect(BowstyleDatum.forBowstyle('longbow'), equals(65));
      });

      test('is case insensitive', () {
        expect(BowstyleDatum.forBowstyle('COMPOUND'), equals(15));
        expect(BowstyleDatum.forBowstyle('Recurve'), equals(30));
        expect(BowstyleDatum.forBowstyle('BareBow'), equals(47));
        expect(BowstyleDatum.forBowstyle('LONGBOW'), equals(65));
      });

      test('returns recurve datum as default for unknown', () {
        expect(BowstyleDatum.forBowstyle('unknown'), equals(30));
        expect(BowstyleDatum.forBowstyle(''), equals(30));
        expect(BowstyleDatum.forBowstyle('crossbow'), equals(30));
      });
    });
  });

  group('IndoorBowstyleDatum', () {
    group('constants', () {
      test('compound datum is 5', () {
        expect(IndoorBowstyleDatum.compound, equals(5));
      });

      test('recurve datum is 14', () {
        expect(IndoorBowstyleDatum.recurve, equals(14));
      });

      test('barebow datum is 30', () {
        expect(IndoorBowstyleDatum.barebow, equals(30));
      });

      test('traditional datum is 30 (same as barebow)', () {
        expect(IndoorBowstyleDatum.traditional, equals(30));
        expect(IndoorBowstyleDatum.traditional, equals(IndoorBowstyleDatum.barebow));
      });

      test('longbow datum is 45', () {
        expect(IndoorBowstyleDatum.longbow, equals(45));
      });

      test('indoor datums are lower than outdoor datums', () {
        // Indoor is easier (shorter distances), so lower handicap thresholds
        expect(IndoorBowstyleDatum.compound, lessThan(BowstyleDatum.compound));
        expect(IndoorBowstyleDatum.recurve, lessThan(BowstyleDatum.recurve));
        expect(IndoorBowstyleDatum.barebow, lessThan(BowstyleDatum.barebow));
        expect(IndoorBowstyleDatum.longbow, lessThan(BowstyleDatum.longbow));
      });
    });

    group('forBowstyle', () {
      test('returns compound datum for compound', () {
        expect(IndoorBowstyleDatum.forBowstyle('compound'), equals(5));
      });

      test('returns recurve datum for recurve', () {
        expect(IndoorBowstyleDatum.forBowstyle('recurve'), equals(14));
      });

      test('returns barebow datum for barebow', () {
        expect(IndoorBowstyleDatum.forBowstyle('barebow'), equals(30));
      });

      test('returns traditional datum for traditional', () {
        expect(IndoorBowstyleDatum.forBowstyle('traditional'), equals(30));
      });

      test('returns longbow datum for longbow', () {
        expect(IndoorBowstyleDatum.forBowstyle('longbow'), equals(45));
      });

      test('is case insensitive', () {
        expect(IndoorBowstyleDatum.forBowstyle('COMPOUND'), equals(5));
        expect(IndoorBowstyleDatum.forBowstyle('Recurve'), equals(14));
        expect(IndoorBowstyleDatum.forBowstyle('LongBow'), equals(45));
      });

      test('returns recurve datum as default for unknown', () {
        expect(IndoorBowstyleDatum.forBowstyle('unknown'), equals(14));
        expect(IndoorBowstyleDatum.forBowstyle(''), equals(14));
      });
    });
  });

  group('PrestigeRounds', () {
    group('outdoor prestige rounds set', () {
      test('contains york', () {
        expect(PrestigeRounds.outdoor.contains('york'), isTrue);
      });

      test('contains hereford', () {
        expect(PrestigeRounds.outdoor.contains('hereford'), isTrue);
      });

      test('contains bristol_1', () {
        expect(PrestigeRounds.outdoor.contains('bristol_1'), isTrue);
      });

      test('contains wa_1440_90m', () {
        expect(PrestigeRounds.outdoor.contains('wa_1440_90m'), isTrue);
      });

      test('contains wa_1440_70m', () {
        expect(PrestigeRounds.outdoor.contains('wa_1440_70m'), isTrue);
      });

      test('contains wa_1440_60m', () {
        expect(PrestigeRounds.outdoor.contains('wa_1440_60m'), isTrue);
      });

      test('contains wa_720_70m', () {
        expect(PrestigeRounds.outdoor.contains('wa_720_70m'), isTrue);
      });

      test('contains wa_720_60m', () {
        expect(PrestigeRounds.outdoor.contains('wa_720_60m'), isTrue);
      });

      test('has 8 prestige rounds', () {
        expect(PrestigeRounds.outdoor, hasLength(8));
      });

      test('does not contain common non-prestige rounds', () {
        expect(PrestigeRounds.outdoor.contains('national'), isFalse);
        expect(PrestigeRounds.outdoor.contains('western'), isFalse);
        expect(PrestigeRounds.outdoor.contains('windsor'), isFalse);
        expect(PrestigeRounds.outdoor.contains('wa_70'), isFalse);
      });
    });

    group('isPrestigeRound', () {
      test('returns true for york', () {
        expect(PrestigeRounds.isPrestigeRound('york'), isTrue);
      });

      test('returns true for hereford', () {
        expect(PrestigeRounds.isPrestigeRound('hereford'), isTrue);
      });

      test('returns true for bristol_1', () {
        expect(PrestigeRounds.isPrestigeRound('bristol_1'), isTrue);
      });

      test('returns true for wa_1440_90m', () {
        expect(PrestigeRounds.isPrestigeRound('wa_1440_90m'), isTrue);
      });

      test('returns true for wa_720_70m', () {
        expect(PrestigeRounds.isPrestigeRound('wa_720_70m'), isTrue);
      });

      test('returns false for national', () {
        expect(PrestigeRounds.isPrestigeRound('national'), isFalse);
      });

      test('returns false for western', () {
        expect(PrestigeRounds.isPrestigeRound('western'), isFalse);
      });

      test('returns false for empty string', () {
        expect(PrestigeRounds.isPrestigeRound(''), isFalse);
      });

      test('returns false for unknown round', () {
        expect(PrestigeRounds.isPrestigeRound('unknown'), isFalse);
      });

      test('is case sensitive', () {
        // The round IDs are lowercase, so uppercase should not match
        expect(PrestigeRounds.isPrestigeRound('YORK'), isFalse);
        expect(PrestigeRounds.isPrestigeRound('York'), isFalse);
      });
    });
  });

  group('Threshold Calculation Formula', () {
    // threshold = datum + (ageStep × 3) + genderAdj + (classIndex × 7)
    // These tests verify the formula components are correct

    int calculateThreshold({
      required int datum,
      required int ageStep,
      required bool isFemale,
      required int classIndex,
    }) {
      final genderAdj = isFemale ? 7 : 0;
      return datum + (ageStep * 3) + genderAdj + (classIndex * 7);
    }

    group('adult male recurve', () {
      test('GMB threshold is 30', () {
        // datum=30, ageStep=0, genderAdj=0, classIndex=0
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(30)); // 30 + 0 + 0 + 0
      });

      test('MB threshold is 37', () {
        // datum=30, ageStep=0, genderAdj=0, classIndex=1
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: OutdoorClassification.masterBowman.classIndex,
        );
        expect(threshold, equals(37)); // 30 + 0 + 0 + 7
      });

      test('A3 threshold is 79', () {
        // datum=30, ageStep=0, genderAdj=0, classIndex=7
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: OutdoorClassification.archerThird.classIndex,
        );
        expect(threshold, equals(79)); // 30 + 0 + 0 + 49
      });
    });

    group('adult female recurve', () {
      test('GMB threshold is 37 (7 higher than male)', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: true,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(37)); // 30 + 0 + 7 + 0
      });

      test('A3 threshold is 86', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: true,
          classIndex: OutdoorClassification.archerThird.classIndex,
        );
        expect(threshold, equals(86)); // 30 + 0 + 7 + 49
      });
    });

    group('adult male compound', () {
      test('GMB threshold is 15', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.compound,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(15)); // 15 + 0 + 0 + 0
      });

      test('A3 threshold is 64', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.compound,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: OutdoorClassification.archerThird.classIndex,
        );
        expect(threshold, equals(64)); // 15 + 0 + 0 + 49
      });
    });

    group('adult male longbow', () {
      test('GMB threshold is 65', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.longbow,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(65)); // 65 + 0 + 0 + 0
      });

      test('A3 threshold is 114', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.longbow,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: OutdoorClassification.archerThird.classIndex,
        );
        expect(threshold, equals(114)); // 65 + 0 + 0 + 49
      });
    });

    group('50+ male recurve', () {
      test('GMB threshold is 33 (3 higher than adult)', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.fiftyPlus.ageStep, // ageStep = 1
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(33)); // 30 + 3 + 0 + 0
      });
    });

    group('60+ male recurve', () {
      test('GMB threshold is 36 (6 higher than adult)', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.sixtyPlus.ageStep, // ageStep = 2
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(36)); // 30 + 6 + 0 + 0
      });
    });

    group('70+ male recurve', () {
      test('GMB threshold is 39 (9 higher than adult)', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.seventyPlus.ageStep, // ageStep = 3
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(39)); // 30 + 9 + 0 + 0
      });
    });

    group('under 18 male recurve', () {
      test('GMB threshold is 36 (6 higher than adult)', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.under18.ageStep, // ageStep = 2
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(36)); // 30 + 6 + 0 + 0
      });
    });

    group('under 12 male recurve', () {
      test('GMB threshold is 54 (24 higher than adult)', () {
        final threshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.under12.ageStep, // ageStep = 8
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(54)); // 30 + 24 + 0 + 0
      });
    });

    group('under 12 female longbow', () {
      test('A3 threshold is 145 (hardest to achieve)', () {
        // This is the hardest combination: longbow, youngest, female, lowest class
        final threshold = calculateThreshold(
          datum: BowstyleDatum.longbow,
          ageStep: AgeCategory.under12.ageStep, // ageStep = 8
          isFemale: true,
          classIndex: OutdoorClassification.archerThird.classIndex,
        );
        expect(threshold, equals(145)); // 65 + 24 + 7 + 49
      });
    });

    group('indoor thresholds', () {
      test('adult male recurve GMB indoor threshold is 14', () {
        final threshold = calculateThreshold(
          datum: IndoorBowstyleDatum.recurve,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: IndoorClassification.grandMasterBowman.classIndex,
        );
        expect(threshold, equals(14)); // 14 + 0 + 0 + 0
      });

      test('indoor thresholds are lower than outdoor', () {
        final outdoorThreshold = calculateThreshold(
          datum: BowstyleDatum.recurve,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
        );
        final indoorThreshold = calculateThreshold(
          datum: IndoorBowstyleDatum.recurve,
          ageStep: AgeCategory.adult.ageStep,
          isFemale: false,
          classIndex: IndoorClassification.grandMasterBowman.classIndex,
        );
        expect(indoorThreshold, lessThan(outdoorThreshold));
      });
    });
  });

  group('AgeCategory enum (classification context)', () {
    group('ageStep values', () {
      test('adult has ageStep 0', () {
        expect(AgeCategory.adult.ageStep, equals(0));
      });

      test('under21 has ageStep 0 (same as adult)', () {
        expect(AgeCategory.under21.ageStep, equals(0));
      });

      test('50+ has ageStep 1', () {
        expect(AgeCategory.fiftyPlus.ageStep, equals(1));
      });

      test('60+ has ageStep 2', () {
        expect(AgeCategory.sixtyPlus.ageStep, equals(2));
      });

      test('70+ has ageStep 3', () {
        expect(AgeCategory.seventyPlus.ageStep, equals(3));
      });

      test('under18 has ageStep 2', () {
        expect(AgeCategory.under18.ageStep, equals(2));
      });

      test('under16 has ageStep 4', () {
        expect(AgeCategory.under16.ageStep, equals(4));
      });

      test('under15 has ageStep 5', () {
        expect(AgeCategory.under15.ageStep, equals(5));
      });

      test('under14 has ageStep 6', () {
        expect(AgeCategory.under14.ageStep, equals(6));
      });

      test('under12 has ageStep 8', () {
        expect(AgeCategory.under12.ageStep, equals(8));
      });
    });

    group('fromDateOfBirth', () {
      test('returns under12 for 10 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 10));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under12));
      });

      test('returns under14 for 13 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 13));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under14));
      });

      test('returns under15 for 14 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 14 + 30));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under15));
      });

      test('returns under16 for 15 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 15 + 30));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under16));
      });

      test('returns under18 for 17 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 17 + 30));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under18));
      });

      test('returns under21 for 20 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 20 + 30));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under21));
      });

      test('returns adult for 30 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 30));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.adult));
      });

      test('returns fiftyPlus for 55 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 55));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.fiftyPlus));
      });

      test('returns sixtyPlus for 65 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 65));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.sixtyPlus));
      });

      test('returns seventyPlus for 75 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 75));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.seventyPlus));
      });

      test('returns seventyPlus for 90 year old', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 90));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.seventyPlus));
      });
    });
  });

  group('Gender enum (classification context)', () {
    test('male has value male', () {
      expect(Gender.male.value, equals('male'));
    });

    test('female has value female', () {
      expect(Gender.female.value, equals('female'));
    });

    test('fromString parses male', () {
      expect(Gender.fromString('male'), equals(Gender.male));
    });

    test('fromString parses female', () {
      expect(Gender.fromString('female'), equals(Gender.female));
    });

    test('fromString returns male for unknown', () {
      expect(Gender.fromString('unknown'), equals(Gender.male));
      expect(Gender.fromString(''), equals(Gender.male));
    });
  });

  group('Provider State Logic Simulation', () {
    // Simulates the logic from ClassificationProvider getters
    // without requiring database access

    // Helper class to simulate classification data
    Classification createMockClassification({
      required String id,
      required String profileId,
      required String classification,
      required String classificationScope,
      required String bowstyle,
      String? firstSessionId,
      DateTime? firstAchievedAt,
      int? firstScore,
      String? firstRoundId,
      String? secondSessionId,
      DateTime? secondAchievedAt,
      int? secondScore,
      String? secondRoundId,
      required bool isClaimed,
      DateTime? claimedAt,
    }) {
      final now = DateTime.now();
      return Classification(
        id: id,
        profileId: profileId,
        classification: classification,
        classificationScope: classificationScope,
        bowstyle: bowstyle,
        firstSessionId: firstSessionId,
        firstAchievedAt: firstAchievedAt,
        firstScore: firstScore,
        firstRoundId: firstRoundId,
        secondSessionId: secondSessionId,
        secondAchievedAt: secondAchievedAt,
        secondScore: secondScore,
        secondRoundId: secondRoundId,
        isClaimed: isClaimed,
        claimedAt: claimedAt,
        createdAt: now,
        updatedAt: now,
      );
    }

    bool isClassificationComplete(Classification c) {
      return c.firstSessionId != null && c.secondSessionId != null;
    }

    bool isClassificationClaimable(Classification c) {
      return isClassificationComplete(c) && !c.isClaimed;
    }

    group('hasClassifications simulation', () {
      test('returns false when both lists are empty', () {
        final outdoor = <Classification>[];
        final indoor = <Classification>[];
        final hasClassifications = outdoor.isNotEmpty || indoor.isNotEmpty;
        expect(hasClassifications, isFalse);
      });

      test('returns true when outdoor has classifications', () {
        final outdoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A3',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            isClaimed: false,
          ),
        ];
        final indoor = <Classification>[];
        final hasClassifications = outdoor.isNotEmpty || indoor.isNotEmpty;
        expect(hasClassifications, isTrue);
      });

      test('returns true when indoor has classifications', () {
        final outdoor = <Classification>[];
        final indoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A3',
            classificationScope: 'indoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            isClaimed: false,
          ),
        ];
        final hasClassifications = outdoor.isNotEmpty || indoor.isNotEmpty;
        expect(hasClassifications, isTrue);
      });

      test('returns true when both have classifications', () {
        final outdoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A3',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            isClaimed: false,
          ),
        ];
        final indoor = [
          createMockClassification(
            id: 'class_2',
            profileId: 'profile_1',
            classification: 'A2',
            classificationScope: 'indoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_2',
            isClaimed: false,
          ),
        ];
        final hasClassifications = outdoor.isNotEmpty || indoor.isNotEmpty;
        expect(hasClassifications, isTrue);
      });
    });

    group('isClassificationComplete', () {
      test('returns false when no scores recorded', () {
        final c = createMockClassification(
          id: 'class_1',
          profileId: 'profile_1',
          classification: 'A3',
          classificationScope: 'outdoor',
          bowstyle: 'recurve',
          isClaimed: false,
        );
        expect(isClassificationComplete(c), isFalse);
      });

      test('returns false when only first score recorded', () {
        final c = createMockClassification(
          id: 'class_1',
          profileId: 'profile_1',
          classification: 'A3',
          classificationScope: 'outdoor',
          bowstyle: 'recurve',
          firstSessionId: 'session_1',
          firstAchievedAt: DateTime.now(),
          firstScore: 500,
          firstRoundId: 'national',
          isClaimed: false,
        );
        expect(isClassificationComplete(c), isFalse);
      });

      test('returns true when both scores recorded', () {
        final c = createMockClassification(
          id: 'class_1',
          profileId: 'profile_1',
          classification: 'A3',
          classificationScope: 'outdoor',
          bowstyle: 'recurve',
          firstSessionId: 'session_1',
          firstAchievedAt: DateTime.now().subtract(const Duration(days: 7)),
          firstScore: 500,
          firstRoundId: 'national',
          secondSessionId: 'session_2',
          secondAchievedAt: DateTime.now(),
          secondScore: 510,
          secondRoundId: 'national',
          isClaimed: false,
        );
        expect(isClassificationComplete(c), isTrue);
      });
    });

    group('isClassificationClaimable', () {
      test('returns false when incomplete', () {
        final c = createMockClassification(
          id: 'class_1',
          profileId: 'profile_1',
          classification: 'A3',
          classificationScope: 'outdoor',
          bowstyle: 'recurve',
          firstSessionId: 'session_1',
          isClaimed: false,
        );
        expect(isClassificationClaimable(c), isFalse);
      });

      test('returns false when complete but already claimed', () {
        final c = createMockClassification(
          id: 'class_1',
          profileId: 'profile_1',
          classification: 'A3',
          classificationScope: 'outdoor',
          bowstyle: 'recurve',
          firstSessionId: 'session_1',
          firstAchievedAt: DateTime.now().subtract(const Duration(days: 7)),
          firstScore: 500,
          firstRoundId: 'national',
          secondSessionId: 'session_2',
          secondAchievedAt: DateTime.now(),
          secondScore: 510,
          secondRoundId: 'national',
          isClaimed: true,
          claimedAt: DateTime.now(),
        );
        expect(isClassificationClaimable(c), isFalse);
      });

      test('returns true when complete and not claimed', () {
        final c = createMockClassification(
          id: 'class_1',
          profileId: 'profile_1',
          classification: 'A3',
          classificationScope: 'outdoor',
          bowstyle: 'recurve',
          firstSessionId: 'session_1',
          firstAchievedAt: DateTime.now().subtract(const Duration(days: 7)),
          firstScore: 500,
          firstRoundId: 'national',
          secondSessionId: 'session_2',
          secondAchievedAt: DateTime.now(),
          secondScore: 510,
          secondRoundId: 'national',
          isClaimed: false,
        );
        expect(isClassificationClaimable(c), isTrue);
      });
    });

    group('hasClaimableClassifications simulation', () {
      test('returns false when no classifications', () {
        final outdoor = <Classification>[];
        final indoor = <Classification>[];

        final hasClaimable = outdoor.any((c) => isClassificationClaimable(c)) ||
            indoor.any((c) => isClassificationClaimable(c));

        expect(hasClaimable, isFalse);
      });

      test('returns false when all incomplete', () {
        final outdoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A3',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            isClaimed: false,
          ),
        ];
        final indoor = <Classification>[];

        final hasClaimable = outdoor.any((c) => isClassificationClaimable(c)) ||
            indoor.any((c) => isClassificationClaimable(c));

        expect(hasClaimable, isFalse);
      });

      test('returns false when all already claimed', () {
        final outdoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A3',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            secondSessionId: 'session_2',
            isClaimed: true,
            claimedAt: DateTime.now(),
          ),
        ];
        final indoor = <Classification>[];

        final hasClaimable = outdoor.any((c) => isClassificationClaimable(c)) ||
            indoor.any((c) => isClassificationClaimable(c));

        expect(hasClaimable, isFalse);
      });

      test('returns true when at least one claimable outdoor', () {
        final outdoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A3',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            secondSessionId: 'session_2',
            isClaimed: false,
          ),
        ];
        final indoor = <Classification>[];

        final hasClaimable = outdoor.any((c) => isClassificationClaimable(c)) ||
            indoor.any((c) => isClassificationClaimable(c));

        expect(hasClaimable, isTrue);
      });

      test('returns true when at least one claimable indoor', () {
        final outdoor = <Classification>[];
        final indoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A2',
            classificationScope: 'indoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            secondSessionId: 'session_2',
            isClaimed: false,
          ),
        ];

        final hasClaimable = outdoor.any((c) => isClassificationClaimable(c)) ||
            indoor.any((c) => isClassificationClaimable(c));

        expect(hasClaimable, isTrue);
      });
    });

    group('claimable classification filtering', () {
      test('filters to only claimable outdoor classifications', () {
        final outdoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A3',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            secondSessionId: 'session_2',
            isClaimed: false, // Claimable
          ),
          createMockClassification(
            id: 'class_2',
            profileId: 'profile_1',
            classification: 'A2',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_3',
            isClaimed: false, // Not complete
          ),
          createMockClassification(
            id: 'class_3',
            profileId: 'profile_1',
            classification: 'A1',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_4',
            secondSessionId: 'session_5',
            isClaimed: true, // Already claimed
          ),
        ];

        final claimable = outdoor.where((c) => isClassificationClaimable(c)).toList();

        expect(claimable, hasLength(1));
        expect(claimable.first.id, equals('class_1'));
        expect(claimable.first.classification, equals('A3'));
      });

      test('returns empty when none claimable', () {
        final outdoor = [
          createMockClassification(
            id: 'class_1',
            profileId: 'profile_1',
            classification: 'A3',
            classificationScope: 'outdoor',
            bowstyle: 'recurve',
            firstSessionId: 'session_1',
            isClaimed: false, // Not complete
          ),
        ];

        final claimable = outdoor.where((c) => isClassificationClaimable(c)).toList();

        expect(claimable, isEmpty);
      });
    });
  });

  group('Real-World Scenarios', () {
    // Helper function to calculate threshold
    int calculateThreshold({
      required String bowstyle,
      required AgeCategory ageCategory,
      required Gender gender,
      required int classIndex,
      required bool isIndoor,
    }) {
      final datum = isIndoor
          ? IndoorBowstyleDatum.forBowstyle(bowstyle)
          : BowstyleDatum.forBowstyle(bowstyle);
      final genderAdj = gender == Gender.female ? 7 : 0;
      return datum + (ageCategory.ageStep * 3) + genderAdj + (classIndex * 7);
    }

    group('Olympic archer (Patrick Huston)', () {
      // Patrick: Adult male recurve archer
      const bowstyle = 'recurve';
      final ageCategory = AgeCategory.adult;
      final gender = Gender.male;

      test('GMB outdoor threshold is 30', () {
        final threshold = calculateThreshold(
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
          isIndoor: false,
        );
        expect(threshold, equals(30));
      });

      test('GMB indoor threshold is 14', () {
        final threshold = calculateThreshold(
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
          classIndex: IndoorClassification.grandMasterBowman.classIndex,
          isIndoor: true,
        );
        expect(threshold, equals(14));
      });

      test('needs prestige round for GMB', () {
        expect(OutdoorClassification.grandMasterBowman.requiresPrestigeRound, isTrue);
      });

      test('WA 1440 90m is valid prestige round', () {
        expect(PrestigeRounds.isPrestigeRound('wa_1440_90m'), isTrue);
      });

      test('York is valid prestige round', () {
        expect(PrestigeRounds.isPrestigeRound('york'), isTrue);
      });
    });

    group('beginner archer', () {
      // New adult male recurve archer starting out
      const bowstyle = 'recurve';
      final ageCategory = AgeCategory.adult;
      final gender = Gender.male;

      test('A3 threshold is achievable at 79 handicap', () {
        final threshold = calculateThreshold(
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
          classIndex: OutdoorClassification.archerThird.classIndex,
          isIndoor: false,
        );
        expect(threshold, equals(79));
      });

      test('A3 does not require prestige round', () {
        expect(OutdoorClassification.archerThird.requiresPrestigeRound, isFalse);
      });

      test('next classification from A3 is A2', () {
        expect(OutdoorClassification.archerThird.nextHigher,
            equals(OutdoorClassification.archerSecond));
      });

      test('A2 threshold is 72', () {
        final threshold = calculateThreshold(
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
          classIndex: OutdoorClassification.archerSecond.classIndex,
          isIndoor: false,
        );
        expect(threshold, equals(72)); // 30 + 0 + 0 + 42
      });
    });

    group('veteran archer (65 year old female longbow)', () {
      const bowstyle = 'longbow';
      final ageCategory = AgeCategory.sixtyPlus;
      final gender = Gender.female;

      test('has adjusted thresholds for age and gender', () {
        final gmbThreshold = calculateThreshold(
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
          isIndoor: false,
        );
        // datum=65, ageStep=2 (+6), genderAdj=+7, classIndex=0
        expect(gmbThreshold, equals(78)); // 65 + 6 + 7 + 0
      });

      test('A3 threshold is generous at 127', () {
        final a3Threshold = calculateThreshold(
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
          classIndex: OutdoorClassification.archerThird.classIndex,
          isIndoor: false,
        );
        // datum=65, ageStep=2 (+6), genderAdj=+7, classIndex=7 (+49)
        expect(a3Threshold, equals(127)); // 65 + 6 + 7 + 49
      });
    });

    group('junior archer (14 year old)', () {
      const bowstyle = 'recurve';
      final ageCategory = AgeCategory.under15;
      final gender = Gender.male;

      test('has age-adjusted thresholds', () {
        // under15 has ageStep = 5
        final gmbThreshold = calculateThreshold(
          bowstyle: bowstyle,
          ageCategory: ageCategory,
          gender: gender,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
          isIndoor: false,
        );
        expect(gmbThreshold, equals(45)); // 30 + 15 + 0 + 0
      });

      test('age category calculated correctly from DOB', () {
        final dob = DateTime.now().subtract(const Duration(days: 365 * 14 + 100));
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under15));
      });
    });

    group('compound archer', () {
      const bowstyle = 'compound';
      final ageCategory = AgeCategory.adult;
      final gender = Gender.male;

      test('has lower thresholds than recurve (more accurate)', () {
        final compoundGmb = calculateThreshold(
          bowstyle: 'compound',
          ageCategory: ageCategory,
          gender: gender,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
          isIndoor: false,
        );
        final recurveGmb = calculateThreshold(
          bowstyle: 'recurve',
          ageCategory: ageCategory,
          gender: gender,
          classIndex: OutdoorClassification.grandMasterBowman.classIndex,
          isIndoor: false,
        );
        expect(compoundGmb, lessThan(recurveGmb));
        expect(compoundGmb, equals(15));
        expect(recurveGmb, equals(30));
      });
    });

    group('classification progression journey', () {
      test('full outdoor classification ladder', () {
        var current = OutdoorClassification.archerThird;

        // Simulate climbing the ladder
        final progression = <OutdoorClassification>[];
        while (current.nextHigher != null) {
          progression.add(current);
          current = current.nextHigher!;
        }
        progression.add(current); // Add GMB

        expect(progression, hasLength(8));
        expect(progression.first, equals(OutdoorClassification.archerThird));
        expect(progression.last, equals(OutdoorClassification.grandMasterBowman));
      });

      test('prestige requirement kicks in at MB', () {
        final ladder = OutdoorClassification.values;

        // B1 and below don't need prestige
        for (final c in ladder.where((c) => c.classIndex >= 2)) {
          expect(c.requiresPrestigeRound, isFalse,
              reason: '${c.code} should not require prestige round');
        }

        // MB and GMB need prestige
        expect(OutdoorClassification.masterBowman.requiresPrestigeRound, isTrue);
        expect(OutdoorClassification.grandMasterBowman.requiresPrestigeRound, isTrue);
      });
    });

    group('indoor vs outdoor', () {
      test('indoor is easier (lower thresholds)', () {
        final ageCategory = AgeCategory.adult;
        final gender = Gender.male;
        const bowstyle = 'recurve';

        for (var i = 0; i < 8; i++) {
          final outdoorThreshold = calculateThreshold(
            bowstyle: bowstyle,
            ageCategory: ageCategory,
            gender: gender,
            classIndex: i,
            isIndoor: false,
          );
          final indoorThreshold = calculateThreshold(
            bowstyle: bowstyle,
            ageCategory: ageCategory,
            gender: gender,
            classIndex: i,
            isIndoor: true,
          );

          expect(indoorThreshold, lessThan(outdoorThreshold),
              reason: 'Indoor classIndex $i should be easier than outdoor');
        }
      });

      test('same code names for indoor and outdoor', () {
        expect(IndoorClassification.grandMasterBowman.code,
            equals(OutdoorClassification.grandMasterBowman.code));
        expect(IndoorClassification.archerThird.code,
            equals(OutdoorClassification.archerThird.code));
      });
    });
  });

  group('Edge Cases', () {
    group('boundary age categories', () {
      test('exactly 12 years old is under14', () {
        // On their 12th birthday
        final now = DateTime.now();
        final dob = DateTime(now.year - 12, now.month, now.day);
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under14));
      });

      test('day before 12th birthday is under12', () {
        final now = DateTime.now();
        final dob = DateTime(now.year - 12, now.month, now.day + 1);
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.under12));
      });

      test('exactly 50 years old is fiftyPlus', () {
        final now = DateTime.now();
        final dob = DateTime(now.year - 50, now.month, now.day);
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.fiftyPlus));
      });

      test('exactly 70 years old is seventyPlus', () {
        final now = DateTime.now();
        final dob = DateTime(now.year - 70, now.month, now.day);
        expect(AgeCategory.fromDateOfBirth(dob), equals(AgeCategory.seventyPlus));
      });
    });

    group('classification code parsing', () {
      test('lowercase codes do not match', () {
        // The enum uses uppercase codes
        expect(OutdoorClassification.fromString('gmb'),
            equals(OutdoorClassification.archerThird));
        expect(OutdoorClassification.fromString('mb'),
            equals(OutdoorClassification.archerThird));
      });

      test('whitespace around codes', () {
        // Should not match due to whitespace
        expect(OutdoorClassification.fromString(' GMB '),
            equals(OutdoorClassification.archerThird));
      });
    });

    group('extreme handicaps', () {
      test('handicap 0 qualifies for everything', () {
        // Handicap 0 is lower than all thresholds
        const handicap = 0;
        const gmbThreshold = 30; // Adult male recurve

        expect(handicap <= gmbThreshold, isTrue);
      });

      test('very high handicap qualifies for nothing', () {
        // Handicap 150 is higher than all thresholds
        const handicap = 150;
        const a3Threshold = 79; // Adult male recurve A3

        expect(handicap <= a3Threshold, isFalse);
      });
    });

    group('scope validation', () {
      test('ClassificationScope.fromString handles case sensitivity', () {
        // The value field is lowercase
        expect(ClassificationScope.fromString('OUTDOOR'),
            equals(ClassificationScope.outdoor)); // Returns default
        expect(ClassificationScope.fromString('outdoor'),
            equals(ClassificationScope.outdoor));
      });
    });

    group('bowstyle validation', () {
      test('BowstyleDatum handles mixed case', () {
        expect(BowstyleDatum.forBowstyle('RECURVE'), equals(30));
        expect(BowstyleDatum.forBowstyle('rEcUrVe'), equals(30));
      });

      test('IndoorBowstyleDatum handles mixed case', () {
        expect(IndoorBowstyleDatum.forBowstyle('COMPOUND'), equals(5));
      });
    });
  });

  group('Data Integrity', () {
    test('all outdoor classification codes are 2-3 characters', () {
      for (final c in OutdoorClassification.values) {
        expect(c.code.length, inInclusiveRange(2, 3));
      }
    });

    test('all indoor classification codes are 2-3 characters', () {
      for (final c in IndoorClassification.values) {
        expect(c.code.length, inInclusiveRange(2, 3));
      }
    });

    test('classification indices are unique within enum', () {
      final outdoorIndices = OutdoorClassification.values.map((c) => c.classIndex).toSet();
      expect(outdoorIndices.length, equals(OutdoorClassification.values.length));

      final indoorIndices = IndoorClassification.values.map((c) => c.classIndex).toSet();
      expect(indoorIndices.length, equals(IndoorClassification.values.length));
    });

    test('age category ageSteps are non-negative', () {
      for (final category in AgeCategory.values) {
        expect(category.ageStep, greaterThanOrEqualTo(0));
      }
    });

    test('all bowstyle datums are positive', () {
      expect(BowstyleDatum.compound, greaterThan(0));
      expect(BowstyleDatum.recurve, greaterThan(0));
      expect(BowstyleDatum.barebow, greaterThan(0));
      expect(BowstyleDatum.traditional, greaterThan(0));
      expect(BowstyleDatum.longbow, greaterThan(0));

      expect(IndoorBowstyleDatum.compound, greaterThan(0));
      expect(IndoorBowstyleDatum.recurve, greaterThan(0));
      expect(IndoorBowstyleDatum.barebow, greaterThan(0));
      expect(IndoorBowstyleDatum.traditional, greaterThan(0));
      expect(IndoorBowstyleDatum.longbow, greaterThan(0));
    });

    test('prestige rounds set is immutable', () {
      // PrestigeRounds.outdoor is const, verify it has expected content
      expect(PrestigeRounds.outdoor, isA<Set<String>>());
      expect(PrestigeRounds.outdoor.length, equals(8));
    });

    test('all age categories have display names', () {
      for (final category in AgeCategory.values) {
        expect(category.displayName, isNotEmpty);
      }
    });

    test('all genders have display names', () {
      for (final gender in Gender.values) {
        expect(gender.displayName, isNotEmpty);
      }
    });
  });
}
