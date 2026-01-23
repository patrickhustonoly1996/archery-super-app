import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../models/field_course.dart' as model;
import '../providers/field_course_provider.dart';
import '../providers/field_session_provider.dart';
import '../providers/equipment_provider.dart';
import 'field_course_selection_screen.dart';
import 'field_scoring_screen.dart';

class FieldSessionStartScreen extends StatefulWidget {
  const FieldSessionStartScreen({super.key});

  @override
  State<FieldSessionStartScreen> createState() => _FieldSessionStartScreenState();
}

class _FieldSessionStartScreenState extends State<FieldSessionStartScreen> {
  model.FieldRoundType _selectedRoundType = model.FieldRoundType.field;
  bool _createNewCourse = false;
  model.FieldCourse? _selectedCourse;
  String _newCourseName = '';

  // Equipment selection
  String? _selectedBowId;
  String? _selectedQuiverId;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final courseProvider = context.read<FieldCourseProvider>();
    final equipmentProvider = context.read<EquipmentProvider>();

    await courseProvider.loadCourses();

    setState(() {
      _selectedBowId = equipmentProvider.defaultBow?.id;
      _selectedQuiverId = equipmentProvider.defaultQuiver?.id;
      _isLoading = false;
    });
  }

  Future<void> _startSession() async {
    if (_selectedBowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bow')),
      );
      return;
    }

    final sessionProvider = context.read<FieldSessionProvider>();

    if (_createNewCourse) {
      if (_newCourseName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a course name')),
        );
        return;
      }

      await sessionProvider.startSessionNewCourse(
        roundType: _selectedRoundType,
        bowId: _selectedBowId!,
        quiverId: _selectedQuiverId,
        courseName: _newCourseName,
      );
    } else {
      if (_selectedCourse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a course')),
        );
        return;
      }

      await sessionProvider.startSessionWithCourse(
        course: _selectedCourse!,
        bowId: _selectedBowId!,
        quiverId: _selectedQuiverId,
      );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FieldScoringScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Archery'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: ElevatedButton(
                onPressed: _canStart() ? _startSession : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: const Text('Start'),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Round Type Selection
                  Text(
                    'Round Type',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildRoundTypeSelector(),

                  const SizedBox(height: AppSpacing.xl),

                  // Course Selection
                  Text(
                    'Course',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildCourseSection(),

                  const SizedBox(height: AppSpacing.xl),

                  // Equipment Selection
                  Text(
                    'Equipment',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildEquipmentSection(),

                  const SizedBox(height: AppSpacing.xl),

                  // Round Info
                  _buildRoundInfo(),
                ],
              ),
            ),
    );
  }

  bool _canStart() {
    if (_selectedBowId == null) return false;
    if (_createNewCourse) {
      return _newCourseName.isNotEmpty;
    }
    return _selectedCourse != null;
  }

  Widget _buildRoundTypeSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: model.FieldRoundType.values.map((type) {
        final isSelected = _selectedRoundType == type;
        return ChoiceChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedRoundType = type;
              _selectedCourse = null; // Reset course selection
            });
          },
          selectedColor: AppColors.gold,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.background : AppColors.textPrimary,
            fontFamily: AppFonts.body,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseSection() {
    return Column(
      children: [
        // Toggle between existing and new course
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Existing Course',
                subtitle: 'Use a saved course',
                isSelected: !_createNewCourse,
                onTap: () => setState(() => _createNewCourse = false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildOptionCard(
                title: 'New Course',
                subtitle: 'Define as you go',
                isSelected: _createNewCourse,
                onTap: () => setState(() => _createNewCourse = true),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Show relevant content
        if (_createNewCourse)
          _buildNewCourseInput()
        else
          _buildCourseSelector(),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.2) : AppColors.surfaceDark,
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCourseInput() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Course name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        filled: true,
        fillColor: AppColors.surfaceDark,
      ),
      onChanged: (value) => setState(() => _newCourseName = value),
    );
  }

  Widget _buildCourseSelector() {
    return Consumer<FieldCourseProvider>(
      builder: (context, provider, _) {
        final coursesForType = provider.courses
            .where((c) => c.roundType == _selectedRoundType)
            .toList();

        if (coursesForType.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.landscape_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No saved ${_selectedRoundType.displayName} courses',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => setState(() => _createNewCourse = true),
                  child: const Text('Create New Course'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Selected course display
            if (_selectedCourse != null)
              _buildSelectedCourseCard()
            else
              _buildCourseSelectionButton(coursesForType.length),
          ],
        );
      },
    );
  }

  Widget _buildSelectedCourseCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCourse!.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_selectedCourse!.targetCount} targets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.textSecondary),
            onPressed: _openCourseSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelectionButton(int count) {
    return OutlinedButton(
      onPressed: _openCourseSelection,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.landscape_outlined),
          const SizedBox(width: AppSpacing.sm),
          Text('Select Course ($count available)'),
        ],
      ),
    );
  }

  Future<void> _openCourseSelection() async {
    final result = await Navigator.push<model.FieldCourse>(
      context,
      MaterialPageRoute(
        builder: (_) => FieldCourseSelectionScreen(
          roundType: _selectedRoundType,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCourse = result;
      });
    }
  }

  Widget _buildEquipmentSection() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, _) {
        final bows = provider.bows;
        final quivers = provider.quivers;

        return Column(
          children: [
            // Bow dropdown
            DropdownButtonFormField<String>(
              value: _selectedBowId,
              decoration: InputDecoration(
                labelText: 'Bow',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                filled: true,
                fillColor: AppColors.surfaceDark,
              ),
              items: bows.map((bow) {
                return DropdownMenuItem(
                  value: bow.id,
                  child: Text(bow.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedBowId = value),
            ),

            const SizedBox(height: AppSpacing.md),

            // Quiver dropdown (optional)
            DropdownButtonFormField<String?>(
              value: _selectedQuiverId,
              decoration: InputDecoration(
                labelText: 'Quiver (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                filled: true,
                fillColor: AppColors.surfaceDark,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No quiver'),
                ),
                ...quivers.map((quiver) {
                  return DropdownMenuItem(
                    value: quiver.id,
                    child: Text(quiver.name),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _selectedQuiverId = value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoundInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedRoundType.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow('Targets', '${_selectedRoundType.targetCount}'),
          _buildInfoRow('Arrows/target', '${_selectedRoundType.maxArrowsPerTarget}'),
          _buildInfoRow('Scoring', _selectedRoundType.scoringDescription),
          _buildInfoRow('Max score', '${_selectedRoundType.maxScore}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
