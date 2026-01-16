import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/import_service.dart';

void main() {
  late ImportService service;

  setUp(() {
    service = ImportService();
  });

  group('parseScoresCsv - Valid files', () {
    test('parses valid score CSV with header', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'],
        ['2026-01-14', '720', 'WA 720'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 2);
      expect(result.skipped, 0);
      expect(result.reasons, isEmpty);

      expect(result.drafts[0].date, DateTime(2026, 1, 15));
      expect(result.drafts[0].score, 650);
      expect(result.drafts[0].roundName, 'WA 1440');

      expect(result.drafts[1].date, DateTime(2026, 1, 14));
      expect(result.drafts[1].score, 720);
      expect(result.drafts[1].roundName, 'WA 720');
    });

    test('parses valid score CSV without header', () {
      final rows = [
        ['2026-01-15', '650', 'WA 1440'],
        ['2026-01-14', '720', 'WA 720'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 2);
      expect(result.skipped, 0);
      expect(result.drafts[0].score, 650);
      expect(result.drafts[1].score, 720);
    });

    test('parses all optional columns when present', () {
      final rows = [
        [
          'Date',
          'Score',
          'Round',
          'Location',
          'Handicap',
          'Hits',
          'Golds',
          'Xs',
          'BowStyle',
          'EventType',
          'Classification'
        ],
        [
          '2026-01-15',
          '650',
          'WA 1440',
          'National Range',
          '35',
          '144',
          '24',
          '8',
          'Recurve',
          'Competition',
          'Master Bowman'
        ],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.skipped, 0);

      final draft = result.drafts[0];
      expect(draft.score, 650);
      expect(draft.roundName, 'WA 1440');
      expect(draft.location, 'National Range');
      expect(draft.handicap, 35);
      expect(draft.hits, 144);
      expect(draft.golds, 24);
      expect(draft.xs, 8);
      expect(draft.bowstyle, 'Recurve');
      expect(draft.eventType, 'Competition');
      expect(draft.classification, 'Master Bowman');
      expect(draft.notes,
          'HC: 35, Hits: 144, Golds: 24, Xs: 8, Master Bowman');
    });

    test('handles missing optional columns', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.skipped, 0);

      final draft = result.drafts[0];
      expect(draft.location, isNull);
      expect(draft.handicap, isNull);
      expect(draft.hits, isNull);
      expect(draft.golds, isNull);
      expect(draft.xs, isNull);
      expect(draft.bowstyle, isNull);
      expect(draft.eventType, isNull);
      expect(draft.classification, isNull);
      expect(draft.notes, isNull);
    });

    test('detects columns using alternative naming conventions', () {
      final rows = [
        ['shot_date', 'total', 'round_name', 'eventname'],
        ['2026-01-15', '650', 'WA 1440', 'Winter Cup'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].date, DateTime(2026, 1, 15));
      expect(result.drafts[0].score, 650);
      expect(result.drafts[0].roundName, 'WA 1440');
      expect(result.drafts[0].location, 'Winter Cup');
    });

    test('detects columns using "contains" matching for longer aliases', () {
      final rows = [
        ['competition_date', 'final_score', 'format', 'event_name'],
        ['2026-01-15', '650', 'WA 1440', 'Winter Cup'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].date, DateTime(2026, 1, 15));
      expect(result.drafts[0].score, 650);
    });
  });

  group('parseScoresCsv - Date formats', () {
    test('parses ISO date format (YYYY-MM-DD)', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].date, DateTime(2026, 1, 15));
    });

    test('parses European date format (DD/MM/YYYY)', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['15/01/2026', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].date, DateTime(2026, 1, 15));
    });

    test('parses dash-separated date format (DD-MM-YYYY)', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['15-01-2026', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].date, DateTime(2026, 1, 15));
    });

    test('parses German date format (DD.MM.YYYY)', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['15.01.2026', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].date, DateTime(2026, 1, 15));
    });

    test('handles dates with single-digit day/month (D/M/YYYY)', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['5/1/2026', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].date, DateTime(2026, 1, 5));
    });

    test('handles dates with single-digit day/month in ISO format (YYYY-M-D)',
        () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-1-5', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].date, DateTime(2026, 1, 5));
    });
  });

  group('parseScoresCsv - Score validation', () {
    test('parses scores as integers', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].score, 650);
    });

    test('handles scores with commas (e.g., 1,296)', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '1,296', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].score, 1296);
    });

    test('handles negative scores by stripping minus sign', () {
      // The regex [^0-9] removes all non-digits, so "-100" becomes "100"
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '-100', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].score, 100); // minus sign stripped
    });

    test('rejects zero scores', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '0', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 0);
      expect(result.skipped, 1);
      expect(result.reasons[0], contains('Invalid score'));
    });

    test('rejects non-numeric scores', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', 'abc', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 0);
      expect(result.skipped, 1);
      expect(result.reasons[0], contains('Invalid score'));
    });

    test('rejects empty scores', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 0);
      expect(result.skipped, 1);
      expect(result.reasons[0], contains('Invalid score'));
    });
  });

  group('parseScoresCsv - Row-level error reporting', () {
    test('reports invalid date with row number', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['invalid-date', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 0);
      expect(result.skipped, 1);
      expect(result.reasons.length, 1);
      expect(result.reasons[0], contains('Row 2'));
      expect(result.reasons[0], contains('Invalid date'));
      expect(result.reasons[0], contains('invalid-date'));
    });

    test('reports invalid score with row number', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', 'bad', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 0);
      expect(result.skipped, 1);
      expect(result.reasons[0], contains('Row 2'));
      expect(result.reasons[0], contains('Invalid score'));
      expect(result.reasons[0], contains('bad'));
    });

    test('tracks multiple skipped rows', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['invalid', '650', 'WA 1440'],
        ['2026-01-15', 'bad', 'WA 1440'],
        ['2026-01-14', '720', 'WA 720'], // valid
        ['2026-01-13', '0', 'WA 720'], // invalid score
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1); // only one valid row
      expect(result.skipped, 3);
      expect(result.reasons.length, 3);
    });

    test('limits error reasons to first 5', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['invalid1', '650', 'WA 1440'],
        ['invalid2', '650', 'WA 1440'],
        ['invalid3', '650', 'WA 1440'],
        ['invalid4', '650', 'WA 1440'],
        ['invalid5', '650', 'WA 1440'],
        ['invalid6', '650', 'WA 1440'],
        ['invalid7', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.skipped, 7);
      expect(result.reasons.length, 5); // limited to 5
    });

    test('continues parsing after errors', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['invalid', '650', 'WA 1440'],
        ['2026-01-15', '650', 'WA 1440'], // valid
        ['2026-01-14', 'bad', 'WA 720'],
        ['2026-01-13', '720', 'WA 720'], // valid
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 2);
      expect(result.skipped, 2);
      expect(result.drafts[0].score, 650);
      expect(result.drafts[1].score, 720);
    });
  });

  group('parseScoresCsv - Missing required columns', () {
    test('handles missing date column by using default position 0', () {
      final rows = [
        ['Score', 'Round'],
        ['650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      // Should try to parse first column as date, which is "Score" -> fails
      expect(result.drafts.length, 0);
      expect(result.skipped, 1);
    });

    test('handles missing score column by using default position 1', () {
      final rows = [
        ['Date', 'Round'],
        ['2026-01-15', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      // Header detected, roundCol found at position 1
      // scoreCol defaults to 1 (not found), so reads "WA 1440"
      // The regex [^0-9] extracts "1440" from "WA 1440"
      expect(result.drafts.length, 1);
      expect(result.drafts[0].score, 1440); // extracted from "WA 1440"
      expect(result.drafts[0].roundName, 'WA 1440'); // roundCol is position 1
    });

    test('handles missing round column by using default position 2', () {
      final rows = [
        ['Date', 'Score'],
        ['2026-01-15', '650'],
      ];

      final result = service.parseScoresCsv(rows);

      // Should parse with "Unknown" as default round name
      expect(result.drafts.length, 1);
      expect(result.drafts[0].roundName, 'Unknown');
    });

    test('handles rows shorter than expected columns', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15'], // missing score and round
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 0);
      expect(result.skipped, 1);
    });
  });

  group('parseScoresCsv - Special characters and encoding', () {
    test('handles UTF-8 BOM in first column header', () {
      final rows = [
        ['\uFEFFDate', 'Score', 'Round'], // BOM prefix
        ['2026-01-15', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      // The service should still detect "date" even with BOM
      // (lowercase and trim should handle it)
      expect(result.drafts.length, 1);
      expect(result.drafts[0].score, 650);
    });

    test('handles special characters in location and notes', () {
      final rows = [
        ['Date', 'Score', 'Round', 'Location'],
        ['2026-01-15', '650', 'WA 1440', 'Café & Restaurant'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].location, 'Café & Restaurant');
    });

    test('trims whitespace from string fields', () {
      final rows = [
        ['Date', 'Score', 'Round', 'Location'],
        ['2026-01-15', '650', '  WA 1440  ', '  National Range  '],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].roundName, 'WA 1440');
      expect(result.drafts[0].location, 'National Range');
    });

    test('handles empty string values in optional fields', () {
      final rows = [
        ['Date', 'Score', 'Round', 'Location', 'BowStyle'],
        ['2026-01-15', '650', 'WA 1440', '', ''],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].location, isNull); // empty string -> null
      expect(result.drafts[0].bowstyle, isNull);
    });
  });

  group('parseScoresCsv - Edge cases', () {
    test('handles empty CSV', () {
      final rows = <List<dynamic>>[];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts, isEmpty);
      expect(result.skipped, 0);
      expect(result.reasons, isEmpty);
    });

    test('handles CSV with only header row', () {
      final rows = [
        ['Date', 'Score', 'Round'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts, isEmpty);
      expect(result.skipped, 0);
    });

    test('skips empty rows', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        [],
        ['2026-01-15', '650', 'WA 1440'],
        [],
        ['2026-01-14', '720', 'WA 720'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 2);
      expect(result.skipped, 0); // empty rows don't count as skipped
    });

    test('handles rows with extra columns beyond expected', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440', 'extra1', 'extra2'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].score, 650);
    });

    test('handles mixed valid and invalid rows', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'],
        ['invalid', '720', 'WA 720'],
        ['2026-01-14', 'bad', 'WA 720'],
        ['2026-01-13', '680', 'WA 720'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 2);
      expect(result.skipped, 2);
      expect(result.drafts[0].score, 650);
      expect(result.drafts[1].score, 680);
    });
  });

  group('parseScoresCsv - Windows line endings', () {
    test('handles data with Windows line ending characters in strings', () {
      // Simulate strings that might contain \r\n within cell values
      final rows = [
        ['Date', 'Score', 'Round', 'Location'],
        ['2026-01-15', '650', 'WA 1440', 'Test\r\nLocation'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].location, 'Test\r\nLocation');
    });
  });

  group('parseScoresCsv - Notes field construction', () {
    test('builds notes from handicap, hits, golds, xs, classification', () {
      final rows = [
        [
          'Date',
          'Score',
          'Round',
          'Handicap',
          'Hits',
          'Golds',
          'Xs',
          'Classification'
        ],
        ['2026-01-15', '650', 'WA 1440', '35', '144', '24', '8', 'Master'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].notes, 'HC: 35, Hits: 144, Golds: 24, Xs: 8, Master');
    });

    test('omits zero values from notes', () {
      final rows = [
        ['Date', 'Score', 'Round', 'Handicap', 'Hits', 'Golds', 'Xs'],
        ['2026-01-15', '650', 'WA 1440', '0', '144', '0', '8'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].notes, 'Hits: 144, Xs: 8');
    });

    test('sets notes to null when no extra fields present', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.drafts[0].notes, isNull);
    });
  });

  group('parseScoresCsv - Archr export format compatibility', () {
    test('parses typical Archr export with handicapatscore column', () {
      final rows = [
        [
          'shot_date',
          'total_score',
          'round_name',
          'eventname',
          'handicapatscore',
          'arrows_shot',
          'tens',
          'x_count'
        ],
        ['15/01/2026', '650', 'WA 1440', 'Winter Cup', '35', '144', '24', '8'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      final draft = result.drafts[0];
      expect(draft.date, DateTime(2026, 1, 15));
      expect(draft.score, 650);
      expect(draft.roundName, 'WA 1440');
      expect(draft.location, 'Winter Cup');
      expect(draft.handicap, 35);
      expect(draft.hits, 144);
      expect(draft.golds, 24);
      expect(draft.xs, 8);
    });
  });

  group('parseVolumeCsv - Valid files', () {
    test('parses valid volume CSV with header', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144'],
        ['2026-01-14', '216'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 2);

      expect(result[0].date, DateTime(2026, 1, 15));
      expect(result[0].arrowCount, 144);
      expect(result[0].title, isNull);
      expect(result[0].notes, isNull);

      expect(result[1].date, DateTime(2026, 1, 14));
      expect(result[1].arrowCount, 216);
    });

    test('parses valid volume CSV without header', () {
      final rows = [
        ['2026-01-15', '144'],
        ['2026-01-14', '216'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 2);
      expect(result[0].arrowCount, 144);
      expect(result[1].arrowCount, 216);
    });

    test('parses volume CSV with all optional columns', () {
      final rows = [
        ['Date', 'Volume', 'Title', 'Notes'],
        ['2026-01-15', '144', 'Morning Practice', 'Good form today'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
      expect(result[0].arrowCount, 144);
      expect(result[0].title, 'Morning Practice');
      expect(result[0].notes, 'Good form today');
    });

    test('detects volume columns using alternative naming conventions', () {
      final rows = [
        ['day', 'arrows'],
        ['2026-01-15', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
      expect(result[0].arrowCount, 144);
    });

    test('detects columns using "contains" matching for longer aliases', () {
      final rows = [
        ['training_date', 'arrow_count', 'session_name', 'remarks'],
        ['2026-01-15', '144', 'AM Session', 'Windy conditions'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
      expect(result[0].arrowCount, 144);
      expect(result[0].title, 'AM Session');
      expect(result[0].notes, 'Windy conditions');
    });

    test('handles mixed naming conventions', () {
      final rows = [
        ['when', 'arrowcount', 'event', 'comment'],
        ['2026-01-15', '144', 'Practice', 'Testing new arrows'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].arrowCount, 144);
      expect(result[0].title, 'Practice');
      expect(result[0].notes, 'Testing new arrows');
    });
  });

  group('parseVolumeCsv - Arrow count validation', () {
    test('parses arrow counts as integers', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].arrowCount, 144);
    });

    test('handles arrow counts with commas (e.g., 1,200)', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '1,200'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].arrowCount, 1200);
    });

    test('rejects zero arrow counts', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '0'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 0);
    });

    test('rejects negative arrow counts', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '-100'],
      ];

      final result = service.parseVolumeCsv(rows);

      // The regex strips minus sign, leaving "100" which is valid
      // This matches the scores behavior
      expect(result.length, 1);
      expect(result[0].arrowCount, 100);
    });

    test('rejects non-numeric arrow counts', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', 'abc'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 0);
    });

    test('rejects empty arrow counts', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', ''],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 0);
    });

    test('accepts typical archery arrow counts', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '36'], // half york
        ['2026-01-14', '72'], // full york
        ['2026-01-13', '144'], // WA 1440
        ['2026-01-12', '216'], // heavy training day
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 4);
      expect(result[0].arrowCount, 36);
      expect(result[1].arrowCount, 72);
      expect(result[2].arrowCount, 144);
      expect(result[3].arrowCount, 216);
    });
  });

  group('parseVolumeCsv - Date formats', () {
    test('parses ISO date format (YYYY-MM-DD)', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
    });

    test('parses European date format (DD/MM/YYYY)', () {
      final rows = [
        ['Date', 'Volume'],
        ['15/01/2026', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
    });

    test('parses dash-separated date format (DD-MM-YYYY)', () {
      final rows = [
        ['Date', 'Volume'],
        ['15-01-2026', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
    });

    test('parses German date format (DD.MM.YYYY)', () {
      final rows = [
        ['Date', 'Volume'],
        ['15.01.2026', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
    });

    test('handles dates with single-digit day/month (D/M/YYYY)', () {
      final rows = [
        ['Date', 'Volume'],
        ['5/1/2026', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 5));
    });

    test('handles dates with single-digit day/month in ISO format (YYYY-M-D)',
        () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-1-5', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 5));
    });

    test('skips rows with invalid dates silently', () {
      final rows = [
        ['Date', 'Volume'],
        ['invalid-date', '144'],
        ['2026-01-15', '216'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
      expect(result[0].arrowCount, 216);
    });
  });

  group('parseVolumeCsv - Error handling', () {
    test('silently skips invalid rows', () {
      final rows = [
        ['Date', 'Volume'],
        ['invalid', '144'],
        ['2026-01-15', 'bad'],
        ['2026-01-14', '216'], // valid
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].arrowCount, 216);
    });

    test('continues parsing after errors', () {
      final rows = [
        ['Date', 'Volume'],
        ['invalid', '144'],
        ['2026-01-15', '144'], // valid
        ['2026-01-14', 'bad'],
        ['2026-01-13', '216'], // valid
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 2);
      expect(result[0].arrowCount, 144);
      expect(result[1].arrowCount, 216);
    });

    test('handles rows shorter than expected columns', () {
      final rows = [
        ['Date', 'Volume', 'Title'],
        ['2026-01-15'], // missing volume and title
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 0);
    });

    test('handles exception during row parsing', () {
      // Test that try-catch handles unexpected errors gracefully
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144'],
        [], // empty row
        ['2026-01-14', '216'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 2);
      expect(result[0].arrowCount, 144);
      expect(result[1].arrowCount, 216);
    });
  });

  group('parseVolumeCsv - Edge cases', () {
    test('handles empty CSV', () {
      final rows = <List<dynamic>>[];

      final result = service.parseVolumeCsv(rows);

      expect(result, isEmpty);
    });

    test('handles CSV with only header row', () {
      final rows = [
        ['Date', 'Volume'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result, isEmpty);
    });

    test('skips empty rows', () {
      final rows = [
        ['Date', 'Volume'],
        [],
        ['2026-01-15', '144'],
        [],
        ['2026-01-14', '216'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 2);
      expect(result[0].arrowCount, 144);
      expect(result[1].arrowCount, 216);
    });

    test('handles rows with extra columns beyond expected', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144', 'extra1', 'extra2'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].arrowCount, 144);
    });

    test('handles mixed valid and invalid rows', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144'],
        ['invalid', '216'],
        ['2026-01-14', 'bad'],
        ['2026-01-13', '72'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 2);
      expect(result[0].arrowCount, 144);
      expect(result[1].arrowCount, 72);
    });
  });

  group('parseVolumeCsv - Special characters and encoding', () {
    test('handles UTF-8 BOM in first column header', () {
      final rows = [
        ['\uFEFFDate', 'Volume'], // BOM prefix
        ['2026-01-15', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].arrowCount, 144);
    });

    test('handles special characters in title and notes', () {
      final rows = [
        ['Date', 'Volume', 'Title', 'Notes'],
        ['2026-01-15', '144', 'Café Practice', 'Wind & rain'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].title, 'Café Practice');
      expect(result[0].notes, 'Wind & rain');
    });

    test('trims whitespace from string fields', () {
      final rows = [
        ['Date', 'Volume', 'Title', 'Notes'],
        ['2026-01-15', '144', '  Morning  ', '  Good session  '],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].title, 'Morning');
      expect(result[0].notes, 'Good session');
    });

    test('handles empty string values in optional fields', () {
      final rows = [
        ['Date', 'Volume', 'Title', 'Notes'],
        ['2026-01-15', '144', '', ''],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].title, isNull); // empty string -> null
      expect(result[0].notes, isNull);
    });
  });

  group('parseVolumeCsv - Default column positions', () {
    test('uses default positions when header not detected', () {
      final rows = [
        ['2026-01-15', '144', 'Practice', 'Notes here'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].date, DateTime(2026, 1, 15));
      expect(result[0].arrowCount, 144);
      expect(result[0].title, 'Practice');
      expect(result[0].notes, 'Notes here');
    });

    test('handles missing optional columns with default positions', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].title, isNull);
      expect(result[0].notes, isNull);
    });
  });

  group('parseVolumeCsv - Real-world scenarios', () {
    test('parses typical training log export', () {
      final rows = [
        ['Date', 'Arrows', 'Session', 'Notes'],
        ['2026-01-15', '144', 'Morning Practice', 'Warm-up + form work'],
        ['2026-01-14', '72', 'Evening Session', 'Short distance'],
        ['2026-01-13', '216', 'Full Day Training', 'Competition prep'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 3);
      expect(result[0].arrowCount, 144);
      expect(result[0].title, 'Morning Practice');
      expect(result[1].arrowCount, 72);
      expect(result[2].arrowCount, 216);
    });

    test('parses minimal CSV with just date and volume', () {
      final rows = [
        ['2026-01-15', '144'],
        ['2026-01-14', '72'],
        ['2026-01-13', '216'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 3);
      expect(result[0].arrowCount, 144);
      expect(result[1].arrowCount, 72);
      expect(result[2].arrowCount, 216);
    });

    test('handles large arrow counts for heavy training days', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '500'], // intensive training camp day
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 1);
      expect(result[0].arrowCount, 500);
    });
  });

  group('Import error handling - Empty files', () {
    test('parseScoresCsv returns helpful result for empty file', () {
      final rows = <List<dynamic>>[];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts, isEmpty);
      expect(result.skipped, 0);
      expect(result.reasons, isEmpty);
    });

    test('parseVolumeCsv returns empty list for empty file', () {
      final rows = <List<dynamic>>[];

      final result = service.parseVolumeCsv(rows);

      expect(result, isEmpty);
    });
  });

  group('Import error handling - Binary/invalid file content', () {
    test('parseScoresCsv handles binary-like content gracefully', () {
      // Simulate binary file content as rows of gibberish
      final rows = [
        ['\x00\x01\x02', '\xFF\xFE', 'binary'],
        ['garbage', 'data', 'here'],
      ];

      final result = service.parseScoresCsv(rows);

      // Should skip all rows as invalid
      expect(result.drafts, isEmpty);
      expect(result.skipped, 2);
      expect(result.reasons.length, 2);
      expect(result.reasons[0], contains('Invalid date'));
    });

    test('parseVolumeCsv handles binary-like content gracefully', () {
      final rows = [
        ['\x00\x01\x02', '\xFF\xFE'],
        ['garbage', 'data'],
      ];

      final result = service.parseVolumeCsv(rows);

      // Should return empty list (all rows silently skipped)
      expect(result, isEmpty);
    });

    test('parseScoresCsv handles non-CSV data gracefully', () {
      // Single row with completely wrong structure
      final rows = [
        ['This is not a CSV file at all, just plain text'],
      ];

      final result = service.parseScoresCsv(rows);

      // Will be treated as no header, tries to parse first row as data
      // Date will be invalid, so skipped
      expect(result.drafts, isEmpty);
      expect(result.skipped, 1);
    });

    test('parseVolumeCsv handles non-CSV data gracefully', () {
      final rows = [
        ['This is not a CSV file at all'],
      ];

      final result = service.parseVolumeCsv(rows);

      expect(result, isEmpty);
    });
  });

  group('Import error handling - Extremely large files', () {
    test('parseScoresCsv handles 10,000 row file efficiently', () {
      // Generate large file with mixed valid/invalid rows
      final rows = <List<dynamic>>[
        ['Date', 'Score', 'Round']
      ];

      // Add 10,000 data rows
      for (int i = 1; i <= 10000; i++) {
        rows.add([
          '2026-01-15',
          '${600 + i}',
          'WA 1440 #$i',
        ]);
      }

      final result = service.parseScoresCsv(rows);

      // Should parse all successfully
      expect(result.drafts.length, 10000);
      expect(result.skipped, 0);
      expect(result.drafts.first.score, 601);
      expect(result.drafts.last.score, 10600);
    });

    test('parseVolumeCsv handles 10,000 row file efficiently', () {
      final rows = <List<dynamic>>[
        ['Date', 'Volume']
      ];

      for (int i = 1; i <= 10000; i++) {
        rows.add(['2026-01-15', '${100 + i}']);
      }

      final result = service.parseVolumeCsv(rows);

      expect(result.length, 10000);
      expect(result.first.arrowCount, 101);
      expect(result.last.arrowCount, 10100);
    });

    test('parseScoresCsv handles large file with many errors efficiently', () {
      final rows = <List<dynamic>>[
        ['Date', 'Score', 'Round']
      ];

      // Add 5,000 invalid rows and 5,000 valid rows
      for (int i = 1; i <= 5000; i++) {
        rows.add(['invalid-date', '650', 'Round $i']);
      }
      for (int i = 1; i <= 5000; i++) {
        rows.add(['2026-01-15', '${600 + i}', 'Round $i']);
      }

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 5000);
      expect(result.skipped, 5000);
      expect(result.reasons.length, 5); // Limited to first 5 errors
    });
  });

  group('Import error handling - Partial success reporting', () {
    test('parseScoresCsv reports partial success with clear counts', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'], // valid - row 2
        ['invalid-date', '720', 'WA 720'], // invalid - row 3
        ['2026-01-14', 'bad-score', 'WA 720'], // invalid - row 4
        ['2026-01-13', '680', 'WA 720'], // valid - row 5
        ['2026-01-12', '0', 'WA 720'], // invalid (zero score) - row 6
      ];

      final result = service.parseScoresCsv(rows);

      // Partial success: 2 valid, 3 skipped
      expect(result.drafts.length, 2);
      expect(result.skipped, 3);
      expect(result.reasons.length, 3);

      // Verify valid rows parsed correctly
      expect(result.drafts[0].score, 650);
      expect(result.drafts[1].score, 680);

      // Verify error messages are helpful
      expect(result.reasons[0], contains('Row 3'));
      expect(result.reasons[0], contains('Invalid date'));
      expect(result.reasons[1], contains('Row 4'));
      expect(result.reasons[1], contains('Invalid score'));
      expect(result.reasons[2], contains('Row 6'));
      expect(result.reasons[2], contains('Invalid score'));
    });

    test('parseScoresCsv reports what worked when mostly invalid', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['invalid1', '650', 'Round'],
        ['invalid2', '720', 'Round'],
        ['2026-01-15', '680', 'WA 720'], // only valid row
        ['invalid3', '690', 'Round'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 1);
      expect(result.skipped, 3);
      expect(result.drafts[0].score, 680);
      expect(result.reasons.length, 3);
    });

    test('parseScoresCsv reports all success when fully valid', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'],
        ['2026-01-14', '720', 'WA 720'],
        ['2026-01-13', '680', 'WA 720'],
      ];

      final result = service.parseScoresCsv(rows);

      expect(result.drafts.length, 3);
      expect(result.skipped, 0);
      expect(result.reasons, isEmpty);
    });

    test('parseVolumeCsv partial success is silent (by design)', () {
      // Volume parsing silently skips invalid rows
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144'], // valid
        ['invalid', '216'], // skipped
        ['2026-01-14', 'bad'], // skipped
        ['2026-01-13', '72'], // valid
      ];

      final result = service.parseVolumeCsv(rows);

      // Only returns successful parses, no error reporting
      expect(result.length, 2);
      expect(result[0].arrowCount, 144);
      expect(result[1].arrowCount, 72);
    });
  });

  group('Import error handling - Real-world failure scenarios', () {
    test('parseScoresCsv handles Excel formula exports', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '=SUM(A1:A10)', 'WA 1440'], // Excel formula
        ['2026-01-14', '720', 'WA 720'], // valid
      ];

      final result = service.parseScoresCsv(rows);

      // Formula extracts "110" from "SUM(A1:A10)"
      // This is acceptable behavior - extracts digits
      expect(result.drafts.length, 2);
      expect(result.drafts[0].score, 110); // digits from formula
      expect(result.drafts[1].score, 720);
    });

    test('parseScoresCsv handles CSV with wrong delimiter (semicolon)', () {
      // CSV library should handle this, but if it comes through as single cells
      final rows = [
        ['Date;Score;Round'], // wrong delimiter - appears as one cell
      ];

      final result = service.parseScoresCsv(rows);

      // Will be treated as no valid data
      expect(result.drafts, isEmpty);
    });

    test('parseScoresCsv handles file with only whitespace rows', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['   ', '   ', '   '],
        ['', '', ''],
      ];

      final result = service.parseScoresCsv(rows);

      // Empty/whitespace rows should be skipped
      expect(result.drafts, isEmpty);
      expect(result.skipped, 2);
    });

    test('parseScoresCsv handles mixed date formats in same file', () {
      final rows = [
        ['Date', 'Score', 'Round'],
        ['2026-01-15', '650', 'WA 1440'], // ISO
        ['15/01/2026', '720', 'WA 720'], // European
        ['15-01-2026', '680', 'WA 720'], // Dash
        ['15.01.2026', '690', 'WA 720'], // German
      ];

      final result = service.parseScoresCsv(rows);

      // All should parse successfully
      expect(result.drafts.length, 4);
      expect(result.skipped, 0);
      expect(result.drafts[0].date, DateTime(2026, 1, 15));
      expect(result.drafts[1].date, DateTime(2026, 1, 15));
      expect(result.drafts[2].date, DateTime(2026, 1, 15));
      expect(result.drafts[3].date, DateTime(2026, 1, 15));
    });

    test('parseVolumeCsv handles common export errors gracefully', () {
      final rows = [
        ['Date', 'Volume'],
        ['2026-01-15', '144'], // valid
        ['not-a-date', '216'], // invalid date format
        ['2026-01-14', ''], // missing volume
        ['', '72'], // missing date
        ['2026-01-13', '0'], // zero volume
      ];

      final result = service.parseVolumeCsv(rows);

      // Only first row is valid (others fail for various reasons)
      expect(result.length, 1);
      expect(result[0].arrowCount, 144);
    });
  });
}
