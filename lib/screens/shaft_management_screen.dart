import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';

class ShaftManagementScreen extends StatelessWidget {
  final Quiver quiver;

  const ShaftManagementScreen({super.key, required this.quiver});

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final shafts = equipmentProvider.getShaftsForQuiver(quiver.id);
    final allShafts = shafts.toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return Scaffold(
      appBar: AppBar(
        title: Text(quiver.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Shaft Management'),
                  content: const Text(
                    'Long press on a shaft to retire or unretire it. '
                    'Retired shafts will not appear during shaft selection but are preserved in historical data.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: allShafts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No shafts found',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This should not happen',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.0,
              ),
              itemCount: allShafts.length,
              itemBuilder: (context, index) {
                final shaft = allShafts[index];
                return _ShaftCard(
                  shaft: shaft,
                  onToggleRetirement: () async {
                    final isRetired = shaft.retiredAt != null;
                    await equipmentProvider.toggleShaftRetirement(
                      shaft.id,
                      !isRetired,
                    );
                  },
                  onEditNotes: () async {
                    final notes = await _showNotesDialog(context, shaft);
                    if (notes != null) {
                      await equipmentProvider.updateShaftNotes(
                        shaft.id,
                        notes,
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  Future<String?> _showNotesDialog(BuildContext context, Shaft shaft) {
    final controller = TextEditingController(text: shaft.notes ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shaft ${shaft.number} Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Bent nock, replaced 2024-01',
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ShaftCard extends StatelessWidget {
  final Shaft shaft;
  final VoidCallback onToggleRetirement;
  final VoidCallback onEditNotes;

  const _ShaftCard({
    required this.shaft,
    required this.onToggleRetirement,
    required this.onEditNotes,
  });

  @override
  Widget build(BuildContext context) {
    final isRetired = shaft.retiredAt != null;
    final hasNotes = shaft.notes != null && shaft.notes!.isNotEmpty;

    return GestureDetector(
      onTap: onEditNotes,
      onLongPress: onToggleRetirement,
      child: Container(
        decoration: BoxDecoration(
          color: isRetired
              ? AppColors.surfaceLight.withValues(alpha: 0.3)
              : AppColors.surfaceDark,
          border: Border.all(
            color: isRetired ? AppColors.textMuted : AppColors.gold,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shaft.number.toString(),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: isRetired ? AppColors.textMuted : AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (isRetired) ...[
                    const SizedBox(height: 4),
                    Text(
                      'RETIRED',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 8,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Notes indicator
            if (hasNotes)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.note,
                  size: 12,
                  color: isRetired ? AppColors.textMuted : AppColors.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
