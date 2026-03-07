import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Full-screen error scaffold used by GoRouter's [errorBuilder] and the /error route.
class AppErrorScreen extends StatelessWidget {
  /// Optional message to display.
  final String? message;

  const AppErrorScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppErrorWidget(
        message: message ?? 'Page not found',
      ),
    );
  }
}

/// Reusable centered error display used across all screens.
class AppErrorWidget extends StatelessWidget {
  /// Optional title — defaults to 'Something went wrong'.
  final String? title;

  /// The error message to display.
  final String message;

  /// Optional retry callback. If provided, a 'Try Again' button is shown.
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
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
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              title ?? 'Something went wrong',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              FilledButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
