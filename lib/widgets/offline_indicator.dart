import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Offline status indicator for the app bar.
///
/// Shows a cloud with X icon when offline, or a spinning sync icon when syncing.
/// No indicator shown when online and synced (clean state).
///
/// Usage in AppBar:
/// ```dart
/// AppBar(
///   title: Text('My Screen'),
///   actions: [
///     OfflineIndicator(
///       isOffline: !hasConnection,
///       isSyncing: isSyncing,
///     ),
///   ],
/// )
/// ```
class OfflineIndicator extends StatelessWidget {
  /// Whether the device is offline
  final bool isOffline;

  /// Whether sync is in progress
  final bool isSyncing;

  const OfflineIndicator({
    super.key,
    this.isOffline = false,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    // No indicator when online and not syncing (clean state)
    if (!isOffline && !isSyncing) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Tooltip(
        message: isOffline
            ? 'Offline - changes will sync when connected'
            : 'Syncing...',
        child: isOffline
            ? const Icon(
                Icons.cloud_off,
                size: 20,
                color: AppColors.textMuted,
              )
            : const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
      ),
    );
  }
}

/// Sync status indicator that shows in app bar
class SyncStatusIndicator extends StatefulWidget {
  /// Stream of sync status updates
  final Stream<SyncStatus>? syncStatusStream;

  const SyncStatusIndicator({
    super.key,
    this.syncStatusStream,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  SyncStatus _status = SyncStatus.idle;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    widget.syncStatusStream?.listen((status) {
      if (mounted) {
        setState(() => _status = status);
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == SyncStatus.idle || _status == SyncStatus.synced) {
      return const SizedBox.shrink();
    }

    if (_status == SyncStatus.error) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Tooltip(
          message: 'Sync error - tap to retry',
          child: Icon(
            Icons.sync_problem,
            size: 20,
            color: Colors.orange.shade600,
          ),
        ),
      );
    }

    // Syncing state
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Tooltip(
        message: 'Syncing...',
        child: RotationTransition(
          turns: _rotationController,
          child: const Icon(
            Icons.sync,
            size: 20,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

/// Sync status states
enum SyncStatus {
  /// No sync activity
  idle,
  /// Sync in progress
  syncing,
  /// Sync completed successfully
  synced,
  /// Sync failed
  error,
}
