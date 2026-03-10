import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/data_exception.dart';
import '../../../../data/datasources/local/local_clothing_datasource.dart';
import '../../../../data/datasources/local/local_outfit_datasource.dart';
import '../../../../features/context_awareness/calendar/calendar_service.dart';
import '../../../../features/context_awareness/weather/weather_service.dart';
import '../../engine/outfit_scoring_engine.dart';
import '../../models/outfit_context.dart';
import '../../models/outfit_generation_result.dart';
import '../../models/scored_outfit.dart';

/// Orchestrates the full outfit generation pipeline.
///
/// On each call, checks if a valid today's outfit already exists before
/// triggering a fresh generation pass. Defaults gracefully when weather
/// or calendar services are unavailable.
class GenerateOutfitUseCase {
  final LocalClothingDatasource _clothingRepository;
  final LocalOutfitDatasource _outfitRepository;
  final WeatherService _weatherService;
  final CalendarService _calendarService;
  final OutfitScoringEngine _engine;

  const GenerateOutfitUseCase({
    required LocalClothingDatasource clothingRepository,
    required LocalOutfitDatasource outfitRepository,
    required WeatherService weatherService,
    required CalendarService calendarService,
    required OutfitScoringEngine engine,
  })  : _clothingRepository = clothingRepository,
        _outfitRepository = outfitRepository,
        _weatherService = weatherService,
        _calendarService = calendarService,
        _engine = engine;

  /// Generates and returns today's outfit recommendation.
  ///
  /// If outfits were already generated today they are returned directly
  /// without re-running the engine. Call [regenerate] to append new outfits.
  ///
  /// Throws [DataException] when the wardrobe is empty.
  Future<OutfitGenerationResult> call() async {
    try {
      final existing = await _outfitRepository.getTodaysOutfits();
      if (existing.isNotEmpty) {
        final context = OutfitContext(
          weatherSeason: WeatherSeason.allWeather,
          eventType: CalendarEventType.casual,
          date: DateTime.now(),
        );
        final scored = existing.map(ScoredOutfit.fromModel).toList();
        return OutfitGenerationResult(
          primary: scored.first,
          alternatives: scored.skip(1).toList(),
          context: context,
          generatedAt: existing.first.generatedAt,
          totalCombinationsEvaluated: 0,
        );
      }
    } catch (_) {
      // Non-fatal — proceed to fresh generation.
    }

    return _generate();
  }

  /// Unconditionally generates a fresh batch of outfits and appends them to
  /// today's list. Duplicate item combinations are filtered out by
  /// [LocalOutfitDatasource.saveAll].
  Future<OutfitGenerationResult> regenerate() => _generate(isUserAdded: true);

  // ─── Internal ──────────────────────────────────────────────────────────────

  Future<OutfitGenerationResult> _generate({bool isUserAdded = false}) async {
    final wardrobe = await _clothingRepository.getAllItems();
    if (wardrobe.isEmpty) {
      throw DataException('Wardrobe is empty');
    }

    final context = await _buildContext();
    final result = _engine.generateOutfitResult(
      wardrobe: wardrobe,
      context: context,
    );

    if (!result.isEmpty) {
      try {
        final all = result.allOutfits.map((s) => s.outfit).toList();
        await _outfitRepository.saveAll(all, isUserAdded: isUserAdded);
      } catch (_) {
        // Save failure is non-fatal — still return the result.
      }
    }

    return result;
  }

  /// Builds an [OutfitContext] from live weather + calendar data.
  ///
  /// Defaults gracefully when either service is unavailable.
  Future<OutfitContext> _buildContext() async {
    WeatherSeason weatherSeason = WeatherSeason.allWeather;
    String weatherDescription = 'Weather unavailable';

    try {
      weatherSeason = await _weatherService.getCurrentWeatherSeason(
        latitude: 0,
        longitude: 0,
      );
      weatherDescription = 'Current weather';
    } catch (_) {
      // Keep allWeather default.
    }

    CalendarEventType eventType = CalendarEventType.casual;
    try {
      eventType = await _calendarService.getTodayEventType();
    } catch (_) {
      // Keep casual default.
    }

    return OutfitContext(
      weatherSeason: weatherSeason,
      weatherDescription: weatherDescription,
      eventType: eventType,
      date: DateTime.now(),
    );
  }
}
