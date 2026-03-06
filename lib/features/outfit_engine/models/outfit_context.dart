import '../../../core/constants/app_enums.dart';

/// Immutable snapshot of the contextual signals used to score outfits.
///
/// Combines weather and calendar data so the scoring engine remains
/// a pure function of its inputs.
class OutfitContext {
  final WeatherSeason weatherSeason;

  /// Ambient temperature in degrees Celsius.
  final double temperatureCelsius;

  /// Human-readable description of the current weather (display only).
  final String weatherDescription;

  final CalendarEventType eventType;

  /// Title of today's primary calendar event, if available (display only —
  /// never used for scoring).
  final String? eventTitle;

  final DateTime date;

  const OutfitContext({
    required this.weatherSeason,
    required this.eventType,
    required this.date,
    this.temperatureCelsius = 20.0,
    this.weatherDescription = '',
    this.eventTitle,
  });

  /// Returns a copy of this context with selected fields replaced.
  OutfitContext copyWith({
    WeatherSeason? weatherSeason,
    double? temperatureCelsius,
    String? weatherDescription,
    CalendarEventType? eventType,
    String? eventTitle,
    DateTime? date,
  }) {
    return OutfitContext(
      weatherSeason: weatherSeason ?? this.weatherSeason,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      weatherDescription: weatherDescription ?? this.weatherDescription,
      eventType: eventType ?? this.eventType,
      eventTitle: eventTitle ?? this.eventTitle,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitContext &&
          weatherSeason == other.weatherSeason &&
          temperatureCelsius == other.temperatureCelsius &&
          weatherDescription == other.weatherDescription &&
          eventType == other.eventType &&
          eventTitle == other.eventTitle &&
          date == other.date;

  @override
  int get hashCode => Object.hash(
        weatherSeason,
        temperatureCelsius,
        weatherDescription,
        eventType,
        eventTitle,
        date,
      );

  @override
  String toString() =>
      'OutfitContext(weatherSeason: $weatherSeason, '
      'temperatureCelsius: $temperatureCelsius, '
      'weatherDescription: $weatherDescription, '
      'eventType: $eventType, '
      'eventTitle: $eventTitle, '
      'date: $date)';
}
