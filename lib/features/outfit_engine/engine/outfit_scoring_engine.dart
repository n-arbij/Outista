import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../data/models/clothing_item_model.dart';
import '../../../data/models/outfit_model.dart';

/// Contextual signals passed to the scoring engine.
class OutfitContext {
  final WeatherSeason weatherSeason;
  final CalendarEventType eventType;
  final DateTime date;

  const OutfitContext({
    required this.weatherSeason,
    required this.eventType,
    required this.date,
  });
}

/// An outfit paired with the score it achieved.
class ScoredOutfit {
  final OutfitModel outfit;
  final double score;

  const ScoredOutfit({required this.outfit, required this.score});
}

/// Deterministic outfit scoring engine.
///
/// Iterates every tops × bottoms × shoes × (no outerwear | outerwear)
/// combination, scores each against the given [OutfitContext], sorts
/// descending, and returns the top [maxResults] outfits.
class OutfitScoringEngine {
  const OutfitScoringEngine();

  static const _uuid = Uuid();

  /// Generates up to [maxResults] ranked [OutfitModel]s from [wardrobe].
  List<OutfitModel> generateOutfits({
    required List<ClothingItemModel> wardrobe,
    required OutfitContext context,
    int maxResults = 4,
  }) {
    final tops =
        wardrobe.where((i) => i.category == ClothingCategory.top).toList();
    final bottoms =
        wardrobe.where((i) => i.category == ClothingCategory.bottom).toList();
    final shoes =
        wardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    final outerwears =
        wardrobe.where((i) => i.category == ClothingCategory.outerwear).toList();

    final scored = <ScoredOutfit>[];

    for (final top in tops) {
      for (final bottom in bottoms) {
        for (final shoe in shoes) {
          // null entry = no outerwear option
          final outerwearOptions = <ClothingItemModel?>[null, ...outerwears];
          for (final outerwear in outerwearOptions) {
            final items = [top, bottom, shoe, if (outerwear != null) outerwear];
            final score = _scoreOutfit(items, context);
            scored.add(
              ScoredOutfit(
                score: score,
                outfit: OutfitModel(
                  id: _uuid.v4(),
                  topId: top.id,
                  bottomId: bottom.id,
                  shoesId: shoe.id,
                  outerwearId: outerwear?.id,
                  score: score,
                  occasionContext: context.eventType.name,
                  weatherContext: context.weatherSeason.name,
                  generatedAt: context.date,
                ),
              ),
            );
          }
        }
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((s) => s.outfit).toList();
  }

  // ---------------------------------------------------------------------------
  // Scoring helpers
  // ---------------------------------------------------------------------------

  /// Aggregates per-item scores and applies the emotional bonus.
  ///
  /// Per item: season (40 pt) + occasion (35 pt) + usage balance (25 pt)
  /// Outfit average + optional emotional bonus (+15 pt).
  double _scoreOutfit(
      List<ClothingItemModel> items, OutfitContext context) {
    if (items.isEmpty) return 0;

    double total = 0;
    bool bonus = false;

    for (final item in items) {
      total += _seasonScore(item, context.weatherSeason);
      total += _occasionScore(item, context.eventType);
      total += _usageBalanceScore(item, context.date);

      if (item.emotionalTag == EmotionalTag.favorite ||
          item.emotionalTag == EmotionalTag.confident) {
        bonus = true;
      }
    }

    return total / items.length +
        (bonus ? AppConstants.emotionalTagBonus.toDouble() : 0);
  }

  /// 40 pt for season match or allWeather; 0 pt for mismatch.
  double _seasonScore(ClothingItemModel item, WeatherSeason weather) {
    if (item.season == ClothingSeason.allWeather) {
      return AppConstants.seasonMatchScore.toDouble();
    }
    final match =
        (item.season == ClothingSeason.hot && weather == WeatherSeason.hot) ||
            (item.season == ClothingSeason.cold &&
                weather == WeatherSeason.cold);
    return match ? AppConstants.seasonMatchScore.toDouble() : 0;
  }

  /// 35 pt for exact occasion match; 35 × 0.3 pt for any other.
  double _occasionScore(ClothingItemModel item, CalendarEventType event) {
    final exact =
        (item.occasion == ClothingOccasion.casual &&
                event == CalendarEventType.casual) ||
            (item.occasion == ClothingOccasion.work &&
                event == CalendarEventType.work) ||
            (item.occasion == ClothingOccasion.formal &&
                event == CalendarEventType.work) ||
            (item.occasion == ClothingOccasion.social &&
                event == CalendarEventType.social);
    return exact
        ? AppConstants.occasionMatchScore.toDouble()
        : AppConstants.occasionMatchScore * 0.3;
  }

  /// 25 pt × factor, where factor fades linearly from 1.0 (never worn)
  /// to 0.0 (worn today) over [AppConstants.recentWearPenaltyDays].
  double _usageBalanceScore(ClothingItemModel item, DateTime ref) {
    if (item.lastWornAt == null) {
      return AppConstants.usageBalanceMaxScore.toDouble();
    }
    final daysAgo = ref
        .difference(item.lastWornAt!)
        .inDays
        .toDouble()
        .clamp(0.0, AppConstants.recentWearPenaltyDays);
    final factor = daysAgo / AppConstants.recentWearPenaltyDays;
    return factor * AppConstants.usageBalanceMaxScore;
  }
}
