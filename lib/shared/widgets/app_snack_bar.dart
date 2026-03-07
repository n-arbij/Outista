import 'package:flutter/material.dart';

/// Static utility class for showing consistent SnackBars app-wide.
///
/// All methods first hide any currently visible SnackBar to prevent stacking.
class AppSnackBar {
  AppSnackBar._();

  /// Shows a success SnackBar (green, 3 s) with a checkmark icon.
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle_outline,
      duration: const Duration(seconds: 3),
    );
  }

  /// Shows an error SnackBar (red.shade700, 4 s) with an error icon.
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error_outline,
      duration: const Duration(seconds: 4),
    );
  }

  /// Shows an info SnackBar (accent #4A90D9, 3 s) with an info icon.
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF4A90D9),
      icon: Icons.info_outline,
      duration: const Duration(seconds: 3),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
