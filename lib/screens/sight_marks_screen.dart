import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/sight_marks_provider.dart';
import '../models/sight_mark.dart';
import '../widgets/sight_mark_entry_form.dart';

/// Screen displaying all sight marks for a bow
class SightMarksScreen extends StatefulWidget {
  final String bowId;
  final String bowName;

  const SightMarksScreen({
    super.key,
    required this.bowId,
    required this.bowName,
  });

  @override
  State<SightMarksScreen> createState() => _SightMarksScreenState();
}

class _SightMarksScreenState extends State<SightMarksScreen> {
  DistanceUnit _selectedUnit = DistanceUnit.meters;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    setState(() => _isLoading = true);
    await context.read<SightMarksProvider>().loadMarksForBow(widget.bowId);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sight Marks'),
        actions: [
          // Unit toggle
          SegmentedButton<DistanceUnit>(
            segments: const [
              ButtonSegment(
                value: DistanceUnit.meters,
                label: Text('M'),
              ),
              ButtonSegment(
                value: DistanceUnit.yards,
                label: Text('YD'),
              ),
            ],
            selected: {_selectedUnit},
            onSelectionChanged: (selected) {
              setState(() => _selectedUnit = selected.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Consumer<SightMarksProvider>(
              builder: (context, provider, child) {
                final marks = provider
                    .getMarksForBow(widget.bowId)
                    .where((m) => m.unit == _selectedUnit)
                    .toList();

                if (marks.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Group by distance
                final groupedMarks = <double, List<SightMark>>{};
                for (final mark in marks) {
                  groupedMarks.putIfAbsent(mark.distance, () => []).add(mark);
                }

                final distances = groupedMarks.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: distances.length + 1, // +1 for the reminder at bottom
                  itemBuilder: (context, index) {
                    // Show reminder as last item
                    if (index == distances.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _buildWrittenRecordReminder(context),
                      );
                    }

                    final distance = distances[index];
                    final distanceMarks = groupedMarks[distance]!;
                    // Get the most recent mark for display
                    distanceMarks.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
                    final primaryMark = distanceMarks.first;

                    return _buildMarkTile(context, primaryMark, distanceMarks.length);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMarkDialog(context),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No sight marks recorded',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to add your first sight mark',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildWrittenRecordReminder(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWrittenRecordReminder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, color: AppColors.gold, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep a written record',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Always write sight marks in your kit bag notebook. This app is your backup - paper is your authority.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkTile(BuildContext context, SightMark mark, int historyCount) {
    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showMarkDetails(context, mark),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Distance
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  mark.distanceDisplay,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Sight value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mark.displayValue,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (historyCount > 1)
                      Text(
                        '$historyCount recordings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                  ],
                ),
              ),
              // Confidence indicator
              _buildConfidenceIndicator(context, mark.confidenceLevel),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context, SightMarkConfidence confidence) {
    Color color;
    IconData icon;

    switch (confidence) {
      case SightMarkConfidence.high:
        color = AppColors.gold;
        icon = Icons.verified;
        break;
      case SightMarkConfidence.medium:
        color = AppColors.textPrimary;
        icon = Icons.check_circle_outline;
        break;
      case SightMarkConfidence.low:
      case SightMarkConfidence.unknown:
        color = AppColors.textMuted;
        icon = Icons.help_outline;
        break;
    }

    return Icon(icon, size: 20, color: color);
  }

  void _showAddMarkDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
      ),
      builder: (context) => SightMarkEntryForm(
        bowId: widget.bowId,
        defaultUnit: _selectedUnit,
        onSaved: () {
          Navigator.pop(context);
          _loadMarks();
        },
      ),
    );
  }

  void _showMarkDetails(BuildContext context, SightMark mark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
      ),
      builder: (context) => _MarkDetailsSheet(
        mark: mark,
        bowId: widget.bowId,
        onUpdate: () {
          Navigator.pop(context);
          _loadMarks();
        },
      ),
    );
  }
}

class _MarkDetailsSheet extends StatelessWidget {
  final SightMark mark;
  final String bowId;
  final VoidCallback onUpdate;

  const _MarkDetailsSheet({
    required this.mark,
    required this.bowId,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                mark.distanceDisplay,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.gold,
                    ),
              ),
              const Spacer(),
              Text(
                mark.displayValue,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.surfaceBright),
          const SizedBox(height: AppSpacing.md),

          // Details
          _buildDetailRow(context, 'Recorded', _formatDate(mark.recordedAt)),
          if (mark.weather != null && mark.weather!.hasAnyData)
            _buildDetailRow(context, 'Weather', mark.weather!.summaryText),
          if (mark.slopeAngle != null)
            _buildDetailRow(context, 'Slope', '${mark.slopeAngle!.toStringAsFixed(0)}°'),
          if (mark.shotCount != null)
            _buildDetailRow(context, 'Shot Count', '${mark.shotCount} arrows'),

          const SizedBox(height: AppSpacing.lg),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editMark(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceBright),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteMark(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editMark(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
      ),
      builder: (ctx) => SightMarkEntryForm(
        bowId: bowId,
        existingMark: mark,
        onSaved: onUpdate,
      ),
    );
  }

  void _deleteMark(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Sight Mark?'),
        content: Text('Delete the ${mark.distanceDisplay} sight mark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SightMarksProvider>().deleteSightMark(mark.id, bowId);
              onUpdate();
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
