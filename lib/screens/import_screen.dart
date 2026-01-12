import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide Column;
import '../db/database.dart';
import '../theme/app_theme.dart';
import 'scores_graph_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  List<_ImportDraft> _drafts = [];
  bool _isLoading = false;
  String? _error;

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
      final drafts = _parseCSV(rows);

      setState(() {
        _drafts = drafts;
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
      final drafts = _parseCSV(rows);

      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to parse CSV: $e';
        _isLoading = false;
      });
    }
  }

  List<_ImportDraft> _parseCSV(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];

    // Try to detect header row
    final firstRow = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final hasHeader = firstRow.any((h) =>
        h.contains('date') || h.contains('score') || h.contains('round'));

    final dataRows = hasHeader ? rows.skip(1) : rows;

    // Column aliases for flexible matching
    const dateAliases = ['date', 'shot_date', 'event_date', 'competition_date', 'when', 'day'];
    const scoreAliases = ['score', 'total', 'total_score', 'points', 'result', 'final_score'];
    const roundAliases = ['round', 'round_name', 'round_type', 'format'];
    const locationAliases = ['location', 'venue', 'club', 'eventname', 'event_name', 'competition', 'place', 'site'];
    const handicapAliases = ['handicap', 'hc', 'handicap_score'];
    const hitsAliases = ['hits', 'arrows', 'arrows_shot'];
    const goldsAliases = ['golds', '10s', 'tens'];
    const xsAliases = ['xs', 'x_count', 'x'];

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

    // Default column positions if not found
    if (dateCol < 0) dateCol = 0;
    if (scoreCol < 0) scoreCol = 1;
    if (roundCol < 0) roundCol = 2;

    final drafts = <_ImportDraft>[];

    for (final row in dataRows) {
      if (row.isEmpty) continue;

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
        if (date == null) continue;

        // Parse score - handle commas (e.g., "1,296" -> 1296)
        final score = int.tryParse(scoreStr.replaceAll(RegExp(r'[^0-9]'), ''));
        if (score == null || score <= 0) continue;

        // Build notes from extra fields
        final notesParts = <String>[];
        if (handicapCol >= 0 && handicapCol < row.length) {
          final hc = row[handicapCol].toString().trim();
          if (hc.isNotEmpty && hc != '0') notesParts.add('HC: $hc');
        }
        if (hitsCol >= 0 && hitsCol < row.length) {
          final hits = row[hitsCol].toString().trim();
          if (hits.isNotEmpty && hits != '0') notesParts.add('Hits: $hits');
        }
        if (goldsCol >= 0 && goldsCol < row.length) {
          final golds = row[goldsCol].toString().trim();
          if (golds.isNotEmpty && golds != '0') notesParts.add('Golds: $golds');
        }
        if (xsCol >= 0 && xsCol < row.length) {
          final xs = row[xsCol].toString().trim();
          if (xs.isNotEmpty && xs != '0') notesParts.add('Xs: $xs');
        }

        drafts.add(_ImportDraft(
          date: date,
          score: score,
          roundName: roundName,
          location: location?.isEmpty == true ? null : location,
          notes: notesParts.isEmpty ? null : notesParts.join(', '),
        ));
      } catch (_) {
        // Skip invalid rows
      }
    }

    return drafts;
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

    setState(() => _isLoading = true);

    int imported = 0;
    int skipped = 0;

    for (final draft in _drafts) {
      // Check for duplicates
      final isDuplicate = await db.isDuplicateScore(draft.date, draft.score);
      if (isDuplicate) {
        skipped++;
        continue;
      }

      // Insert - use unique ID with timestamp and index to avoid collisions
      final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${draft.date.millisecondsSinceEpoch}_${draft.score}_$imported';
      await db.insertImportedScore(ImportedScoresCompanion.insert(
        id: uniqueId,
        date: draft.date,
        roundName: draft.roundName,
        score: draft.score,
        location: Value(draft.location),
        source: const Value('csv'),
      ));
      imported++;
    }

    setState(() {
      _drafts = [];
      _isLoading = false;
    });

    if (mounted && imported > 0) {
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
      body: _isLoading
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

  const _DraftReview({
    required this.drafts,
    required this.onImport,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final dateStr =
                  '${draft.date.day}/${draft.date.month}/${draft.date.year}';
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Text(
                        draft.score.toString(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(draft.roundName),
                            Text(
                              dateStr,
                              style: Theme.of(context).textTheme.bodySmall,
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

  _ImportDraft({
    required this.date,
    required this.score,
    required this.roundName,
    this.location,
    this.notes,
  });
}
