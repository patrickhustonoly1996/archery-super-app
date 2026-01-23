import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../models/bow_specifications.dart';
import '../models/tuning_session.dart';
import '../widgets/bow_icon.dart';
import '../widgets/measurement_guide_button.dart';
import '../utils/undo_manager.dart';
import '../providers/sight_marks_provider.dart';
import '../models/sight_mark.dart';
import 'bow_form_screen.dart';
import 'sight_marks_screen.dart';
import 'bow_specs_screen.dart';
import 'stabilizer_form_screen.dart';
import 'string_form_screen.dart';

/// Detailed view of a bow with all specifications
class BowDetailScreen extends StatefulWidget {
  final Bow bow;

  const BowDetailScreen({super.key, required this.bow});

  @override
  State<BowDetailScreen> createState() => _BowDetailScreenState();
}

class _BowDetailScreenState extends State<BowDetailScreen> {
  late Bow _bow;

  @override
  void initState() {
    super.initState();
    _bow = widget.bow;
  }

  void _refreshBow() async {
    final provider = context.read<EquipmentProvider>();
    await provider.loadEquipment();
    final updatedBow = provider.bows.firstWhere(
      (b) => b.id == _bow.id,
      orElse: () => _bow,
    );
    if (mounted) {
      setState(() => _bow = updatedBow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final specs = BowSpecifications.fromBow(_bow);

    return Scaffold(
      appBar: AppBar(
        title: Text(_bow.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BowFormScreen(bow: _bow),
                ),
              );
              _refreshBow();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'default') {
                await context.read<EquipmentProvider>().setDefaultBow(_bow.id);
                _refreshBow();
              } else if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              if (!_bow.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Set as default'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error),
                    SizedBox(width: AppSpacing.sm),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with bow icon and type
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),

            // Primary Settings Section
            _buildSection(
              context,
              title: 'PRIMARY SETTINGS',
              isPrimary: true,
              children: [
                _buildSpecRow(
                  context,
                  label: 'Brace Height',
                  value: specs.braceHeight != null
                      ? '${specs.braceHeight!.toStringAsFixed(1)} mm'
                      : null,
                  isPrimary: true,
                  tuningType: TuningType.braceHeight,
                ),
                _buildSpecRow(
                  context,
                  label: 'Nocking Point',
                  value: specs.nockingPoint != null
                      ? '${specs.nockingPoint! >= 0 ? '+' : ''}${specs.nockingPoint!.toStringAsFixed(1)} mm'
                      : null,
                  subtitle: 'Above square',
                  isPrimary: true,
                  tuningType: TuningType.nockPoint,
                ),
                _buildSpecRow(
                  context,
                  label: 'Tiller (Top)',
                  value: specs.tillerTop != null
                      ? '${specs.tillerTop!.toStringAsFixed(1)} mm'
                      : null,
                  isPrimary: true,
                  tuningType: TuningType.tiller,
                ),
                _buildSpecRow(
                  context,
                  label: 'Tiller (Bottom)',
                  value: specs.tillerBottom != null
                      ? '${specs.tillerBottom!.toStringAsFixed(1)} mm'
                      : null,
                  isPrimary: true,
                ),
                if (specs.tillerDifference != null)
                  _buildSpecRow(
                    context,
                    label: 'Tiller Difference',
                    value:
                        '${specs.tillerDifference! >= 0 ? '+' : ''}${specs.tillerDifference!.toStringAsFixed(1)} mm',
                    subtitle: 'Top - Bottom',
                    isCalculated: true,
                  ),
              ],
              onEdit: () => _editSpecs(context, 'primary'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Equipment Section
            _buildSection(
              context,
              title: 'EQUIPMENT',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Riser',
                  value: specs.riserModel,
                  subtitle: specs.riserLength != null ? '${specs.riserLength}"' : null,
                ),
                _buildSpecRow(
                  context,
                  label: 'Limbs',
                  value: specs.limbModel,
                  subtitle: _buildLimbSubtitle(specs),
                ),
                if (specs.totalBowLength != null)
                  _buildSpecRow(
                    context,
                    label: 'Total Bow Length',
                    value: specs.totalBowLength,
                    isCalculated: true,
                  ),
                _buildSpecRow(
                  context,
                  label: 'String',
                  value: specs.stringMaterial,
                  subtitle: specs.stringStrands != null
                      ? '${specs.stringStrands} strands'
                      : null,
                ),
              ],
              onEdit: () => _editSpecs(context, 'equipment'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Button & Centre Shot Section
            _buildSection(
              context,
              title: 'BUTTON / CENTRE SHOT',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Button Model',
                  value: specs.buttonModel,
                ),
                _buildSpecRow(
                  context,
                  label: 'Spring Tension',
                  value: specs.buttonSpringTension,
                  tuningType: TuningType.plungerTension,
                ),
                _buildSpecRow(
                  context,
                  label: 'Centre Shot',
                  value: CentreShotOptions.displayName(specs.centreShot),
                  tuningType: TuningType.centershot,
                ),
              ],
              onEdit: () => _editSpecs(context, 'button'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Accessories Section
            _buildSection(
              context,
              title: 'ACCESSORIES',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Clicker',
                  value: specs.clickerModel,
                  subtitle: specs.clickerPosition != null
                      ? '${specs.clickerPosition!.toStringAsFixed(0)} mm from button'
                      : null,
                ),
                _buildSpecRow(
                  context,
                  label: 'Sight',
                  value: specs.sightModel,
                  subtitle: specs.sightExtensionLength != null
                      ? '${specs.sightExtensionLength}" extension'
                      : null,
                ),
              ],
              onEdit: () => _editSpecs(context, 'accessories'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Stabilizers Section
            _buildStabilizersSection(context),

            const SizedBox(height: AppSpacing.lg),

            // Strings Section
            _buildStringsSection(context),

            const SizedBox(height: AppSpacing.lg),

            // Sight Marks Section
            _buildSightMarksSection(context),

            const SizedBox(height: AppSpacing.lg),

            // Arrow Setup Section
            _buildSection(
              context,
              title: 'ARROW SETUP',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Arrow Model',
                  value: specs.arrowModel,
                ),
                _buildSpecRow(
                  context,
                  label: 'Spine',
                  value: specs.arrowSpine,
                ),
                _buildSpecRow(
                  context,
                  label: 'Arrow Length',
                  value: specs.arrowLength != null
                      ? '${specs.arrowLength!.toStringAsFixed(2)}"'
                      : null,
                ),
              ],
              onEdit: () => _editSpecs(context, 'arrows'),
            ),

            if (specs.notes != null && specs.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildSection(
                context,
                title: 'NOTES',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text(
                      specs.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                onEdit: () => _editSpecs(context, 'notes'),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editSpecs(context, 'all'),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Specs'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: BowIcon(
            size: 48,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _bow.bowType.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (_bow.isDefault) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DEFAULT',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _bow.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    VoidCallback? onEdit,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPrimary ? AppColors.gold.withValues(alpha: 0.3) : AppColors.surfaceBright,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.gold.withValues(alpha: 0.1)
                  : AppColors.surfaceBright.withValues(alpha: 0.5),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.sm - 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isPrimary ? AppColors.gold : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
                if (onEdit != null)
                  InkWell(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(
    BuildContext context, {
    required String label,
    String? value,
    String? subtitle,
    bool isPrimary = false,
    bool isCalculated = false,
    String? tuningType,
  }) {
    final hasValue = value != null && value != 'Not set';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                        ),
                    ],
                  ),
                ),
                if (tuningType != null)
                  MeasurementGuideButton(
                    tuningType: tuningType,
                    bowType: _bow.bowType,
                    size: 14,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              hasValue ? value! : '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasValue
                        ? (isPrimary ? AppColors.gold : AppColors.textPrimary)
                        : AppColors.textMuted,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                    fontStyle: isCalculated ? FontStyle.italic : FontStyle.normal,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String? _buildLimbSubtitle(BowSpecifications specs) {
    final parts = <String>[];
    if (specs.limbLength != null) {
      parts.add(LimbLengthOptions.displayName(specs.limbLength));
    }
    if (specs.markedLimbWeight != null) {
      parts.add('${specs.markedLimbWeight!.toStringAsFixed(0)}#');
    }
    return parts.isEmpty ? null : parts.join(' • ');
  }

  void _editSpecs(BuildContext context, String section) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BowSpecsScreen(bow: _bow, initialSection: section),
      ),
    );
    _refreshBow();
  }

  Widget _buildStabilizersSection(BuildContext context) {
    return FutureBuilder<List<Stabilizer>>(
      future: context.read<EquipmentProvider>().getStabilizersForBow(_bow.id),
      builder: (context, snapshot) {
        final stabilizers = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceBright),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.sm - 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STABILIZERS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StabilizerFormScreen(bowId: _bow.id),
                          ),
                        );
                        setState(() {});
                      },
                      child: const Icon(Icons.add, size: 20, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              if (stabilizers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'No stabilizer setups recorded',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                )
              else
                ...stabilizers.map((s) => _buildStabilizerTile(context, s)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStabilizerTile(BuildContext context, Stabilizer s) {
    final parts = <String>[];
    if (s.longRodLength != null) parts.add('Long: ${s.longRodLength!.toStringAsFixed(0)}"');
    if (s.sideRodLength != null) parts.add('Sides: ${s.sideRodLength!.toStringAsFixed(0)}"');
    if (s.vbarAngleHorizontal != null) parts.add('V-bar: ${s.vbarAngleHorizontal!.toStringAsFixed(0)}°');

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StabilizerFormScreen(bowId: _bow.id, stabilizer: s),
          ),
        );
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.straighten, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name ?? s.longRodModel ?? 'Stabilizer Setup',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (parts.isNotEmpty)
                    Text(
                      parts.join(' | '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildStringsSection(BuildContext context) {
    return FutureBuilder<List<BowString>>(
      future: context.read<EquipmentProvider>().getStringsForBow(_bow.id),
      builder: (context, snapshot) {
        final strings = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceBright),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.sm - 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STRINGS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StringFormScreen(bowId: _bow.id),
                          ),
                        );
                        setState(() {});
                      },
                      child: const Icon(Icons.add, size: 20, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              if (strings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'No strings recorded',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                )
              else
                ...strings.map((s) => _buildStringTile(context, s)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStringTile(BuildContext context, BowString s) {
    final parts = <String>[];
    if (s.material != null) parts.add(s.material!);
    if (s.strandCount != null) parts.add('${s.strandCount} strands');
    if (s.stringLength != null) parts.add('${s.stringLength!.toStringAsFixed(0)}"');

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StringFormScreen(bowId: _bow.id, bowString: s),
          ),
        );
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              s.isActive ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: s.isActive ? AppColors.gold : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.name ?? s.material ?? 'String',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (s.isActive) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.gold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (parts.isNotEmpty)
                    Text(
                      parts.join(' | '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSightMarksSection(BuildContext context) {
    // Load sight marks when section is built
    context.read<SightMarksProvider>().loadMarksForBow(_bow.id);

    return Consumer<SightMarksProvider>(
      builder: (context, provider, child) {
        final marks = provider.getMarksForBow(_bow.id);

        // Group by distance for summary
        final metricDistances = marks
            .where((m) => m.unit == DistanceUnit.meters)
            .map((m) => m.distance)
            .toSet()
            .toList()
          ..sort();

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.sm - 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility, size: 16, color: AppColors.gold),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'SIGHT MARKS',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SightMarksScreen(
                              bowId: _bow.id,
                              bowName: _bow.name,
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      child: const Icon(Icons.chevron_right, size: 20, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              if (marks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SightMarksScreen(
                            bowId: _bow.id,
                            bowName: _bow.name,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 20, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Tap to add sight marks',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SightMarksScreen(
                            bowId: _bow.id,
                            bowName: _bow.name,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary row showing recorded distances
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: metricDistances.take(6).map((d) {
                            final mark = marks.firstWhere(
                              (m) => m.distance == d && m.unit == DistanceUnit.meters,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBright,
                                borderRadius: BorderRadius.circular(AppSpacing.xs),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${d.toStringAsFixed(0)}m',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                        ),
                                  ),
                                  Text(
                                    mark.sightValue,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        if (metricDistances.length > 6) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '+${metricDistances.length - 6} more',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Bow?'),
        content: Text('Delete ${_bow.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final bowId = _bow.id;
              final bowName = _bow.name;
              final equipmentProvider = context.read<EquipmentProvider>();

              await equipmentProvider.deleteBow(bowId);

              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close detail screen

                // Show undo snackbar
                UndoManager.showUndoSnackbar(
                  context: context,
                  message: 'Bow deleted',
                  onUndo: () async {
                    await equipmentProvider.restoreBow(bowId);
                  },
                  onExpired: () async {
                    await equipmentProvider.permanentlyDeleteBow(bowId);
                  },
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
