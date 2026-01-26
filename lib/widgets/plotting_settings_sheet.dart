import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Settings bottom sheet for plotting screen
class PlottingSettingsSheet extends StatelessWidget {
  final bool supportsTripleSpot;
  final bool useTripleSpot;
  final ValueChanged<bool> onTripleSpotChanged;
  final bool useCombinedView;
  final ValueChanged<bool> onCombinedViewChanged;
  final bool compoundScoring;
  final ValueChanged<bool> onCompoundScoringChanged;
  final double confidenceMultiplier;
  final VoidCallback onToggleConfidence;
  final bool showRingNotation;
  final VoidCallback onToggleRingNotation;
  final bool? shaftTaggingEnabled;
  final ValueChanged<bool>? onShaftTaggingChanged;
  final bool autoAdvanceEnabled;
  final ValueChanged<bool> onAutoAdvanceChanged;
  final String autoAdvanceOrder;
  final ValueChanged<String> onAutoAdvanceOrderChanged;

  // Timer settings
  final bool timerEnabled;
  final ValueChanged<bool> onTimerEnabledChanged;
  final int timerDuration;
  final ValueChanged<int> onTimerDurationChanged;
  final int timerLeadIn;
  final ValueChanged<int> onTimerLeadInChanged;

  // Zoom window settings
  final bool zoomWindowEnabled;
  final ValueChanged<bool> onZoomWindowEnabledChanged;

  // Line cutter prompt settings
  final bool lineCutterEnabled;
  final ValueChanged<bool> onLineCutterEnabledChanged;

  // Arrow marker size settings
  final double arrowMarkerSize;
  final ValueChanged<double> onArrowMarkerSizeChanged;

  const PlottingSettingsSheet({
    super.key,
    required this.supportsTripleSpot,
    required this.useTripleSpot,
    required this.onTripleSpotChanged,
    required this.useCombinedView,
    required this.onCombinedViewChanged,
    required this.compoundScoring,
    required this.onCompoundScoringChanged,
    required this.confidenceMultiplier,
    required this.onToggleConfidence,
    required this.showRingNotation,
    required this.onToggleRingNotation,
    this.shaftTaggingEnabled,
    this.onShaftTaggingChanged,
    required this.autoAdvanceEnabled,
    required this.onAutoAdvanceChanged,
    required this.autoAdvanceOrder,
    required this.onAutoAdvanceOrderChanged,
    required this.timerEnabled,
    required this.onTimerEnabledChanged,
    required this.timerDuration,
    required this.onTimerDurationChanged,
    required this.timerLeadIn,
    required this.onTimerLeadInChanged,
    required this.zoomWindowEnabled,
    required this.onZoomWindowEnabledChanged,
    required this.lineCutterEnabled,
    required this.onLineCutterEnabledChanged,
    required this.arrowMarkerSize,
    required this.onArrowMarkerSizeChanged,
  });

  // Helper to convert timer duration to selector index
  static int _durationToIndex(int duration) {
    switch (duration) {
      case 90:
        return 0;
      case 120:
        return 1;
      case 180:
        return 2;
      case 240:
        return 3;
      default:
        return 1; // Default to 120s
    }
  }

  // Helper to convert selector index to timer duration
  static int _indexToDuration(int index) {
    switch (index) {
      case 0:
        return 90;
      case 1:
        return 120;
      case 2:
        return 180;
      case 3:
        return 240;
      default:
        return 120;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pixel-style handle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    color: AppColors.gold.withValues(alpha: 0.4),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'PLOTTING SETTINGS',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Target Face (indoor only)
              if (supportsTripleSpot) ...[
                _SettingsRow(
                  label: 'Target Face',
                  child: _SegmentedToggle(
                    options: const ['Single', 'Triple'],
                    selectedIndex: useTripleSpot ? 1 : 0,
                    onChanged: (index) => onTripleSpotChanged(index == 1),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Scoring Mode
              _SettingsRow(
                label: 'Scoring',
                child: _SegmentedToggle(
                  options: const ['Recurve', 'Compound'],
                  selectedIndex: compoundScoring ? 1 : 0,
                  onChanged: (index) => onCompoundScoringChanged(index == 1),
                ),
              ),
              const SizedBox(height: 12),

              // View Mode (only when triple spot)
              if (supportsTripleSpot && useTripleSpot) ...[
                _SettingsRow(
                  label: 'View Mode',
                  child: _SegmentedToggle(
                    options: const ['Separate', 'Combined'],
                    selectedIndex: useCombinedView ? 1 : 0,
                    onChanged: (index) => onCombinedViewChanged(index == 1),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Arrow Tracking (only if quiver selected)
              if (shaftTaggingEnabled != null && onShaftTaggingChanged != null) ...[
                _SettingsRow(
                  label: 'Arrow Tracking',
                  child: _SegmentedToggle(
                    options: const ['Off', 'On'],
                    selectedIndex: shaftTaggingEnabled! ? 1 : 0,
                    onChanged: (index) => onShaftTaggingChanged!(index == 1),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Confidence Interval
              _SettingsRow(
                label: 'Confidence',
                child: _SegmentedToggle(
                  options: const ['67%', '95%'],
                  selectedIndex: confidenceMultiplier == 1.0 ? 0 : 1,
                  onChanged: (_) => onToggleConfidence(),
                ),
              ),
              const SizedBox(height: 12),

              // Ring Notation
              _SettingsRow(
                label: 'Ring Notation',
                child: _SegmentedToggle(
                  options: const ['Hide', 'Show'],
                  selectedIndex: showRingNotation ? 1 : 0,
                  onChanged: (_) => onToggleRingNotation(),
                ),
              ),
              const SizedBox(height: 12),

              // Zoom Window
              _SettingsRow(
                label: 'Zoom Window',
                child: _SegmentedToggle(
                  options: const ['Off', 'On'],
                  selectedIndex: zoomWindowEnabled ? 1 : 0,
                  onChanged: (index) => onZoomWindowEnabledChanged(index == 1),
                ),
              ),
              const SizedBox(height: 12),

              // Line Cutter Prompt
              _SettingsRow(
                label: 'Line Cutter',
                child: _SegmentedToggle(
                  options: const ['Off', 'On'],
                  selectedIndex: lineCutterEnabled ? 1 : 0,
                  onChanged: (index) => onLineCutterEnabledChanged(index == 1),
                ),
              ),
              const SizedBox(height: 12),

              // Arrow Marker Size
              _ArrowSizeSlider(
                value: arrowMarkerSize,
                onChanged: onArrowMarkerSizeChanged,
              ),

              // Auto-advance settings (triple spot only)
              if (supportsTripleSpot && useTripleSpot && !useCombinedView) ...[
                const SizedBox(height: 12),
                _SettingsRow(
                  label: 'Auto-Advance',
                  child: _SegmentedToggle(
                    options: const ['Off', 'On'],
                    selectedIndex: autoAdvanceEnabled ? 1 : 0,
                    onChanged: (index) => onAutoAdvanceChanged(index == 1),
                  ),
                ),
                if (autoAdvanceEnabled) ...[
                  const SizedBox(height: 12),
                  _ShootingOrderSelector(
                    currentOrder: autoAdvanceOrder,
                    onOrderChanged: onAutoAdvanceOrderChanged,
                  ),
                ],
              ],

              // Timer section divider
              const SizedBox(height: 16),
              Container(height: 1, color: AppColors.surfaceLight),
              const SizedBox(height: 16),

              // Timer settings
              _SettingsRow(
                label: 'Timer',
                child: _SegmentedToggle(
                  options: const ['Off', 'On'],
                  selectedIndex: timerEnabled ? 1 : 0,
                  onChanged: (index) => onTimerEnabledChanged(index == 1),
                ),
              ),
              if (timerEnabled) ...[
                const SizedBox(height: 12),
                _SettingsRow(
                  label: 'Duration',
                  child: _SegmentedToggle(
                    options: const ['90s', '120s', '180s', '240s'],
                    selectedIndex: _durationToIndex(timerDuration),
                    onChanged: (index) => onTimerDurationChanged(_indexToDuration(index)),
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsRow(
                  label: 'Lead-in',
                  child: _SegmentedToggle(
                    options: const ['10s', '15s'],
                    selectedIndex: timerLeadIn == 15 ? 1 : 0,
                    onChanged: (index) => onTimerLeadInChanged(index == 0 ? 10 : 15),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        child,
      ],
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedToggle({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = index == selectedIndex;
          final isLast = index == options.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => onChanged(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 12,
                      color: isSelected ? AppColors.gold : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(width: 1, height: 32, color: AppColors.surfaceLight),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Slider for adjusting arrow marker size
class _ArrowSizeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ArrowSizeSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Convert multiplier to display label
    String sizeLabel;
    if (value <= 0.6) {
      sizeLabel = 'XS';
    } else if (value <= 0.85) {
      sizeLabel = 'S';
    } else if (value <= 1.15) {
      sizeLabel = 'M';
    } else if (value <= 1.5) {
      sizeLabel = 'L';
    } else {
      sizeLabel = 'XL';
    }

    return Row(
      children: [
        Text(
          'Arrow Size',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0.5,
              max: 2.0,
              divisions: 6, // 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          alignment: Alignment.center,
          child: Text(
            sizeLabel,
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 14,
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tap-to-define shooting order selector for triple spot targets.
/// User taps the 3 target icons in the order they want to shoot them.
class _ShootingOrderSelector extends StatefulWidget {
  final String currentOrder;
  final ValueChanged<String> onOrderChanged;

  const _ShootingOrderSelector({
    required this.currentOrder,
    required this.onOrderChanged,
  });

  @override
  State<_ShootingOrderSelector> createState() => _ShootingOrderSelectorState();
}

class _ShootingOrderSelectorState extends State<_ShootingOrderSelector> {
  // Track taps during order definition
  List<int> _tapSequence = [];
  bool _isDefiningOrder = false;

  // Parse current order to list [0,1,2] or [0,2,1] etc.
  List<int> get _currentOrderList {
    if (widget.currentOrder == 'triangular') return [0, 2, 1];
    if (widget.currentOrder == 'column') return [0, 1, 2];
    // Custom order format: "0,1,2" or "0,2,1" etc.
    if (widget.currentOrder.contains(',')) {
      return widget.currentOrder.split(',').map((s) => int.tryParse(s.trim()) ?? 0).toList();
    }
    return [0, 1, 2]; // Default
  }

  void _startDefiningOrder() {
    setState(() {
      _isDefiningOrder = true;
      _tapSequence = [];
    });
  }

  void _onFaceTapped(int faceIndex) {
    if (!_isDefiningOrder) return;
    if (_tapSequence.contains(faceIndex)) return; // Already tapped

    setState(() {
      _tapSequence.add(faceIndex);
    });

    // If all 3 tapped, save the order
    if (_tapSequence.length == 3) {
      // Convert to order string
      String orderString;
      if (_tapSequence[0] == 0 && _tapSequence[1] == 1 && _tapSequence[2] == 2) {
        orderString = 'column';
      } else if (_tapSequence[0] == 0 && _tapSequence[1] == 2 && _tapSequence[2] == 1) {
        orderString = 'triangular';
      } else {
        // Custom order
        orderString = _tapSequence.join(',');
      }
      widget.onOrderChanged(orderString);
      setState(() {
        _isDefiningOrder = false;
        _tapSequence = [];
      });
    }
  }

  void _cancelDefining() {
    setState(() {
      _isDefiningOrder = false;
      _tapSequence = [];
    });
  }

  // Get display order for a face (1st, 2nd, 3rd) based on current order
  int? _getOrderPosition(int faceIndex) {
    final order = _isDefiningOrder ? _tapSequence : _currentOrderList;
    final position = order.indexOf(faceIndex);
    return position >= 0 ? position + 1 : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Shooting Order',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (!_isDefiningOrder)
              GestureDetector(
                onTap: _startDefiningOrder,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TAP TO SET',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 10,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            if (_isDefiningOrder)
              GestureDetector(
                onTap: _cancelDefining,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textMuted),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // 3 target face icons arranged vertically (like actual triple spot)
        Center(
          child: Column(
            children: [
              if (_isDefiningOrder)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Tap faces in shooting order',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Face 1 (top)
                  _buildFaceIcon(0),
                  const SizedBox(width: 16),
                  // Face 2 (middle)
                  _buildFaceIcon(1),
                  const SizedBox(width: 16),
                  // Face 3 (bottom)
                  _buildFaceIcon(2),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaceIcon(int faceIndex) {
    final orderPosition = _getOrderPosition(faceIndex);
    final isSelected = _isDefiningOrder && _tapSequence.contains(faceIndex);
    final isNextToTap = _isDefiningOrder && !_tapSequence.contains(faceIndex);

    return GestureDetector(
      onTap: isNextToTap ? () => _onFaceTapped(faceIndex) : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.3)
              : AppColors.surfaceLight,
          border: Border.all(
            color: isNextToTap
                ? AppColors.gold
                : isSelected
                    ? AppColors.gold
                    : AppColors.surfaceLight,
            width: isNextToTap ? 2 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${faceIndex + 1}',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 14,
                  color: isSelected || orderPosition != null
                      ? AppColors.gold
                      : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (orderPosition != null)
                Text(
                  _getOrdinal(orderPosition),
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    color: AppColors.gold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getOrdinal(int n) {
    switch (n) {
      case 1: return '1st';
      case 2: return '2nd';
      case 3: return '3rd';
      default: return '${n}th';
    }
  }
}
