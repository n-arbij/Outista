import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../data/models/clothing_item_model.dart';
import '../../../data/models/outfit_model.dart';
import '../models/outfit_context.dart';
import '../models/outfit_generation_result.dart';
import '../models/scored_outfit.dart';

export '../models/outfit_context.dart';
export '../models/outfit_generation_result.dart';
export '../models/scored_outfit.dart';

/// Deterministic outfit scoring engine.
///
/// Iterates every tops × bottoms × shoes × (no outerwear | outerwear)
/// combination, scores each against the given [OutfitContext], filters
/// season-conflicting combos, sorts descending, and returns the top
/// [maxResults] [ScoredOutfit]s.
///
/// This class has no Flutter dependencies and is fully testable without
/// a widget tree.
class OutfitScoringEngine {
  const OutfitScoringEngine();

  static const _uuid = Uuid();

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Returns up to [maxResults] ranked [ScoredOutfit]s built from [wardrobe].
  ///
  /// Returns an empty list when any required category (tops, bottoms, shoes)
  /// is absent from [wardrobe].
  List<ScoredOutfit> generateOutfits({
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
    final outerwears = wardrobe
        .where((i) => i.category == ClothingCategory.outerwear)
        .toList();

    if (tops.isEmpty || bottoms.isEmpty || shoes.isEmpty) return [];

    final results = <ScoredOutfit>[];

    for (final top in tops) {
      for (final bottom in bottoms) {
        for (final shoe in shoes) {
          final outerwearOptions = <ClothingItemModel?>[null, ...outerwears];
          for (final outerwear in outerwearOptions) {
            final items = [
              top,
              bottom,
              shoe,
              if (outerwear != null) outerwear,
            ];
            if (_hasSeasonConflict(items)) continue;
            results.add(_buildScoredOutfit(items, context));
          }
        }
      }
    }

    results.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return results.take(maxResults).toList();
  }

  /// Generates outfits and wraps the result in an [OutfitGenerationResult].
  ///
  /// Always returns a result — [OutfitGenerationResult.isEmpty] is `true`
  /// when no valid combinations exist.
  OutfitGenerationResult generateOutfitResult({
    required List<ClothingItemModel> wardrobe,
    required OutfitContext context,
  }) {
    final tops =
        wardrobe.where((i) => i.category == ClothingCategory.top).toList();
    final bottoms =
        wardrobe.where((i) => i.category == ClothingCategory.bottom).toList();
    final shoes =
        wardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    final combos = tops.length * bottoms.length * shoes.length;

    final scored =
        generateOutfits(wardrobe: wardrobe, context: context, maxResults: 4);

    return OutfitGenerationResult(
      primary: scored.isEmpty ? null : scored.first,
      alternatives: scored.length > 1 ? scored.sublist(1) : [],
      context: context,
      generatedAt: context.date,
      totalCombinationsEvaluated: combos,
    );
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  ScoredOutfit _buildScoredOutfit(
    List<ClothingItemModel> items,
    OutfitContext context,
  ) {
    final seasonScore =
        _calculateSeasonScore(items, context.weatherSeason);
    final occasionScore =
        _calculateOccasionScore(items, context.eventType);
    final usageScore =
        _calculateUsageScore(items, context.date);
    final bonusScore =
        _calculateBonusScore(items, context.date);

    final total = seasonScore + occasionScore + usageScore + bonusScore;

    final top = items.firstWhere((i) => i.category == ClothingCategory.top);
    final bottom =
        items.firstWhere((i) => i.category == ClothingCategory.bottom);
    final shoe =
        items.firstWhere((i) => i.category == ClothingCategory.shoes);
    final outerwear = items
        .where((i) => i.category == ClothingCategory.outerwear)
        .firstOrNull;

    return ScoredOutfit(
      totalScore: total,
      seasonScore: seasonScore,
      occasionScore: occasionScore,
      usageScore: usageScore,
      bonusScore: bonusScore,
      outfit: OutfitModel(
        id: _uuid.v4(),
        topId: top.id,
        bottomId: bottom.id,
        shoesId: shoe.id,
        outerwearId: outerwear?.id,
        score: total,
        occasionContext: context.eventType.name,
        weatherContext: context.weatherSeason.name,
        generatedAt: context.date,
      ),
    );
  }

  /// Computes the season component (0–40 pts) averaged across all items.
  double _calculateSeasonScore(
      List<ClothingItemModel> items, WeatherSeason weather) {
    if (items.isEmpty) return 0;
    final avg =
        items.map((i) => _itemSeasonScore(i, weather)).reduce((a, b) => a + b) /
            items.length;
    return avg * AppConstants.seasonMatchScore;
  }

  /// Computes the occasion component (0–35 pts) averaged across all items.
  double _calculateOccasionScore(
      List<ClothingItemModel> items, CalendarEventType event) {
    if (items.isEmpty) return 0;
    final avg = items
            .map((i) => _itemOccasionScore(i, event))
            .reduce((a, b) => a + b) /
        items.length;
    return avg * AppConstants.occasionMatchScore;
  }

  /// Computes the usage balance component (0–25 pts) averaged across all items.
  double _calculateUsageScore(
      List<ClothingItemModel> items, DateTime ref) {
    if (items.isEmpty) return 0;
    final avg =
        items.map((i) => _itemUsageScore(i, ref)).reduce((a, b) => a + b) /
            items.length;
    return avg * AppConstants.usageBalanceMaxScore;
  }

  /// Computes flat emotional + diversity bonuses.
  double _calculateBonusScore(
      List<ClothingItemModel> items, DateTime ref) {
    // Emotional tag bonus — not additive when both tags present.
    final hasFavorite =
        items.any((i) => i.emotionalTag == EmotionalTag.favorite);
    final hasConfident =
        items.any((i) => i.emotionalTag == EmotionalTag.confident);

    double emotionalBonus = 0;
    if (hasFavorite) {
      emotionalBonus = AppConstants.emotionalTagBonus.toDouble(); // 15
    } else if (hasConfident) {
      emotionalBonus = AppConstants.confidentTagBonus.toDouble(); // 10
    }

    // Diversity bonus.
    final allNeverWorn = items.every((i) => i.lastWornAt == null);
    final noneRecentlyWorn = items.every((i) {
      if (i.lastWornAt == null) return true;
      return ref.difference(i.lastWornAt!).inDays >= 3;
    });

    double diversityBonus = 0;
    if (allNeverWorn) {
      diversityBonus = AppConstants.allNewDiversityBonus.toDouble(); // 8
    } else if (noneRecentlyWorn) {
      diversityBonus = AppConstants.noRecentWearDiversityBonus.toDouble(); // 5
    }

    return emotionalBonus + diversityBonus;
  }

  /// Returns `true` when the combination has a season conflict —
  /// i.e. one non-allWeather item is hot-season and another is cold-season.
  bool _hasSeasonConflict(List<ClothingItemModel> items) {
    bool hasHot = false;
    bool hasCold = false;
    for (final item in items) {
      if (item.season == ClothingSeason.hot) hasHot = true;
      if (item.season == ClothingSeason.cold) hasCold = true;
    }
    return hasHot && hasCold;
  }

  /// Season match ratio for a single item: 1.0 = full match, 0.0 = no match.
  double _itemSeasonScore(ClothingItemModel item, WeatherSeason weather) {
    if (item.season == ClothingSeason.allWeather) return 1.0;
    final match =
        (item.season == ClothingSeason.hot && weather == WeatherSeason.hot) ||
            (item.season == ClothingSeason.cold &&
                weather == WeatherSeason.cold);
    return match ? 1.0 : 0.0;
  }

  /// Occasion match ratio for a single item.
  ///
  /// * Exact match → 1.0
  /// * Casual + unknown event → 0.8 (safe default)
  /// * Formal + work event → 0.7 (office-appropriate)
  /// * Any other mismatch → 0.3
  double _itemOccasionScore(
      ClothingItemModel item, CalendarEventType event) {
    // Map event type to the expected occasion.
    final match =
        (item.occasion == ClothingOccasion.casual &&
                event == CalendarEventType.casual) ||
            (item.occasion == ClothingOccasion.work &&
                event == CalendarEventType.work) ||
            (item.occasion == ClothingOccasion.social &&
                event == CalendarEventType.social);
    if (match) return 1.0;

    // Casual is a safe fallback when event type is unknown.
    if (item.occasion == ClothingOccasion.casual &&
        event == CalendarEventType.unknown) return 0.8;

    // Formal items are somewhat appropriate for work.
    if (item.occasion == ClothingOccasion.formal &&
        event == CalendarEventType.work) return 0.7;

    return 0.3;
  }

  /// Usage balance ratio for a single item.
  ///
  /// * Never worn → 1.0
  /// * Worn [AppConstants.recentWearPenaltyDays] or more days ago → 1.0
  /// * Worn today → 0.0
  /// * Linear interpolation in between.
  double _itemUsageScore(ClothingItemModel item, DateTime ref) {
    if (item.lastWornAt == null) {
      return 1.0;
    }
    final daysAgo = ref
        .difference(item.lastWornAt!)
        .inDays
        .toDouble()
        .clamp(0.0, AppConstants.recentWearPenaltyDays);
    return daysAgo / AppConstants.recentWearPenaltyDays;
  }
}

