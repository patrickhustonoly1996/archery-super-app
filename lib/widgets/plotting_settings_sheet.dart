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
                  _SettingsRow(
                    label: 'Advance Order',
                    child: _SegmentedToggle(
                      options: const ['1-2-3', '1-3-2'],
                      selectedIndex: autoAdvanceOrder == 'triangular' ? 1 : 0,
                      onChanged: (index) => onAutoAdvanceOrderChanged(
                        index == 0 ? 'column' : 'triangular',
                      ),
                    ),
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
