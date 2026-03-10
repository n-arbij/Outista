import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../data/models/clothing_item_model.dart';
import '../../../data/models/outfit_model.dart';
import '../models/outfit_context.dart';
import '../models/outfit_generation_result.dart';
import '../models/scored_outfit.dart';
import 'archetype_engine.dart';

export '../models/outfit_context.dart';
export '../models/outfit_generation_result.dart';
export '../models/scored_outfit.dart';

/// Deterministic outfit scoring engine.
///
/// Delegates combination generation to [ArchetypeEngine], scores each
/// [OutfitCombination] against the given [OutfitContext], sorts descending,
/// and returns the top [maxResults] [ScoredOutfit]s.
///
/// This class has no Flutter dependencies and is fully testable without
/// a widget tree.
class OutfitScoringEngine {
  final ArchetypeEngine archetypeEngine;

  const OutfitScoringEngine({this.archetypeEngine = const ArchetypeEngine()});

  static const _uuid = Uuid();

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Returns up to [maxResults] ranked [ScoredOutfit]s built from [wardrobe].
  ///
  /// Delegates combination generation to [archetypeEngine]. Returns an empty
  /// list when no valid combinations exist.
  List<ScoredOutfit> generateOutfits({
    required List<ClothingItemModel> wardrobe,
    required OutfitContext context,
    int maxResults = 4,
  }) {
    final archetypes = archetypeEngine.detectAvailableArchetypes(wardrobe);
    if (archetypes.isEmpty) return [];

    final allCombinations = archetypes
        .expand((a) => archetypeEngine.generateForArchetype(
              wardrobe: wardrobe,
              archetype: a,
            ))
        .toList();

    final results = allCombinations
        .map((combo) => _buildScoredOutfit(combo, context))
        .toList();

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
    // Keep the existing combination count formula for backward compatibility.
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
    OutfitCombination combination,
    OutfitContext context,
  ) {
    final items = _itemsFromCombination(combination);

    final seasonScore =
        _calculateSeasonScore(items, context.weatherSeason);
    final occasionScore =
        _calculateOccasionScore(combination, context.eventType);
    final usageScore =
        _calculateUsageScore(items, context.date);
    final shoePairingBonus =
        _calculateShoePairingBonus(combination, context.eventType);
    final coordSetBonus = _calculateCoordSetBonus(combination);
    final bonusScore =
        _calculateBonusScore(items, context.date) +
        shoePairingBonus +
        coordSetBonus;

    final total = seasonScore + occasionScore + usageScore + bonusScore;

    final topId = combination.top?.id ?? combination.onePiece!.id;
    final bottomId = combination.bottom?.id ?? combination.onePiece!.id;

    return ScoredOutfit(
      totalScore: total,
      seasonScore: seasonScore,
      occasionScore: occasionScore,
      usageScore: usageScore,
      bonusScore: bonusScore,
      outfit: OutfitModel(
        id: _uuid.v4(),
        topId: topId,
        bottomId: bottomId,
        shoesId: combination.shoes.id,
        outerwearId: combination.outerwear?.id,
        onePieceId: combination.onePiece?.id,
        archetype: combination.archetype,
        score: total,
        occasionContext: context.eventType.name,
        weatherContext: context.weatherSeason.name,
        generatedAt: context.date,
      ),
    );
  }

  /// Extracts the scoring item list from a [combination].
  ///
  /// For one-piece archetypes: `[onePiece, shoes, (outerwear?)]`.
  /// For separates archetypes: `[top, bottom, shoes, (outerwear?)]`.
  List<ClothingItemModel> _itemsFromCombination(
      OutfitCombination combination) {
    if (combination.onePiece != null) {
      return [
        combination.onePiece!,
        combination.shoes,
        if (combination.outerwear != null) combination.outerwear!,
      ];
    }
    return [
      combination.top!,
      combination.bottom!,
      combination.shoes,
      if (combination.outerwear != null) combination.outerwear!,
    ];
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

  /// Computes the occasion component (0–35 pts) averaged across the
  /// relevant items for the combination's archetype.
  double _calculateOccasionScore(
      OutfitCombination combination, CalendarEventType event) {
    final items = _itemsFromCombination(combination);
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

  /// Awards a bonus for intentional shoe-formality pairings.
  ///
  /// Only awarded when the shoe's [ShoeFormality] is explicitly set (non-null),
  /// so existing items without formality data are unaffected.
  double _calculateShoePairingBonus(
      OutfitCombination combination, CalendarEventType event) {
    final shoeFormality = combination.shoes.shoeFormality;
    if (shoeFormality == null) return 0;

    switch (event) {
      case CalendarEventType.work:
        return shoeFormality == ShoeFormality.formal ? 5 : 0;
      case CalendarEventType.social:
        return shoeFormality == ShoeFormality.formal ? 4 : 0;
      case CalendarEventType.casual:
        return shoeFormality == ShoeFormality.casual ? 3 : 0;
      case CalendarEventType.unknown:
        return 0;
    }
  }

  /// Awards a coherence bonus for coord-set outfits.
  double _calculateCoordSetBonus(OutfitCombination combination) {
    return combination.archetype == OutfitArchetype.coordSet ? 8 : 0;
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

