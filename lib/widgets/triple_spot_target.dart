import 'package:flutter/material.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import 'target_face.dart';

/// Display mode for triple spot targets
enum TripleSpotDisplayMode {
  /// Show all 3 faces side by side (default for plotting)
  threeFaces,
  /// Show combined view with all arrows on single target
  combined,
}

/// A triple spot target face showing 3 vertical targets for indoor rounds.
/// Each face shows only rings 6-10 (the "spot") as per WA indoor rules.
///
/// The triple spot significantly changes the size of the 10 ring:
/// - Single 40cm face: 10 ring is 4cm diameter (inner 2cm radius)
/// - Triple spot: each spot's 10 ring fills the same visual space but
///   represents only 1/3 of the scoring area
class TripleSpotTarget extends StatelessWidget {
  final List<Arrow> arrows;
  final double size;
  final int? selectedFace;
  final ValueChanged<int>? onFaceSelected;
  final bool showFaceLabels;
  final bool compoundScoring;

  const TripleSpotTarget({
    super.key,
    required this.arrows,
    this.size = 300,
    this.selectedFace,
    this.onFaceSelected,
    this.showFaceLabels = true,
    this.compoundScoring = false,
  });

  @override
  Widget build(BuildContext context) {
    // Triple spot arranged vertically (stacked) as per Portsmouth rules
    // Account for 8px gaps (x2) + 2px border on each side (x6)
    final faceSize = (size - 28) / 3;

    return SizedBox(
      width: faceSize + 4, // Single face width + border
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFace(0, faceSize),
          const SizedBox(height: 8),
          _buildFace(1, faceSize),
          const SizedBox(height: 8),
          _buildFace(2, faceSize),
        ],
      ),
    );
  }

  Widget _buildFace(int faceIndex, double faceSize) {
    final faceArrows = arrows.where((a) => a.faceIndex == faceIndex).toList();
    final isSelected = selectedFace == faceIndex;

    return GestureDetector(
      onTap: onFaceSelected != null ? () => onFaceSelected!(faceIndex) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: TargetFace(
          arrows: faceArrows,
          size: faceSize,
          triSpot: true, // Always tri-spot mode (rings 6-10 only)
          compoundScoring: compoundScoring,
        ),
      ),
    );
  }

  Widget _buildLabel(int faceIndex, double faceSize) {
    final faceArrows = arrows.where((a) => a.faceIndex == faceIndex).toList();
    final hasArrow = faceArrows.isNotEmpty;
    final isSelected = selectedFace == faceIndex;

    return SizedBox(
      width: faceSize,
      child: Text(
        '${faceIndex + 1}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 14,
          color: hasArrow
              ? AppColors.gold
              : (isSelected ? AppColors.gold : AppColors.textMuted),
        ),
      ),
    );
  }
}

/// Interactive triple spot target for plotting arrows.
/// Shows 3 faces and allows tapping to select which face to plot on.
class InteractiveTripleSpotTarget extends StatefulWidget {
  final List<Arrow> arrows;
  final double size;
  final Function(double x, double y, int faceIndex) onArrowPlotted;
  final bool enabled;
  final bool isLeftHanded;
  final bool compoundScoring;
  /// Enable auto-advance to next face after plotting
  final bool autoAdvance;
  /// Advance order: 'column' (0→1→2→0) or 'triangular' (0→2→1→0)
  final String advanceOrder;

  const InteractiveTripleSpotTarget({
    super.key,
    required this.arrows,
    required this.onArrowPlotted,
    this.size = 300,
    this.enabled = true,
    this.isLeftHanded = false,
    this.compoundScoring = false,
    this.autoAdvance = false,
    this.advanceOrder = 'column',
  });

  @override
  State<InteractiveTripleSpotTarget> createState() =>
      _InteractiveTripleSpotTargetState();
}

class _InteractiveTripleSpotTargetState
    extends State<InteractiveTripleSpotTarget> {
  int _selectedFace = 0;

  /// Calculate next face based on advance order
  int _getNextFace(int current) {
    if (widget.advanceOrder == 'triangular') {
      // Triangular: 0→2, 1→0, 2→1 (top, bottom, middle)
      const order = [2, 0, 1];
      return order[current];
    }
    // Column: 0→1→2→0 (top to bottom)
    return (current + 1) % 3;
  }

  void _onArrowPlotted(double x, double y, int faceIndex) {
    widget.onArrowPlotted(x, y, faceIndex);
    if (widget.autoAdvance) {
      setState(() => _selectedFace = _getNextFace(faceIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Focused layout: selected face is large, others are small selectors
    // Main face gets ~70% of available size, selectors split the rest
    final mainFaceSize = widget.size * 0.75;
    final selectorSize = (widget.size - mainFaceSize - 24) / 3; // 24 = gaps

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Face selectors on the left (small thumbnails)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFaceSelector(0, selectorSize),
            const SizedBox(height: 8),
            _buildFaceSelector(1, selectorSize),
            const SizedBox(height: 8),
            _buildFaceSelector(2, selectorSize),
          ],
        ),
        const SizedBox(width: 8),
        // Main interactive face (large, selected)
        _buildMainFace(_selectedFace, mainFaceSize),
      ],
    );
  }

  /// Build the main interactive face (large, for plotting)
  Widget _buildMainFace(int faceIndex, double faceSize) {
    final faceArrows =
        widget.arrows.where((a) => a.faceIndex == faceIndex).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.gold,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: InteractiveTargetFace(
        arrows: faceArrows,
        size: faceSize,
        enabled: widget.enabled,
        isIndoor: true,
        triSpot: true,
        isLeftHanded: widget.isLeftHanded,
        compoundScoring: widget.compoundScoring,
        onArrowPlotted: (x, y) {
          _onArrowPlotted(x, y, faceIndex);
        },
      ),
    );
  }

  /// Build a small face selector (thumbnail with score)
  Widget _buildFaceSelector(int faceIndex, double selectorSize) {
    final faceArrows =
        widget.arrows.where((a) => a.faceIndex == faceIndex).toList();
    final isSelected = _selectedFace == faceIndex;
    final hasArrow = faceArrows.isNotEmpty;
    final score = hasArrow
        ? faceArrows.map((a) => a.score).reduce((a, b) => a + b)
        : 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedFace = faceIndex),
      child: Container(
        width: selectorSize + 24, // Extra width for label
        height: selectorSize + 4,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : (hasArrow ? AppColors.gold.withOpacity(0.3) : AppColors.surfaceLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Small target preview
            TargetFace(
              arrows: faceArrows,
              size: selectorSize,
              triSpot: true,
              compoundScoring: widget.compoundScoring,
            ),
            const SizedBox(width: 4),
            // Face number and score
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${faceIndex + 1}',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 14,
                    color: isSelected ? AppColors.gold : AppColors.textMuted,
                  ),
                ),
                if (hasArrow)
                  Text(
                    '$score',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.gold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle button for switching between triple spot and single face view
class TripleSpotToggle extends StatelessWidget {
  final bool isTripleSpot;
  final ValueChanged<bool> onChanged;

  const TripleSpotToggle({
    super.key,
    required this.isTripleSpot,
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
        children: [
          _buildOption(
            label: '1',
            icon: Icons.crop_square,
            isSelected: !isTripleSpot,
            onTap: () => onChanged(false),
          ),
          Container(width: 1, height: 32, color: AppColors.surfaceLight),
          _buildOption(
            label: '3',
            icon: Icons.view_column,
            isSelected: isTripleSpot,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.2) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 14,
                color: isSelected ? AppColors.gold : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Combined view showing all arrows from 3 faces on a single target
class CombinedTripleSpotView extends StatelessWidget {
  final List<Arrow> arrows;
  final double size;
  final bool compoundScoring;

  const CombinedTripleSpotView({
    super.key,
    required this.arrows,
    this.size = 300,
    this.compoundScoring = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show all arrows on a single tri-spot face (rings 6-10 only)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TargetFace(
          arrows: arrows,
          size: size,
          triSpot: true,
          compoundScoring: compoundScoring,
        ),
        const SizedBox(height: 8),
        // Show face breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFaceSummary(0),
            const SizedBox(width: 16),
            _buildFaceSummary(1),
            const SizedBox(width: 16),
            _buildFaceSummary(2),
          ],
        ),
      ],
    );
  }

  Widget _buildFaceSummary(int faceIndex) {
    final faceArrows = arrows.where((a) => a.faceIndex == faceIndex).toList();
    final score = faceArrows.isEmpty
        ? 0
        : faceArrows.map((a) => a.score).reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: faceArrows.isNotEmpty ? AppColors.gold : AppColors.surfaceLight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            '${faceIndex + 1}',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: faceArrows.isNotEmpty ? AppColors.gold : AppColors.textMuted,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: faceArrows.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
