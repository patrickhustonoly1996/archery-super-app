import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide Column;
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../services/import_service.dart';

class VolumeImportScreen extends StatefulWidget {
  const VolumeImportScreen({super.key});

  @override
  State<VolumeImportScreen> createState() => _VolumeImportScreenState();
}

class _VolumeImportScreenState extends State<VolumeImportScreen> {
  final _importService = ImportService();
  List<VolumeDraft> _drafts = [];
  bool _isLoading = false;
  bool _isImporting = false;
  int _importProgress = 0;
  int _importTotal = 0;
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
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

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

      final drafts = _importService.parseVolumeCsv(rows);

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

      final drafts = _importService.parseVolumeCsv(rows);

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


  Future<void> _importAll() async {
    final db = context.read<AppDatabase>();

    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = _drafts.length;
    });

    int imported = 0;
    int updated = 0;
    int processed = 0;

    // Process in batches for large imports
    const batchSize = 50;
    for (int i = 0; i < _drafts.length; i += batchSize) {
      final batch = _drafts.skip(i).take(batchSize);

      for (final draft in batch) {
        processed++;

        // Check if entry exists for this date
        final existing = await db.getVolumeEntryForDate(draft.date);

        if (existing != null) {
          // Update existing entry (add to existing count or replace)
          await db.setVolumeForDate(
            draft.date,
            draft.arrowCount,
            title: draft.title ?? existing.title,
            notes: draft.notes ?? existing.notes,
          );
          updated++;
        } else {
          // Insert new entry
          await db.setVolumeForDate(
            draft.date,
            draft.arrowCount,
            title: draft.title,
            notes: draft.notes,
          );
          imported++;
        }
      }

      // Update progress and yield to UI every batch
      setState(() => _importProgress = processed);
      await Future.delayed(Duration.zero);
    }

    setState(() {
      _drafts = [];
      _isImporting = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported > 0 && updated > 0
                ? 'Imported $imported new entries, updated $updated existing'
                : imported > 0
                    ? 'Imported $imported volume entries'
                    : 'Updated $updated existing entries',
          ),
          backgroundColor: AppColors.surfaceDark,
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate data changed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Volume'),
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
                    ),
    );
  }

  void _showPasteCSVDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Paste CSV Text'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expected columns: date, arrows, title (optional), notes (optional)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: '2024-01-15, 120, Practice\n2024-01-16, 90, Competition, World Cup',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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

          await db.setVolumeForDate(
            draft.date,
            draft.arrowCount,
            title: draft.title,
            notes: draft.notes,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Volume entry added'),
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
              'Importing volume data...',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // Help text
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supported CSV Formats',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Columns can be in any order. The importer recognizes:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '  Date: date, day, when, training_date...\n'
                  '  Volume: arrows, volume, count, total...\n'
                  '  Title: title, event, competition, session...\n'
                  '  Notes: notes, comment, remarks...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Date formats: YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // CSV File
          _ImportOptionCard(
            icon: Icons.file_upload_outlined,
            title: 'Import from CSV File',
            description: 'Upload a spreadsheet of your training volume',
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
            description: 'Add a single volume entry',
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
  final List<VolumeDraft> drafts;
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${draft.arrowCount}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
                          Text(
                            'arrows',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (draft.title != null && draft.title!.isNotEmpty)
                              Text(
                                draft.title!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            if (draft.notes != null && draft.notes!.isNotEmpty)
                              Text(
                                draft.notes!,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                  child: Text('Import ${drafts.length} Entries'),
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
  final Function(VolumeDraft) onSave;

  const _ManualEntryDialog({required this.onSave});

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final _arrowCountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text('Add Volume Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _arrowCountController,
              decoration: const InputDecoration(labelText: 'Arrow Count'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'e.g., World Cup, Practice',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional details',
              ),
              maxLines: 2,
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
            final arrowCount = int.tryParse(_arrowCountController.text);
            if (arrowCount == null || arrowCount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid arrow count')),
              );
              return;
            }

            widget.onSave(VolumeDraft(
              date: _date,
              arrowCount: arrowCount,
              title: _titleController.text.isEmpty ? null : _titleController.text,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
            ));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

