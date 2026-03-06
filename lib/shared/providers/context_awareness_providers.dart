import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_enums.dart';
import '../../core/services/cache_service.dart';
import '../../features/context_awareness/calendar/calendar_service.dart';
import '../../features/context_awareness/calendar/models/calendar_event_summary.dart';
import '../../features/context_awareness/weather/models/weather_data.dart';
import '../../features/context_awareness/weather/weather_service.dart';
import '../../features/outfit_engine/models/outfit_context.dart';

// ─── Infrastructure ─────────────────────────────────────────────────────────

/// Provides the [CacheService] singleton.
final cacheServiceProvider = Provider<CacheService>((_) => CacheService());

/// Provides the [WeatherService], wired to the shared [CacheService].
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(cacheService: ref.watch(cacheServiceProvider));
});

/// Provides the [CalendarService] singleton.
final calendarServiceProvider = Provider<CalendarService>(
  (_) => CalendarService(),
);

// ─── Async data ──────────────────────────────────────────────────────────────

/// Resolves the current [WeatherData] for the user's location.
///
/// Uses [WeatherService.getWeatherForDisplay] so a non-null value is always
/// returned even when the API and cache are both unavailable.
final currentWeatherProvider = FutureProvider<WeatherData?>((ref) async {
  return ref.watch(weatherServiceProvider).getWeatherForDisplay();
});

/// Resolves the highest-priority [CalendarEventType] from today's events.
final todaysEventTypeProvider = FutureProvider<CalendarEventType>((ref) async {
  return ref.watch(calendarServiceProvider).getTodaysEventType();
});

/// Resolves a full list of classified [CalendarEventSummary] for today.
final todaysEventSummariesProvider =
    FutureProvider<List<CalendarEventSummary>>((ref) async {
  return ref.watch(calendarServiceProvider).getTodaysEventSummaries();
});

/// Returns `true` if the READ_CALENDAR permission is currently granted.
final calendarPermissionProvider = FutureProvider<bool>((ref) async {
  return ref.watch(calendarServiceProvider).hasCalendarPermission();
});

// ─── Composed context ─────────────────────────────────────────────────────────

/// Single source of truth for the [OutfitContext] used by outfit generation.
///
/// Combines [currentWeatherProvider] and [todaysEventTypeProvider], applying
/// safe defaults when either source is unavailable:
/// - Weather unavailable → [WeatherSeason.allWeather], 20.0 °C
/// - Calendar unavailable → [CalendarEventType.casual]
final outfitContextProvider = FutureProvider<OutfitContext>((ref) async {
  final weatherAsync = await ref.watch(currentWeatherProvider.future);
  final eventType = await ref
      .watch(todaysEventTypeProvider.future)
      .catchError((_) => CalendarEventType.casual);

  final weather = weatherAsync;
  final season = weather?.season ?? WeatherSeason.allWeather;
  final temperature = weather?.temperatureCelsius ?? 20.0;
  final description = weather?.conditionDescription ?? 'Weather unavailable';

  return OutfitContext(
    weatherSeason: season,
    temperatureCelsius: temperature,
    weatherDescription: description,
    eventType: eventType,
    date: DateTime.now(),
  );
});
