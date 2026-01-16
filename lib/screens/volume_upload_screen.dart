import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide Column;
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../utils/unique_id.dart';

class VolumeUploadScreen extends StatefulWidget {
  const VolumeUploadScreen({super.key});

  @override
  State<VolumeUploadScreen> createState() => _VolumeUploadScreenState();
}

class _VolumeUploadScreenState extends State<VolumeUploadScreen> {
  // Raw data state
  String? _rawData;
  String? _sourceName;
  List<List<dynamic>> _parsedRows = [];

  // Column mapping
  int _dateColumn = 0;
  int _arrowsColumn = 1;
  int? _notesColumn;
  bool _hasHeader = true;

  // UI state
  bool _isLoading = false;
  String? _error;

  // Import preview
  List<_VolumeImportRow> _previewRows = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Arrow Volume'),
        actions: [
          if (_parsedRows.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Start over',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _parsedRows.isEmpty
              ? _buildInputOptions()
              : _buildDataPreview(),
    );
  }

  Widget _buildInputOptions() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // Header text
          Text(
            'Import your training volume data',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upload a spreadsheet or paste data directly. Your original data will be preserved.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // CSV File Upload
          _InputOptionCard(
            icon: Icons.file_upload_outlined,
            title: 'Upload CSV File',
            description: 'Select a spreadsheet from your device',
            onTap: _pickFile,
          ),

          const SizedBox(height: AppSpacing.md),

          // Paste Data
          _InputOptionCard(
            icon: Icons.content_paste,
            title: 'Paste Spreadsheet Data',
            description: 'Copy from Excel, Google Sheets, or any spreadsheet',
            onTap: _showPasteDialog,
          ),

          const SizedBox(height: AppSpacing.lg),

          // View previous imports
          TextButton.icon(
            onPressed: _showPreviousImports,
            icon: const Icon(Icons.history, size: 18),
            label: const Text('View Previous Imports'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPreview() {
    return Column(
      children: [
        // Spreadsheet preview
        Expanded(
          child: _SpreadsheetPreview(
            rows: _parsedRows,
            hasHeader: _hasHeader,
            dateColumn: _dateColumn,
            arrowsColumn: _arrowsColumn,
            notesColumn: _notesColumn,
          ),
        ),

        // Column mapping and import controls
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border(
              top: BorderSide(color: AppColors.surfaceLight, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row toggle
              Row(
                children: [
                  Checkbox(
                    value: _hasHeader,
                    onChanged: (value) {
                      setState(() {
                        _hasHeader = value ?? true;
                        _updatePreview();
                      });
                    },
                    activeColor: AppColors.gold,
                  ),
                  const Text('First row is header'),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Column mapping
              Text(
                'Map Columns',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: _ColumnDropdown(
                      label: 'Date',
                      value: _dateColumn,
                      columnCount: _parsedRows.isNotEmpty
                          ? _parsedRows.first.length
                          : 0,
                      headers: _hasHeader && _parsedRows.isNotEmpty
                          ? _parsedRows.first
                          : null,
                      onChanged: (value) {
                        setState(() {
                          _dateColumn = value;
                          _updatePreview();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ColumnDropdown(
                      label: 'Arrow Count',
                      value: _arrowsColumn,
                      columnCount: _parsedRows.isNotEmpty
                          ? _parsedRows.first.length
                          : 0,
                      headers: _hasHeader && _parsedRows.isNotEmpty
                          ? _parsedRows.first
                          : null,
                      onChanged: (value) {
                        setState(() {
                          _arrowsColumn = value;
                          _updatePreview();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ColumnDropdown(
                      label: 'Notes (optional)',
                      value: _notesColumn ?? -1,
                      columnCount: _parsedRows.isNotEmpty
                          ? _parsedRows.first.length
                          : 0,
                      headers: _hasHeader && _parsedRows.isNotEmpty
                          ? _parsedRows.first
                          : null,
                      allowNone: true,
                      onChanged: (value) {
                        setState(() {
                          _notesColumn = value == -1 ? null : value;
                          _updatePreview();
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Preview stats
              _buildPreviewStats(),

              const SizedBox(height: AppSpacing.md),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _previewRows.isEmpty ? null : _importData,
                      child: Text('Import ${_previewRows.where((r) => r.isValid).length} Entries'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStats() {
    final validCount = _previewRows.where((r) => r.isValid).length;
    final invalidCount = _previewRows.where((r) => !r.isValid).length;
    final totalRows = _hasHeader ? _parsedRows.length - 1 : _parsedRows.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            label: 'Total Rows',
            value: '$totalRows',
            color: AppColors.textSecondary,
          ),
          _StatChip(
            label: 'Valid',
            value: '$validCount',
            color: AppColors.success,
          ),
          if (invalidCount > 0)
            _StatChip(
              label: 'Skipped',
              value: '$invalidCount',
              color: AppColors.error,
            ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _error = 'Could not read file';
          _isLoading = false;
        });
        return;
      }

      final content = utf8.decode(bytes);
      _processRawData(content, file.name);
    } catch (e) {
      setState(() {
        _error = 'Failed to read file: $e';
        _isLoading = false;
      });
    }
  }

  void _showPasteDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Paste Your Data'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Paste data from your spreadsheet here...\n\nExample:\nDate,Arrows,Notes\n2024-01-15,120,Morning session\n2024-01-16,90,Light day',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _processRawData(controller.text, 'Pasted Data');
              }
            },
            child: const Text('Parse'),
          ),
        ],
      ),
    );
  }

  void _processRawData(String data, String name) {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to parse as CSV
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter(eol: '\n').convert(data);
      } catch (_) {
        // Try with different line endings
        rows = const CsvToListConverter(eol: '\r\n').convert(data);
      }

      if (rows.isEmpty) {
        setState(() {
          _error = 'No data found';
          _isLoading = false;
        });
        return;
      }

      // Auto-detect column mapping
      _autoDetectColumns(rows);

      setState(() {
        _rawData = data;
        _sourceName = name;
        _parsedRows = rows;
        _isLoading = false;
      });

      _updatePreview();
    } catch (e) {
      setState(() {
        _error = 'Failed to parse data: $e';
        _isLoading = false;
      });
    }
  }

  void _autoDetectColumns(List<List<dynamic>> rows) {
    if (rows.isEmpty) return;

    final firstRow = rows.first.map((e) => e.toString().toLowerCase()).toList();

    // Check if first row looks like a header
    _hasHeader = firstRow.any((h) =>
        h.contains('date') ||
        h.contains('arrow') ||
        h.contains('count') ||
        h.contains('volume') ||
        h.contains('shot'));

    if (_hasHeader) {
      // Find columns by header names
      for (int i = 0; i < firstRow.length; i++) {
        final h = firstRow[i];
        if (h.contains('date') || h.contains('day')) {
          _dateColumn = i;
        } else if (h.contains('arrow') || h.contains('count') || h.contains('volume') || h.contains('shot') || h.contains('total')) {
          _arrowsColumn = i;
        } else if (h.contains('note') || h.contains('comment') || h.contains('description')) {
          _notesColumn = i;
        }
      }
    } else {
      // Default: first column is date, second is arrows
      _dateColumn = 0;
      _arrowsColumn = rows.first.length > 1 ? 1 : 0;
    }
  }

  void _updatePreview() {
    final dataRows = _hasHeader ? _parsedRows.skip(1) : _parsedRows;

    _previewRows = dataRows.map((row) {
      return _VolumeImportRow(
        rawRow: row,
        date: _parseDate(row, _dateColumn),
        arrowCount: _parseArrowCount(row, _arrowsColumn),
        notes: _notesColumn != null ? _parseNotes(row, _notesColumn!) : null,
      );
    }).toList();

    setState(() {});
  }

  DateTime? _parseDate(List<dynamic> row, int column) {
    if (column >= row.length) return null;

    final value = row[column].toString().trim();
    if (value.isEmpty) return null;

    // Try various date formats
    final formats = [
      // ISO format
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})'),
      // UK/EU format
      RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
      RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{2})$'),
      // US format
      RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
    ];

    for (final format in formats) {
      final match = format.firstMatch(value);
      if (match != null) {
        try {
          int year, month, day;

          if (format.pattern.startsWith(r'^(\d{4})')) {
            // ISO: YYYY-MM-DD
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else if (format.pattern.endsWith(r'(\d{2})$')) {
            // Short year: DD/MM/YY
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = 2000 + int.parse(match.group(3)!);
          } else {
            // DD/MM/YYYY - try to auto-detect
            final a = int.parse(match.group(1)!);
            final b = int.parse(match.group(2)!);
            final c = int.parse(match.group(3)!);

            if (a > 12) {
              // First number > 12, must be day
              day = a;
              month = b;
              year = c;
            } else if (b > 12) {
              // Second number > 12, must be day (US format)
              month = a;
              day = b;
              year = c;
            } else {
              // Assume DD/MM/YYYY (UK format)
              day = a;
              month = b;
              year = c;
            }
          }

          if (year < 100) year += 2000;
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  int? _parseArrowCount(List<dynamic> row, int column) {
    if (column >= row.length) return null;

    final value = row[column].toString().trim();
    if (value.isEmpty) return null;

    // Extract numeric value
    final numericStr = value.replaceAll(RegExp(r'[^0-9]'), '');
    final count = int.tryParse(numericStr);

    // Sanity check: arrow count should be reasonable (1-1000)
    if (count != null && count > 0 && count <= 1000) {
      return count;
    }

    return null;
  }

  String? _parseNotes(List<dynamic> row, int column) {
    if (column >= row.length) return null;
    final value = row[column].toString().trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _importData() async {
    if (_rawData == null || _previewRows.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final db = context.read<AppDatabase>();

      // Save raw import data
      final importId = UniqueId.generate();
      final columnMapping = jsonEncode({
        'date': _dateColumn,
        'arrows': _arrowsColumn,
        if (_notesColumn != null) 'notes': _notesColumn,
        'hasHeader': _hasHeader,
      });

      await db.insertVolumeImport(VolumeImportsCompanion.insert(
        id: importId,
        name: _sourceName ?? 'Import ${DateTime.now().toString().substring(0, 10)}',
        rawData: _rawData!,
        columnMapping: Value(columnMapping),
        rowCount: _previewRows.length,
      ));

      // Import valid rows to VolumeEntries
      int importedCount = 0;
      for (final row in _previewRows) {
        if (row.isValid) {
          await db.setVolumeForDate(
            row.date!,
            row.arrowCount!,
            notes: row.notes,
          );
          importedCount++;
        }
      }

      // Update import count
      await db.updateVolumeImportCount(importId, importedCount);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $importedCount volume entries'),
            backgroundColor: AppColors.surfaceDark,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful import
      }
    } catch (e) {
      setState(() {
        _error = 'Import failed: $e';
        _isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _rawData = null;
      _sourceName = null;
      _parsedRows = [];
      _previewRows = [];
      _dateColumn = 0;
      _arrowsColumn = 1;
      _notesColumn = null;
      _hasHeader = true;
      _error = null;
    });
  }

  void _showPreviousImports() async {
    final db = context.read<AppDatabase>();
    final imports = await db.getAllVolumeImports();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) => _PreviousImportsSheet(
        imports: imports,
        onSelect: (import_) {
          Navigator.pop(context);
          _viewImport(import_);
        },
        onDelete: (import_) async {
          await db.deleteVolumeImport(import_.id);
          Navigator.pop(context);
          _showPreviousImports(); // Refresh
        },
      ),
    );
  }

  void _viewImport(VolumeImport import_) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImportDetailScreen(import_: import_),
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _InputOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _InputOptionCard({
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(icon, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    Text(description, style: Theme.of(context).textTheme.bodySmall),
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

class _ColumnDropdown extends StatelessWidget {
  final String label;
  final int value;
  final int columnCount;
  final List<dynamic>? headers;
  final bool allowNone;
  final ValueChanged<int> onChanged;

  const _ColumnDropdown({
    required this.label,
    required this.value,
    required this.columnCount,
    required this.onChanged,
    this.headers,
    this.allowNone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppColors.surfaceLight,
            items: [
              if (allowNone)
                const DropdownMenuItem(
                  value: -1,
                  child: Text('None', style: TextStyle(color: AppColors.textMuted)),
                ),
              for (int i = 0; i < columnCount; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    headers != null && i < headers!.length
                        ? '${_columnLetter(i)}: ${headers![i]}'
                        : 'Column ${_columnLetter(i)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => onChanged(v ?? 0),
          ),
        ),
      ],
    );
  }

  String _columnLetter(int index) {
    return String.fromCharCode('A'.codeUnitAt(0) + index);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SPREADSHEET PREVIEW
// =============================================================================

class _SpreadsheetPreview extends StatelessWidget {
  final List<List<dynamic>> rows;
  final bool hasHeader;
  final int dateColumn;
  final int arrowsColumn;
  final int? notesColumn;

  const _SpreadsheetPreview({
    required this.rows,
    required this.hasHeader,
    required this.dateColumn,
    required this.arrowsColumn,
    this.notesColumn,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final columnCount = rows.fold<int>(
      0,
      (max, row) => row.length > max ? row.length : max,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceDark),
          dataRowColor: WidgetStateProperty.all(AppColors.backgroundDark),
          border: TableBorder.all(color: AppColors.surfaceLight, width: 1),
          columnSpacing: 16,
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 36,
          columns: [
            // Row number column
            const DataColumn(
              label: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            // Data columns
            for (int i = 0; i < columnCount; i++)
              DataColumn(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasHeader && rows.isNotEmpty && i < rows.first.length
                          ? rows.first[i].toString()
                          : String.fromCharCode('A'.codeUnitAt(0) + i),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (i == dateColumn)
                      _ColumnTag(label: 'Date', color: Colors.blue),
                    if (i == arrowsColumn)
                      _ColumnTag(label: 'Arrows', color: AppColors.gold),
                    if (i == notesColumn)
                      _ColumnTag(label: 'Notes', color: Colors.green),
                  ],
                ),
              ),
          ],
          rows: [
            for (int rowIndex = (hasHeader ? 1 : 0); rowIndex < rows.length; rowIndex++)
              DataRow(
                cells: [
                  // Row number
                  DataCell(Text(
                    '${rowIndex + 1}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  )),
                  // Data cells
                  for (int colIndex = 0; colIndex < columnCount; colIndex++)
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          colIndex < rows[rowIndex].length
                              ? rows[rowIndex][colIndex].toString()
                              : '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _getCellColor(colIndex),
                            fontWeight: colIndex == dateColumn || colIndex == arrowsColumn
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getCellColor(int column) {
    if (column == dateColumn) return Colors.blue.shade200;
    if (column == arrowsColumn) return AppColors.gold;
    if (column == notesColumn) return Colors.green.shade200;
    return AppColors.textPrimary;
  }
}

class _ColumnTag extends StatelessWidget {
  final String label;
  final Color color;

  const _ColumnTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =============================================================================
// PREVIOUS IMPORTS SHEET
// =============================================================================

class _PreviousImportsSheet extends StatelessWidget {
  final List<VolumeImport> imports;
  final ValueChanged<VolumeImport> onSelect;
  final ValueChanged<VolumeImport> onDelete;

  const _PreviousImportsSheet({
    required this.imports,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (imports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            'No previous imports',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Previous Imports',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.builder(
            itemCount: imports.length,
            itemBuilder: (context, index) {
              final import_ = imports[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: const Icon(Icons.table_chart, color: AppColors.gold, size: 20),
                ),
                title: Text(import_.name),
                subtitle: Text(
                  '${import_.rowCount} rows, ${import_.importedCount} imported\n${import_.createdAt.toString().substring(0, 10)}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => onDelete(import_),
                ),
                onTap: () => onSelect(import_),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// IMPORT DETAIL SCREEN (view raw data)
// =============================================================================

class _ImportDetailScreen extends StatelessWidget {
  final VolumeImport import_;

  const _ImportDetailScreen({required this.import_});

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> rows = [];
    try {
      rows = const CsvToListConverter().convert(import_.rawData);
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Text(import_.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surfaceDark,
            child: Row(
              children: [
                _StatChip(
                  label: 'Rows',
                  value: '${import_.rowCount}',
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.lg),
                _StatChip(
                  label: 'Imported',
                  value: '${import_.importedCount}',
                  color: AppColors.gold,
                ),
                const SizedBox(width: AppSpacing.lg),
                _StatChip(
                  label: 'Date',
                  value: import_.createdAt.toString().substring(0, 10),
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),

          // Spreadsheet view
          Expanded(
            child: rows.isEmpty
                ? const Center(child: Text('Could not parse data'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildTable(rows),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<List<dynamic>> rows) {
    final columnCount = rows.fold<int>(
      0,
      (max, row) => row.length > max ? row.length : max,
    );

    return DataTable(
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceDark),
      border: TableBorder.all(color: AppColors.surfaceLight, width: 1),
      columnSpacing: 16,
      columns: [
        const DataColumn(label: Text('#')),
        for (int i = 0; i < columnCount; i++)
          DataColumn(
            label: Text(
              String.fromCharCode('A'.codeUnitAt(0) + i),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
      rows: [
        for (int rowIndex = 0; rowIndex < rows.length; rowIndex++)
          DataRow(
            cells: [
              DataCell(Text('${rowIndex + 1}')),
              for (int colIndex = 0; colIndex < columnCount; colIndex++)
                DataCell(
                  Container(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      colIndex < rows[rowIndex].length
                          ? rows[rowIndex][colIndex].toString()
                          : '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// =============================================================================
// DATA CLASSES
// =============================================================================

class _VolumeImportRow {
  final List<dynamic> rawRow;
  final DateTime? date;
  final int? arrowCount;
  final String? notes;

  _VolumeImportRow({
    required this.rawRow,
    this.date,
    this.arrowCount,
    this.notes,
  });

  bool get isValid => date != null && arrowCount != null;
}
