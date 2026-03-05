import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:outista/core/constants/app_constants.dart';
import 'package:outista/core/constants/app_enums.dart';

// Module 6 — Open-Meteo weather integration
class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the current weather condition for the given coordinates.
  Future<WeatherCondition> getCurrentCondition({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.openMeteoBaseUrl}/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current_weather=true',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather fetch failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final weatherCode = (json['current_weather']['weathercode'] as num).toInt();
    return _mapWmoCode(weatherCode);
  }

  WeatherCondition _mapWmoCode(int code) {
    if (code == 0) return WeatherCondition.sunny;
    if (code <= 3) return WeatherCondition.cloudy;
    if (code <= 67) return WeatherCondition.rainy;
    if (code <= 77) return WeatherCondition.snowy;
    return WeatherCondition.windy;
  }
}
