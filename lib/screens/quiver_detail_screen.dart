import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../models/arrow_specifications.dart';
import '../utils/undo_manager.dart';
import 'quiver_form_screen.dart';
import 'quiver_specs_screen.dart';
import 'shaft_management_screen.dart';

/// Detailed view of a quiver with arrow specifications
class QuiverDetailScreen extends StatefulWidget {
  final Quiver quiver;

  const QuiverDetailScreen({super.key, required this.quiver});

  @override
  State<QuiverDetailScreen> createState() => _QuiverDetailScreenState();
}

class _QuiverDetailScreenState extends State<QuiverDetailScreen> {
  late Quiver _quiver;

  @override
  void initState() {
    super.initState();
    _quiver = widget.quiver;
  }

  void _refreshQuiver() async {
    final provider = context.read<EquipmentProvider>();
    await provider.loadEquipment();
    final updatedQuiver = provider.quivers.firstWhere(
      (q) => q.id == _quiver.id,
      orElse: () => _quiver,
    );
    if (mounted) {
      setState(() => _quiver = updatedQuiver);
    }
  }

  @override
  Widget build(BuildContext context) {
    final specs = ArrowSpecifications.fromJson(_quiver.settings);
    final provider = context.watch<EquipmentProvider>();
    final linkedBow = _quiver.bowId != null
        ? provider.bows.where((b) => b.id == _quiver.bowId).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiver.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuiverFormScreen(quiver: _quiver),
                ),
              );
              _refreshQuiver();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'default') {
                await context.read<EquipmentProvider>().setDefaultQuiver(_quiver.id);
                _refreshQuiver();
              } else if (value == 'shafts') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShaftManagementScreen(quiver: _quiver),
                  ),
                );
                _refreshQuiver();
              } else if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              if (!_quiver.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Set as default'),
                ),
              const PopupMenuItem(
                value: 'shafts',
                child: Text('Manage individual arrows'),
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
            // Header
            _buildHeader(context, linkedBow),
            const SizedBox(height: AppSpacing.xl),

            // Shaft Section
            _buildSection(
              context,
              title: 'SHAFT',
              isPrimary: true,
              children: [
                _buildSpecRow(context, label: 'Model', value: specs.shaftModel, isPrimary: true),
                _buildSpecRow(context, label: 'Spine', value: specs.shaftSpine, isPrimary: true),
                _buildSpecRow(
                  context,
                  label: 'Diameter',
                  value: specs.shaftDiameter != null ? '${specs.shaftDiameter!.toStringAsFixed(1)} mm' : null,
                ),
                _buildSpecRow(
                  context,
                  label: 'Cut Length',
                  value: specs.cutLength != null ? '${specs.cutLength!.toStringAsFixed(2)}"' : null,
                  subtitle: 'End to end',
                  isPrimary: true,
                ),
                _buildSpecRow(
                  context,
                  label: 'Total Length',
                  value: specs.totalLength != null ? '${specs.totalLength!.toStringAsFixed(2)}"' : null,
                  subtitle: 'With point',
                ),
              ],
              onEdit: () => _editSpecs(context, 'shaft'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Point Section
            _buildSection(
              context,
              title: 'POINT',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Type',
                  value: PointTypeOptions.displayName(specs.pointType),
                ),
                _buildSpecRow(context, label: 'Model', value: specs.pointModel),
                _buildSpecRow(
                  context,
                  label: 'Weight',
                  value: specs.pointWeight != null ? '${specs.pointWeight} gr' : null,
                  isPrimary: true,
                ),
              ],
              onEdit: () => _editSpecs(context, 'point'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Nock Section
            _buildSection(
              context,
              title: 'NOCK',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Type',
                  value: NockTypeOptions.displayName(specs.nockType),
                  isPrimary: true,
                ),
                _buildSpecRow(context, label: 'Model', value: specs.nockModel),
                _buildSpecRow(context, label: 'Size', value: specs.nockSize),
                _buildSpecRow(context, label: 'Color', value: specs.nockColor),
              ],
              onEdit: () => _editSpecs(context, 'nock'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Fletching Section
            _buildSection(
              context,
              title: 'FLETCHING',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Type',
                  value: FletchTypeOptions.displayName(specs.fletchType),
                  isPrimary: true,
                ),
                _buildSpecRow(context, label: 'Model', value: specs.fletchModel),
                _buildSpecRow(
                  context,
                  label: 'Size',
                  value: specs.fletchSize != null ? '${specs.fletchSize!.toStringAsFixed(2)}"' : null,
                ),
                _buildSpecRow(
                  context,
                  label: 'Angle/Offset',
                  value: specs.fletchAngle != null ? '${specs.fletchAngle!.toStringAsFixed(1)}°' : null,
                ),
                _buildSpecRow(context, label: 'Color', value: specs.fletchColor),
                _buildSpecRow(
                  context,
                  label: 'Count',
                  value: specs.fletchCount?.toString(),
                ),
              ],
              onEdit: () => _editSpecs(context, 'fletching'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Wrap Section
            _buildSection(
              context,
              title: 'WRAP',
              children: [
                _buildSpecRow(
                  context,
                  label: 'Has Wrap',
                  value: specs.hasWrap == true ? 'Yes' : (specs.hasWrap == false ? 'No' : null),
                ),
                if (specs.hasWrap == true) ...[
                  _buildSpecRow(context, label: 'Model', value: specs.wrapModel),
                  _buildSpecRow(context, label: 'Color', value: specs.wrapColor),
                ],
              ],
              onEdit: () => _editSpecs(context, 'wrap'),
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

            const SizedBox(height: AppSpacing.lg),

            // Individual Arrows link
            Card(
              child: ListTile(
                leading: const Icon(Icons.format_list_numbered, color: AppColors.gold),
                title: const Text('Individual Arrows'),
                subtitle: Text('${_quiver.shaftCount} arrows in this quiver'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShaftManagementScreen(quiver: _quiver),
                    ),
                  );
                  _refreshQuiver();
                },
              ),
            ),

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

  Widget _buildHeader(BuildContext context, Bow? linkedBow) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
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
                    '${_quiver.shaftCount} ARROWS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (_quiver.isDefault) ...[
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
                _quiver.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (linkedBow != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Linked to: ${linkedBow.name}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
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
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _editSpecs(BuildContext context, String section) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuiverSpecsScreen(quiver: _quiver, initialSection: section),
      ),
    );
    _refreshQuiver();
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Quiver?'),
        content: Text('Delete ${_quiver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final quiverId = _quiver.id;
              final quiverName = _quiver.name;
              final equipmentProvider = context.read<EquipmentProvider>();

              await equipmentProvider.deleteQuiver(quiverId);

              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close detail screen

                // Show undo snackbar
                UndoManager.showUndoSnackbar(
                  context: context,
                  message: 'Quiver deleted',
                  onUndo: () async {
                    await equipmentProvider.restoreQuiver(quiverId);
                  },
                  onExpired: () async {
                    await equipmentProvider.permanentlyDeleteQuiver(quiverId);
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
