import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Sidebar showing 3 miniature targets for face tracking in single-view mode.
/// Displays current face with green halo and arrow count per face.
class FaceIndicatorSidebar extends StatelessWidget {
  /// Currently selected face (0, 1, or 2)
  final int currentFace;
  /// Number of arrows on each face [face0, face1, face2]
  final List<int> arrowCounts;
  /// Layout style: 'column' or 'triangular'
  final String layoutStyle;
  /// Callback when user taps a face to select it
  final ValueChanged<int>? onFaceSelected;
  /// Size of each miniature target
  final double faceSize;

  const FaceIndicatorSidebar({
    super.key,
    required this.currentFace,
    required this.arrowCounts,
    this.layoutStyle = 'column',
    this.onFaceSelected,
    this.faceSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    // Always show 3 faces in a vertical column
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFaceIndicator(0),
        const SizedBox(height: 4),
        _buildFaceIndicator(1),
        const SizedBox(height: 4),
        _buildFaceIndicator(2),
      ],
    );
  }

  Widget _buildFaceIndicator(int faceIndex) {
    final isSelected = currentFace == faceIndex;
    final arrowCount = faceIndex < arrowCounts.length ? arrowCounts[faceIndex] : 0;

    return GestureDetector(
      onTap: onFaceSelected != null ? () => onFaceSelected!(faceIndex) : null,
      child: Container(
        width: faceSize,
        height: faceSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Miniature target rings (simplified)
            Center(
              child: _MiniatureTarget(
                size: faceSize - 4,
                arrowCount: arrowCount,
              ),
            ),
            // Face number badge
            Positioned(
              left: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : AppColors.surfaceDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${faceIndex + 1}',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 9,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            // Arrow count badge (if any arrows)
            if (arrowCount > 0)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '$arrowCount',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 9,
                      color: AppColors.surfaceDark,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Simplified miniature target showing concentric rings
class _MiniatureTarget extends StatelessWidget {
  final double size;
  final int arrowCount;

  const _MiniatureTarget({
    required this.size,
    required this.arrowCount,
  });

  @override
  Widget build(BuildContext context) {
    // Simplified tri-spot style rings (5 rings for 6-10)
    return CustomPaint(
      size: Size(size, size),
      painter: _MiniTargetPainter(),
    );
  }
}

class _MiniTargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ring colors from outer to inner (6-10 for tri-spot)
    final colors = [
      const Color(0xFF2196F3), // 6 - Blue
      const Color(0xFF2196F3), // 7 - Blue
      const Color(0xFFFF5555), // 8 - Red
      const Color(0xFFFF5555), // 9 - Red
      AppColors.gold, // 10 - Gold
    ];

    // Draw rings from outer to inner
    for (var i = 0; i < 5; i++) {
      final ringRadius = radius * (1 - i * 0.2);
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, ringRadius, paint);

      // Ring border
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(center, ringRadius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact face layout toggle buttons for the plotting screen
/// Single = 1 target with face tracking sidebar
/// Vertical = 3 targets stacked
/// Triangular = 3 targets in triangle (WA 18m only)
class FaceLayoutToggle extends StatelessWidget {
  /// Currently selected layout: 'single', 'vertical', 'triangular'
  final String currentLayout;
  /// Whether triangular layout is supported (WA 18m only)
  final bool triangularSupported;
  /// Callback when layout is changed
  final ValueChanged<String> onLayoutChanged;

  const FaceLayoutToggle({
    super.key,
    required this.currentLayout,
    this.triangularSupported = false,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single face (1 target with face tracking)
          _buildLayoutButton(
            layout: 'single',
            icon: Icons.crop_square,
            label: '1',
            tooltip: 'Single target (track faces via sidebar)',
          ),
          const SizedBox(height: 4),
          // Vertical triple (3 targets stacked)
          _buildLayoutButton(
            layout: 'vertical',
            icon: Icons.view_agenda_outlined,
            label: '3',
            tooltip: 'Triple spot (3 targets)',
          ),
          // Triangular button (only if supported - WA 18m)
          if (triangularSupported) ...[
            const SizedBox(height: 4),
            _buildLayoutButton(
              layout: 'triangular',
              icon: Icons.change_history,
              label: null,
              tooltip: 'Triangle layout (WA 18m)',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayoutButton({
    required String layout,
    required IconData icon,
    String? label,
    required String tooltip,
  }) {
    final isSelected = currentLayout == layout;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onLayoutChanged(layout),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.gold.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: label != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected ? AppColors.gold : AppColors.textMuted,
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppFonts.pixel,
                          fontSize: 10,
                          color: isSelected ? AppColors.gold : AppColors.textMuted,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    icon,
                    size: 16,
                    color: isSelected ? AppColors.gold : AppColors.textMuted,
                  ),
          ),
        ),
      ),
    );
  }
}

