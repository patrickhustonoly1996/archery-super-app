import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide Column;
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../services/firestore_sync_service.dart';
import '../services/import_service.dart';
import '../utils/error_handler.dart';
import '../utils/unique_id.dart';
import 'scores_graph_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _importService = ImportService();
  List<ScoreDraft> _drafts = [];
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
      final parseResult = _importService.parseScoresCsv(rows);

      // Check if all rows failed
      if (parseResult.drafts.isEmpty && parseResult.skipped > 0) {
        setState(() {
          _error = 'Could not parse any valid rows. ${parseResult.skipped} row${parseResult.skipped == 1 ? '' : 's'} failed.';
          _skippedRows = parseResult.skipped;
          _skippedReasons = parseResult.reasons;
          _isLoading = false;
        });
        return;
      }

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
      final result = _importService.parseScoresCsv(rows);

      // Check if all rows failed
      if (result.drafts.isEmpty && result.skipped > 0) {
        setState(() {
          _error = 'Could not parse any valid rows. ${result.skipped} row${result.skipped == 1 ? '' : 's'} failed.';
          _skippedRows = result.skipped;
          _skippedReasons = result.reasons;
          _isLoading = false;
        });
        return;
      }

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

    try {
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

          // Insert - use UUID to avoid collisions
          final uniqueId = UniqueId.generate();

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
    } catch (e) {
      debugPrint('ErrorHandler: Import failed: $e');
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.gold,
              onPressed: _importAll,
            ),
          ),
        );
      }
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
            id: UniqueId.generate(),
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

class _DraftReview extends StatefulWidget {
  final List<ScoreDraft> drafts;
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
  State<_DraftReview> createState() => _DraftReviewState();
}

class _DraftReviewState extends State<_DraftReview> {
  bool _showSkippedDetails = false;

  void _copySkippedToClipboard() {
    final text = widget.skippedReasons.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skipped rows copied to clipboard'),
        backgroundColor: AppColors.surfaceDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group by round type for summary
    final roundCounts = <String, int>{};
    for (final draft in widget.drafts) {
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
                '${widget.drafts.length} scores ready to import',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.gold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${roundCounts.length} round types found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (widget.drafts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Date range: ${_formatDate(widget.drafts.last.date)} - ${_formatDate(widget.drafts.first.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              // Show skipped rows warning
              if (widget.skippedRows > 0) ...[
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
                      InkWell(
                        onTap: () => setState(() => _showSkippedDetails = !_showSkippedDetails),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '${widget.skippedRows} row${widget.skippedRows == 1 ? '' : 's'} skipped',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Icon(
                              _showSkippedDetails ? Icons.expand_less : Icons.expand_more,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      if (_showSkippedDetails && widget.skippedReasons.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        ...widget.skippedReasons.map((reason) => Padding(
                              padding: const EdgeInsets.only(left: 20, top: 2),
                              child: Text(
                                reason,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                              ),
                            )),
                        if (widget.skippedReasons.length < widget.skippedRows)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 2),
                            child: Text(
                              '... and ${widget.skippedRows - widget.skippedReasons.length} more',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: _copySkippedToClipboard,
                          icon: Icon(Icons.copy, size: 14, color: Colors.orange),
                          label: Text(
                            'Copy skipped rows',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            itemCount: widget.drafts.length,
            itemBuilder: (context, index) {
              final draft = widget.drafts[index];
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
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.onImport,
                  child: Text('Import ${widget.drafts.length} Scores'),
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
  final Function(ScoreDraft) onSave;

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

            widget.onSave(ScoreDraft(
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

