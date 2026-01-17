import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/auto_plot_provider.dart';
import '../services/vision_api_service.dart';

/// Screen to review and adjust detected arrow positions
class AutoPlotConfirmScreen extends StatefulWidget {
  final String targetType;
  final bool isTripleSpot;

  const AutoPlotConfirmScreen({
    super.key,
    required this.targetType,
    this.isTripleSpot = false,
  });

  @override
  State<AutoPlotConfirmScreen> createState() => _AutoPlotConfirmScreenState();
}

class _AutoPlotConfirmScreenState extends State<AutoPlotConfirmScreen> {
  int? _selectedArrowIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'CONFIRM ARROWS',
          style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            context.read<AutoPlotProvider>().retryCapture();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AutoPlotProvider>().retryCapture();
              Navigator.of(context).pop();
            },
            child: Text(
              'RETRY',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AutoPlotProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                color: AppColors.surfaceDark,
                child: Text(
                  'Tap an arrow to select. Drag to adjust. Tap empty space to add.',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Target visualization with arrows
              Expanded(
                child: _buildTargetView(provider),
              ),
              // Arrow count and controls
              _buildControls(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTargetView(AutoPlotProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final padding = 16.0;
        final targetSize = size - padding * 2;

        return Center(
          child: GestureDetector(
            onTapUp: (details) {
              _handleTap(details.localPosition, targetSize, padding, provider);
            },
            child: Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(padding),
              child: Stack(
                children: [
                  // Target face
                  _buildTargetFace(targetSize),
                  // Detected arrows
                  ...provider.detectedArrows.asMap().entries.map((entry) {
                    return _buildArrowMarker(
                      entry.key,
                      entry.value,
                      targetSize,
                      provider,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTargetFace(double size) {
    // Standard 10-ring target
    return CustomPaint(
      size: Size(size, size),
      painter: _TargetPainter(),
    );
  }

  Widget _buildArrowMarker(
    int index,
    DetectedArrow arrow,
    double targetSize,
    AutoPlotProvider provider,
  ) {
    final isSelected = _selectedArrowIndex == index;
    final markerSize = isSelected ? 24.0 : 18.0;

    // Convert normalized coordinates (-1 to 1) to pixel position
    final centerX = targetSize / 2;
    final centerY = targetSize / 2;
    final x = centerX + (arrow.x * targetSize / 2);
    final y = centerY + (arrow.y * targetSize / 2);

    return Positioned(
      left: x - markerSize / 2,
      top: y - markerSize / 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedArrowIndex = _selectedArrowIndex == index ? null : index;
          });
        },
        onPanUpdate: (details) {
          _handleArrowDrag(index, details.delta, targetSize, provider);
        },
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.gold : AppColors.error,
            border: Border.all(
              color: isSelected ? AppColors.background : AppColors.textPrimary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: isSelected ? 12 : 10,
                color: isSelected ? AppColors.background : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position, double targetSize, double padding, AutoPlotProvider provider) {
    // Check if tap is within target bounds
    final adjustedPos = Offset(position.dx - padding, position.dy - padding);
    if (adjustedPos.dx < 0 || adjustedPos.dx > targetSize ||
        adjustedPos.dy < 0 || adjustedPos.dy > targetSize) {
      return;
    }

    // If arrow is selected, deselect
    if (_selectedArrowIndex != null) {
      setState(() {
        _selectedArrowIndex = null;
      });
      return;
    }

    // Convert to normalized coordinates
    final centerX = targetSize / 2;
    final centerY = targetSize / 2;
    final normalizedX = (adjustedPos.dx - centerX) / (targetSize / 2);
    final normalizedY = (adjustedPos.dy - centerY) / (targetSize / 2);

    // Add new arrow
    provider.addArrow(normalizedX, normalizedY);
  }

  void _handleArrowDrag(int index, Offset delta, double targetSize, AutoPlotProvider provider) {
    final arrows = provider.detectedArrows;
    if (index >= arrows.length) return;

    final arrow = arrows[index];

    // Convert delta to normalized coordinates
    final normalizedDeltaX = delta.dx / (targetSize / 2);
    final normalizedDeltaY = delta.dy / (targetSize / 2);

    // Clamp new position to target bounds
    final newX = (arrow.x + normalizedDeltaX).clamp(-1.0, 1.0);
    final newY = (arrow.y + normalizedDeltaY).clamp(-1.0, 1.0);

    provider.adjustArrow(index, newX, newY);
  }

  Widget _buildControls(AutoPlotProvider provider) {
    final arrowCount = provider.detectedArrows.length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceDark,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arrow count and delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$arrowCount ${arrowCount == 1 ? 'arrow' : 'arrows'} detected',
                  style: TextStyle(fontFamily: AppFonts.body, fontSize: 14),
                ),
                if (_selectedArrowIndex != null)
                  TextButton.icon(
                    onPressed: () {
                      provider.removeArrow(_selectedArrowIndex!);
                      setState(() {
                        _selectedArrowIndex = null;
                      });
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                    label: Text(
                      'DELETE',
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: arrowCount > 0
                    ? () {
                        final arrows = provider.confirmArrows();
                        Navigator.of(context).pop(arrows);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'CONFIRM & PLOT',
                  style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the target face
class _TargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Ring colors (from outside to inside)
    final ringColors = [
      Colors.white, // 1-2
      Colors.white,
      Colors.black, // 3-4
      Colors.black,
      const Color(0xFF00AAFF), // 5-6 (blue)
      const Color(0xFF00AAFF),
      const Color(0xFFFF0000), // 7-8 (red)
      const Color(0xFFFF0000),
      const Color(0xFFFFD700), // 9-10 (gold)
      const Color(0xFFFFD700),
    ];

    // Draw rings from outside to inside
    for (int i = 0; i < 10; i++) {
      final ringRadius = maxRadius * (10 - i) / 10;
      final paint = Paint()
        ..color = ringColors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, ringRadius, paint);

      // Draw ring outline
      final outlinePaint = Paint()
        ..color = i < 4 ? Colors.grey : Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, ringRadius, outlinePaint);
    }

    // Draw X ring (inner gold)
    final xRingRadius = maxRadius * 0.5 / 10;
    final xRingPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, xRingRadius, xRingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
