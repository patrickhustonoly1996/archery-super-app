import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../providers/equipment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/shaft_comparison.dart';

/// Interactive shaft comparison tool.
/// Allows toggling shafts on/off and finding optimal combinations.
class ShaftComparisonScreen extends StatefulWidget {
  const ShaftComparisonScreen({super.key});

  @override
  State<ShaftComparisonScreen> createState() => _ShaftComparisonScreenState();
}

class _ShaftComparisonScreenState extends State<ShaftComparisonScreen> {
  // Data
  List<Quiver> _quivers = [];
  Quiver? _selectedQuiver;
  List<Shaft> _shafts = [];
  List<Arrow> _allArrows = [];
  List<Session> _sessions = [];

  // Filter state
  DateTimeRange? _dateRange;
  final Set<String> _selectedSessionIds = {};
  bool _filterBySession = false;

  // Selection state
  Set<String> _selectedShaftIds = {};

  // Analysis results
  List<ShaftComparisonStats> _shaftStats = [];
  ShaftCombinationResult? _combinedResult;

  // UI state
  bool _loading = true;
  bool _showSessionPicker = false;

  // Preset date ranges
  static const _datePresets = [
    ('Last 30 days', 30),
    ('Last 60 days', 60),
    ('Last 90 days', 90),
    ('All time', 0),
  ];
  int _selectedPresetIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final db = context.read<AppDatabase>();
    final equipmentProvider = context.read<EquipmentProvider>();

    // Load quivers
    final quivers = equipmentProvider.quivers;

    // Default to first quiver with shafts, or default quiver
    Quiver? selectedQuiver = equipmentProvider.defaultQuiver;
    if (selectedQuiver == null && quivers.isNotEmpty) {
      selectedQuiver = quivers.first;
    }

    // Load sessions for date filtering
    final sessions = await db.getAllSessions();

    setState(() {
      _quivers = quivers;
      _selectedQuiver = selectedQuiver;
      _sessions = sessions;
      _loading = false;
    });

    if (selectedQuiver != null) {
      await _loadQuiverData(selectedQuiver);
    }
  }

  Future<void> _loadQuiverData(Quiver quiver) async {
    final db = context.read<AppDatabase>();
    final equipmentProvider = context.read<EquipmentProvider>();

    // Get shafts for this quiver
    final shafts = equipmentProvider.getShaftsForQuiver(quiver.id);

    // Get all arrows for this quiver's shafts
    final shaftIds = shafts.map((s) => s.id).toSet();
    List<Arrow> allArrows = [];

    // Query arrows by session, then filter by shaft
    for (final session in _sessions) {
      if (session.quiverId != quiver.id) continue;

      // Apply date filter
      if (_dateRange != null) {
        if (session.startedAt.isBefore(_dateRange!.start) ||
            session.startedAt.isAfter(_dateRange!.end)) {
          continue;
        }
      }

      // Apply session filter
      if (_filterBySession && !_selectedSessionIds.contains(session.id)) {
        continue;
      }

      final sessionArrows = await db.getArrowsForSession(session.id);
      allArrows.addAll(
        sessionArrows.where((a) => a.shaftId != null && shaftIds.contains(a.shaftId)),
      );
    }

    // Analyze shafts
    final stats = ShaftComparison.analyzeShafts(
      shafts: shafts,
      allArrows: allArrows,
    );

    // Default: select all shafts with data
    final shaftsWithData = stats.where((s) => s.arrowCount >= 3).map((s) => s.shaft.id).toSet();

    setState(() {
      _shafts = shafts;
      _allArrows = allArrows;
      _shaftStats = stats;
      _selectedShaftIds = shaftsWithData;
    });

    _updateCombinedResult();
  }

  void _updateCombinedResult() {
    if (_selectedShaftIds.isEmpty) {
      setState(() => _combinedResult = null);
      return;
    }

    final selectedShafts =
        _shafts.where((s) => _selectedShaftIds.contains(s.id)).toList();

    final result = ShaftComparison.analyzeCombination(
      shafts: selectedShafts,
      allArrows: _allArrows,
    );

    setState(() => _combinedResult = result);
  }

  void _toggleShaft(String shaftId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedShaftIds.contains(shaftId)) {
        _selectedShaftIds.remove(shaftId);
      } else {
        _selectedShaftIds.add(shaftId);
      }
    });
    _updateCombinedResult();
  }

  Future<void> _findBestN(int n) async {
    HapticFeedback.mediumImpact();

    final result = ShaftComparison.findBestCombination(
      n: n,
      availableShafts: _shafts,
      allArrows: _allArrows,
    );

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough shafts with data for best $n',
            style: TextStyle(fontFamily: AppFonts.body),
          ),
          backgroundColor: AppColors.surfaceDark,
        ),
      );
      return;
    }

    setState(() {
      _selectedShaftIds = result.shafts.map((s) => s.id).toSet();
      _combinedResult = result;
    });
  }

  void _applyDatePreset(int index) async {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedPresetIndex = index;
      _filterBySession = false;
      _selectedSessionIds.clear();
    });

    final days = _datePresets[index].$2;
    if (days == 0) {
      _dateRange = null;
    } else {
      final now = DateTime.now();
      _dateRange = DateTimeRange(
        start: now.subtract(Duration(days: days)),
        end: now,
      );
    }

    if (_selectedQuiver != null) {
      await _loadQuiverData(_selectedQuiver!);
    }
  }

  void _toggleSessionFilter() {
    HapticFeedback.lightImpact();
    setState(() => _showSessionPicker = !_showSessionPicker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SHAFT COMPARISON',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSessionPicker ? Icons.close : Icons.filter_list,
              semanticLabel: 'Filter sessions',
            ),
            onPressed: _toggleSessionFilter,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_quivers.isEmpty) {
      return _buildEmptyState('No quivers found', 'Create a quiver in Equipment first.');
    }

    if (_selectedQuiver == null) {
      return _buildEmptyState('No quiver selected', 'Select a quiver to analyze.');
    }

    if (_shafts.isEmpty) {
      return _buildEmptyState('No shafts in quiver', 'Add shafts to this quiver first.');
    }

    if (_allArrows.isEmpty) {
      return _buildEmptyState(
        'No arrow data',
        'Shoot some arrows with shaft tagging enabled.',
      );
    }

    return Column(
      children: [
        // Filter bar
        _buildFilterBar(),

        // Session picker (expandable)
        if (_showSessionPicker) _buildSessionPicker(),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target visualization
                _buildTargetVisualization(),

                const SizedBox(height: AppSpacing.lg),

                // Stats summary
                _buildStatsSummary(),

                const SizedBox(height: AppSpacing.lg),

                // Shaft toggles
                _buildShaftToggles(),

                const SizedBox(height: AppSpacing.lg),

                // Best N buttons
                _buildBestNButtons(),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiver selector
          if (_quivers.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DropdownButton<Quiver>(
                value: _selectedQuiver,
                dropdownColor: AppColors.surfaceDark,
                underline: const SizedBox(),
                isExpanded: true,
                items: _quivers.map((q) {
                  return DropdownMenuItem(
                    value: q,
                    child: Text(
                      q.name,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (quiver) async {
                  if (quiver == null) return;
                  setState(() => _selectedQuiver = quiver);
                  await _loadQuiverData(quiver);
                },
              ),
            ),

          // Date presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _datePresets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _buildPresetChip(
                      _datePresets[i].$1,
                      selected: _selectedPresetIndex == i && !_filterBySession,
                      onTap: () => _applyDatePreset(i),
                    ),
                  ),
                _buildPresetChip(
                  'Sessions',
                  selected: _filterBySession,
                  onTap: _toggleSessionFilter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.surfaceLight,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: selected ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionPicker() {
    // Get sessions for selected quiver within date range
    final quiverSessions = _sessions.where((s) {
      if (s.quiverId != _selectedQuiver?.id) return false;
      if (_dateRange != null) {
        if (s.startedAt.isBefore(_dateRange!.start) ||
            s.startedAt.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();

    quiverSessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return Container(
      height: 200,
      color: AppColors.surfaceDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: quiverSessions.length,
        itemBuilder: (context, index) {
          final session = quiverSessions[index];
          final selected = _selectedSessionIds.contains(session.id);
          final date = session.startedAt;
          final dateStr = '${date.day}/${date.month}/${date.year}';

          return GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              setState(() {
                _filterBySession = true;
                if (selected) {
                  _selectedSessionIds.remove(session.id);
                } else {
                  _selectedSessionIds.add(session.id);
                }
              });
              if (_selectedQuiver != null) {
                await _loadQuiverData(_selectedQuiver!);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: selected ? AppColors.gold.withValues(alpha: 0.1) : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.gold : AppColors.surfaceLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 18,
                    color: selected ? AppColors.gold : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      session.sessionType,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetVisualization() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 350.0);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _ShaftComparisonTargetPainter(
                shaftStats: _shaftStats,
                selectedShaftIds: _selectedShaftIds,
                combinedResult: _combinedResult,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSummary() {
    if (_combinedResult == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Text(
          'Select shafts to see combined stats',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    final result = _combinedResult!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECTED: ${_selectedShaftIds.length} shafts, ${result.arrows.length} arrows',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 14,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStatRow('Group spread', '${result.groupSpreadMm.toStringAsFixed(1)}mm'),
          _buildStatRow('Avg deviation', '${result.avgDeviationMm.toStringAsFixed(1)}mm'),
          _buildStatRow(
            'Center offset',
            '${result.centerOffsetMm.toStringAsFixed(1)}mm @ ${result.centerOffsetClock} o\'clock',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShaftToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SHAFTS',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 14,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedShaftIds = _shaftStats
                          .where((s) => s.arrowCount >= 3)
                          .map((s) => s.shaft.id)
                          .toSet();
                    });
                    _updateCombinedResult();
                  },
                  child: Text(
                    'ALL',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedShaftIds.clear());
                    _updateCombinedResult();
                  },
                  child: Text(
                    'NONE',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _shaftStats.map((stats) {
            final selected = _selectedShaftIds.contains(stats.shaft.id);
            final hasData = stats.arrowCount >= 3;
            final color = _getShaftColor(stats.shaft.number);

            return GestureDetector(
              onTap: hasData ? () => _toggleShaft(stats.shaft.id) : null,
              child: Container(
                width: 72,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.2) : AppColors.surfaceDark,
                  border: Border.all(
                    color: selected ? color : (hasData ? AppColors.surfaceLight : AppColors.surfaceDark),
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: hasData ? 0.8 : 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '${stats.shaft.number}',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${stats.arrowCount}',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        color: hasData ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                    if (hasData)
                      Text(
                        '${stats.groupSpreadMm.toStringAsFixed(0)}mm',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 9,
                          color: AppColors.textMuted,
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

  Widget _buildBestNButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIND BEST',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 14,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final n in [6, 9, 12])
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ElevatedButton(
                  onPressed: () => _findBestN(n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: Text(
                    'BEST $n',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Get a distinct color for each shaft number
  Color _getShaftColor(int number) {
    const colors = [
      Color(0xFFE53935), // 1 - Red
      Color(0xFF1E88E5), // 2 - Blue
      Color(0xFF43A047), // 3 - Green
      Color(0xFFFFA726), // 4 - Orange
      Color(0xFF8E24AA), // 5 - Purple
      Color(0xFF00ACC1), // 6 - Cyan
      Color(0xFFD81B60), // 7 - Pink
      Color(0xFF7CB342), // 8 - Light green
      Color(0xFF5E35B1), // 9 - Deep purple
      Color(0xFF00897B), // 10 - Teal
      Color(0xFFF4511E), // 11 - Deep orange
      Color(0xFF3949AB), // 12 - Indigo
    ];
    return colors[(number - 1) % colors.length];
  }
}

/// Custom painter for the shaft comparison target
class _ShaftComparisonTargetPainter extends CustomPainter {
  final List<ShaftComparisonStats> shaftStats;
  final Set<String> selectedShaftIds;
  final ShaftCombinationResult? combinedResult;

  _ShaftComparisonTargetPainter({
    required this.shaftStats,
    required this.selectedShaftIds,
    required this.combinedResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw target rings
    _drawTargetRings(canvas, center, radius);

    // Draw arrows for selected shafts
    for (final stats in shaftStats) {
      if (!selectedShaftIds.contains(stats.shaft.id)) continue;

      final color = _getShaftColor(stats.shaft.number);

      // Draw each arrow
      for (final arrow in stats.arrows) {
        // Convert mm to pixels (assume ~300mm radius = full target)
        // We'll scale based on max visible range
        const maxRangeMm = 150.0; // Show up to 150mm from center
        final scale = radius / maxRangeMm;

        final x = center.dx + (arrow.xMm * scale);
        final y = center.dy + (arrow.yMm * scale);

        // Clamp to visible area
        if ((arrow.xMm.abs() > maxRangeMm) || (arrow.yMm.abs() > maxRangeMm)) {
          continue;
        }

        // Draw arrow marker
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), 4, paint);

        // Border
        final borderPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawCircle(Offset(x, y), 4, borderPaint);
      }

      // Draw group center marker
      const maxRangeMm = 150.0;
      final scale = radius / maxRangeMm;

      if (stats.centerXMm.abs() < maxRangeMm && stats.centerYMm.abs() < maxRangeMm) {
        final cx = center.dx + (stats.centerXMm * scale);
        final cy = center.dy + (stats.centerYMm * scale);

        // Draw crosshair at group center
        final centerPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawLine(
          Offset(cx - 8, cy),
          Offset(cx + 8, cy),
          centerPaint,
        );
        canvas.drawLine(
          Offset(cx, cy - 8),
          Offset(cx, cy + 8),
          centerPaint,
        );
      }
    }

    // Draw combined center if multiple shafts selected
    if (combinedResult != null && selectedShaftIds.length > 1) {
      const maxRangeMm = 150.0;
      final scale = radius / maxRangeMm;

      final cx = center.dx + (combinedResult!.centerXMm * scale);
      final cy = center.dy + (combinedResult!.centerYMm * scale);

      // Draw gold combined center
      final centerPaint = Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Draw larger crosshair
      canvas.drawLine(
        Offset(cx - 12, cy),
        Offset(cx + 12, cy),
        centerPaint,
      );
      canvas.drawLine(
        Offset(cx, cy - 12),
        Offset(cx, cy + 12),
        centerPaint,
      );

      // Draw circle around it
      canvas.drawCircle(Offset(cx, cy), 6, centerPaint);
    }
  }

  void _drawTargetRings(Canvas canvas, Offset center, double radius) {
    // Draw simplified target rings
    const ringColors = [
      AppColors.ring1, // Outer white
      AppColors.ring3, // Black
      AppColors.ring5, // Blue
      AppColors.ring7, // Red
      AppColors.ring9, // Gold
    ];

    const ringFractions = [1.0, 0.8, 0.6, 0.4, 0.2];

    for (int i = 0; i < ringColors.length; i++) {
      final paint = Paint()
        ..color = ringColors[i]
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius * ringFractions[i], paint);
    }

    // Draw ring lines
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final frac in ringFractions) {
      canvas.drawCircle(center, radius * frac, linePaint);
    }

    // Draw center cross
    final crossPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(center.dx - radius * 0.05, center.dy),
      Offset(center.dx + radius * 0.05, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.05),
      Offset(center.dx, center.dy + radius * 0.05),
      crossPaint,
    );
  }

  Color _getShaftColor(int number) {
    const colors = [
      Color(0xFFE53935), // 1 - Red
      Color(0xFF1E88E5), // 2 - Blue
      Color(0xFF43A047), // 3 - Green
      Color(0xFFFFA726), // 4 - Orange
      Color(0xFF8E24AA), // 5 - Purple
      Color(0xFF00ACC1), // 6 - Cyan
      Color(0xFFD81B60), // 7 - Pink
      Color(0xFF7CB342), // 8 - Light green
      Color(0xFF5E35B1), // 9 - Deep purple
      Color(0xFF00897B), // 10 - Teal
      Color(0xFFF4511E), // 11 - Deep orange
      Color(0xFF3949AB), // 12 - Indigo
    ];
    return colors[(number - 1) % colors.length];
  }

  @override
  bool shouldRepaint(covariant _ShaftComparisonTargetPainter oldDelegate) {
    return oldDelegate.selectedShaftIds != selectedShaftIds ||
        oldDelegate.combinedResult != combinedResult;
  }
}
