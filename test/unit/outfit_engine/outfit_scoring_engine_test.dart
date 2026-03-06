import 'package:flutter_test/flutter_test.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/features/outfit_engine/engine/outfit_scoring_engine.dart';

void main() {
  group('OutfitScoringEngine', () {
    late OutfitScoringEngine engine;
    late DateTime today;

    setUp(() {
      engine = const OutfitScoringEngine();
      today = DateTime(2024, 6, 15);
    });

    // Helper: build a minimal ClothingItemModel for testing.
    ClothingItemModel item({
      required String id,
      required ClothingCategory category,
      ClothingSeason season = ClothingSeason.allWeather,
      ClothingOccasion occasion = ClothingOccasion.casual,
      EmotionalTag emotionalTag = EmotionalTag.none,
      DateTime? lastWornAt,
    }) =>
        ClothingItemModel(
          id: id,
          imagePath: 'test/$id.jpg',
          category: category,
          season: season,
          occasion: occasion,
          emotionalTag: emotionalTag,
          usageCount: lastWornAt != null ? 1 : 0,
          createdAt: today.subtract(const Duration(days: 30)),
          lastWornAt: lastWornAt,
        );

    OutfitContext casualHot() => OutfitContext(
          weatherSeason: WeatherSeason.hot,
          eventType: CalendarEventType.casual,
          date: today,
        );

    // ─── Test 1 ──────────────────────────────────────────────────────────────
    test('returns empty list when no complete combination exists', () {
      // Only tops — no bottoms or shoes → no valid outfit.
      final result = engine.generateOutfits(
        wardrobe: [item(id: 't1', category: ClothingCategory.top)],
        context: casualHot(),
      );
      expect(result, isEmpty);
    });

    // ─── Test 2 ──────────────────────────────────────────────────────────────
    test('respects maxResults cap', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 't2', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 'b2', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
        item(id: 's2', category: ClothingCategory.shoes),
      ];
      final result = engine.generateOutfits(
        wardrobe: wardrobe,
        context: casualHot(),
        maxResults: 3,
      );
      expect(result.length, lessThanOrEqualTo(3));
    });

    // ─── Test 3 ──────────────────────────────────────────────────────────────
    test('season-matched item scores higher than season-mismatched item', () {
      final bottom = item(id: 'b1', category: ClothingCategory.bottom);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final hotTop = item(
          id: 'hot', category: ClothingCategory.top, season: ClothingSeason.hot);
      final coldTop = item(
          id: 'cold',
          category: ClothingCategory.top,
          season: ClothingSeason.cold);

      final hotResults = engine.generateOutfits(
        wardrobe: [hotTop, bottom, shoe],
        context: casualHot(),
      );
      final coldResults = engine.generateOutfits(
        wardrobe: [coldTop, bottom, shoe],
        context: casualHot(),
      );

      expect(hotResults.first.score, greaterThan(coldResults.first.score));
    });

    // ─── Test 4 ──────────────────────────────────────────────────────────────
    test('never-worn item scores higher than item worn today', () {
      final bottom = item(id: 'b1', category: ClothingCategory.bottom);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final freshTop = item(id: 'fresh', category: ClothingCategory.top);
      final wornTop = item(
          id: 'worn', category: ClothingCategory.top, lastWornAt: today);

      final freshResults = engine.generateOutfits(
        wardrobe: [freshTop, bottom, shoe],
        context: casualHot(),
      );
      final wornResults = engine.generateOutfits(
        wardrobe: [wornTop, bottom, shoe],
        context: casualHot(),
      );

      expect(freshResults.first.score, greaterThan(wornResults.first.score));
    });

    // ─── Test 5 ──────────────────────────────────────────────────────────────
    test('favorite emotional tag adds bonus over identical neutral item', () {
      final bottom = item(id: 'b1', category: ClothingCategory.bottom);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final favTop = item(
          id: 'fav',
          category: ClothingCategory.top,
          emotionalTag: EmotionalTag.favorite);
      final regTop = item(id: 'reg', category: ClothingCategory.top);

      final favResults = engine.generateOutfits(
        wardrobe: [favTop, bottom, shoe],
        context: casualHot(),
      );
      final regResults = engine.generateOutfits(
        wardrobe: [regTop, bottom, shoe],
        context: casualHot(),
      );

      expect(favResults.first.score, greaterThan(regResults.first.score));
    });
  });
}
