import 'package:flutter/material.dart';

/// Amber-tinted banner prompting the user to grant a required permission.
class PermissionBanner extends StatelessWidget {
  /// Either `'calendar'` or `'location'`.
  final String permissionType;

  /// Called when the user taps the 'Allow' button.
  final VoidCallback onGrantPressed;

  const PermissionBanner({
    super.key,
    required this.permissionType,
    required this.onGrantPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCalendar = permissionType == 'calendar';
    final title =
        isCalendar ? 'Calendar access needed' : 'Location access needed';
    final subtitle = isCalendar
        ? 'Allow calendar access for smarter outfit suggestions'
        : 'Allow location access to fetch local weather';

    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onGrantPressed,
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }
}
