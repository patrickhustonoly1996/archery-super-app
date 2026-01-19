import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Minimum touch target size per WCAG 2.1 guidelines (48x48 logical pixels)
const double kMinTouchTargetSize = 48.0;

/// A wrapper widget that ensures child has at least 48x48dp touch target.
///
/// Use this to wrap small interactive elements (icons, small buttons) to ensure
/// they meet accessibility guidelines for touch target size.
///
/// Example:
/// ```dart
/// AccessibleTouchTarget(
///   semanticLabel: 'Close dialog',
///   onTap: () => Navigator.pop(context),
///   child: Icon(Icons.close, size: 24),
/// )
/// ```
class AccessibleTouchTarget extends StatelessWidget {
  /// The child widget to wrap
  final Widget child;

  /// Semantic label for screen readers
  final String semanticLabel;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Callback when long pressed
  final VoidCallback? onLongPress;

  /// Minimum size of the touch target (defaults to 48x48)
  final double minSize;

  /// Whether to provide haptic feedback on tap
  final bool hapticFeedback;

  /// Whether this represents a button (affects Semantics)
  final bool isButton;

  /// Additional semantic hint
  final String? semanticHint;

  /// Whether the element is currently selected/checked
  final bool? isSelected;

  const AccessibleTouchTarget({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.onLongPress,
    this.minSize = kMinTouchTargetSize,
    this.hapticFeedback = true,
    this.isButton = true,
    this.semanticHint,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isButton,
      label: semanticLabel,
      hint: semanticHint,
      selected: isSelected,
      enabled: onTap != null || onLongPress != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap != null
            ? () {
                if (hapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                onTap!();
              }
            : null,
        onLongPress: onLongPress != null
            ? () {
                if (hapticFeedback) {
                  HapticFeedback.mediumImpact();
                }
                onLongPress!();
              }
            : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// A row of accessible icon buttons with proper spacing and touch targets.
///
/// Useful for toolbars and action rows.
class AccessibleIconRow extends StatelessWidget {
  final List<AccessibleIconButton> buttons;
  final double spacing;

  const AccessibleIconRow({
    super.key,
    required this.buttons,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          buttons[i],
          if (i < buttons.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// An icon button with guaranteed 48x48 touch target and proper semantics.
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color? color;
  final double iconSize;
  final bool hapticFeedback;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.color,
    this.iconSize = 24.0,
    this.hapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleTouchTarget(
      semanticLabel: semanticLabel,
      onTap: onTap,
      hapticFeedback: hapticFeedback,
      child: Icon(
        icon,
        color: color,
        size: iconSize,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Extension to add semantic labels to icons easily
extension AccessibleIcon on Icon {
  /// Creates an accessible version of this icon with a semantic label
  Widget withSemantics(String label) {
    return Semantics(
      label: label,
      child: Icon(
        icon,
        size: size,
        color: color,
        semanticLabel: label,
      ),
    );
  }
}
