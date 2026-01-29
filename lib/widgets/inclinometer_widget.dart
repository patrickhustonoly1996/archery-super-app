import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/inclinometer_service.dart';
import '../theme/app_theme.dart';

/// Compact inline inclinometer widget for field archery angle measurement.
///
/// Shows a horizontal tilt bar with angle readout.
/// Tap the angle to toggle manual text input.
/// "Use This" button confirms the angle.
class InclinometerWidget extends StatefulWidget {
  /// Pre-filled angle for "consistent angle" mode
  final double? prefilledAngle;

  /// Callback when angle is confirmed
  final ValueChanged<double> onAngleConfirmed;

  /// Optional label override
  final String? label;

  const InclinometerWidget({
    super.key,
    this.prefilledAngle,
    required this.onAngleConfirmed,
    this.label,
  });

  @override
  State<InclinometerWidget> createState() => _InclinometerWidgetState();
}

class _InclinometerWidgetState extends State<InclinometerWidget> {
  final InclinometerService _service = InclinometerService();
  final TextEditingController _manualController = TextEditingController();

  bool _isManualMode = false;
  double _currentAngle = 0.0;
  bool _isStable = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAngle != null) {
      _currentAngle = widget.prefilledAngle!;
      _manualController.text = widget.prefilledAngle!.toStringAsFixed(1);
    }
    _service.onAngleUpdate = (angle, isStable) {
      if (!_isManualMode && mounted) {
        setState(() {
          _currentAngle = angle;
          _isStable = isStable;
        });
      }
    };
    if (widget.prefilledAngle == null) {
      _service.startReading();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _manualController.dispose();
    super.dispose();
  }

  String get _angleLabel {
    if (_currentAngle.abs() < 1.0) return 'FLAT';
    return _currentAngle < 0 ? 'UPHILL' : 'DOWNHILL';
  }

  Color get _stabilityColor {
    if (_isManualMode) return AppColors.gold;
    return _isStable ? const Color(0xFF4CAF50) : const Color(0xFFFFC107);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: label + stability indicator
          Row(
            children: [
              Text(
                widget.label ?? 'ANGLE',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Stability dot
              if (!_isManualMode) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _stabilityColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isStable ? 'STABLE' : 'SETTLING',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 9,
                    color: _stabilityColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tilt bar + angle readout
          Row(
            children: [
              // Tilt visualization bar
              Expanded(
                child: _buildTiltBar(),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Angle readout (tappable to toggle manual)
              GestureDetector(
                onTap: _toggleManualMode,
                child: _isManualMode
                    ? _buildManualInput()
                    : _buildAngleDisplay(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Direction label + Use This button
          Row(
            children: [
              Text(
                _angleLabel,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Use This button
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: _confirmAngle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                  ),
                  child: Text(
                    'USE THIS',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTiltBar() {
    return SizedBox(
      height: 24,
      child: CustomPaint(
        painter: _TiltBarPainter(
          angle: _currentAngle,
          isStable: _isStable || _isManualMode,
        ),
        size: const Size(double.infinity, 24),
      ),
    );
  }

  Widget _buildAngleDisplay() {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        '${_currentAngle.toStringAsFixed(1)}°',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 22,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    return Container(
      width: 80,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: TextField(
        controller: _manualController,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
        ],
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: (value) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            setState(() {
              _currentAngle = parsed.clamp(-45.0, 45.0);
            });
          }
        },
        onSubmitted: (_) => _confirmAngle(),
      ),
    );
  }

  void _toggleManualMode() {
    setState(() {
      _isManualMode = !_isManualMode;
      if (_isManualMode) {
        _service.stopReading();
        _manualController.text = _currentAngle.toStringAsFixed(1);
      } else {
        _service.startReading();
      }
    });
  }

  void _confirmAngle() {
    if (_isManualMode) {
      final parsed = double.tryParse(_manualController.text);
      if (parsed != null) {
        widget.onAngleConfirmed(parsed.clamp(-45.0, 45.0));
      }
    } else {
      widget.onAngleConfirmed(_currentAngle);
    }
  }
}

/// Custom painter for the horizontal tilt bar
class _TiltBarPainter extends CustomPainter {
  final double angle;
  final bool isStable;

  _TiltBarPainter({required this.angle, required this.isStable});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background bar
    final bgPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.fill;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, centerY - 4, size.width, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Center tick mark
    final tickPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(centerX, centerY - 8),
      Offset(centerX, centerY + 8),
      tickPaint,
    );

    // Tilt indicator position
    // Map angle (-45 to +45) to position (0 to width)
    final normalizedAngle = (angle / 45.0).clamp(-1.0, 1.0);
    final indicatorX = centerX + normalizedAngle * (size.width / 2 - 12);

    // Tilt indicator (gold circle)
    final indicatorPaint = Paint()
      ..color = isStable ? AppColors.gold : AppColors.gold.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(indicatorX, centerY), 8, indicatorPaint);

    // Indicator outline
    final outlinePaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(indicatorX, centerY), 8, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _TiltBarPainter oldDelegate) {
    return angle != oldDelegate.angle || isStable != oldDelegate.isStable;
  }
}
