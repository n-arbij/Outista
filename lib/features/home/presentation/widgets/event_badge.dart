import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';

/// Badge displaying the inferred calendar event type with a matching icon.
class EventBadge extends StatelessWidget {
  /// The event type to display.
  final CalendarEventType eventType;

  const EventBadge({super.key, required this.eventType});

  static const _accent = Color(0xFF4A90D9);

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _props(eventType);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  (IconData, Color, String) _props(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.work:
        return (Icons.work_outline, _accent, 'Work');
      case CalendarEventType.social:
        return (Icons.people_outline, Colors.purple, 'Social');
      case CalendarEventType.casual:
        return (Icons.weekend_outlined, Colors.green, 'Casual');
      case CalendarEventType.unknown:
        return (Icons.event_outlined, Colors.grey, 'Unknown');
    }
  }
}
