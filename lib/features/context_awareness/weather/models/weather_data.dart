import '../../../../core/constants/app_enums.dart';

/// Immutable snapshot of current weather conditions.
///
/// Parsed from the Open-Meteo API response and used by the outfit scoring
/// engine to determine appropriate clothing recommendations.
class WeatherData {
  /// Actual air temperature in °C.
  final double temperatureCelsius;

  /// Perceived ("feels-like") temperature in °C.
  final double apparentTemperatureCelsius;

  /// Daily forecast maximum temperature in °C.
  final double temperatureMaxCelsius;

  /// Daily forecast minimum temperature in °C.
  final double temperatureMinCelsius;

  /// WMO weather interpretation code.
  final int weatherCode;

  /// Human-readable description of current conditions.
  final String conditionDescription;

  /// Wind speed at 10 m height in km/h.
  final double windSpeedKmh;

  /// Relative humidity as a percentage (0–100).
  final int humidityPercent;

  /// Season derived from the apparent temperature.
  final WeatherSeason season;

  /// When this snapshot was fetched.
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperatureCelsius,
    required this.apparentTemperatureCelsius,
    required this.temperatureMaxCelsius,
    required this.temperatureMinCelsius,
    required this.weatherCode,
    required this.conditionDescription,
    required this.windSpeedKmh,
    required this.humidityPercent,
    required this.season,
    required this.fetchedAt,
  });

  /// Returns a copy of this instance with the specified fields replaced.
  WeatherData copyWith({
    double? temperatureCelsius,
    double? apparentTemperatureCelsius,
    double? temperatureMaxCelsius,
    double? temperatureMinCelsius,
    int? weatherCode,
    String? conditionDescription,
    double? windSpeedKmh,
    int? humidityPercent,
    WeatherSeason? season,
    DateTime? fetchedAt,
  }) {
    return WeatherData(
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      apparentTemperatureCelsius:
          apparentTemperatureCelsius ?? this.apparentTemperatureCelsius,
      temperatureMaxCelsius:
          temperatureMaxCelsius ?? this.temperatureMaxCelsius,
      temperatureMinCelsius:
          temperatureMinCelsius ?? this.temperatureMinCelsius,
      weatherCode: weatherCode ?? this.weatherCode,
      conditionDescription: conditionDescription ?? this.conditionDescription,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      season: season ?? this.season,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  /// `true` when weather code falls in the 51–99 (precipitation) range.
  bool get isRainy => weatherCode >= 51 && weatherCode <= 99;

  /// `true` when the season is [WeatherSeason.cold].
  bool get isCold => season == WeatherSeason.cold;

  /// `true` when the season is [WeatherSeason.hot].
  bool get isHot => season == WeatherSeason.hot;

  /// Formatted temperature string, e.g. `'24°C'`.
  String get displayTemperature =>
      '${temperatureCelsius.toStringAsFixed(0)}°C';

  /// Emoji-prefixed condition description, e.g. `'☀️ Clear sky'`.
  String get displayCondition {
    final String emoji;
    if (weatherCode == 0) {
      emoji = '☀️';
    } else if (weatherCode >= 1 && weatherCode <= 3) {
      emoji = '⛅';
    } else if (weatherCode == 45 || weatherCode == 48) {
      emoji = '🌫️';
    } else if (weatherCode >= 51 && weatherCode <= 67) {
      emoji = '🌧️';
    } else if (weatherCode >= 71 && weatherCode <= 77) {
      emoji = '❄️';
    } else if (weatherCode >= 80 && weatherCode <= 82) {
      emoji = '🌦️';
    } else if (weatherCode >= 95 && weatherCode <= 99) {
      emoji = '⛈️';
    } else {
      emoji = '🌡️';
    }
    return '$emoji $conditionDescription';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherData &&
          runtimeType == other.runtimeType &&
          temperatureCelsius == other.temperatureCelsius &&
          apparentTemperatureCelsius == other.apparentTemperatureCelsius &&
          temperatureMaxCelsius == other.temperatureMaxCelsius &&
          temperatureMinCelsius == other.temperatureMinCelsius &&
          weatherCode == other.weatherCode &&
          conditionDescription == other.conditionDescription &&
          windSpeedKmh == other.windSpeedKmh &&
          humidityPercent == other.humidityPercent &&
          season == other.season &&
          fetchedAt == other.fetchedAt;

  @override
  int get hashCode => Object.hash(
        temperatureCelsius,
        apparentTemperatureCelsius,
        temperatureMaxCelsius,
        temperatureMinCelsius,
        weatherCode,
        conditionDescription,
        windSpeedKmh,
        humidityPercent,
        season,
        fetchedAt,
      );

  @override
  String toString() =>
      'WeatherData(temp=$temperatureCelsius°C, '
      'apparentTemp=$apparentTemperatureCelsius°C, '
      'code=$weatherCode, season=$season)';
}
