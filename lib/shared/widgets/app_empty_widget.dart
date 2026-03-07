import 'package:flutter/material.dart';

/// Reusable empty state widget used across all screens.
class AppEmptyWidget extends StatelessWidget {
  /// Icon to display at the top.
  final IconData icon;

  /// Primary empty-state message.
  final String title;

  /// Supporting subtitle text.
  final String subtitle;

  /// Optional label for the action button.
  final String? actionLabel;

  /// Optional callback invoked when the action button is pressed.
  final VoidCallback? onAction;

  const AppEmptyWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onAction != null)
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel ?? ''),
              ),
          ],
        ),
      ),
    );
  }
}
