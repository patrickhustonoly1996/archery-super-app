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
}
