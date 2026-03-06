import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';

/// Fetches current weather from the Open-Meteo API and maps it to a
/// [WeatherSeason] using the temperature thresholds in [AppConstants].
class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns [WeatherSeason.hot], [WeatherSeason.cold], or
  /// [WeatherSeason.allWeather] for the given coordinates.
  Future<WeatherSeason> getCurrentWeatherSeason({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.weatherApiBaseUrl}/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current_weather=true',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather fetch failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final temperature =
        (json['current_weather']['temperature'] as num).toDouble();
    return _classify(temperature);
  }

  WeatherSeason _classify(double temp) {
    if (temp >= AppConstants.hotTempThreshold) return WeatherSeason.hot;
    if (temp <= AppConstants.coldTempThreshold) return WeatherSeason.cold;
    return WeatherSeason.allWeather;
  }
}
