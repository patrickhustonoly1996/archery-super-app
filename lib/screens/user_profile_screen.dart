import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_profile_provider.dart';
import '../providers/accessibility_provider.dart';
import '../db/database.dart';
import '../models/user_profile.dart';
import '../widgets/pixel_archer_icon.dart';
import '../services/sample_data_seeder.dart';
import 'federation_form_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _notesController = TextEditingController();

  BowType _selectedBowType = BowType.recurve;
  Handedness _selectedHandedness = Handedness.right;
  int? _yearsShootingStart;
  double _shootingFrequency = 3.0;
  Set<CompetitionLevel> _selectedCompetitionLevels = {};
  Gender? _selectedGender;
  DateTime? _selectedDateOfBirth;

  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clubNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final provider = context.read<UserProfileProvider>();
    await provider.loadProfile();

    if (mounted) {
      setState(() {
        _nameController.text = provider.name ?? '';
        _clubNameController.text = provider.clubName ?? '';
        _notesController.text = provider.notes ?? '';
        _selectedBowType = provider.primaryBowType;
        _selectedHandedness = provider.handedness;
        _yearsShootingStart = provider.yearsShootingStart;
        _shootingFrequency = provider.shootingFrequency;
        _selectedCompetitionLevels = provider.competitionLevels.toSet();
        _selectedGender = provider.gender;
        _selectedDateOfBirth = provider.dateOfBirth;
        _isLoading = false;
      });
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserProfileProvider>();
    await provider.saveProfile(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      clubName: _clubNameController.text.trim().isEmpty ? null : _clubNameController.text.trim(),
      bowType: _selectedBowType,
      handedness: _selectedHandedness,
      yearsShootingStart: _yearsShootingStart,
      shootingFrequency: _shootingFrequency,
      competitionLevels: _selectedCompetitionLevels.toList(),
      gender: _selectedGender,
      dateOfBirth: _selectedDateOfBirth,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() => _hasChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PixelArcherIcon(size: 24),
            const SizedBox(width: 12),
            Text(
              'PROFILE',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'SAVE',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Core shooting info section
                  _buildSectionHeader('SHOOTING STYLE'),
                  const SizedBox(height: 12),
                  _buildBowTypeSelector(),
                  const SizedBox(height: 16),
                  _buildHandednessSelector(),

                  const SizedBox(height: 32),

                  // Personal info section
                  _buildSectionHeader('ARCHER INFO'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Your name',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _clubNameController,
                    label: 'Club',
                    hint: 'Your archery club',
                  ),
                  const SizedBox(height: 16),
                  _buildYearStartedPicker(),
                  const SizedBox(height: 16),
                  _buildFrequencySlider(),
                  const SizedBox(height: 16),
                  _buildCompetitionLevels(),

                  const SizedBox(height: 32),

                  // Classification section
                  _buildSectionHeader('CLASSIFICATION'),
                  const SizedBox(height: 12),
                  _buildGenderSelector(),
                  const SizedBox(height: 16),
                  _buildDateOfBirthPicker(),
                  if (_selectedDateOfBirth != null) ...[
                    const SizedBox(height: 12),
                    _buildAgeCategoryDisplay(),
                  ],

                  const SizedBox(height: 32),

                  // Accessibility section
                  _buildSectionHeader('ACCESSIBILITY'),
                  const SizedBox(height: 12),
                  _buildTextSizeSlider(),

                  const SizedBox(height: 32),

                  // Federation memberships section
                  _buildSectionHeader('FEDERATION MEMBERSHIPS'),
                  const SizedBox(height: 12),
                  _buildFederationsList(),

                  const SizedBox(height: 32),

                  // Notes section
                  _buildSectionHeader('NOTES'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Club access codes, locker number, etc.',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 32),

                  // Bow type defaults info card
                  _buildBowTypeInfoCard(),

                  const SizedBox(height: 32),

                  // Acknowledgement footer
                  _buildAcknowledgementFooter(),

                  // Debug section (only in debug mode)
                  if (kDebugMode) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader('DEBUG'),
                    const SizedBox(height: 12),
                    _buildDebugSection(),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _saveProfile,
              backgroundColor: AppColors.gold,
              label: Text(
                'SAVE',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  color: AppColors.backgroundDark,
                ),
              ),
              icon: const Icon(Icons.check, color: AppColors.backgroundDark),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          color: AppColors.gold,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 14,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildBowTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Bow Type',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BowType.values.map((type) {
            final isSelected = _selectedBowType == type;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedBowType = type);
                _markChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.surfaceBright,
                  ),
                ),
                child: Text(
                  type.displayName,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHandednessSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Handedness',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: Handedness.values.map((hand) {
            final isSelected = _selectedHandedness == hand;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedHandedness = hand);
                  _markChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.surfaceBright,
                    ),
                  ),
                  child: Text(
                    hand.displayName,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 14,
                      color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontFamily: AppFonts.body),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: AppFonts.body,
              color: AppColors.textMuted,
            ),
          ),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }

  Widget _buildYearStartedPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(80, (i) => currentYear - i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year Started Shooting',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<int>(
            value: _yearsShootingStart,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
            ),
            hint: Text(
              'Select year',
              style: TextStyle(
                fontFamily: AppFonts.body,
                color: AppColors.textMuted,
              ),
            ),
            dropdownColor: AppColors.surfaceDark,
            style: TextStyle(
              fontFamily: AppFonts.body,
              color: AppColors.textPrimary,
            ),
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text('$year'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _yearsShootingStart = value);
              _markChanged();
            },
          ),
        ),
        if (_yearsShootingStart != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${currentYear - _yearsShootingStart!} years experience',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFrequencySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shooting Frequency',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${_shootingFrequency.round()} days/week',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.gold,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.gold,
            overlayColor: AppColors.gold.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _shootingFrequency,
            min: 0,
            max: 7,
            divisions: 7,
            onChanged: (value) {
              setState(() => _shootingFrequency = value);
              _markChanged();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Competition Levels',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CompetitionLevel.values.map((level) {
            final isSelected = _selectedCompetitionLevels.contains(level);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCompetitionLevels.remove(level);
                  } else {
                    _selectedCompetitionLevels.add(level);
                  }
                });
                _markChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold.withValues(alpha: 0.2) : AppColors.surfaceLight,
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.surfaceBright,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 18,
                      color: isSelected ? AppColors.gold : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      level.displayName,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender (for classification)',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: Gender.values.map((gender) {
            final isSelected = _selectedGender == gender;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedGender = gender);
                  _markChanged();
                },
                child: Container(
                  margin: EdgeInsets.only(right: gender == Gender.male ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : AppColors.surfaceLight,
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.surfaceBright,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      gender.displayName,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Used to calculate AGB classification thresholds',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthPicker() {
    final formattedDate = _selectedDateOfBirth != null
        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
        : 'Not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border.all(color: AppColors.surfaceBright),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 14,
                      color: _selectedDateOfBirth != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Used to determine your age category for classifications',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.background,
              surface: AppColors.surfaceLight,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
      _markChanged();
    }
  }

  Widget _buildAgeCategoryDisplay() {
    final ageCategory = _selectedDateOfBirth != null
        ? AgeCategory.fromDateOfBirth(_selectedDateOfBirth!)
        : null;

    if (ageCategory == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 20,
            color: AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age Category',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  ageCategory.displayName,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSizeSlider() {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border.all(color: AppColors.surfaceBright),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 20,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Text Size',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    accessibility.textScalePercentage,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 14,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'A',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.gold,
                        inactiveTrackColor: AppColors.surfaceBright,
                        thumbColor: AppColors.gold,
                        overlayColor: AppColors.gold.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: accessibility.textScaleFactor,
                        min: accessibility.minTextScale,
                        max: accessibility.maxTextScale,
                        divisions: 14, // 0.05 increments
                        onChanged: (value) {
                          accessibility.setTextScaleFactor(value);
                        },
                      ),
                    ),
                  ),
                  Text(
                    'A',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Adjusts text size throughout the app. Logos and icons also scale.',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (accessibility.textScaleFactor != 1.0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => accessibility.resetTextScale(),
                    child: Text(
                      'RESET TO DEFAULT',
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 12,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAcknowledgementFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Handicap and classification calculations based on archeryutils',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFederationsList() {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, _) {
        final federations = provider.federations;

        return Column(
          children: [
            if (federations.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.surfaceBright),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_membership,
                      size: 32,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No federation memberships',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ...federations.map((fed) => _buildFederationCard(fed)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openFederationForm(null),
              icon: const Icon(Icons.add, color: AppColors.gold),
              label: Text(
                'ADD FEDERATION',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  color: AppColors.gold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFederationCard(dynamic federation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(
          color: federation.isPrimary ? AppColors.gold : AppColors.surfaceBright,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      federation.federationName,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (federation.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Text(
                          'PRIMARY',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 8,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (federation.membershipNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Member #: ${federation.membershipNumber}',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (federation.expiryDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Expires: ${_formatDate(federation.expiryDate!)}',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: _isExpired(federation.expiryDate!)
                          ? AppColors.error
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (federation.cardImagePath != null)
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceBright),
              ),
              child: ClipRect(
                child: Image.file(
                  File(federation.cardImagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: () => _openFederationForm(federation),
            icon: const Icon(Icons.edit, color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  void _openFederationForm(dynamic federation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FederationFormScreen(federation: federation),
      ),
    ).then((_) {
      // Refresh profile after returning
      context.read<UserProfileProvider>().loadProfile();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isExpired(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  Widget _buildBowTypeInfoCard() {
    final indoorSuggestion = BowTypeDefaults.getIndoorSuggestion(_selectedBowType);
    final outdoorSuggestion = BowTypeDefaults.getOutdoorSuggestion(_selectedBowType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                'Target Face Suggestions',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 12,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Based on ${_selectedBowType.displayName}:',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Indoor',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      indoorSuggestion,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outdoor',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      outdoorSuggestion,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Development Tools',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sample Data Seeding',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creates demo account for "Testy McTestface" with 6 months of realistic scoring, training, and equipment data.',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _seedSampleData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                  child: const Text('SEED DATA'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearSampleData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('CLEAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _seedSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          'Seed Sample Data?',
          style: TextStyle(fontFamily: AppFonts.pixel, color: AppColors.textPrimary),
        ),
        content: Text(
          'This will create sample data for "Testy McTestface" including 6 months of sessions, training logs, equipment, and more.\n\nExisting sample data will be replaced.',
          style: TextStyle(fontFamily: AppFonts.body, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('SEED'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
    );

    try {
      final db = context.read<AppDatabase>();
      final seeder = SampleDataSeeder(db);
      await seeder.seedAll();

      if (mounted) {
        Navigator.pop(context); // Close loading
        await _loadProfile(); // Reload profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          'Clear Sample Data?',
          style: TextStyle(fontFamily: AppFonts.pixel, color: AppColors.textPrimary),
        ),
        content: Text(
          'This will remove all sample data created by the seeder. Your own data will not be affected.',
          style: TextStyle(fontFamily: AppFonts.body, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final db = context.read<AppDatabase>();
      final seeder = SampleDataSeeder(db);
      await seeder.clearSampleData();

      if (mounted) {
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
