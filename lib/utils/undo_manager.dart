import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Manages undo operations with automatic purging after timeout
class UndoManager {
  /// Show a snackbar with undo action and automatically purge after timeout
  ///
  /// [context] - BuildContext for showing the snackbar
  /// [message] - Message to display (e.g., "Session deleted")
  /// [onUndo] - Callback to restore the deleted item
  /// [onExpired] - Callback to permanently delete the item (called after 5 seconds if no undo)
  /// [duration] - How long to show the snackbar (default 5 seconds)
  static void showUndoSnackbar({
    required BuildContext context,
    required String message,
    required Future<void> Function() onUndo,
    required Future<void> Function() onExpired,
    Duration duration = const Duration(seconds: 5),
  }) {
    bool undoTapped = false;
    Timer? purgeTimer;

    // Start timer for automatic purge
    purgeTimer = Timer(duration, () async {
      if (!undoTapped) {
        await onExpired();
      }
    });

    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.surfaceBright,
      duration: duration,
      action: SnackBarAction(
        label: 'UNDO',
        textColor: AppColors.gold,
        onPressed: () async {
          undoTapped = true;
          purgeTimer?.cancel();
          await onUndo();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Restored',
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.textPrimary,
                  ),
                ),
                backgroundColor: AppColors.surfaceBright,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
