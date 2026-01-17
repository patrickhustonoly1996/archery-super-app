import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../models/bow_specifications.dart';
import '../widgets/bow_icon.dart';
import '../utils/undo_manager.dart';
import 'bow_form_screen.dart';
import 'bow_specs_screen.dart';

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
    final specs = BowSpecifications.fromJson(_bow.settings);

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
                ),
                _buildSpecRow(
                  context,
                  label: 'Nocking Point',
                  value: specs.nockingPoint != null
                      ? '${specs.nockingPoint! >= 0 ? '+' : ''}${specs.nockingPoint!.toStringAsFixed(1)} mm'
                      : null,
                  subtitle: 'Above square',
                  isPrimary: true,
                ),
                _buildSpecRow(
                  context,
                  label: 'Tiller (Top)',
                  value: specs.tillerTop != null
                      ? '${specs.tillerTop!.toStringAsFixed(1)} mm'
                      : null,
                  isPrimary: true,
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
                ),
                _buildSpecRow(
                  context,
                  label: 'Centre Shot',
                  value: CentreShotOptions.displayName(specs.centreShot),
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
            _buildSection(
              context,
              title: 'STABILIZERS',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Long Rod',
                  value: specs.longRodLength != null
                      ? '${specs.longRodLength!.toStringAsFixed(0)}"'
                      : null,
                ),
                _buildSpecRow(
                  context,
                  label: 'Side Rods',
                  value: specs.sideRodLength != null
                      ? '${specs.sideRodLength!.toStringAsFixed(0)}"'
                      : null,
                ),
                _buildSpecRow(
                  context,
                  label: 'V-Bar Angle',
                  value: specs.vBarAngle != null
                      ? '${specs.vBarAngle!.toStringAsFixed(0)}°'
                      : null,
                ),
                _buildSpecRow(
                  context,
                  label: 'Weights',
                  value: specs.stabilizerWeights,
                ),
              ],
              onEdit: () => _editSpecs(context, 'stabilizers'),
            ),

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
            color: AppColors.gold.withOpacity(0.1),
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
                        color: AppColors.gold.withOpacity(0.2),
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
          color: isPrimary ? AppColors.gold.withOpacity(0.3) : AppColors.surfaceBright,
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
                  ? AppColors.gold.withOpacity(0.1)
                  : AppColors.surfaceBright.withOpacity(0.5),
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
  }) {
    final hasValue = value != null && value != 'Not set';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
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
    if (specs.limbPoundage != null) {
      parts.add('${specs.limbPoundage!.toStringAsFixed(0)}#');
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
