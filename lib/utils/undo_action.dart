import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Helper for implementing undo on destructive operations.
///
/// Shows a snackbar with an undo action for a configurable duration.
/// If undo is not tapped, executes the permanent deletion.
///
/// Usage:
/// ```dart
/// await UndoAction.show(
///   context: context,
///   message: 'Session deleted',
///   onUndo: () => restoreSession(sessionId),
///   onTimeout: () => permanentlyDeleteSession(sessionId),
/// );
/// ```
class UndoAction {
  /// Show an undo snackbar for a destructive operation.
  ///
  /// [context] - BuildContext for showing snackbar
  /// [message] - Message to display (e.g., "Session deleted")
  /// [onUndo] - Callback when user taps Undo
  /// [onTimeout] - Callback when undo window expires (optional - for permanent deletion)
  /// [duration] - How long to show the undo option (default 5 seconds)
  static Future<bool> show({
    required BuildContext context,
    required String message,
    required VoidCallback onUndo,
    VoidCallback? onTimeout,
    Duration duration = const Duration(seconds: 5),
  }) async {
    final completer = Completer<bool>();
    bool undoPressed = false;

    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceDark,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.gold,
          onPressed: () {
            undoPressed = true;
            onUndo();
            completer.complete(true);
          },
        ),
      ),
    );

    // Wait for snackbar to close
    await controller.closed;

    // If undo wasn't pressed and we have a timeout callback, call it
    if (!undoPressed) {
      onTimeout?.call();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  /// Execute a soft-delete operation with undo support.
  ///
  /// This is a convenience method that handles the common pattern:
  /// 1. Call softDelete immediately
  /// 2. Show undo snackbar
  /// 3. If undo pressed, call restore
  /// 4. If timeout, call permanentDelete
  static Future<void> withSoftDelete({
    required BuildContext context,
    required String message,
    required Future<void> Function() softDelete,
    required Future<void> Function() restore,
    required Future<void> Function() permanentDelete,
    Duration duration = const Duration(seconds: 5),
  }) async {
    // Execute soft delete immediately
    await softDelete();

    // Show undo option
    await show(
      context: context,
      message: message,
      onUndo: () async {
        await restore();
      },
      onTimeout: () async {
        await permanentDelete();
      },
      duration: duration,
    );
  }
}
