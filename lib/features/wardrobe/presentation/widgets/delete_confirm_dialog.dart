import 'package:flutter/material.dart';

/// Confirmation dialog shown before permanently deleting a clothing item.
///
/// Returns `true` via [Navigator.pop] when the user confirms, `false` (or
/// `null`) when they cancel.
class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({super.key});

  /// Shows the dialog and returns whether the user confirmed deletion.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteConfirmDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Item'),
      content: const Text(
        'This item will be permanently removed from your wardrobe and all '
        'outfit history. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
