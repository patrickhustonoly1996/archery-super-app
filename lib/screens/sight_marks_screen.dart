import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/sight_marks_provider.dart';
import '../providers/equipment_provider.dart';
import '../models/sight_mark.dart';
import '../utils/sight_mark_calculator.dart';
import '../widgets/sight_mark_entry_form.dart';
import 'bow_detail_screen.dart';

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
          : Consumer2<SightMarksProvider, EquipmentProvider>(
              builder: (context, sightProvider, equipProvider, child) {
                // Get ALL marks (not filtered by unit - they're the same data!)
                final allMarks = sightProvider.getMarksForBow(widget.bowId);

                // Check if bow has equipment specs for better predictions
                final bow = equipProvider.bows.where((b) => b.id == widget.bowId).firstOrNull;
                final hasPoundage = bow?.poundage != null;
                final hasDrawLength = bow?.drawLength != null;
                final needsSpecs = !hasPoundage || !hasDrawLength;

                if (allMarks.isEmpty) {
                  return _buildEmptyState(context, needsSpecs: needsSpecs);
                }

                // Group by distance in the selected unit
                // Convert distances to the selected unit for grouping
                final groupedMarks = <double, List<SightMark>>{};
                for (final mark in allMarks) {
                  // Convert distance to selected unit
                  double displayDistance;
                  if (mark.unit == _selectedUnit) {
                    displayDistance = mark.distance;
                  } else {
                    // Convert from mark's unit to selected unit
                    displayDistance = mark.unit.convert(mark.distance);
                  }
                  // Round to nearest whole number for grouping
                  final groupKey = displayDistance.roundToDouble();
                  groupedMarks.putIfAbsent(groupKey, () => []).add(mark);
                }

                final distances = groupedMarks.keys.toList()..sort();

                // Generate predictions for common distances not yet recorded
                final predictions = <PredictedSightMark>[];

                // Only show predictions if we have 2+ marks
                if (allMarks.length >= 2) {
                  for (final commonDist in _selectedUnit.commonDistances) {
                    if (!distances.contains(commonDist)) {
                      final prediction = SightMarkCalculator.predict(
                        marks: allMarks,
                        targetDistance: commonDist,
                        unit: _selectedUnit,
                        specs: bow != null
                            ? EquipmentSpecs(
                                poundage: bow.poundage,
                                drawLength: bow.drawLength,
                              )
                            : null,
                      );
                      if (prediction != null) {
                        predictions.add(prediction);
                      }
                    }
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Equipment specs prompt if needed
                    if (needsSpecs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildEquipmentSpecsPrompt(context),
                      ),

                    // Recorded marks header
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Recorded Marks',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ),

                    // All recorded marks
                    ...distances.map((distance) {
                      final distanceMarks = groupedMarks[distance]!;
                      distanceMarks.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
                      final primaryMark = distanceMarks.first;
                      return _buildMarkTile(
                        context,
                        primaryMark,
                        distanceMarks.length,
                        displayDistance: distance,
                        displayUnit: _selectedUnit,
                      );
                    }),

                    // Predictions section (if we have any)
                    if (predictions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(Icons.auto_fix_high, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Estimated Marks',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '(tap to record actual)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ...predictions.map((prediction) => _buildPredictionTile(context, prediction)),
                    ],

                    // Written record reminder
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: _buildWrittenRecordReminder(context),
                    ),
                  ],
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

  Widget _buildEmptyState(BuildContext context, {bool needsSpecs = false}) {
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
            if (needsSpecs) ...[
              _buildEquipmentSpecsPrompt(context),
              const SizedBox(height: AppSpacing.md),
            ],
            _buildWrittenRecordReminder(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSpecsPrompt(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToBowDetails(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.accentCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune, color: AppColors.accentCyan, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Improve predictions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.accentCyan,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add poundage and draw length to your bow for more accurate sight mark calculations.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.accentCyan),
          ],
        ),
      ),
    );
  }

  void _navigateToBowDetails(BuildContext context) {
    final equipmentProvider = context.read<EquipmentProvider>();
    final bow = equipmentProvider.bows.firstWhere(
      (b) => b.id == widget.bowId,
      orElse: () => throw StateError('Bow not found: ${widget.bowId}'),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BowDetailScreen(bow: bow),
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

  Widget _buildMarkTile(
    BuildContext context,
    SightMark mark,
    int historyCount, {
    required double displayDistance,
    required DistanceUnit displayUnit,
  }) {
    // Calculate equivalent in other unit
    final otherUnit = displayUnit.other;
    final convertedDistance = displayUnit.convert(displayDistance);

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
              // Distance with conversion (shown in selected unit)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      '${displayDistance.toStringAsFixed(0)}${displayUnit.abbreviation}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Show converted equivalent
                  Text(
                    '≈ ${convertedDistance.toStringAsFixed(0)}${otherUnit.abbreviation}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                  ),
                ],
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

  Widget _buildPredictionTile(BuildContext context, PredictedSightMark prediction) {
    // Calculate equivalent in other unit
    final otherUnit = prediction.unit.other;
    final convertedDistance = prediction.unit.convert(prediction.distance);

    return Card(
      color: AppColors.surfaceDark.withValues(alpha: 0.5),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showAddMarkDialog(
          context,
          defaultDistance: prediction.distance,
          defaultUnit: prediction.unit,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Distance with conversion
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      border: Border.all(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Text(
                      prediction.distanceDisplay,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Show converted equivalent
                  Text(
                    '≈ ${convertedDistance.toStringAsFixed(0)}${otherUnit.abbreviation}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              // Predicted sight value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '~${prediction.displayValue}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    Text(
                      prediction.source,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
              // Confidence indicator
              _buildConfidenceIndicator(context, prediction.confidence),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.add_circle_outline, color: AppColors.textMuted, size: 20),
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

  void _showAddMarkDialog(
    BuildContext context, {
    double? defaultDistance,
    DistanceUnit? defaultUnit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
      ),
      builder: (context) => SightMarkEntryForm(
        bowId: widget.bowId,
        defaultUnit: defaultUnit ?? _selectedUnit,
        defaultDistance: defaultDistance,
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
