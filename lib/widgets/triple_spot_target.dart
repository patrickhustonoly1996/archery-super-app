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

  const TripleSpotTarget({
    super.key,
    required this.arrows,
    this.size = 300,
    this.selectedFace,
    this.onFaceSelected,
    this.showFaceLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate individual face size (3 faces with small gaps)
    final faceSize = (size - 16) / 3; // 8px gap between faces

    return SizedBox(
      width: size,
      height: faceSize + (showFaceLabels ? 24 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFace(0, faceSize),
              const SizedBox(width: 8),
              _buildFace(1, faceSize),
              const SizedBox(width: 8),
              _buildFace(2, faceSize),
            ],
          ),
          if (showFaceLabels) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLabel(0, faceSize),
                const SizedBox(width: 8),
                _buildLabel(1, faceSize),
                const SizedBox(width: 8),
                _buildLabel(2, faceSize),
              ],
            ),
          ],
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

  const InteractiveTripleSpotTarget({
    super.key,
    required this.arrows,
    required this.onArrowPlotted,
    this.size = 300,
    this.enabled = true,
    this.isLeftHanded = false,
  });

  @override
  State<InteractiveTripleSpotTarget> createState() =>
      _InteractiveTripleSpotTargetState();
}

class _InteractiveTripleSpotTargetState
    extends State<InteractiveTripleSpotTarget> {
  int _selectedFace = 0;

  @override
  Widget build(BuildContext context) {
    final faceSize = (widget.size - 16) / 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Face selector row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInteractiveFace(0, faceSize),
            const SizedBox(width: 8),
            _buildInteractiveFace(1, faceSize),
            const SizedBox(width: 8),
            _buildInteractiveFace(2, faceSize),
          ],
        ),
        const SizedBox(height: 8),
        // Face labels with arrow counts
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFaceLabel(0, faceSize),
            const SizedBox(width: 8),
            _buildFaceLabel(1, faceSize),
            const SizedBox(width: 8),
            _buildFaceLabel(2, faceSize),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractiveFace(int faceIndex, double faceSize) {
    final faceArrows =
        widget.arrows.where((a) => a.faceIndex == faceIndex).toList();
    final isSelected = _selectedFace == faceIndex;
    final hasArrow = faceArrows.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFace = faceIndex);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : (hasArrow ? AppColors.gold.withOpacity(0.3) : AppColors.surfaceLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: InteractiveTargetFace(
          arrows: faceArrows,
          size: faceSize,
          enabled: widget.enabled && isSelected,
          isIndoor: true,
          triSpot: true,
          isLeftHanded: widget.isLeftHanded,
          onArrowPlotted: (x, y) {
            widget.onArrowPlotted(x, y, faceIndex);
          },
        ),
      ),
    );
  }

  Widget _buildFaceLabel(int faceIndex, double faceSize) {
    final faceArrows =
        widget.arrows.where((a) => a.faceIndex == faceIndex).toList();
    final isSelected = _selectedFace == faceIndex;
    final hasArrow = faceArrows.isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() => _selectedFace = faceIndex),
      child: Container(
        width: faceSize,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(
              'SPOT ${faceIndex + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 12,
                color: isSelected ? AppColors.gold : AppColors.textMuted,
              ),
            ),
            if (hasArrow)
              Text(
                '${faceArrows.map((a) => a.score).reduce((a, b) => a + b)}',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 10,
                  color: AppColors.gold,
                ),
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

  const CombinedTripleSpotView({
    super.key,
    required this.arrows,
    this.size = 300,
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
