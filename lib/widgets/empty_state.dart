import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable empty state widget for screens with no data.
///
/// Displays a centered icon, title, optional subtitle, and optional action button.
/// Follows app aesthetic (dark background + gold accents).
///
/// Usage:
/// ```dart
/// EmptyState(
///   icon: Icons.history,
///   title: 'No sessions yet',
///   subtitle: 'Start training to see your history',
///   actionLabel: 'Start Session',
///   onAction: () => navigateToSession(),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Icon to display (64px, muted color) - use this OR iconWidget
  final IconData? icon;

  /// Custom widget to display instead of icon
  final Widget? iconWidget;

  /// Main title text (headline style)
  final String title;

  /// Optional subtitle text (muted style)
  final String? subtitle;

  /// Optional action button label
  final String? actionLabel;

  /// Optional action button callback
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || iconWidget != null, 'Either icon or iconWidget must be provided');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            if (iconWidget != null)
              iconWidget!
            else
              Icon(
                icon,
                size: 64,
                color: AppColors.textMuted.withOpacity(0.5),
              ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            // Subtitle (optional)
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button (optional)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
