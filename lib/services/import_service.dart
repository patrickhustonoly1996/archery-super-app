/// Service for parsing CSV import data (scores and volume)
///
/// Extracted from import_screen.dart and volume_import_screen.dart
/// to enable unit testing of CSV parsing logic.
class ImportService {
  /// Parse scores CSV data
  ///
  /// Returns a record with:
  /// - drafts: List of parsed score drafts
  /// - skipped: Number of rows skipped due to parsing errors
  /// - reasons: List of skip reasons (limited to first 5)
  ({List<ScoreDraft> drafts, int skipped, List<String> reasons}) parseScoresCsv(
      List<List<dynamic>> rows) {
    if (rows.isEmpty) return (drafts: [], skipped: 0, reasons: []);

    // Try to detect header row
    final firstRow =
        rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final hasHeader = firstRow.any((h) =>
        h.contains('date') || h.contains('score') || h.contains('round'));

    final dataRows = hasHeader ? rows.skip(1) : rows;

    // Column aliases for flexible matching - supports Archr export format
    const dateAliases = [
      'date',
      'shot_date',
      'event_date',
      'competition_date',
      'when',
      'day'
    ];
    const scoreAliases = [
      'score',
      'total',
      'total_score',
      'points',
      'result',
      'final_score'
    ];
    const roundAliases = ['round', 'round_name', 'round_type', 'format'];
    const locationAliases = [
      'eventname',
      'event_name',
      'location',
      'venue',
      'club',
      'competition',
      'place',
      'site'
    ];
    const handicapAliases = [
      'handicap',
      'hc',
      'handicap_score',
      'handicapatscore'
    ];
    const hitsAliases = ['hits', 'arrows', 'arrows_shot'];
    const goldsAliases = ['golds', '10s', 'tens'];
    const xsAliases = ['xs', 'x_count', 'x'];
    const bowstyleAliases = ['bowstyle', 'bow_style', 'bow', 'equipment'];
    const eventTypeAliases = [
      'eventtype',
      'event_type',
      'type',
      'session_type'
    ];
    const classificationAliases = ['classification', 'class', 'grade'];

    // Find column index using aliases (exact match first, then contains)
    int findColumn(List<String> aliases) {
      // Exact match
      for (final alias in aliases) {
        final idx = firstRow.indexOf(alias);
        if (idx >= 0) return idx;
      }
      // Contains match for longer aliases only
      for (final alias in aliases) {
        if (alias.length >= 4) {
          for (int i = 0; i < firstRow.length; i++) {
            if (firstRow[i].contains(alias)) return i;
          }
        }
      }
      return -1;
    }

    int dateCol = hasHeader ? findColumn(dateAliases) : -1;
    int scoreCol = hasHeader ? findColumn(scoreAliases) : -1;
    int roundCol = hasHeader ? findColumn(roundAliases) : -1;
    int locationCol = hasHeader ? findColumn(locationAliases) : -1;
    int handicapCol = hasHeader ? findColumn(handicapAliases) : -1;
    int hitsCol = hasHeader ? findColumn(hitsAliases) : -1;
    int goldsCol = hasHeader ? findColumn(goldsAliases) : -1;
    int xsCol = hasHeader ? findColumn(xsAliases) : -1;
    int bowstyleCol = hasHeader ? findColumn(bowstyleAliases) : -1;
    int eventTypeCol = hasHeader ? findColumn(eventTypeAliases) : -1;
    int classificationCol = hasHeader ? findColumn(classificationAliases) : -1;

    // Default column positions if not found (common CSV format: date, score, round)
    if (dateCol < 0) dateCol = 0;
    if (scoreCol < 0) scoreCol = 1;
    if (roundCol < 0) roundCol = 2;

    final drafts = <ScoreDraft>[];
    int skippedCount = 0;
    final skippedReasons = <String>[];

    int rowNumber = hasHeader ? 2 : 1; // Start counting from 1, skip header
    for (final row in dataRows) {
      if (row.isEmpty) {
        rowNumber++;
        continue;
      }

      try {
        final dateStr = dateCol < row.length ? row[dateCol].toString() : '';
        final scoreStr = scoreCol < row.length ? row[scoreCol].toString() : '';
        final roundName =
            roundCol < row.length ? row[roundCol].toString().trim() : 'Unknown';
        final location = locationCol >= 0 && locationCol < row.length
            ? row[locationCol].toString().trim()
            : null;

        // Parse date
        final date = _parseDate(dateStr);
        if (date == null) {
          skippedCount++;
          if (skippedReasons.length < 5) {
            skippedReasons.add('Row $rowNumber: Invalid date "$dateStr"');
          }
          rowNumber++;
          continue;
        }

        // Parse score - handle commas (e.g., "1,296" -> 1296)
        final score =
            int.tryParse(scoreStr.replaceAll(RegExp(r'[^0-9]'), ''));
        if (score == null || score <= 0) {
          skippedCount++;
          if (skippedReasons.length < 5) {
            skippedReasons.add('Row $rowNumber: Invalid score "$scoreStr"');
          }
          rowNumber++;
          continue;
        }

        // Parse optional fields
        final handicap = handicapCol >= 0 && handicapCol < row.length
            ? int.tryParse(
                row[handicapCol].toString().replaceAll(RegExp(r'[^0-9]'), ''))
            : null;
        final hits = hitsCol >= 0 && hitsCol < row.length
            ? int.tryParse(
                row[hitsCol].toString().replaceAll(RegExp(r'[^0-9]'), ''))
            : null;
        final golds = goldsCol >= 0 && goldsCol < row.length
            ? int.tryParse(
                row[goldsCol].toString().replaceAll(RegExp(r'[^0-9]'), ''))
            : null;
        final xs = xsCol >= 0 && xsCol < row.length
            ? int.tryParse(
                row[xsCol].toString().replaceAll(RegExp(r'[^0-9]'), ''))
            : null;
        final bowstyle = bowstyleCol >= 0 && bowstyleCol < row.length
            ? row[bowstyleCol].toString().trim()
            : null;
        final eventType = eventTypeCol >= 0 && eventTypeCol < row.length
            ? row[eventTypeCol].toString().trim()
            : null;
        final classification =
            classificationCol >= 0 && classificationCol < row.length
                ? row[classificationCol].toString().trim()
                : null;

        // Build notes from extra fields for display
        final notesParts = <String>[];
        if (handicap != null && handicap > 0) notesParts.add('HC: $handicap');
        if (hits != null && hits > 0) notesParts.add('Hits: $hits');
        if (golds != null && golds > 0) notesParts.add('Golds: $golds');
        if (xs != null && xs > 0) notesParts.add('Xs: $xs');
        if (classification != null && classification.isNotEmpty) {
          notesParts.add(classification);
        }

        drafts.add(ScoreDraft(
          date: date,
          score: score,
          roundName: roundName,
          location: location?.isEmpty == true ? null : location,
          notes: notesParts.isEmpty ? null : notesParts.join(', '),
          bowstyle: bowstyle?.isEmpty == true ? null : bowstyle,
          eventType: eventType?.isEmpty == true ? null : eventType,
          handicap: handicap,
          hits: hits,
          golds: golds,
          xs: xs,
          classification: classification?.isEmpty == true ? null : classification,
        ));
      } catch (e) {
        // Track the error
        skippedCount++;
        if (skippedReasons.length < 5) {
          skippedReasons.add('Row $rowNumber: Parse error - $e');
        }
      }
      rowNumber++;
    }

    return (drafts: drafts, skipped: skippedCount, reasons: skippedReasons);
  }

  /// Parse volume CSV data
  ///
  /// Returns a record with:
  /// - drafts: List of parsed volume drafts
  /// - skipped: Number of rows skipped due to parsing errors
  /// - reasons: List of skip reasons (limited to first 5)
  ({List<VolumeDraft> drafts, int skipped, List<String> reasons}) parseVolumeCsv(
      List<List<dynamic>> rows) {
    if (rows.isEmpty) return (drafts: [], skipped: 0, reasons: []);

    // Try to detect header row
    final firstRow =
        rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final hasHeader = firstRow.any((h) =>
        h.contains('date') ||
        h.contains('volume') ||
        h.contains('arrow') ||
        h.contains('count'));

    final dataRows = hasHeader ? rows.skip(1) : rows;

    // Column aliases for flexible matching - supports various naming conventions
    const dateAliases = [
      'date',
      'day',
      'when',
      'training_date',
      'session_date',
      'shot_date',
    ];
    const volumeAliases = [
      'volume',
      'arrows',
      'arrow_count',
      'arrowcount',
      'count',
      'total',
      'arrow_volume',
      'arrows_shot',
      'num_arrows',
      'quantity',
    ];
    const titleAliases = [
      'title',
      'name',
      'event',
      'competition',
      'comp',
      'session',
      'event_name',
      'competition_name',
      'session_name',
      'description',
    ];
    const notesAliases = [
      'notes',
      'note',
      'comment',
      'comments',
      'remarks',
      'details',
      'info',
    ];

    // Find column index using aliases (exact match first, then contains)
    int findColumn(List<String> aliases) {
      // Exact match first
      for (final alias in aliases) {
        final idx = firstRow.indexOf(alias);
        if (idx >= 0) return idx;
      }
      // Contains match for longer aliases only
      for (final alias in aliases) {
        if (alias.length >= 4) {
          for (int i = 0; i < firstRow.length; i++) {
            if (firstRow[i].contains(alias)) return i;
          }
        }
      }
      return -1;
    }

    int dateCol = hasHeader ? findColumn(dateAliases) : -1;
    int volumeCol = hasHeader ? findColumn(volumeAliases) : -1;
    int titleCol = hasHeader ? findColumn(titleAliases) : -1;
    int notesCol = hasHeader ? findColumn(notesAliases) : -1;

    // Default column positions if no header found
    // Assumes: date, volume, title, notes order
    if (dateCol < 0) dateCol = 0;
    if (volumeCol < 0) volumeCol = 1;
    // Title and notes are optional, try positions 2 and 3
    if (titleCol < 0 && firstRow.length > 2) titleCol = 2;
    if (notesCol < 0 && firstRow.length > 3) notesCol = 3;

    final drafts = <VolumeDraft>[];
    int skippedCount = 0;
    final skippedReasons = <String>[];

    int rowNumber = hasHeader ? 2 : 1; // Start counting from 1, skip header
    for (final row in dataRows) {
      if (row.isEmpty) {
        rowNumber++;
        continue;
      }

      try {
        final dateStr = dateCol < row.length ? row[dateCol].toString() : '';
        final volumeStr =
            volumeCol < row.length ? row[volumeCol].toString() : '';
        final title = titleCol >= 0 && titleCol < row.length
            ? row[titleCol].toString().trim()
            : null;
        final notes = notesCol >= 0 && notesCol < row.length
            ? row[notesCol].toString().trim()
            : null;

        // Parse date
        final date = _parseDate(dateStr);
        if (date == null) {
          skippedCount++;
          if (skippedReasons.length < 5) {
            skippedReasons.add('Row $rowNumber: Invalid date "$dateStr"');
          }
          rowNumber++;
          continue;
        }

        // Parse volume - handle commas (e.g., "1,200" -> 1200)
        final volume =
            int.tryParse(volumeStr.replaceAll(RegExp(r'[^0-9]'), ''));
        if (volume == null || volume <= 0) {
          skippedCount++;
          if (skippedReasons.length < 5) {
            skippedReasons.add('Row $rowNumber: Invalid arrow count "$volumeStr"');
          }
          rowNumber++;
          continue;
        }

        drafts.add(VolumeDraft(
          date: date,
          arrowCount: volume,
          title: title?.isEmpty == true ? null : title,
          notes: notes?.isEmpty == true ? null : notes,
        ));
      } catch (e) {
        skippedCount++;
        if (skippedReasons.length < 5) {
          skippedReasons.add('Row $rowNumber: Parse error - $e');
        }
      }
      rowNumber++;
    }

    return (drafts: drafts, skipped: skippedCount, reasons: skippedReasons);
  }

  /// Parse date string in various common formats
  ///
  /// Supports:
  /// - YYYY-MM-DD (ISO)
  /// - DD/MM/YYYY (European)
  /// - DD-MM-YYYY
  /// - DD.MM.YYYY (German)
  DateTime? _parseDate(String dateStr) {
    // Try common formats
    final formats = [
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // YYYY-MM-DD or YYYY-M-D
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'), // DD/MM/YYYY or D/M/YYYY
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'), // DD-MM-YYYY or D-M-YYYY
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'), // DD.MM.YYYY
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          if (format.pattern.startsWith(r'(\d{4})')) {
            // YYYY-MM-DD format
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            );
          } else {
            // DD/MM/YYYY, DD-MM-YYYY, or DD.MM.YYYY format
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
            );
          }
        } catch (_) {}
      }
    }
    return null;
  }
}

/// Draft score data parsed from CSV
class ScoreDraft {
  final DateTime date;
  final int score;
  final String roundName;
  final String? location;
  final String? notes;
  final String? bowstyle;
  final String? eventType;
  final int? handicap;
  final int? hits;
  final int? golds;
  final int? xs;
  final String? classification;

  ScoreDraft({
    required this.date,
    required this.score,
    required this.roundName,
    this.location,
    this.notes,
    this.bowstyle,
    this.eventType,
    this.handicap,
    this.hits,
    this.golds,
    this.xs,
    this.classification,
  });
}

/// Draft volume data parsed from CSV
class VolumeDraft {
  final DateTime date;
  final int arrowCount;
  final String? title;
  final String? notes;

  VolumeDraft({
    required this.date,
    required this.arrowCount,
    this.title,
    this.notes,
  });
}
