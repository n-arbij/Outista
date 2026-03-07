import 'package:flutter/material.dart';
import '../../../../features/context_awareness/weather/models/weather_data.dart';

/// Compact weather info pill showing temperature and condition emoji.
class WeatherBadge extends StatelessWidget {
  /// The current weather snapshot, or `null` when unavailable.
  final WeatherData? weather;

  const WeatherBadge({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return const Text('🌡️ --°C',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          weather!.displayTemperature,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            weather!.displayCondition,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
