import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart' show scaffoldMessengerKey;

/// Result of an error-handled operation
class ErrorHandlerResult<T> {
  final T? data;
  final bool success;
  final String? error;

  const ErrorHandlerResult._({
    this.data,
    required this.success,
    this.error,
  });

  factory ErrorHandlerResult.success(T data) =>
      ErrorHandlerResult._(data: data, success: true);

  factory ErrorHandlerResult.failure(String error) =>
      ErrorHandlerResult._(success: false, error: error);
}

/// Centralized error handling with user feedback.
///
/// Wraps async operations with consistent error handling, loading states,
/// and user notifications. Prevents silent failures.
///
/// Usage:
/// ```dart
/// await ErrorHandler.run(
///   context,
///   () => saveSession(),
///   successMessage: 'Session saved',
///   errorMessage: 'Failed to save session',
/// );
/// ```
class ErrorHandler {
  /// Execute an async operation with error handling and user feedback.
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing snackbars
  /// - [action]: The async operation to execute
  /// - [successMessage]: Optional message to show on success
  /// - [errorMessage]: Custom error message prefix (actual error is appended)
  /// - [showLoading]: Whether to show a loading indicator during execution
  /// - [onRetry]: Custom retry action, defaults to re-running the action
  ///
  /// Returns an [ErrorHandlerResult] containing the result or error.
  static Future<ErrorHandlerResult<T>> run<T>(
    BuildContext context,
    Future<T> Function() action, {
    String? successMessage,
    String? errorMessage,
    bool showLoading = false,
    VoidCallback? onRetry,
  }) async {
    // Show loading if requested
    if (showLoading && context.mounted) {
      _showLoading(context);
    }

    try {
      final result = await action();

      // Hide loading
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message if provided
      if (successMessage != null && context.mounted) {
        _showSuccess(context, successMessage);
      }

      return ErrorHandlerResult.success(result);
    } catch (e) {
      // Hide loading
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }

      // Log error to debug console
      debugPrint('ErrorHandler: ${errorMessage ?? 'Operation failed'}: $e');

      // Show error with retry option
      if (context.mounted) {
        _showError(
          context,
          errorMessage != null ? '$errorMessage: $e' : '$e',
          onRetry: onRetry ?? () => run(context, action,
              successMessage: successMessage,
              errorMessage: errorMessage,
              showLoading: showLoading),
        );
      }

      return ErrorHandlerResult.failure(e.toString());
    }
  }

  /// Execute an operation without context (for background operations).
  /// Returns the result or throws on failure.
  static Future<T> runSilent<T>(
    Future<T> Function() action, {
    String? errorMessage,
  }) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('ErrorHandler: ${errorMessage ?? 'Operation failed'}: $e');
      rethrow;
    }
  }

  /// Execute a background operation and show error if it fails.
  /// Use for non-blocking operations like cloud backup.
  ///
  /// Parameters:
  /// - [action]: The async operation to execute
  /// - [errorMessage]: Error message to show to user
  /// - [onRetry]: Optional retry callback
  ///
  /// Logs to console and shows snackbar on error, but doesn't block user flow.
  static Future<void> runBackground(
    Future<void> Function() action, {
    required String errorMessage,
    VoidCallback? onRetry,
  }) async {
    try {
      await action();
    } catch (e) {
      debugPrint('ErrorHandler (background): $errorMessage: $e');

      // Show non-blocking error notification
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '$errorMessage: $e',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: AppColors.gold,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
    }
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }

  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void _showError(
    BuildContext context,
    String message, {
    required VoidCallback onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: AppColors.gold,
          onPressed: onRetry,
        ),
      ),
    );
  }
}
