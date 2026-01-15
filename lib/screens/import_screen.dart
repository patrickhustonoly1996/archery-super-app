import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide Column;
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../services/firestore_sync_service.dart';
import 'scores_graph_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  List<_ImportDraft> _drafts = [];
  bool _isLoading = false;
  bool _isImporting = false;
  int _importProgress = 0;
  int _importTotal = 0;
  String? _error;
  int _skippedRows = 0;
  List<String> _skippedReasons = [];

  /// Trigger cloud backup in background (non-blocking)
  void _triggerCloudBackup(AppDatabase db) {
    Future.microtask(() async {
      try {
        final syncService = FirestoreSyncService();
        if (syncService.isAuthenticated) {
          await syncService.backupAllData(db);
          debugPrint('Cloud backup completed after import');
        }
      } catch (e) {
        debugPrint('Cloud backup error (non-fatal): $e');
      }
    });
  }

  Future<void> _pickAndParseCSV() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Required to get bytes on all platforms
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Web uses bytes, mobile can use bytes too - works on all platforms
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        setState(() {
          _error = 'Could not read file';
          _isLoading = false;
        });
        return;
      }
      final content = utf8.decode(bytes);
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) {
        setState(() {
          _error = 'Empty CSV file';
          _isLoading = false;
        });
        return;
      }

      // Parse CSV
      final parseResult = _parseCSV(rows);

      setState(() {
        _drafts = parseResult.drafts;
        _skippedRows = parseResult.skipped;
        _skippedReasons = parseResult.reasons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to parse CSV: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _parseCSVText(String csvText) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = const CsvToListConverter().convert(csvText);

      if (rows.isEmpty) {
        setState(() {
          _error = 'Empty CSV text';
          _isLoading = false;
        });
        return;
      }

      // Parse CSV
      final result = _parseCSV(rows);

      setState(() {
        _drafts = result.drafts;
        _skippedRows = result.skipped;
        _skippedReasons = result.reasons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to parse CSV: $e';
        _isLoading = false;
      });
    }
  }

  ({List<_ImportDraft> drafts, int skipped, List<String> reasons}) _parseCSV(List<List<dynamic>> rows) {
    if (rows.isEmpty) return (drafts: [], skipped: 0, reasons: []);

    // Try to detect header row
    final firstRow = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final hasHeader = firstRow.any((h) =>
        h.contains('date') || h.contains('score') || h.contains('round'));

    final dataRows = hasHeader ? rows.skip(1) : rows;

    // Column aliases for flexible matching - supports Archr export format
    const dateAliases = ['date', 'shot_date', 'event_date', 'competition_date', 'when', 'day'];
    const scoreAliases = ['score', 'total', 'total_score', 'points', 'result', 'final_score'];
    const roundAliases = ['round', 'round_name', 'round_type', 'format'];
    const locationAliases = ['eventname', 'event_name', 'location', 'venue', 'club', 'competition', 'place', 'site'];
    const handicapAliases = ['handicap', 'hc', 'handicap_score', 'handicapatscore'];
    const hitsAliases = ['hits', 'arrows', 'arrows_shot'];
    const goldsAliases = ['golds', '10s', 'tens'];
    const xsAliases = ['xs', 'x_count', 'x'];
    const bowstyleAliases = ['bowstyle', 'bow_style', 'bow', 'equipment'];
    const eventTypeAliases = ['eventtype', 'event_type', 'type', 'session_type'];
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

    final drafts = <_ImportDraft>[];
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
        final location =
            locationCol >= 0 && locationCol < row.length
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
        final score = int.tryParse(scoreStr.replaceAll(RegExp(r'[^0-9]'), ''));
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
            ? int.tryParse(row[handicapCol].toString().replaceAll(RegExp(r'[^0-9]'), ''))
            : null;
        final hits = hitsCol >= 0 && hitsCol < row.length
            ? int.tryParse(row[hitsCol].toString().replaceAll(RegExp(r'[^0-9]'), ''))
            : null;
        final golds = goldsCol >= 0 && goldsCol < row.length
            ? int.tryParse(row[goldsCol].toString().replaceAll(RegExp(r'[^0-9]'), ''))
            : null;
        final xs = xsCol >= 0 && xsCol < row.length
            ? int.tryParse(row[xsCol].toString().replaceAll(RegExp(r'[^0-9]'), ''))
            : null;
        final bowstyle = bowstyleCol >= 0 && bowstyleCol < row.length
            ? row[bowstyleCol].toString().trim()
            : null;
        final eventType = eventTypeCol >= 0 && eventTypeCol < row.length
            ? row[eventTypeCol].toString().trim()
            : null;
        final classification = classificationCol >= 0 && classificationCol < row.length
            ? row[classificationCol].toString().trim()
            : null;

        // Build notes from extra fields for display
        final notesParts = <String>[];
        if (handicap != null && handicap > 0) notesParts.add('HC: $handicap');
        if (hits != null && hits > 0) notesParts.add('Hits: $hits');
        if (golds != null && golds > 0) notesParts.add('Golds: $golds');
        if (xs != null && xs > 0) notesParts.add('Xs: $xs');
        if (classification != null && classification.isNotEmpty) notesParts.add(classification);

        drafts.add(_ImportDraft(
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

  DateTime? _parseDate(String dateStr) {
    // Try common formats
    final formats = [
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'), // YYYY-MM-DD
      RegExp(r'(\d{2})/(\d{2})/(\d{4})'), // DD/MM/YYYY
      RegExp(r'(\d{2})-(\d{2})-(\d{4})'), // DD-MM-YYYY
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          if (format.pattern.startsWith(r'(\d{4})')) {
            // YYYY-MM-DD
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            );
          } else {
            // DD/MM/YYYY or DD-MM-YYYY
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

  Future<void> _importAll() async {
    final db = context.read<AppDatabase>();

    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = _drafts.length;
    });

    int imported = 0;
    int skipped = 0;
    int processed = 0;

    // Process in batches for large imports
    const batchSize = 50;
    for (int i = 0; i < _drafts.length; i += batchSize) {
      final batch = _drafts.skip(i).take(batchSize);

      for (final draft in batch) {
        processed++;

        // Check for duplicates - match on date, score, AND round name for accuracy
        final isDuplicate = await db.isDuplicateScoreWithRound(
          draft.date,
          draft.score,
          draft.roundName,
        );
        if (isDuplicate) {
          skipped++;
          continue;
        }

        // Build comprehensive notes
        final notesParts = <String>[];
        if (draft.handicap != null && draft.handicap! > 0) {
          notesParts.add('HC: ${draft.handicap}');
        }
        if (draft.hits != null && draft.hits! > 0) {
          notesParts.add('Hits: ${draft.hits}');
        }
        if (draft.golds != null && draft.golds! > 0) {
          notesParts.add('Golds: ${draft.golds}');
        }
        if (draft.classification != null && draft.classification!.isNotEmpty) {
          notesParts.add(draft.classification!);
        }

        // Insert - use unique ID with timestamp and index to avoid collisions
        final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${draft.date.millisecondsSinceEpoch}_${draft.score}_$imported';

        // Determine session type from event type
        String sessionType = 'competition';
        if (draft.eventType != null) {
          final eventLower = draft.eventType!.toLowerCase();
          if (eventLower.contains('practice')) {
            sessionType = 'practice';
          } else if (eventLower.contains('non record') || eventLower.contains('non-record')) {
            sessionType = 'competition';
          }
        }

        await db.insertImportedScore(ImportedScoresCompanion.insert(
          id: uniqueId,
          date: draft.date,
          roundName: draft.roundName,
          score: draft.score,
          xCount: Value(draft.xs),
          location: Value(draft.location),
          notes: Value(notesParts.isEmpty ? null : notesParts.join(', ')),
          sessionType: Value(sessionType),
          source: const Value('csv'),
        ));
        imported++;
      }

      // Update progress and yield to UI every batch
      setState(() => _importProgress = processed);
      await Future.delayed(Duration.zero);
    }

    setState(() {
      _drafts = [];
      _isImporting = false;
    });

    if (mounted && imported > 0) {
      // Trigger cloud backup in background
      _triggerCloudBackup(db);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $imported scores${skipped > 0 ? ', skipped $skipped duplicates' : ''}'),
          backgroundColor: AppColors.surfaceDark,
        ),
      );

      // Navigate to scores graph to show the imported data
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ScoresGraphScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No new scores imported (skipped $skipped duplicates)'),
          backgroundColor: AppColors.surfaceDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Scores'),
      ),
      body: _isImporting
          ? _ImportProgressView(
              progress: _importProgress,
              total: _importTotal,
            )
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                )
              : _drafts.isEmpty
                  ? _ImportOptions(
                      onPickCSV: _pickAndParseCSV,
                      onPasteCSV: _showPasteCSVDialog,
                      onManualEntry: _showManualEntryDialog,
                      error: _error,
                    )
                  : _DraftReview(
                      drafts: _drafts,
                      onImport: _importAll,
                      onCancel: () => setState(() => _drafts = []),
                      skippedRows: _skippedRows,
                      skippedReasons: _skippedReasons,
                    ),
    );
  }

  void _showPasteCSVDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste CSV Text'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 15,
            decoration: const InputDecoration(
              hintText: 'Paste your CSV data here...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _parseCSVText(controller.text);
            },
            child: const Text('Parse'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => _ManualEntryDialog(
        onSave: (draft) async {
          final db = context.read<AppDatabase>();

          await db.insertImportedScore(ImportedScoresCompanion.insert(
            id: '${draft.date.millisecondsSinceEpoch}_${draft.score}',
            date: draft.date,
            roundName: draft.roundName,
            score: draft.score,
            location: Value(draft.location),
            source: const Value('manual'),
          ));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Score added'),
                backgroundColor: AppColors.surfaceDark,
              ),
            );
          }
        },
      ),
    );
  }
}

class _ImportProgressView extends StatelessWidget {
  final int progress;
  final int total;

  const _ImportProgressView({
    required this.progress,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? progress / total : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceLight,
                    color: AppColors.gold,
                  ),
                  Center(
                    child: Text(
                      '${(percent * 100).toInt()}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Importing scores...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$progress / $total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportOptions extends StatelessWidget {
  final VoidCallback onPickCSV;
  final VoidCallback onPasteCSV;
  final VoidCallback onManualEntry;
  final String? error;

  const _ImportOptions({
    required this.onPickCSV,
    required this.onPasteCSV,
    required this.onManualEntry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Text(
                error!,
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),

          // CSV Import
          _ImportOptionCard(
            icon: Icons.file_upload_outlined,
            title: 'Import from CSV File',
            description: 'Upload a spreadsheet of your scores',
            onTap: onPickCSV,
          ),

          const SizedBox(height: AppSpacing.md),

          // Paste CSV
          _ImportOptionCard(
            icon: Icons.content_paste,
            title: 'Paste CSV Text',
            description: 'Copy and paste CSV data directly',
            onTap: onPasteCSV,
          ),

          const SizedBox(height: AppSpacing.md),

          // Manual Entry
          _ImportOptionCard(
            icon: Icons.edit_outlined,
            title: 'Manual Entry',
            description: 'Type in a score by hand',
            onTap: onManualEntry,
          ),
        ],
      ),
    );
  }
}

class _ImportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ImportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    Text(description,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftReview extends StatelessWidget {
  final List<_ImportDraft> drafts;
  final VoidCallback onImport;
  final VoidCallback onCancel;
  final int skippedRows;
  final List<String> skippedReasons;

  const _DraftReview({
    required this.drafts,
    required this.onImport,
    required this.onCancel,
    this.skippedRows = 0,
    this.skippedReasons = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Group by round type for summary
    final roundCounts = <String, int>{};
    for (final draft in drafts) {
      roundCounts[draft.roundName] = (roundCounts[draft.roundName] ?? 0) + 1;
    }

    return Column(
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.surfaceDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${drafts.length} scores ready to import',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.gold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${roundCounts.length} round types found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (drafts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Date range: ${_formatDate(drafts.last.date)} - ${_formatDate(drafts.first.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              // Show skipped rows warning
              if (skippedRows > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '$skippedRows row${skippedRows == 1 ? '' : 's'} skipped',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      if (skippedReasons.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        ...skippedReasons.take(3).map((reason) => Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text(
                                reason,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                              ),
                            )),
                        if (skippedReasons.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(
                              '... and ${skippedReasons.length - 3} more',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Score list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Score with gold styling
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Text(
                          draft.score.toString(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draft.roundName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _formatDate(draft.date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (draft.location != null && draft.location!.isNotEmpty) ...[
                                  Text(
                                    ' - ',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Flexible(
                                    child: Text(
                                      draft.location!,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (draft.notes != null && draft.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  draft.notes!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.surfaceDark,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onImport,
                  child: Text('Import ${drafts.length} Scores'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ManualEntryDialog extends StatefulWidget {
  final Function(_ImportDraft) onSave;

  const _ManualEntryDialog({required this.onSave});

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final _scoreController = TextEditingController();
  final _roundController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text('Add Score'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _scoreController,
              decoration: const InputDecoration(labelText: 'Score'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _roundController,
              decoration: const InputDecoration(labelText: 'Round Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final score = int.tryParse(_scoreController.text);
            if (score == null || _roundController.text.isEmpty) return;

            widget.onSave(_ImportDraft(
              date: _date,
              score: score,
              roundName: _roundController.text,
              location: _locationController.text.isEmpty
                  ? null
                  : _locationController.text,
            ));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ImportDraft {
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

  _ImportDraft({
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
