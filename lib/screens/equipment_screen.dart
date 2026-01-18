import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../widgets/bow_icon.dart';
import '../widgets/quiver_icon.dart';
import '../widgets/empty_state.dart';
import '../models/bow_specifications.dart';
import '../models/arrow_specifications.dart';
import 'bow_form_screen.dart';
import 'bow_detail_screen.dart';
import 'quiver_form_screen.dart';
import 'quiver_detail_screen.dart';
import 'shaft_management_screen.dart';
import 'tuning_history_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Bows'),
            Tab(text: 'Quivers'),
            Tab(text: 'Tuning'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BowsTab(),
          _QuiversTab(),
          TuningHistoryScreen(),
        ],
      ),
    );
  }
}

class _BowsTab extends StatelessWidget {
  const _BowsTab();

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final bows = equipmentProvider.bows;

    if (bows.isEmpty) {
      return EmptyState(
        iconWidget: const BowIcon(size: 64, color: AppColors.textMuted),
        title: 'No bows added',
        subtitle: 'Add a bow to get started',
        actionLabel: 'Add Bow',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BowFormScreen(),
            ),
          ).then((_) => equipmentProvider.loadEquipment());
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: bows.length + 1,
      itemBuilder: (context, index) {
        if (index == bows.length) {
          // Add button at the end
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BowFormScreen(),
                  ),
                ).then((_) => equipmentProvider.loadEquipment());
              },
              icon: const Icon(Icons.add, semanticLabel: 'Add'),
              label: const Text('Add Bow'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          );
        }

        final bow = bows[index];
        return _BowTile(bow: bow);
      },
    );
  }
}

class _BowTile extends StatelessWidget {
  final Bow bow;

  const _BowTile({required this.bow});

  @override
  Widget build(BuildContext context) {
    final specs = BowSpecifications.fromJson(bow.settings);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BowDetailScreen(bow: bow),
            ),
          ).then((_) => context.read<EquipmentProvider>().loadEquipment());
        },
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: bow.isDefault ? AppColors.gold : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Row(
            children: [
              BowIcon(
                size: 32,
                color: bow.isDefault ? AppColors.gold : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bow.name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        if (bow.isDefault) ...[
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
                    const SizedBox(height: 2),
                    Text(
                      bow.bowType.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (specs.hasAnySpecs) ...[
                      const SizedBox(height: 4),
                      Text(
                        specs.summaryText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuiversTab extends StatelessWidget {
  const _QuiversTab();

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final quivers = equipmentProvider.quivers;

    if (quivers.isEmpty) {
      return EmptyState(
        iconWidget: const QuiverIcon(size: 64, color: AppColors.textMuted),
        title: 'No quivers added',
        subtitle: 'Add a quiver to track arrows',
        actionLabel: 'Add Quiver',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QuiverFormScreen(),
            ),
          ).then((_) => equipmentProvider.loadEquipment());
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: quivers.length + 1,
      itemBuilder: (context, index) {
        if (index == quivers.length) {
          // Add button at the end
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuiverFormScreen(),
                  ),
                ).then((_) => equipmentProvider.loadEquipment());
              },
              icon: const Icon(Icons.add, semanticLabel: 'Add'),
              label: const Text('Add Quiver'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          );
        }

        final quiver = quivers[index];
        return _QuiverTile(quiver: quiver);
      },
    );
  }
}

class _QuiverTile extends StatelessWidget {
  final Quiver quiver;

  const _QuiverTile({required this.quiver});

  @override
  Widget build(BuildContext context) {
    final specs = ArrowSpecifications.fromJson(quiver.settings);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuiverDetailScreen(quiver: quiver),
            ),
          ).then((_) => context.read<EquipmentProvider>().loadEquipment());
        },
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: quiver.isDefault ? AppColors.gold : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Row(
            children: [
              QuiverIcon(
                size: 32,
                color: quiver.isDefault ? AppColors.gold : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          quiver.name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        if (quiver.isDefault) ...[
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
                    const SizedBox(height: 2),
                    Text(
                      '${quiver.shaftCount} arrows',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (specs.hasAnySpecs) ...[
                      const SizedBox(height: 4),
                      Text(
                        specs.summaryText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
