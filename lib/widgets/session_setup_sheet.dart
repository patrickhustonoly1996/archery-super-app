import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../providers/equipment_provider.dart';
import '../providers/session_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../screens/plotting_screen.dart';
import '../screens/settings_screen.dart' show kArrowTrackingDefaultPref;

/// Preference key for scoring timer enabled
const kScoringTimerEnabledPref = 'scoring_timer_enabled';

/// Preference key for scoring timer duration
const kScoringTimerDurationPref = 'scoring_timer_duration';

/// Bottom sheet for session setup when starting a new scoring session.
/// Collects title (required), location name, equipment, and timer settings.
class SessionSetupSheet extends StatefulWidget {
  final RoundType roundType;
  final String sessionType; // 'practice' or 'competition'

  const SessionSetupSheet({
    super.key,
    required this.roundType,
    required this.sessionType,
  });

  /// Show the session setup sheet and return true if session was started
  static Future<bool> show({
    required BuildContext context,
    required RoundType roundType,
    required String sessionType,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SessionSetupSheet(
        roundType: roundType,
        sessionType: sessionType,
      ),
    );
    return result ?? false;
  }

  @override
  State<SessionSetupSheet> createState() => _SessionSetupSheetState();
}

class _SessionSetupSheetState extends State<SessionSetupSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _titleFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isStarting = false;

  // Equipment selection
  String? _selectedBowId;
  String? _selectedQuiverId;
  bool _shaftTaggingEnabled = false;
  bool _arrowTrackingDefault = false;

  // Timer settings
  bool _timerEnabled = false;
  int _timerDuration = 120;

  // Location data (silently fetched)
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchLocationSilently();

    // Auto-focus title field after sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    final equipmentProvider = context.read<EquipmentProvider>();

    final arrowTrackingDefault =
        await db.getBoolPreference(kArrowTrackingDefaultPref, defaultValue: false);
    final timerEnabled =
        await db.getBoolPreference(kScoringTimerEnabledPref, defaultValue: false);
    final timerDuration =
        await db.getIntPreference(kScoringTimerDurationPref, defaultValue: 120);

    // Pre-populate with default equipment
    final defaultBowId = equipmentProvider.defaultBow?.id;
    final defaultQuiverId = equipmentProvider.defaultQuiver?.id;

    setState(() {
      _arrowTrackingDefault = arrowTrackingDefault;
      _timerEnabled = timerEnabled;
      _timerDuration = timerDuration;
      _selectedBowId = defaultBowId;
      _selectedQuiverId = defaultQuiverId;
      if (defaultQuiverId != null) {
        _shaftTaggingEnabled = arrowTrackingDefault;
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchLocationSilently() async {
    // Don't block UI - fetch in background
    final location = await LocationService.getCurrentLocation(requestIfDenied: false);
    if (location != null && mounted) {
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
      });
    }
  }

  bool get _canStart => _titleController.text.trim().isNotEmpty && !_isStarting;

  Future<void> _startSession() async {
    if (!_canStart) return;

    setState(() => _isStarting = true);

    final provider = context.read<SessionProvider>();
    await provider.startSession(
      roundTypeId: widget.roundType.id,
      title: _titleController.text.trim(),
      locationName: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      sessionType: widget.sessionType,
      bowId: _selectedBowId,
      quiverId: _selectedQuiverId,
      shaftTaggingEnabled: _shaftTaggingEnabled,
    );

    if (mounted) {
      // Close sheet and navigate to plotting
      Navigator.pop(context, true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PlottingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.roundType.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.gold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.roundType.distance}m • ${widget.roundType.arrowsPerEnd} arrows/end • ${widget.roundType.totalEnds} ends',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.sessionType == 'competition'
                              ? AppColors.gold.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.sessionType == 'competition' ? 'Competition' : 'Practice',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            color: widget.sessionType == 'competition'
                                ? AppColors.gold
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title (required)
                  Text(
                    'Session Title *',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Morning Practice, League Round 2',
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _startSession(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Location name (optional)
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Evesham Archery Club',
                      suffixIcon: _latitude != null
                          ? const Tooltip(
                              message: 'GPS location captured',
                              child: Icon(
                                Icons.location_on,
                                color: AppColors.gold,
                                size: 20,
                              ),
                            )
                          : null,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Equipment section (collapsible)
                  _EquipmentSection(
                    selectedBowId: _selectedBowId,
                    selectedQuiverId: _selectedQuiverId,
                    shaftTaggingEnabled: _shaftTaggingEnabled,
                    arrowTrackingDefault: _arrowTrackingDefault,
                    onBowChanged: (id) => setState(() => _selectedBowId = id),
                    onQuiverChanged: (id) {
                      setState(() {
                        _selectedQuiverId = id;
                        if (id == null) {
                          _shaftTaggingEnabled = false;
                        } else {
                          _shaftTaggingEnabled = _arrowTrackingDefault;
                        }
                      });
                    },
                    onShaftTaggingChanged: (val) =>
                        setState(() => _shaftTaggingEnabled = val),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Timer section (collapsible)
                  _TimerSection(
                    timerEnabled: _timerEnabled,
                    timerDuration: _timerDuration,
                    isIndoor: widget.roundType.isIndoor,
                    onTimerEnabledChanged: (val) async {
                      setState(() => _timerEnabled = val);
                      final db = context.read<AppDatabase>();
                      await db.setBoolPreference(kScoringTimerEnabledPref, val);
                    },
                    onDurationChanged: (val) async {
                      setState(() => _timerDuration = val);
                      final db = context.read<AppDatabase>();
                      await db.setIntPreference(kScoringTimerDurationPref, val);
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Start button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canStart ? _startSession : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: _isStarting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.backgroundDark,
                              ),
                            )
                          : const Text('Start Session'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
    );
  }
}

/// Collapsible equipment selection section
class _EquipmentSection extends StatefulWidget {
  final String? selectedBowId;
  final String? selectedQuiverId;
  final bool shaftTaggingEnabled;
  final bool arrowTrackingDefault;
  final ValueChanged<String?> onBowChanged;
  final ValueChanged<String?> onQuiverChanged;
  final ValueChanged<bool> onShaftTaggingChanged;

  const _EquipmentSection({
    required this.selectedBowId,
    required this.selectedQuiverId,
    required this.shaftTaggingEnabled,
    required this.arrowTrackingDefault,
    required this.onBowChanged,
    required this.onQuiverChanged,
    required this.onShaftTaggingChanged,
  });

  @override
  State<_EquipmentSection> createState() => _EquipmentSectionState();
}

class _EquipmentSectionState extends State<_EquipmentSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<EquipmentProvider>(
      builder: (context, equipmentProvider, _) {
        final bows = equipmentProvider.bows;
        final quivers = equipmentProvider.quivers;
        final hasEquipment = bows.isNotEmpty || quivers.isNotEmpty;

        if (!hasEquipment) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Equipment',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  if (widget.selectedBowId != null || widget.selectedQuiverId != null)
                    Text(
                      _getEquipmentSummary(equipmentProvider),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.md),
              // Bow dropdown
              if (bows.isNotEmpty)
                DropdownButtonFormField<String?>(
                  value: widget.selectedBowId,
                  decoration: const InputDecoration(
                    labelText: 'Bow',
                    hintText: 'Select a bow',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...bows.map((bow) {
                      return DropdownMenuItem<String?>(
                        value: bow.id,
                        child: Text(bow.name),
                      );
                    }),
                  ],
                  onChanged: widget.onBowChanged,
                ),
              const SizedBox(height: AppSpacing.md),
              // Quiver dropdown
              if (quivers.isNotEmpty)
                DropdownButtonFormField<String?>(
                  value: widget.selectedQuiverId,
                  decoration: const InputDecoration(
                    labelText: 'Quiver',
                    hintText: 'Select a quiver',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...quivers.where((q) {
                      if (widget.selectedBowId == null) return true;
                      return q.bowId == null || q.bowId == widget.selectedBowId;
                    }).map((quiver) {
                      return DropdownMenuItem<String?>(
                        value: quiver.id,
                        child: Text('${quiver.name} (${quiver.shaftCount} arrows)'),
                      );
                    }),
                  ],
                  onChanged: widget.onQuiverChanged,
                ),
              // Shaft tagging toggle
              if (widget.selectedQuiverId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  title: const Text('Enable shaft tagging'),
                  subtitle: const Text('Track individual arrow performance'),
                  value: widget.shaftTaggingEnabled,
                  activeThumbColor: AppColors.gold,
                  onChanged: widget.onShaftTaggingChanged,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  String _getEquipmentSummary(EquipmentProvider provider) {
    final parts = <String>[];
    if (widget.selectedBowId != null) {
      final bow = provider.bows.where((b) => b.id == widget.selectedBowId).firstOrNull;
      if (bow != null) parts.add(bow.name);
    }
    if (widget.selectedQuiverId != null) {
      final quiver =
          provider.quivers.where((q) => q.id == widget.selectedQuiverId).firstOrNull;
      if (quiver != null) parts.add(quiver.name);
    }
    return parts.join(' + ');
  }
}

/// Collapsible timer section
class _TimerSection extends StatefulWidget {
  final bool timerEnabled;
  final int timerDuration;
  final bool isIndoor;
  final ValueChanged<bool> onTimerEnabledChanged;
  final ValueChanged<int> onDurationChanged;

  const _TimerSection({
    required this.timerEnabled,
    required this.timerDuration,
    required this.isIndoor,
    required this.onTimerEnabledChanged,
    required this.onDurationChanged,
  });

  @override
  State<_TimerSection> createState() => _TimerSectionState();
}

class _TimerSectionState extends State<_TimerSection> {
  bool _expanded = false;

  int get _suggestedDuration => widget.isIndoor ? 120 : 240;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Timer',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              if (widget.timerEnabled)
                Text(
                  '${widget.timerDuration}s',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                      ),
                )
              else
                Text(
                  'Off',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            title: const Text('Enable Timer'),
            subtitle: const Text('Competition-style countdown'),
            value: widget.timerEnabled,
            activeThumbColor: AppColors.gold,
            onChanged: (val) {
              widget.onTimerEnabledChanged(val);
              if (val) {
                widget.onDurationChanged(_suggestedDuration);
              }
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (widget.timerEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _DurationChip(
                  label: '90s',
                  isSelected: widget.timerDuration == 90,
                  onTap: () => widget.onDurationChanged(90),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DurationChip(
                  label: '120s',
                  isSelected: widget.timerDuration == 120,
                  onTap: () => widget.onDurationChanged(120),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DurationChip(
                  label: '180s',
                  isSelected: widget.timerDuration == 180,
                  onTap: () => widget.onDurationChanged(180),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DurationChip(
                  label: '240s',
                  isSelected: widget.timerDuration == 240,
                  onTap: () => widget.onDurationChanged(240),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 12,
            color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
