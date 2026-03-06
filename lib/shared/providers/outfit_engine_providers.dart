import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/local_clothing_datasource.dart';
import '../../data/datasources/local/local_outfit_datasource.dart';
import '../../features/context_awareness/calendar/calendar_service.dart';
import '../../features/context_awareness/weather/weather_service.dart';
import '../../features/outfit_engine/domain/usecases/generate_outfit_usecase.dart';
import '../../features/outfit_engine/engine/outfit_scoring_engine.dart';
import '../../features/outfit_engine/models/outfit_generation_result.dart';
import 'repository_providers.dart';

// ─── Pure services ───────────────────────────────────────────────────────────

/// Provides the stateless [OutfitScoringEngine].
final outfitScoringEngineProvider = Provider<OutfitScoringEngine>(
  (_) => const OutfitScoringEngine(),
);

/// Provides the [WeatherService] used by the generation pipeline.
final weatherServiceProvider = Provider<WeatherService>(
  (_) => WeatherService(),
);

/// Provides the [CalendarService] used by the generation pipeline.
final calendarServiceProvider = Provider<CalendarService>(
  (_) => CalendarService(),
);

// ─── Use case ────────────────────────────────────────────────────────────────

/// Provides [GenerateOutfitUseCase] wired to all required services.
final generateOutfitUseCaseProvider = Provider<GenerateOutfitUseCase>((ref) {
  return GenerateOutfitUseCase(
    clothingRepository:
        ref.watch(clothingRepositoryProvider) as LocalClothingDatasource,
    outfitRepository:
        ref.watch(outfitRepositoryProvider) as LocalOutfitDatasource,
    weatherService: ref.watch(weatherServiceProvider),
    calendarService: ref.watch(calendarServiceProvider),
    engine: ref.watch(outfitScoringEngineProvider),
  );
});

// ─── Result providers ────────────────────────────────────────────────────────

/// Async provider that resolves today's outfit recommendation.
///
/// Automatically invoked when the home screen is first mounted. The
/// result is cached for the lifetime of the provider scope.
final outfitGenerationResultProvider =
    FutureProvider<OutfitGenerationResult>((ref) async {
  return ref.watch(generateOutfitUseCaseProvider).call();
});

/// Returns a callable that triggers a fresh outfit generation pass.
///
/// Usage:
/// ```dart
/// final regen = ref.read(regenerateOutfitProvider);
/// await regen();
/// ref.invalidate(outfitGenerationResultProvider);
/// ```
final regenerateOutfitProvider =
    Provider<Future<OutfitGenerationResult> Function()>((ref) {
  return () => ref.read(generateOutfitUseCaseProvider).regenerate();
});
