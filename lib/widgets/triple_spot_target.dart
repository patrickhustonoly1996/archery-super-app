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
    // Show ALL arrows on every face for visual grouping
    // (arrows retain their faceIndex internally for scoring)
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
          arrows: arrows,
          size: faceSize,
          triSpot: true, // Always tri-spot mode (rings 6-10 only)
          compoundScoring: compoundScoring,
        ),
      ),
    );
  }

}

/// Interactive triple spot target for plotting arrows.
/// Shows all 3 faces side-by-side at equal sizes so arrows remain visible
/// across all faces. Tap a face to select it for plotting.
///
/// Can be used as controlled (provide selectedFace + onFaceChanged) or
/// uncontrolled (internal state manages selection).
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
  /// Optional: controlled face selection (survives parent rebuilds)
  final int? selectedFace;
  /// Optional: callback when face selection changes
  final ValueChanged<int>? onFaceChanged;
  /// Callback for pending arrow position (for fixed zoom window)
  final Function(double? x, double? y)? onPendingArrowChanged;

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
    this.selectedFace,
    this.onFaceChanged,
    this.onPendingArrowChanged,
  });

  @override
  State<InteractiveTripleSpotTarget> createState() =>
      _InteractiveTripleSpotTargetState();
}

class _InteractiveTripleSpotTargetState
    extends State<InteractiveTripleSpotTarget> {
  int _internalSelectedFace = 0;

  /// Get current selected face (controlled or internal)
  int get _selectedFace => widget.selectedFace ?? _internalSelectedFace;

  /// Update face selection
  void _setSelectedFace(int face) {
    if (widget.selectedFace != null) {
      // Controlled mode - notify parent
      widget.onFaceChanged?.call(face);
    } else {
      // Uncontrolled mode - update internal state
      setState(() => _internalSelectedFace = face);
    }
  }

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
      _setSelectedFace(_getNextFace(faceIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    // All 3 faces shown at equal size, stacked vertically
    // Budget: 3 faces + 2 gaps (8px each) = widget.size
    // faceSize includes the border, which is painted inside the container
    final faceSize = (widget.size - 16) / 3;

    return SizedBox(
      width: faceSize,
      height: widget.size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInteractiveFace(0, faceSize),
          const SizedBox(height: 8),
          _buildInteractiveFace(1, faceSize),
          const SizedBox(height: 8),
          _buildInteractiveFace(2, faceSize),
        ],
      ),
    );
  }

  /// Build an interactive face that shows all arrows and allows plotting
  Widget _buildInteractiveFace(int faceIndex, double faceSize) {
    // Show ALL arrows on every face for visual grouping
    // (arrows retain their faceIndex internally for scoring)
    final isSelected = _selectedFace == faceIndex;

    // Calculate the inner target size (face - border on each side)
    final borderWidth = isSelected ? 2.0 : 1.0;
    final innerSize = faceSize - borderWidth * 2;

    return GestureDetector(
      // Tap anywhere on the face to select it (if not already selected)
      onTap: !isSelected ? () => _setSelectedFace(faceIndex) : null,
      child: Container(
        width: faceSize,
        height: faceSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // The target face - interactive only when selected
            InteractiveTargetFace(
              arrows: widget.arrows,
              size: innerSize,
              enabled: widget.enabled && isSelected,
              isIndoor: true,
              triSpot: true,
              isLeftHanded: widget.isLeftHanded,
              compoundScoring: widget.compoundScoring,
              onArrowPlotted: (x, y) {
                _onArrowPlotted(x, y, faceIndex);
              },
              onPendingArrowChanged: widget.onPendingArrowChanged,
            ),
            // Face number indicator in corner
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.surfaceDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${faceIndex + 1}',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 12,
                    color: isSelected ? AppColors.surfaceDark : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            // Overlay to capture taps when not selected
            if (!isSelected)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
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
          color: isSelected ? AppColors.gold.withValues(alpha: 0.2) : Colors.transparent,
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
