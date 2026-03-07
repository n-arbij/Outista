import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../features/context_awareness/weather/models/weather_data.dart';
import 'weather_badge.dart';
import 'event_badge.dart';

/// Horizontal pill banner combining weather and calendar context.
class ContextBanner extends StatelessWidget {
  /// Current weather snapshot; may be `null` when unavailable.
  final WeatherData? weather;

  /// Today's inferred calendar event type.
  final CalendarEventType eventType;

  const ContextBanner({
    super.key,
    required this.weather,
    required this.eventType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WeatherBadge(weather: weather),
          const SizedBox(width: 12),
          const SizedBox(
            height: 20,
            child: VerticalDivider(width: 1, thickness: 1),
          ),
          const SizedBox(width: 12),
          EventBadge(eventType: eventType),
        ],
      ),
    );
  }
}
