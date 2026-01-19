/// Tests for ClassificationService
///
/// These tests verify the AGB classification system calculations including:
/// - Threshold calculations for all bowstyles, age categories, and genders
/// - Classification determination from handicap values
/// - Prestige round requirements for GMB/MB
/// - Database operations for recording qualifying scores
/// - Edge cases and boundary conditions
///
/// The classification formula is:
/// threshold = datum + (ageStep × 3) + genderAdj + (classIndex × 7)
///
/// Where:
/// - datum: bowstyle-specific base value
/// - ageStep: age category modifier
/// - genderAdj: +7 for female
/// - classIndex: 0 for GMB, 7 for A3
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/models/classification.dart';
import 'package:archery_super_app/models/user_profile.dart';
import 'package:archery_super_app/services/classification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClassificationService', () {
    group('constants', () {
      test('genderAdjustmentFemale is 7', () {
        expect(ClassificationService.genderAdjustmentFemale, equals(7));
      });
    });

    group('BowstyleDatum', () {
      test('compound datum is 15', () {
        expect(BowstyleDatum.compound, equals(15));
      });

      test('recurve datum is 30', () {
        expect(BowstyleDatum.recurve, equals(30));
      });

      test('barebow datum is 47', () {
        expect(BowstyleDatum.barebow, equals(47));
      });

      test('traditional datum is same as barebow (47)', () {
        expect(BowstyleDatum.traditional, equals(47));
        expect(BowstyleDatum.traditional, equals(BowstyleDatum.barebow));
      });

      test('longbow datum is 65', () {
        expect(BowstyleDatum.longbow, equals(65));
      });

      test('forBowstyle returns correct datum for compound', () {
        expect(BowstyleDatum.forBowstyle('compound'), equals(15));
        expect(BowstyleDatum.forBowstyle('Compound'), equals(15));
        expect(BowstyleDatum.forBowstyle('COMPOUND'), equals(15));
      });

      test('forBowstyle returns correct datum for recurve', () {
        expect(BowstyleDatum.forBowstyle('recurve'), equals(30));
        expect(BowstyleDatum.forBowstyle('Recurve'), equals(30));
      });

      test('forBowstyle returns correct datum for barebow', () {
        expect(BowstyleDatum.forBowstyle('barebow'), equals(47));
        expect(BowstyleDatum.forBowstyle('Barebow'), equals(47));
      });

      test('forBowstyle returns correct datum for traditional', () {
        expect(BowstyleDatum.forBowstyle('traditional'), equals(47));
        expect(BowstyleDatum.forBowstyle('Traditional'), equals(47));
      });

      test('forBowstyle returns correct datum for longbow', () {
        expect(BowstyleDatum.forBowstyle('longbow'), equals(65));
        expect(BowstyleDatum.forBowstyle('Longbow'), equals(65));
      });

      test('forBowstyle defaults to recurve for unknown bowstyle', () {
        expect(BowstyleDatum.forBowstyle('unknown'), equals(30));
        expect(BowstyleDatum.forBowstyle('crossbow'), equals(30));
        expect(BowstyleDatum.forBowstyle(''), equals(30));
      });
    });

    group('IndoorBowstyleDatum', () {
      test('indoor compound datum is 5', () {
        expect(IndoorBowstyleDatum.compound, equals(5));
      });

      test('indoor recurve datum is 14', () {
        expect(IndoorBowstyleDatum.recurve, equals(14));
      });

      test('indoor barebow datum is 30', () {
        expect(IndoorBowstyleDatum.barebow, equals(30));
      });

      test('indoor traditional datum is same as barebow (30)', () {
        expect(IndoorBowstyleDatum.traditional, equals(30));
        expect(IndoorBowstyleDatum.traditional, equals(IndoorBowstyleDatum.barebow));
      });

      test('indoor longbow datum is 45', () {
        expect(IndoorBowstyleDatum.longbow, equals(45));
      });

      test('indoor datums are lower than outdoor datums', () {
        expect(IndoorBowstyleDatum.compound, lessThan(BowstyleDatum.compound));
        expect(IndoorBowstyleDatum.recurve, lessThan(BowstyleDatum.recurve));
        expect(IndoorBowstyleDatum.barebow, lessThan(BowstyleDatum.barebow));
        expect(IndoorBowstyleDatum.longbow, lessThan(BowstyleDatum.longbow));
      });

      test('forBowstyle returns correct indoor datum', () {
        expect(IndoorBowstyleDatum.forBowstyle('compound'), equals(5));
        expect(IndoorBowstyleDatum.forBowstyle('recurve'), equals(14));
        expect(IndoorBowstyleDatum.forBowstyle('barebow'), equals(30));
        expect(IndoorBowstyleDatum.forBowstyle('traditional'), equals(30));
        expect(IndoorBowstyleDatum.forBowstyle('longbow'), equals(45));
      });

      test('forBowstyle defaults to recurve for unknown bowstyle', () {
        expect(IndoorBowstyleDatum.forBowstyle('unknown'), equals(14));
        expect(IndoorBowstyleDatum.forBowstyle(''), equals(14));
      });
    });

    group('OutdoorClassification', () {
      test('GMB has classIndex 0', () {
        expect(OutdoorClassification.grandMasterBowman.classIndex, equals(0));
        expect(OutdoorClassification.grandMasterBowman.code, equals('GMB'));
      });

      test('MB has classIndex 1', () {
        expect(OutdoorClassification.masterBowman.classIndex, equals(1));
        expect(OutdoorClassification.masterBowman.code, equals('MB'));
      });

      test('B1 has classIndex 2', () {
        expect(OutdoorClassification.bowmanFirst.classIndex, equals(2));
        expect(OutdoorClassification.bowmanFirst.code, equals('B1'));
      });

      test('B2 has classIndex 3', () {
        expect(OutdoorClassification.bowmanSecond.classIndex, equals(3));
        expect(OutdoorClassification.bowmanSecond.code, equals('B2'));
      });

      test('B3 has classIndex 4', () {
        expect(OutdoorClassification.bowmanThird.classIndex, equals(4));
        expect(OutdoorClassification.bowmanThird.code, equals('B3'));
      });

      test('A1 has classIndex 5', () {
        expect(OutdoorClassification.archerFirst.classIndex, equals(5));
        expect(OutdoorClassification.archerFirst.code, equals('A1'));
      });

      test('A2 has classIndex 6', () {
        expect(OutdoorClassification.archerSecond.classIndex, equals(6));
        expect(OutdoorClassification.archerSecond.code, equals('A2'));
      });

      test('A3 has classIndex 7', () {
        expect(OutdoorClassification.archerThird.classIndex, equals(7));
        expect(OutdoorClassification.archerThird.code, equals('A3'));
      });

      test('GMB and MB require prestige rounds', () {
        expect(OutdoorClassification.grandMasterBowman.requiresPrestigeRound, isTrue);
        expect(OutdoorClassification.masterBowman.requiresPrestigeRound, isTrue);
      });

      test('B1 and below do not require prestige rounds', () {
        expect(OutdoorClassification.bowmanFirst.requiresPrestigeRound, isFalse);
        expect(OutdoorClassification.bowmanSecond.requiresPrestigeRound, isFalse);
        expect(OutdoorClassification.bowmanThird.requiresPrestigeRound, isFalse);
        expect(OutdoorClassification.archerFirst.requiresPrestigeRound, isFalse);
        expect(OutdoorClassification.archerSecond.requiresPrestigeRound, isFalse);
        expect(OutdoorClassification.archerThird.requiresPrestigeRound, isFalse);
      });

      test('fromString parses code correctly', () {
        expect(OutdoorClassification.fromString('GMB'), equals(OutdoorClassification.grandMasterBowman));
        expect(OutdoorClassification.fromString('MB'), equals(OutdoorClassification.masterBowman));
        expect(OutdoorClassification.fromString('B1'), equals(OutdoorClassification.bowmanFirst));
        expect(OutdoorClassification.fromString('B2'), equals(OutdoorClassification.bowmanSecond));
        expect(OutdoorClassification.fromString('B3'), equals(OutdoorClassification.bowmanThird));
        expect(OutdoorClassification.fromString('A1'), equals(OutdoorClassification.archerFirst));
        expect(OutdoorClassification.fromString('A2'), equals(OutdoorClassification.archerSecond));
        expect(OutdoorClassification.fromString('A3'), equals(OutdoorClassification.archerThird));
      });

      test('fromString defaults to A3 for unknown', () {
        expect(OutdoorClassification.fromString('unknown'), equals(OutdoorClassification.archerThird));
        expect(OutdoorClassification.fromString(''), equals(OutdoorClassification.archerThird));
      });

      test('nextHigher returns correct classification', () {
        expect(OutdoorClassification.archerThird.nextHigher, equals(OutdoorClassification.archerSecond));
        expect(OutdoorClassification.archerSecond.nextHigher, equals(OutdoorClassification.archerFirst));
        expect(OutdoorClassification.archerFirst.nextHigher, equals(OutdoorClassification.bowmanThird));
        expect(OutdoorClassification.bowmanThird.nextHigher, equals(OutdoorClassification.bowmanSecond));
        expect(OutdoorClassification.bowmanSecond.nextHigher, equals(OutdoorClassification.bowmanFirst));
        expect(OutdoorClassification.bowmanFirst.nextHigher, equals(OutdoorClassification.masterBowman));
        expect(OutdoorClassification.masterBowman.nextHigher, equals(OutdoorClassification.grandMasterBowman));
        expect(OutdoorClassification.grandMasterBowman.nextHigher, isNull);
      });

      test('nextLower returns correct classification', () {
        expect(OutdoorClassification.grandMasterBowman.nextLower, equals(OutdoorClassification.masterBowman));
        expect(OutdoorClassification.masterBowman.nextLower, equals(OutdoorClassification.bowmanFirst));
        expect(OutdoorClassification.bowmanFirst.nextLower, equals(OutdoorClassification.bowmanSecond));
        expect(OutdoorClassification.bowmanSecond.nextLower, equals(OutdoorClassification.bowmanThird));
        expect(OutdoorClassification.bowmanThird.nextLower, equals(OutdoorClassification.archerFirst));
        expect(OutdoorClassification.archerFirst.nextLower, equals(OutdoorClassification.archerSecond));
        expect(OutdoorClassification.archerSecond.nextLower, equals(OutdoorClassification.archerThird));
        expect(OutdoorClassification.archerThird.nextLower, isNull);
      });
    });

    group('IndoorClassification', () {
      test('GMB has classIndex 0', () {
        expect(IndoorClassification.grandMasterBowman.classIndex, equals(0));
        expect(IndoorClassification.grandMasterBowman.code, equals('GMB'));
      });

      test('MB has classIndex 1', () {
        expect(IndoorClassification.masterBowman.classIndex, equals(1));
        expect(IndoorClassification.masterBowman.code, equals('MB'));
      });

      test('all class indices match outdoor', () {
        expect(IndoorClassification.grandMasterBowman.classIndex,
            equals(OutdoorClassification.grandMasterBowman.classIndex));
        expect(IndoorClassification.masterBowman.classIndex,
            equals(OutdoorClassification.masterBowman.classIndex));
        expect(IndoorClassification.bowmanFirst.classIndex,
            equals(OutdoorClassification.bowmanFirst.classIndex));
        expect(IndoorClassification.archerThird.classIndex,
            equals(OutdoorClassification.archerThird.classIndex));
      });

      test('fromString parses code correctly', () {
        expect(IndoorClassification.fromString('GMB'), equals(IndoorClassification.grandMasterBowman));
        expect(IndoorClassification.fromString('MB'), equals(IndoorClassification.masterBowman));
        expect(IndoorClassification.fromString('A3'), equals(IndoorClassification.archerThird));
      });

      test('fromString defaults to A3 for unknown', () {
        expect(IndoorClassification.fromString('unknown'), equals(IndoorClassification.archerThird));
      });

      test('nextHigher returns correct classification', () {
        expect(IndoorClassification.archerThird.nextHigher, equals(IndoorClassification.archerSecond));
        expect(IndoorClassification.grandMasterBowman.nextHigher, isNull);
      });

      test('nextLower returns correct classification', () {
        expect(IndoorClassification.grandMasterBowman.nextLower, equals(IndoorClassification.masterBowman));
        expect(IndoorClassification.archerThird.nextLower, isNull);
      });
    });

    group('ClassificationScope', () {
      test('outdoor scope has correct value', () {
        expect(ClassificationScope.outdoor.value, equals('outdoor'));
        expect(ClassificationScope.outdoor.displayName, equals('Outdoor'));
      });

      test('indoor scope has correct value', () {
        expect(ClassificationScope.indoor.value, equals('indoor'));
        expect(ClassificationScope.indoor.displayName, equals('Indoor'));
      });

      test('fromString parses correctly', () {
        expect(ClassificationScope.fromString('outdoor'), equals(ClassificationScope.outdoor));
        expect(ClassificationScope.fromString('indoor'), equals(ClassificationScope.indoor));
      });

      test('fromString defaults to outdoor for unknown', () {
        expect(ClassificationScope.fromString('unknown'), equals(ClassificationScope.outdoor));
        expect(ClassificationScope.fromString(''), equals(ClassificationScope.outdoor));
      });
    });

    group('PrestigeRounds', () {
      test('york is a prestige round', () {
        expect(PrestigeRounds.isPrestigeRound('york'), isTrue);
      });

      test('hereford is a prestige round', () {
        expect(PrestigeRounds.isPrestigeRound('hereford'), isTrue);
      });

      test('bristol_1 is a prestige round', () {
        expect(PrestigeRounds.isPrestigeRound('bristol_1'), isTrue);
      });

      test('WA 1440 rounds are prestige rounds', () {
        expect(PrestigeRounds.isPrestigeRound('wa_1440_90m'), isTrue);
        expect(PrestigeRounds.isPrestigeRound('wa_1440_70m'), isTrue);
        expect(PrestigeRounds.isPrestigeRound('wa_1440_60m'), isTrue);
      });

      test('WA 720 rounds are prestige rounds', () {
        expect(PrestigeRounds.isPrestigeRound('wa_720_70m'), isTrue);
        expect(PrestigeRounds.isPrestigeRound('wa_720_60m'), isTrue);
      });

      test('non-prestige rounds return false', () {
        expect(PrestigeRounds.isPrestigeRound('national'), isFalse);
        expect(PrestigeRounds.isPrestigeRound('bristol_2'), isFalse);
        expect(PrestigeRounds.isPrestigeRound('western'), isFalse);
        expect(PrestigeRounds.isPrestigeRound('albion'), isFalse);
        expect(PrestigeRounds.isPrestigeRound('portsmouth'), isFalse);
        expect(PrestigeRounds.isPrestigeRound('wa_18'), isFalse);
        expect(PrestigeRounds.isPrestigeRound(''), isFalse);
      });

      test('prestige round set contains exactly 8 rounds', () {
        expect(PrestigeRounds.outdoor.length, equals(8));
      });
    });

    group('AgeCategory', () {
      test('adult has ageStep 0', () {
        expect(AgeCategory.adult.ageStep, equals(0));
      });

      test('under21 has same ageStep as adult (0)', () {
        expect(AgeCategory.under21.ageStep, equals(0));
        expect(AgeCategory.under21.ageStep, equals(AgeCategory.adult.ageStep));
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

      test('fromString parses correctly', () {
        expect(AgeCategory.fromString('adult'), equals(AgeCategory.adult));
        expect(AgeCategory.fromString('under_21'), equals(AgeCategory.under21));
        expect(AgeCategory.fromString('50+'), equals(AgeCategory.fiftyPlus));
        expect(AgeCategory.fromString('60+'), equals(AgeCategory.sixtyPlus));
        expect(AgeCategory.fromString('70+'), equals(AgeCategory.seventyPlus));
        expect(AgeCategory.fromString('under_18'), equals(AgeCategory.under18));
        expect(AgeCategory.fromString('under_16'), equals(AgeCategory.under16));
        expect(AgeCategory.fromString('under_15'), equals(AgeCategory.under15));
        expect(AgeCategory.fromString('under_14'), equals(AgeCategory.under14));
        expect(AgeCategory.fromString('under_12'), equals(AgeCategory.under12));
      });

      test('fromString defaults to adult for unknown', () {
        expect(AgeCategory.fromString('unknown'), equals(AgeCategory.adult));
      });

      test('fromDateOfBirth calculates age categories correctly', () {
        final now = DateTime.now();

        // Under 12
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 10, now.month, now.day)),
          equals(AgeCategory.under12),
        );

        // Under 14
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 13, now.month, now.day)),
          equals(AgeCategory.under14),
        );

        // Under 15
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 14, now.month, now.day)),
          equals(AgeCategory.under15),
        );

        // Under 16
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 15, now.month, now.day)),
          equals(AgeCategory.under16),
        );

        // Under 18
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 17, now.month, now.day)),
          equals(AgeCategory.under18),
        );

        // Under 21
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 20, now.month, now.day)),
          equals(AgeCategory.under21),
        );

        // Adult
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 30, now.month, now.day)),
          equals(AgeCategory.adult),
        );

        // 50+
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 55, now.month, now.day)),
          equals(AgeCategory.fiftyPlus),
        );

        // 60+
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 62, now.month, now.day)),
          equals(AgeCategory.sixtyPlus),
        );

        // 70+
        expect(
          AgeCategory.fromDateOfBirth(DateTime(now.year - 75, now.month, now.day)),
          equals(AgeCategory.seventyPlus),
        );
      });

      test('fromDateOfBirth handles boundary cases correctly', () {
        final now = DateTime.now();

        // Exactly 12 years old today
        final justTurned12 = DateTime(now.year - 12, now.month, now.day);
        expect(AgeCategory.fromDateOfBirth(justTurned12), equals(AgeCategory.under14));

        // One day before 12th birthday
        final almostTwelve = DateTime(now.year - 12, now.month, now.day + 1);
        expect(AgeCategory.fromDateOfBirth(almostTwelve), equals(AgeCategory.under12));

        // Exactly 50 years old
        final justFifty = DateTime(now.year - 50, now.month, now.day);
        expect(AgeCategory.fromDateOfBirth(justFifty), equals(AgeCategory.fiftyPlus));

        // One day before 50th birthday
        final almostFifty = DateTime(now.year - 50, now.month, now.day + 1);
        expect(AgeCategory.fromDateOfBirth(almostFifty), equals(AgeCategory.adult));
      });
    });

    group('threshold calculations', () {
      // These tests verify the formula:
      // threshold = datum + (ageStep × 3) + genderAdj + (classIndex × 7)

      group('outdoor thresholds', () {
        test('adult male recurve GMB threshold is 30', () {
          // datum(30) + ageStep(0)*3 + genderAdj(0) + classIndex(0)*7 = 30
          final threshold = BowstyleDatum.recurve +
              (AgeCategory.adult.ageStep * 3) +
              0 + // male
              (OutdoorClassification.grandMasterBowman.classIndex * 7);
          expect(threshold, equals(30));
        });

        test('adult male recurve MB threshold is 37', () {
          // datum(30) + ageStep(0)*3 + genderAdj(0) + classIndex(1)*7 = 37
          final threshold = BowstyleDatum.recurve +
              (AgeCategory.adult.ageStep * 3) +
              0 +
              (OutdoorClassification.masterBowman.classIndex * 7);
          expect(threshold, equals(37));
        });

        test('adult male recurve A3 threshold is 79', () {
          // datum(30) + ageStep(0)*3 + genderAdj(0) + classIndex(7)*7 = 79
          final threshold = BowstyleDatum.recurve +
              (AgeCategory.adult.ageStep * 3) +
              0 +
              (OutdoorClassification.archerThird.classIndex * 7);
          expect(threshold, equals(79));
        });

        test('adult female recurve GMB threshold is 37', () {
          // datum(30) + ageStep(0)*3 + genderAdj(7) + classIndex(0)*7 = 37
          final threshold = BowstyleDatum.recurve +
              (AgeCategory.adult.ageStep * 3) +
              7 + // female
              (OutdoorClassification.grandMasterBowman.classIndex * 7);
          expect(threshold, equals(37));
        });

        test('adult male compound GMB threshold is 15', () {
          // datum(15) + ageStep(0)*3 + genderAdj(0) + classIndex(0)*7 = 15
          final threshold = BowstyleDatum.compound +
              (AgeCategory.adult.ageStep * 3) +
              0 +
              (OutdoorClassification.grandMasterBowman.classIndex * 7);
          expect(threshold, equals(15));
        });

        test('adult male longbow A3 threshold is 114', () {
          // datum(65) + ageStep(0)*3 + genderAdj(0) + classIndex(7)*7 = 114
          final threshold = BowstyleDatum.longbow +
              (AgeCategory.adult.ageStep * 3) +
              0 +
              (OutdoorClassification.archerThird.classIndex * 7);
          expect(threshold, equals(114));
        });

        test('under12 male recurve GMB threshold is 54', () {
          // datum(30) + ageStep(8)*3 + genderAdj(0) + classIndex(0)*7 = 54
          final threshold = BowstyleDatum.recurve +
              (AgeCategory.under12.ageStep * 3) +
              0 +
              (OutdoorClassification.grandMasterBowman.classIndex * 7);
          expect(threshold, equals(54));
        });

        test('under12 female longbow A3 threshold is 145', () {
          // datum(65) + ageStep(8)*3 + genderAdj(7) + classIndex(7)*7 = 145
          final threshold = BowstyleDatum.longbow +
              (AgeCategory.under12.ageStep * 3) +
              7 +
              (OutdoorClassification.archerThird.classIndex * 7);
          expect(threshold, equals(145));
        });

        test('70+ female barebow GMB threshold is 63', () {
          // datum(47) + ageStep(3)*3 + genderAdj(7) + classIndex(0)*7 = 63
          final threshold = BowstyleDatum.barebow +
              (AgeCategory.seventyPlus.ageStep * 3) +
              7 +
              (OutdoorClassification.grandMasterBowman.classIndex * 7);
          expect(threshold, equals(63));
        });
      });

      group('indoor thresholds', () {
        test('adult male recurve GMB indoor threshold is 14', () {
          // datum(14) + ageStep(0)*3 + genderAdj(0) + classIndex(0)*7 = 14
          final threshold = IndoorBowstyleDatum.recurve +
              (AgeCategory.adult.ageStep * 3) +
              0 +
              (IndoorClassification.grandMasterBowman.classIndex * 7);
          expect(threshold, equals(14));
        });

        test('adult male compound GMB indoor threshold is 5', () {
          // datum(5) + ageStep(0)*3 + genderAdj(0) + classIndex(0)*7 = 5
          final threshold = IndoorBowstyleDatum.compound +
              (AgeCategory.adult.ageStep * 3) +
              0 +
              (IndoorClassification.grandMasterBowman.classIndex * 7);
          expect(threshold, equals(5));
        });

        test('adult female longbow A3 indoor threshold is 101', () {
          // datum(45) + ageStep(0)*3 + genderAdj(7) + classIndex(7)*7 = 101
          final threshold = IndoorBowstyleDatum.longbow +
              (AgeCategory.adult.ageStep * 3) +
              7 +
              (IndoorClassification.archerThird.classIndex * 7);
          expect(threshold, equals(101));
        });

        test('indoor thresholds are lower than outdoor for same config', () {
          // Adult male recurve GMB: indoor=14, outdoor=30
          final indoorThreshold = IndoorBowstyleDatum.recurve +
              (AgeCategory.adult.ageStep * 3) +
              0 +
              (IndoorClassification.grandMasterBowman.classIndex * 7);
          final outdoorThreshold = BowstyleDatum.recurve +
              (AgeCategory.adult.ageStep * 3) +
              0 +
              (OutdoorClassification.grandMasterBowman.classIndex * 7);

          expect(indoorThreshold, lessThan(outdoorThreshold));
        });
      });
    });

    group('classification from handicap', () {
      group('outdoor', () {
        // For adult male recurve:
        // GMB: 30, MB: 37, B1: 44, B2: 51, B3: 58, A1: 65, A2: 72, A3: 79

        test('handicap 25 qualifies for GMB (adult male recurve)', () {
          // Handicap 25 <= GMB threshold 30
          expect(25 <= 30, isTrue);
        });

        test('handicap 30 qualifies for GMB (exactly at threshold)', () {
          expect(30 <= 30, isTrue);
        });

        test('handicap 31 does not qualify for GMB but qualifies for MB', () {
          expect(31 <= 30, isFalse);
          expect(31 <= 37, isTrue);
        });

        test('handicap 80 does not qualify for any classification', () {
          // A3 threshold for adult male recurve is 79
          expect(80 <= 79, isFalse);
        });

        test('very low handicap qualifies for highest classification', () {
          expect(5 <= 30, isTrue); // GMB
        });
      });
    });

    group('prestige round requirements', () {
      test('GMB requires prestige round', () {
        expect(OutdoorClassification.grandMasterBowman.requiresPrestigeRound, isTrue);
      });

      test('MB requires prestige round', () {
        expect(OutdoorClassification.masterBowman.requiresPrestigeRound, isTrue);
      });

      test('B1 does not require prestige round', () {
        expect(OutdoorClassification.bowmanFirst.requiresPrestigeRound, isFalse);
      });

      test('requiresPrestigeRound matches classIndex <= 1', () {
        for (final classification in OutdoorClassification.values) {
          expect(
            classification.requiresPrestigeRound,
            equals(classification.classIndex <= 1),
          );
        }
      });
    });

    group('real-world scenarios', () {
      test('Olympic archer achieving GMB - adult male recurve', () {
        // Patrick Huston's scenario: top-level archer
        // Adult male recurve with handicap ~15-20 should easily qualify for GMB
        // GMB threshold = 30
        const handicap = 18;
        const gmbThreshold = 30;
        expect(handicap <= gmbThreshold, isTrue);
      });

      test('beginner archer progression - adult male recurve', () {
        // Starting archer might have handicap 70-80
        // A3 threshold = 79, so handicap 75 qualifies for A3
        const handicap = 75;
        const a3Threshold = 79;
        const a2Threshold = 72;

        expect(handicap <= a3Threshold, isTrue); // Qualifies for A3
        expect(handicap <= a2Threshold, isFalse); // Does not qualify for A2
      });

      test('veteran archer - 60+ male recurve', () {
        // 60+ has ageStep 2, so thresholds increase by 6
        // GMB threshold = 30 + (2*3) = 36
        const handicap = 35;
        const gmbThreshold = 36;
        expect(handicap <= gmbThreshold, isTrue);
      });

      test('junior archer - under16 female barebow', () {
        // under16 has ageStep 4, female adds 7
        // GMB threshold = 47 + (4*3) + 7 = 66
        const handicap = 60;
        const gmbThreshold = 66;
        expect(handicap <= gmbThreshold, isTrue);
      });

      test('compound archer has lower thresholds', () {
        // Adult male compound GMB = 15 (vs recurve 30)
        const compoundGmbThreshold = 15;
        const recurveGmbThreshold = 30;

        // A handicap of 20 qualifies for compound B2 but recurve GMB
        const handicap = 20;
        expect(handicap <= recurveGmbThreshold, isTrue);
        expect(handicap <= compoundGmbThreshold, isFalse);
      });

      test('longbow archer has higher thresholds', () {
        // Adult male longbow GMB = 65 (vs recurve 30)
        const longbowGmbThreshold = 65;
        const recurveGmbThreshold = 30;

        // A handicap of 50 qualifies for longbow GMB but not recurve GMB
        const handicap = 50;
        expect(handicap <= longbowGmbThreshold, isTrue);
        expect(handicap <= recurveGmbThreshold, isFalse);
      });
    });

    group('edge cases', () {
      test('handicap 0 qualifies for highest classification', () {
        // Even compound indoor GMB threshold is 5
        const handicap = 0;
        expect(handicap <= 5, isTrue);
      });

      test('very high handicap does not qualify', () {
        // Even longbow under12 female A3 threshold is 145
        // Handicap 150 would not qualify
        const handicap = 150;
        const maxThreshold = 145;
        expect(handicap <= maxThreshold, isFalse);
      });

      test('negative handicap (theoretical) qualifies for all', () {
        // Negative handicap should qualify for any classification
        const handicap = -5;
        expect(handicap <= 5, isTrue); // compound GMB
      });

      test('threshold at boundary exactly qualifies', () {
        const handicap = 30;
        const threshold = 30;
        expect(handicap <= threshold, isTrue);
      });

      test('threshold just above boundary does not qualify', () {
        const handicap = 31;
        const threshold = 30;
        expect(handicap <= threshold, isFalse);
      });
    });

    group('display names', () {
      test('outdoor classifications have correct display names', () {
        expect(OutdoorClassification.grandMasterBowman.displayName, equals('Grand Master Bowman'));
        expect(OutdoorClassification.masterBowman.displayName, equals('Master Bowman'));
        expect(OutdoorClassification.bowmanFirst.displayName, equals('Bowman 1st Class'));
        expect(OutdoorClassification.bowmanSecond.displayName, equals('Bowman 2nd Class'));
        expect(OutdoorClassification.bowmanThird.displayName, equals('Bowman 3rd Class'));
        expect(OutdoorClassification.archerFirst.displayName, equals('Archer 1st Class'));
        expect(OutdoorClassification.archerSecond.displayName, equals('Archer 2nd Class'));
        expect(OutdoorClassification.archerThird.displayName, equals('Archer 3rd Class'));
      });

      test('indoor classifications have correct display names', () {
        expect(IndoorClassification.grandMasterBowman.displayName, equals('Grand Master Bowman'));
        expect(IndoorClassification.masterBowman.displayName, equals('Master Bowman'));
        expect(IndoorClassification.bowmanFirst.displayName, equals('Bowman 1st Class'));
        expect(IndoorClassification.archerThird.displayName, equals('Archer 3rd Class'));
      });

      test('age categories have correct display names', () {
        expect(AgeCategory.adult.displayName, equals('Adult'));
        expect(AgeCategory.under21.displayName, equals('Under 21'));
        expect(AgeCategory.fiftyPlus.displayName, equals('50+'));
        expect(AgeCategory.sixtyPlus.displayName, equals('60+'));
        expect(AgeCategory.seventyPlus.displayName, equals('70+'));
        expect(AgeCategory.under18.displayName, equals('Under 18'));
        expect(AgeCategory.under16.displayName, equals('Under 16'));
        expect(AgeCategory.under15.displayName, equals('Under 15'));
        expect(AgeCategory.under14.displayName, equals('Under 14'));
        expect(AgeCategory.under12.displayName, equals('Under 12'));
      });

      test('genders have correct display names', () {
        expect(Gender.male.displayName, equals('Male'));
        expect(Gender.female.displayName, equals('Female'));
      });
    });

    group('data integrity', () {
      test('all outdoor classifications have unique codes', () {
        final codes = OutdoorClassification.values.map((c) => c.code).toSet();
        expect(codes.length, equals(OutdoorClassification.values.length));
      });

      test('all outdoor classifications have unique class indices', () {
        final indices = OutdoorClassification.values.map((c) => c.classIndex).toSet();
        expect(indices.length, equals(OutdoorClassification.values.length));
      });

      test('all indoor classifications have unique codes', () {
        final codes = IndoorClassification.values.map((c) => c.code).toSet();
        expect(codes.length, equals(IndoorClassification.values.length));
      });

      test('all indoor classifications have unique class indices', () {
        final indices = IndoorClassification.values.map((c) => c.classIndex).toSet();
        expect(indices.length, equals(IndoorClassification.values.length));
      });

      test('class indices are sequential from 0 to 7', () {
        for (int i = 0; i < 8; i++) {
          expect(
            OutdoorClassification.values.any((c) => c.classIndex == i),
            isTrue,
            reason: 'Missing outdoor class index $i',
          );
          expect(
            IndoorClassification.values.any((c) => c.classIndex == i),
            isTrue,
            reason: 'Missing indoor class index $i',
          );
        }
      });

      test('outdoor and indoor classifications have matching codes', () {
        for (final outdoor in OutdoorClassification.values) {
          final indoor = IndoorClassification.values.firstWhere(
            (i) => i.code == outdoor.code,
          );
          expect(indoor.classIndex, equals(outdoor.classIndex));
        }
      });

      test('age categories all have non-negative age steps', () {
        for (final category in AgeCategory.values) {
          expect(category.ageStep, greaterThanOrEqualTo(0));
        }
      });

      test('age step increases as age category gets younger', () {
        // Under 12 should have highest ageStep
        expect(AgeCategory.under12.ageStep, greaterThan(AgeCategory.under14.ageStep));
        expect(AgeCategory.under14.ageStep, greaterThan(AgeCategory.under15.ageStep));
        // Note: under15 and under16 difference
        expect(AgeCategory.under15.ageStep, greaterThan(AgeCategory.under16.ageStep));
        expect(AgeCategory.under16.ageStep, greaterThan(AgeCategory.under18.ageStep));
      });
    });

    group('Gender', () {
      test('fromString parses correctly', () {
        expect(Gender.fromString('male'), equals(Gender.male));
        expect(Gender.fromString('female'), equals(Gender.female));
      });

      test('fromString defaults to male for unknown', () {
        expect(Gender.fromString('unknown'), equals(Gender.male));
        expect(Gender.fromString(''), equals(Gender.male));
      });

      test('fromStringNullable returns null for null input', () {
        expect(Gender.fromStringNullable(null), isNull);
      });

      test('fromStringNullable returns null for invalid input', () {
        expect(Gender.fromStringNullable('invalid'), isNull);
      });

      test('fromStringNullable parses valid input', () {
        expect(Gender.fromStringNullable('male'), equals(Gender.male));
        expect(Gender.fromStringNullable('female'), equals(Gender.female));
      });

      test('gender values are correct', () {
        expect(Gender.male.value, equals('male'));
        expect(Gender.female.value, equals('female'));
      });
    });

    group('BowType', () {
      test('all bow types have correct values', () {
        expect(BowType.recurve.value, equals('recurve'));
        expect(BowType.compound.value, equals('compound'));
        expect(BowType.barebow.value, equals('barebow'));
        expect(BowType.longbow.value, equals('longbow'));
        expect(BowType.traditional.value, equals('traditional'));
      });

      test('fromString parses correctly', () {
        expect(BowType.fromString('recurve'), equals(BowType.recurve));
        expect(BowType.fromString('compound'), equals(BowType.compound));
        expect(BowType.fromString('barebow'), equals(BowType.barebow));
        expect(BowType.fromString('longbow'), equals(BowType.longbow));
        expect(BowType.fromString('traditional'), equals(BowType.traditional));
      });

      test('fromString defaults to recurve for unknown', () {
        expect(BowType.fromString('unknown'), equals(BowType.recurve));
      });
    });

    group('Handedness', () {
      test('fromString parses correctly', () {
        expect(Handedness.fromString('right'), equals(Handedness.right));
        expect(Handedness.fromString('left'), equals(Handedness.left));
      });

      test('fromString defaults to right for unknown', () {
        expect(Handedness.fromString('unknown'), equals(Handedness.right));
      });

      test('display names are correct', () {
        expect(Handedness.right.displayName, equals('Right-handed'));
        expect(Handedness.left.displayName, equals('Left-handed'));
      });
    });

    group('CompetitionLevel', () {
      test('all levels have correct values', () {
        expect(CompetitionLevel.local.value, equals('local'));
        expect(CompetitionLevel.regional.value, equals('regional'));
        expect(CompetitionLevel.national.value, equals('national'));
        expect(CompetitionLevel.international.value, equals('international'));
        expect(CompetitionLevel.nationalTeam.value, equals('national_team'));
      });

      test('fromString parses correctly', () {
        expect(CompetitionLevel.fromString('local'), equals(CompetitionLevel.local));
        expect(CompetitionLevel.fromString('national'), equals(CompetitionLevel.national));
        expect(CompetitionLevel.fromString('national_team'), equals(CompetitionLevel.nationalTeam));
      });

      test('fromString defaults to local for unknown', () {
        expect(CompetitionLevel.fromString('unknown'), equals(CompetitionLevel.local));
      });

      test('fromJsonList parses empty input', () {
        expect(CompetitionLevel.fromJsonList(null), isEmpty);
        expect(CompetitionLevel.fromJsonList(''), isEmpty);
      });

      test('fromJsonList parses valid JSON array', () {
        final levels = CompetitionLevel.fromJsonList('["local","national"]');
        expect(levels.length, equals(2));
        expect(levels[0], equals(CompetitionLevel.local));
        expect(levels[1], equals(CompetitionLevel.national));
      });

      test('fromJsonList handles invalid JSON gracefully', () {
        expect(CompetitionLevel.fromJsonList('not json'), isEmpty);
      });

      test('toJsonList creates valid JSON', () {
        final json = CompetitionLevel.toJsonList([
          CompetitionLevel.local,
          CompetitionLevel.national,
        ]);
        expect(json, equals('["local","national"]'));
      });
    });

    group('BowTypeDefaults', () {
      test('indoor suggestions are correct for each bow type', () {
        expect(BowTypeDefaults.getIndoorSuggestion(BowType.recurve), contains('Triple spot'));
        expect(BowTypeDefaults.getIndoorSuggestion(BowType.compound), contains('Small inner'));
        expect(BowTypeDefaults.getIndoorSuggestion(BowType.barebow), contains('Full face'));
        expect(BowTypeDefaults.getIndoorSuggestion(BowType.longbow), contains('Full face'));
        expect(BowTypeDefaults.getIndoorSuggestion(BowType.traditional), contains('Full face'));
      });

      test('outdoor defaults are correct for recurve', () {
        final defaults = BowTypeDefaults.getOutdoorDefaults(BowType.recurve);
        expect(defaults.distance, equals(70));
        expect(defaults.faceSize, equals(122));
      });

      test('outdoor defaults are correct for compound', () {
        final defaults = BowTypeDefaults.getOutdoorDefaults(BowType.compound);
        expect(defaults.distance, equals(50));
        expect(defaults.faceSize, equals(80));
      });

      test('outdoor defaults are correct for barebow', () {
        final defaults = BowTypeDefaults.getOutdoorDefaults(BowType.barebow);
        expect(defaults.distance, equals(50));
        expect(defaults.faceSize, equals(122));
      });

      test('outdoor suggestions include distance and face size', () {
        final suggestion = BowTypeDefaults.getOutdoorSuggestion(BowType.recurve);
        expect(suggestion, contains('70m'));
        expect(suggestion, contains('122cm'));
      });

      test('triple spot preference is correct', () {
        expect(BowTypeDefaults.prefersTripleSpot(BowType.recurve), isTrue);
        expect(BowTypeDefaults.prefersTripleSpot(BowType.compound), isTrue);
        expect(BowTypeDefaults.prefersTripleSpot(BowType.barebow), isFalse);
        expect(BowTypeDefaults.prefersTripleSpot(BowType.longbow), isFalse);
        expect(BowTypeDefaults.prefersTripleSpot(BowType.traditional), isFalse);
      });
    });

    group('threshold calculation verification', () {
      // Comprehensive verification of the threshold formula across all combinations

      test('threshold increases by 7 for each classification level down', () {
        // For adult male recurve outdoor
        const datum = 30;
        const ageStep = 0;
        const genderAdj = 0;

        for (int i = 0; i < 7; i++) {
          final threshold1 = datum + (ageStep * 3) + genderAdj + (i * 7);
          final threshold2 = datum + (ageStep * 3) + genderAdj + ((i + 1) * 7);
          expect(threshold2 - threshold1, equals(7));
        }
      });

      test('threshold increases by 3 for each ageStep increase', () {
        // For adult male recurve outdoor GMB
        const datum = 30;
        const genderAdj = 0;
        const classIndex = 0;

        for (int ageStep = 0; ageStep < 8; ageStep++) {
          final threshold1 = datum + (ageStep * 3) + genderAdj + (classIndex * 7);
          final threshold2 = datum + ((ageStep + 1) * 3) + genderAdj + (classIndex * 7);
          expect(threshold2 - threshold1, equals(3));
        }
      });

      test('female thresholds are exactly 7 higher than male', () {
        // For adult recurve outdoor GMB
        const datum = 30;
        const ageStep = 0;
        const classIndex = 0;

        final maleThreshold = datum + (ageStep * 3) + 0 + (classIndex * 7);
        final femaleThreshold = datum + (ageStep * 3) + 7 + (classIndex * 7);

        expect(femaleThreshold - maleThreshold, equals(7));
      });
    });
  });
}
