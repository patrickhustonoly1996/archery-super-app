import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/connectivity_provider.dart';

/// Subtle connectivity status indicator shown in app bar
///
/// Shows:
/// - Cloud with X when offline
/// - Spinning sync icon when syncing
/// - Nothing when online and synced (clean state)
class ConnectivityIndicator extends StatefulWidget {
  const ConnectivityIndicator({super.key});

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        // Clean state - online and not syncing
        if (connectivity.isOnline && !connectivity.isSyncing) {
          return const SizedBox.shrink();
        }

        return Semantics(
          label: connectivity.isOffline
              ? 'Offline - data will sync when connection is restored'
              : 'Syncing data',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: connectivity.isOffline
                    ? AppColors.error.withValues(alpha: 0.3)
                    : AppColors.gold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                if (connectivity.isOffline)
                  const _OfflineIcon(size: 16)
                else
                  RotationTransition(
                    turns: _spinController,
                    child: const _SyncIcon(size: 16),
                  ),
                const SizedBox(width: 6),
                // Label
                Text(
                  connectivity.isOffline ? 'OFFLINE' : 'SYNC',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 8,
                    color: connectivity.isOffline
                        ? AppColors.error
                        : AppColors.gold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cloud with X icon (offline indicator)
class _OfflineIcon extends StatelessWidget {
  final double size;

  const _OfflineIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OfflineIconPainter(),
    );
  }
}

class _OfflineIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = size.width / 12; // 12x12 pixel grid
    final paint = Paint()..color = AppColors.error;

    // Cloud shape
    // Top of cloud
    _px(canvas, 4, 2, p, paint);
    _px(canvas, 5, 2, p, paint);
    _px(canvas, 6, 2, p, paint);
    _px(canvas, 7, 2, p, paint);
    // Upper sides
    _px(canvas, 3, 3, p, paint);
    _px(canvas, 8, 3, p, paint);
    _px(canvas, 2, 4, p, paint);
    _px(canvas, 9, 4, p, paint);
    // Middle - puff on right
    _px(canvas, 2, 5, p, paint);
    _px(canvas, 9, 5, p, paint);
    _px(canvas, 10, 5, p, paint);
    _px(canvas, 2, 6, p, paint);
    _px(canvas, 10, 6, p, paint);
    // Bottom
    _px(canvas, 2, 7, p, paint);
    _px(canvas, 3, 7, p, paint);
    _px(canvas, 4, 7, p, paint);
    _px(canvas, 5, 7, p, paint);
    _px(canvas, 6, 7, p, paint);
    _px(canvas, 7, 7, p, paint);
    _px(canvas, 8, 7, p, paint);
    _px(canvas, 9, 7, p, paint);

    // X mark (diagonal lines)
    final xPaint = Paint()..color = AppColors.error;
    // Top-left to bottom-right
    _px(canvas, 4, 4, p, xPaint);
    _px(canvas, 5, 5, p, xPaint);
    _px(canvas, 6, 6, p, xPaint);
    // Top-right to bottom-left
    _px(canvas, 8, 4, p, xPaint);
    _px(canvas, 7, 5, p, xPaint);
    _px(canvas, 6, 6, p, xPaint);
  }

  void _px(Canvas canvas, int x, int y, double p, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x * p, y * p, p, p), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular sync/refresh icon
class _SyncIcon extends StatelessWidget {
  final double size;

  const _SyncIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SyncIconPainter(),
    );
  }
}

class _SyncIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = size.width / 12; // 12x12 pixel grid
    final paint = Paint()..color = AppColors.gold;

    // Circular arrow (clockwise)
    // Top arc
    _px(canvas, 4, 2, p, paint);
    _px(canvas, 5, 2, p, paint);
    _px(canvas, 6, 2, p, paint);
    _px(canvas, 7, 2, p, paint);
    // Right side going down
    _px(canvas, 8, 3, p, paint);
    _px(canvas, 9, 4, p, paint);
    _px(canvas, 9, 5, p, paint);
    _px(canvas, 9, 6, p, paint);
    // Bottom arc
    _px(canvas, 8, 7, p, paint);
    _px(canvas, 7, 8, p, paint);
    _px(canvas, 6, 8, p, paint);
    _px(canvas, 5, 8, p, paint);
    // Left side going up
    _px(canvas, 4, 7, p, paint);
    _px(canvas, 3, 6, p, paint);
    _px(canvas, 3, 5, p, paint);
    // Arrow head pointing down (at bottom)
    _px(canvas, 4, 9, p, paint);
    _px(canvas, 5, 9, p, paint);
    _px(canvas, 6, 9, p, paint);
    _px(canvas, 5, 10, p, paint);
  }

  void _px(Canvas canvas, int x, int y, double p, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x * p, y * p, p, p), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
