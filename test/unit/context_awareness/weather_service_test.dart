import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../../../lib/core/constants/app_enums.dart';
import '../../../lib/core/services/cache_service.dart';
import '../../../lib/features/context_awareness/weather/models/weather_data.dart';
import '../../../lib/features/context_awareness/weather/weather_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockHttpClient extends Mock implements http.Client {}

class MockCacheService extends Mock implements CacheService {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

WeatherData _makeWeatherData({
  double temp = 20.0,
  double apparentTemp = 20.0,
  WeatherSeason season = WeatherSeason.allWeather,
}) {
  return WeatherData(
    temperatureCelsius: temp,
    apparentTemperatureCelsius: apparentTemp,
    temperatureMaxCelsius: temp + 2,
    temperatureMinCelsius: temp - 2,
    weatherCode: 0,
    conditionDescription: 'Clear sky',
    windSpeedKmh: 10.0,
    humidityPercent: 50,
    season: season,
    fetchedAt: DateTime.now(),
  );
}

Position _fakePosition(double lat, double lon) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

/// Builds a minimal valid Open-Meteo JSON response string.
String _fakeApiResponse({
  double temperature = 20.0,
  double apparentTemperature = 20.0,
  int weatherCode = 0,
  double windSpeed = 10.0,
  int humidity = 50,
  double tempMax = 22.0,
  double tempMin = 18.0,
}) {
  return '''
{
  "current": {
    "temperature_2m": $temperature,
    "apparent_temperature": $apparentTemperature,
    "weathercode": $weatherCode,
    "windspeed_10m": $windSpeed,
    "relativehumidity_2m": $humidity
  },
  "daily": {
    "temperature_2m_max": [$tempMax],
    "temperature_2m_min": [$tempMin]
  }
}
''';
}

WeatherService _makeService({
  required MockCacheService cache,
  required MockHttpClient client,
  Future<Position?> Function()? locationProvider,
}) {
  return WeatherService(
    cacheService: cache,
    client: client,
    locationProvider: locationProvider,
  );
}

void main() {
  late MockHttpClient mockClient;
  late MockCacheService mockCache;

  setUp(() {
    mockClient = MockHttpClient();
    mockCache = MockCacheService();

    // Register fallbacks before any 'any()' usage
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(_makeWeatherData());

    // Default: cache miss
    when(() => mockCache.getWeather()).thenAnswer((_) async => null);
    when(() => mockCache.saveWeather(any())).thenAnswer((_) async {});
  });

  group('WeatherService', () {
    test('returns cached data when cache is fresh', () async {
      final cached = _makeWeatherData(temp: 22.0);
      when(() => mockCache.getWeather()).thenAnswer((_) async => cached);

      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => _fakePosition(51.5, -0.1),
      );

      final result = await service.getCurrentWeather();

      expect(result, equals(cached));
      // HTTP client must not be called when cache is fresh
      verifyNever(() => mockClient.get(any()));
    });

    test('fetches from API when cache is stale', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(_fakeApiResponse(temperature: 20.0), 200),
      );

      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => _fakePosition(51.5, -0.1),
      );

      final result = await service.getCurrentWeather();

      expect(result, isNotNull);
      expect(result!.temperatureCelsius, 20.0);
      verify(() => mockClient.get(any())).called(1);
      verify(() => mockCache.saveWeather(any())).called(1);
    });

    test('returns null when location permission is denied and cache is empty',
        () async {
      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => null, // simulates denied permission
      );

      final result = await service.getCurrentWeather();

      expect(result, isNull);
      verifyNever(() => mockClient.get(any()));
    });

    test('returns cached data when API call fails', () async {
      final staleData = _makeWeatherData(temp: 15.0);
      // First call returns null (stale check), second call returns stale data
      var callCount = 0;
      when(() => mockCache.getWeather()).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? null : staleData;
      });
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Server error', 500),
      );

      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => _fakePosition(51.5, -0.1),
      );

      final result = await service.getCurrentWeather();

      expect(result, equals(staleData));
    });

    test('maps apparent temperature >= 25 to WeatherSeason.hot', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(
          _fakeApiResponse(apparentTemperature: 30.0),
          200,
        ),
      );

      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => _fakePosition(51.5, -0.1),
      );

      final result = await service.getCurrentWeather();
      expect(result?.season, WeatherSeason.hot);
    });

    test('maps apparent temperature <= 15 to WeatherSeason.cold', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(
          _fakeApiResponse(apparentTemperature: 10.0),
          200,
        ),
      );

      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => _fakePosition(51.5, -0.1),
      );

      final result = await service.getCurrentWeather();
      expect(result?.season, WeatherSeason.cold);
    });

    test('maps apparent temperature between 15–25 to WeatherSeason.allWeather',
        () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(
          _fakeApiResponse(apparentTemperature: 20.0),
          200,
        ),
      );

      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => _fakePosition(51.5, -0.1),
      );

      final result = await service.getCurrentWeather();
      expect(result?.season, WeatherSeason.allWeather);
    });

    test('uses apparentTemperature, not raw temperature, for season mapping',
        () async {
      // Raw temp = 30°C (would be hot), but apparent = 14°C (cold)
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(
          _fakeApiResponse(temperature: 30.0, apparentTemperature: 14.0),
          200,
        ),
      );

      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => _fakePosition(51.5, -0.1),
      );

      final result = await service.getCurrentWeather();
      // Season must be based on apparent (14°C → cold), not raw (30°C → hot)
      expect(result?.season, WeatherSeason.cold);
    });

    test(
        'getWeatherForDisplay returns default WeatherData when API and cache fail',
        () async {
      final service = _makeService(
        cache: mockCache,
        client: mockClient,
        locationProvider: () async => null,
      );

      final result = await service.getWeatherForDisplay();

      expect(result, isNotNull);
      expect(result.season, WeatherSeason.allWeather);
      expect(result.conditionDescription, 'Weather unavailable');
    });
  });
}
