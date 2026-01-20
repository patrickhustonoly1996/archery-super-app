import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Button that shows a loading spinner during async operations.
///
/// Prevents double-taps by disabling the button while loading.
/// Maintains consistent styling with the app's gold theme.
///
/// Usage:
/// ```dart
/// LoadingButton(
///   label: 'Sign In',
///   isLoading: _isLoading,
///   onPressed: _handleSignIn,
/// )
/// ```
class LoadingButton extends StatelessWidget {
  /// Button label text
  final String label;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Callback when button is pressed (null to disable)
  final VoidCallback? onPressed;

  /// Optional icon to show before the label
  final IconData? icon;

  /// Button style variant (default is elevated/filled)
  final LoadingButtonStyle style;

  const LoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.onPressed,
    this.icon,
    this.style = LoadingButtonStyle.elevated,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.backgroundDark,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, semanticLabel: null), // Label handled by button
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    // Wrap with Semantics to announce loading state
    final button = switch (style) {
      LoadingButtonStyle.elevated => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      LoadingButtonStyle.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      LoadingButtonStyle.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
    };

    return Semantics(
      button: true,
      label: isLoading ? '$label, loading' : label,
      enabled: !isLoading && onPressed != null,
      child: ExcludeSemantics(child: button),
    );
  }
}

/// Button style variants for LoadingButton
enum LoadingButtonStyle {
  /// Filled button (primary action)
  elevated,
  /// Outlined button (secondary action)
  outlined,
  /// Text button (tertiary action)
  text,
}
