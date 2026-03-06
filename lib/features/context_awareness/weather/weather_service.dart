import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/services/cache_service.dart';
import 'models/weather_data.dart';

/// Fetches current weather from the Open-Meteo API and exposes it as a
/// fully-parsed [WeatherData] object.
///
/// Results are cached in [CacheService] for [AppConstants.weatherCacheDurationHours]
/// hours. Location is obtained via [Geolocator] after requesting permission
/// through [permission_handler]. All errors are caught and handled gracefully.
class WeatherService {
  final CacheService _cacheService;
  final http.Client _client;

  /// Optional override for obtaining the device position.
  ///
  /// Provide a non-null value in tests to avoid real GPS calls. When `null`
  /// the real [Geolocator] implementation is used.
  final Future<Position?> Function()? _locationProvider;

  WeatherService({
    required CacheService cacheService,
    http.Client? client,
    Future<Position?> Function()? locationProvider,
  })  : _cacheService = cacheService,
        _client = client ?? http.Client(),
        _locationProvider = locationProvider;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns the current [WeatherData], using the cache when fresh.
  ///
  /// Returns `null` when location permission is denied and no cached data
  /// is available, or when all network and cache sources fail.
  Future<WeatherData?> getCurrentWeather() async {
    // 1. Try the cache first.
    final cached = await _cacheService.getWeather();
    if (cached != null) return cached;

    // 2. Obtain device position.
    final position = await _getLocation();
    if (position == null) return cached; // cached is null here

    // 3. Fetch from Open-Meteo.
    try {
      final uri = _buildRequestUrl(position.latitude, position.longitude);
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return await _cacheService.getWeather();
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = _parseResponse(json);
      await _cacheService.saveWeather(data);
      return data;
    } catch (_) {
      return await _cacheService.getWeather();
    }
  }

  /// Like [getCurrentWeather] but always returns a non-null value.
  ///
  /// Returns a default [WeatherData] with [WeatherSeason.allWeather] and
  /// description `'Weather unavailable'` when all sources fail.
  Future<WeatherData> getWeatherForDisplay() async {
    return await getCurrentWeather() ??
        WeatherData(
          temperatureCelsius: 20.0,
          apparentTemperatureCelsius: 20.0,
          temperatureMaxCelsius: 20.0,
          temperatureMinCelsius: 20.0,
          weatherCode: 0,
          conditionDescription: 'Weather unavailable',
          windSpeedKmh: 0.0,
          humidityPercent: 0,
          season: WeatherSeason.allWeather,
          fetchedAt: DateTime.now(),
        );
  }

  /// Compatibility shim for [GenerateOutfitUseCase] (Module 5).
  ///
  /// Delegates to [getCurrentWeather] and maps the result to a [WeatherSeason].
  Future<WeatherSeason> getCurrentWeatherSeason({
    required double latitude,
    required double longitude,
  }) async {
    final data = await getCurrentWeather();
    return data?.season ?? WeatherSeason.allWeather;
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  /// Obtains the current device position or returns `null` on failure.
  Future<Position?> _getLocation() async {
    if (_locationProvider != null) return _locationProvider!();

    try {
      final status = await Permission.location.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        return null;
      }
      if (!status.isGranted) {
        final result = await Permission.location.request();
        if (!result.isGranted) return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds the Open-Meteo forecast request URI.
  Uri _buildRequestUrl(double lat, double lon) {
    return Uri.parse(
      '${AppConstants.weatherApiBaseUrl}/forecast'
      '?latitude=$lat'
      '&longitude=$lon'
      '&current=temperature_2m,apparent_temperature,'
      'weathercode,windspeed_10m,relativehumidity_2m'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&timezone=auto'
      '&forecast_days=1',
    );
  }

  /// Parses a raw Open-Meteo JSON response into a [WeatherData].
  WeatherData _parseResponse(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final temperature =
        (current['temperature_2m'] as num).toDouble();
    final apparentTemperature =
        (current['apparent_temperature'] as num).toDouble();
    final weatherCode = (current['weathercode'] as num).toInt();
    final windSpeed = (current['windspeed_10m'] as num).toDouble();
    final humidity = (current['relativehumidity_2m'] as num).toInt();

    final tempMax = ((daily['temperature_2m_max'] as List).first as num)
        .toDouble();
    final tempMin = ((daily['temperature_2m_min'] as List).first as num)
        .toDouble();

    final season = _classifySeason(apparentTemperature);
    final description = _describeWeatherCode(weatherCode);

    return WeatherData(
      temperatureCelsius: temperature,
      apparentTemperatureCelsius: apparentTemperature,
      temperatureMaxCelsius: tempMax,
      temperatureMinCelsius: tempMin,
      weatherCode: weatherCode,
      conditionDescription: description,
      windSpeedKmh: windSpeed,
      humidityPercent: humidity,
      season: season,
      fetchedAt: DateTime.now(),
    );
  }

  WeatherSeason _classifySeason(double apparentTemp) {
    if (apparentTemp >= AppConstants.hotTempThreshold) {
      return WeatherSeason.hot;
    }
    if (apparentTemp <= AppConstants.coldTempThreshold) {
      return WeatherSeason.cold;
    }
    return WeatherSeason.allWeather;
  }

  /// Maps a WMO weather interpretation code to a human-readable description.
  String _describeWeatherCode(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
        return 'Light drizzle';
      case 55:
        return 'Dense drizzle';
      case 61:
      case 63:
        return 'Slight rain';
      case 65:
        return 'Heavy rain';
      case 71:
      case 73:
        return 'Slight snow';
      case 75:
        return 'Heavy snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
        return 'Slight showers';
      case 82:
        return 'Violent showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown conditions';
    }
  }
}
