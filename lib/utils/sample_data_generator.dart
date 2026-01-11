import 'package:drift/drift.dart';
import '../db/database.dart';

/// Generate sample score data for testing the handicap chart
class SampleDataGenerator {
  static Future<void> generateSampleScores(AppDatabase db) async {
    final scores = [
      // WA 720 70m scores (2023)
      _score('2023-08-15', 'WA 720 70m', 670),
      _score('2023-08-10', 'WA 720 70m', 665),
      _score('2023-08-05', 'WA 720 70m', 658),
      _score('2023-07-28', 'WA 720 70m', 663),
      _score('2023-07-20', 'WA 720 70m', 655),

      // Portsmouth scores (2023-2024)
      _score('2023-12-08', 'Portsmouth', 589),
      _score('2023-12-01', 'Portsmouth', 586),
      _score('2023-11-30', 'Portsmouth', 595),
      _score('2023-11-26', 'Portsmouth', 585),
      _score('2023-11-18', 'Portsmouth', 586),

      // WA 18m scores (winter 2023-2024)
      _score('2024-01-15', 'WA 18m', 588),
      _score('2024-01-10', 'WA 18m', 587),
      _score('2024-01-05', 'WA 18m', 589),
      _score('2023-12-20', 'WA 18m', 586),
      _score('2023-12-15', 'WA 18m', 585),

      // York outdoor (summer 2023)
      _score('2023-06-20', 'York', 1212),
      _score('2023-06-15', 'York', 1192),
      _score('2023-06-10', 'York', 1205),

      // More WA 720 70m (spring 2023)
      _score('2023-05-25', 'WA 720 70m', 661),
      _score('2023-05-18', 'WA 720 70m', 659),
      _score('2023-05-10', 'WA 720 70m', 655),
      _score('2023-05-05', 'WA 720 70m', 658),
      _score('2023-04-28', 'WA 720 70m', 651),
      _score('2023-04-20', 'WA 720 70m', 647),

      // Early 2023 indoor
      _score('2023-03-15', 'Portsmouth', 594),
      _score('2023-03-10', 'Portsmouth', 590),
      _score('2023-03-05', 'WA 18m', 587),
      _score('2023-02-28', 'WA 18m', 588),
      _score('2023-02-20', 'Portsmouth', 592),
    ];

    for (final score in scores) {
      await db.insertImportedScore(score);
    }
  }

  static ImportedScoresCompanion _score(String dateStr, String roundName, int score) {
    final parts = dateStr.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    return ImportedScoresCompanion.insert(
      id: '${date.millisecondsSinceEpoch}_$score',
      date: date,
      roundName: roundName,
      score: score,
      source: const Value('sample'),
    );
  }
}
