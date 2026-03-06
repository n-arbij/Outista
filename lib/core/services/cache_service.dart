import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../features/context_awareness/weather/models/weather_data.dart';
import '../../core/constants/app_enums.dart';

/// Lightweight cache backed by [SharedPreferences] for weather data.
///
/// Automatically expires entries older than [AppConstants.weatherCacheDurationHours].
class CacheService {
  static const _weatherKey = 'cached_weather';
  static const _weatherTimeKey = 'cached_weather_time';

  /// Serialises [data] and persists it to [SharedPreferences].
  Future<void> saveWeather(WeatherData data) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'temperatureCelsius': data.temperatureCelsius,
      'apparentTemperatureCelsius': data.apparentTemperatureCelsius,
      'temperatureMaxCelsius': data.temperatureMaxCelsius,
      'temperatureMinCelsius': data.temperatureMinCelsius,
      'weatherCode': data.weatherCode,
      'humidityPercent': data.humidityPercent,
      'windSpeedKmh': data.windSpeedKmh,
      'season': data.season.name,
      'conditionDescription': data.conditionDescription,
      'fetchedAt': data.fetchedAt.toIso8601String(),
    };
    await prefs.setString(_weatherKey, _encode(map));
    await prefs.setString(_weatherTimeKey, data.fetchedAt.toIso8601String());
  }

  /// Returns a cached [WeatherData] if one exists and is still fresh, or
  /// `null` if no entry exists or the entry is stale.
  Future<WeatherData?> getWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_weatherTimeKey);
      if (timeStr == null) return null;

      final fetchedAt = DateTime.parse(timeStr);
      final age = DateTime.now().difference(fetchedAt);
      if (age.inHours >= AppConstants.weatherCacheDurationHours) return null;

      final raw = prefs.getString(_weatherKey);
      if (raw == null) return null;

      final map = _decode(raw);
      return WeatherData(
        temperatureCelsius: (map['temperatureCelsius'] as num).toDouble(),
        apparentTemperatureCelsius:
            (map['apparentTemperatureCelsius'] as num).toDouble(),
        temperatureMaxCelsius:
            (map['temperatureMaxCelsius'] as num).toDouble(),
        temperatureMinCelsius:
            (map['temperatureMinCelsius'] as num).toDouble(),
        weatherCode: map['weatherCode'] as int,
        humidityPercent: map['humidityPercent'] as int,
        windSpeedKmh: (map['windSpeedKmh'] as num).toDouble(),
        season: WeatherSeason.values
            .firstWhere((s) => s.name == map['season'] as String),
        conditionDescription: map['conditionDescription'] as String,
        fetchedAt: fetchedAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// Removes all cached weather data from [SharedPreferences].
  Future<void> clearWeather() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_weatherKey);
    await prefs.remove(_weatherTimeKey);
  }

  // ─── Serialisation helpers ─────────────────────────────────────────────────

  String _encode(Map<String, dynamic> map) {
    final parts = map.entries.map((e) => '${e.key}==${e.value}').join('||');
    return parts;
  }

  Map<String, dynamic> _decode(String raw) {
    final map = <String, dynamic>{};
    for (final part in raw.split('||')) {
      final idx = part.indexOf('==');
      if (idx < 0) continue;
      final key = part.substring(0, idx);
      final value = part.substring(idx + 2);
      // Attempt numeric coercion, then bool, then leave as string.
      final asInt = int.tryParse(value);
      if (asInt != null) {
        map[key] = asInt;
        continue;
      }
      final asDouble = double.tryParse(value);
      if (asDouble != null) {
        map[key] = asDouble;
        continue;
      }
      map[key] = value;
    }
    return map;
  }
}
