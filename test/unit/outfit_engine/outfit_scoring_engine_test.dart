import 'package:flutter_test/flutter_test.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/features/outfit_engine/engine/outfit_scoring_engine.dart';
import 'package:outista/features/outfit_engine/models/outfit_context.dart';
import 'package:outista/features/outfit_engine/models/outfit_generation_result.dart';

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

    // Helper: build a minimal wardrobe with one item per category.
    List<ClothingItemModel> minimalWardrobe({
      EmotionalTag topTag = EmotionalTag.none,
      DateTime? topLastWorn,
      DateTime? bottomLastWorn,
      DateTime? shoeLastWorn,
    }) =>
        [
          item(
            id: 't1',
            category: ClothingCategory.top,
            emotionalTag: topTag,
            lastWornAt: topLastWorn,
          ),
          item(
            id: 'b1',
            category: ClothingCategory.bottom,
            lastWornAt: bottomLastWorn,
          ),
          item(
            id: 's1',
            category: ClothingCategory.shoes,
            lastWornAt: shoeLastWorn,
          ),
        ];

    // ─── Existing Test 1 ─────────────────────────────────────────────────────
    test('returns empty list when no complete combination exists', () {
      // Only tops — no bottoms or shoes → no valid outfit.
      final result = engine.generateOutfits(
        wardrobe: [item(id: 't1', category: ClothingCategory.top)],
        context: casualHot(),
      );
      expect(result, isEmpty);
    });

    // ─── Existing Test 2 ─────────────────────────────────────────────────────
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

    // ─── Existing Test 3 ─────────────────────────────────────────────────────
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

    // ─── Existing Test 4 ─────────────────────────────────────────────────────
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

    // ─── Existing Test 5 ─────────────────────────────────────────────────────
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

    // ─── Scoring accuracy tests ───────────────────────────────────────────────

    test('occasion-matched outfit scores higher than mismatched', () {
      final context = OutfitContext(
        weatherSeason: WeatherSeason.allWeather,
        eventType: CalendarEventType.work,
        date: today,
      );
      final bottom = item(id: 'b1', category: ClothingCategory.bottom);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final workTop =
          item(id: 'work', category: ClothingCategory.top, occasion: ClothingOccasion.work);
      final casualTop =
          item(id: 'cas', category: ClothingCategory.top, occasion: ClothingOccasion.casual);

      final workResult = engine.generateOutfits(wardrobe: [workTop, bottom, shoe], context: context);
      final casualResult = engine.generateOutfits(wardrobe: [casualTop, bottom, shoe], context: context);

      expect(workResult.first.score, greaterThan(casualResult.first.score));
    });

    test('items worn 7+ days ago score same as never-worn (usage fully recovered)', () {
      final bottom = item(id: 'b1', category: ClothingCategory.bottom);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final neverWornTop = item(id: 'new', category: ClothingCategory.top);
      final recoveredTop = item(
          id: 'old',
          category: ClothingCategory.top,
          lastWornAt: today.subtract(const Duration(days: 7)));

      // Same usage score expected → same totalScore for otherwise identical items.
      final neverResults =
          engine.generateOutfits(wardrobe: [neverWornTop, bottom, shoe], context: casualHot());
      final recoveredResults =
          engine.generateOutfits(wardrobe: [recoveredTop, bottom, shoe], context: casualHot());

      // Diversity bonus differs (never-worn → 8, worn-7d → 5), but usageScore is same.
      expect(neverResults.first.usageScore, equals(recoveredResults.first.usageScore));
    });

    test('favorite tag adds exactly 15 bonus points relative to no-tag outfit', () {
      final wardrobe = minimalWardrobe();
      final favWardrobe = minimalWardrobe(topTag: EmotionalTag.favorite);

      final noTagResult = engine.generateOutfits(wardrobe: wardrobe, context: casualHot());
      final favResult = engine.generateOutfits(wardrobe: favWardrobe, context: casualHot());

      expect(
        favResult.first.bonusScore - noTagResult.first.bonusScore,
        equals(15.0),
      );
    });

    test('confident tag adds exactly 10 bonus points relative to no-tag outfit', () {
      final wardrobe = minimalWardrobe();
      final confWardrobe = minimalWardrobe(topTag: EmotionalTag.confident);

      final noTagResult = engine.generateOutfits(wardrobe: wardrobe, context: casualHot());
      final confResult = engine.generateOutfits(wardrobe: confWardrobe, context: casualHot());

      expect(
        confResult.first.bonusScore - noTagResult.first.bonusScore,
        equals(10.0),
      );
    });

    test('both favorite and confident tags add 15 not 25 bonus points', () {
      // top=favorite, bottom=confident, shoe=none → both tags present
      final bothTagWardrobe = [
        item(id: 't1', category: ClothingCategory.top, emotionalTag: EmotionalTag.favorite),
        item(id: 'b1', category: ClothingCategory.bottom, emotionalTag: EmotionalTag.confident),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final favOnlyWardrobe = minimalWardrobe(topTag: EmotionalTag.favorite);

      final bothResult =
          engine.generateOutfits(wardrobe: bothTagWardrobe, context: casualHot());
      final favOnlyResult =
          engine.generateOutfits(wardrobe: favOnlyWardrobe, context: casualHot());

      // Both should have the same bonusScore — 15 (not 25) for emotional portion.
      expect(bothResult.first.bonusScore, equals(favOnlyResult.first.bonusScore));
    });

    test('all-new-items diversity bonus score equals 8', () {
      // All items never worn, no emotional tags → diversity bonus = 8.
      final result =
          engine.generateOutfits(wardrobe: minimalWardrobe(), context: casualHot());
      expect(result.first.bonusScore, equals(8.0));
    });

    test('no-recent-wear diversity bonus score equals 5 when all worn 7+ days ago', () {
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      final wardrobe = minimalWardrobe(
        topLastWorn: sevenDaysAgo,
        bottomLastWorn: sevenDaysAgo,
        shoeLastWorn: sevenDaysAgo,
      );
      final result = engine.generateOutfits(wardrobe: wardrobe, context: casualHot());
      expect(result.first.bonusScore, equals(5.0));
    });

    // ─── Conflict and edge-case tests ─────────────────────────────────────────

    test('hot + cold season combination is filtered out', () {
      final hotTop =
          item(id: 'hot', category: ClothingCategory.top, season: ClothingSeason.hot);
      final coldBottom =
          item(id: 'cold', category: ClothingCategory.bottom, season: ClothingSeason.cold);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final result = engine.generateOutfits(
        wardrobe: [hotTop, coldBottom, shoe],
        context: casualHot(),
      );
      expect(result, isEmpty);
    });

    test('allWeather + hot combination is not filtered', () {
      final allTop =
          item(id: 'all', category: ClothingCategory.top, season: ClothingSeason.allWeather);
      final hotBottom =
          item(id: 'hot', category: ClothingCategory.bottom, season: ClothingSeason.hot);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final result = engine.generateOutfits(
        wardrobe: [allTop, hotBottom, shoe],
        context: casualHot(),
      );
      expect(result, isNotEmpty);
    });

    test('empty wardrobe returns empty OutfitGenerationResult', () {
      final result = engine.generateOutfitResult(
        wardrobe: [],
        context: casualHot(),
      );
      expect(result.isEmpty, isTrue);
      expect(result.totalCombinationsEvaluated, equals(0));
    });

    test('missing shoes returns empty OutfitGenerationResult', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        // no shoes
      ];
      final result =
          engine.generateOutfitResult(wardrobe: wardrobe, context: casualHot());
      expect(result.isEmpty, isTrue);
    });

    test('single item per category returns one result with no alternatives', () {
      final result = engine.generateOutfitResult(
        wardrobe: minimalWardrobe(),
        context: casualHot(),
      );
      expect(result.primary, isNotNull);
      expect(result.alternatives, isEmpty);
    });

    test('formal occasion scores 0.7 ratio for work event', () {
      final context = OutfitContext(
        weatherSeason: WeatherSeason.allWeather,
        eventType: CalendarEventType.work,
        date: today,
      );
      final formalTop =
          item(id: 'ft', category: ClothingCategory.top, occasion: ClothingOccasion.formal);
      final workTop =
          item(id: 'wt', category: ClothingCategory.top, occasion: ClothingOccasion.work);
      final bottom = item(id: 'b1', category: ClothingCategory.bottom);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final formalResult =
          engine.generateOutfits(wardrobe: [formalTop, bottom, shoe], context: context);
      final workResult =
          engine.generateOutfits(wardrobe: [workTop, bottom, shoe], context: context);

      // Formal at work should score lower than work at work but higher than 0.3.
      expect(formalResult.first.occasionScore,
          greaterThan(0.3 * 35)); // above 0.3 threshold
      expect(formalResult.first.occasionScore, lessThan(workResult.first.occasionScore));
    });

    test('casual occasion scores 0.8 ratio for unknown event', () {
      final context = OutfitContext(
        weatherSeason: WeatherSeason.allWeather,
        eventType: CalendarEventType.unknown,
        date: today,
      );
      final casualTop =
          item(id: 'ct', category: ClothingCategory.top, occasion: ClothingOccasion.casual);
      final workTop =
          item(id: 'wt', category: ClothingCategory.top, occasion: ClothingOccasion.work);
      final bottom = item(id: 'b1', category: ClothingCategory.bottom);
      final shoe = item(id: 's1', category: ClothingCategory.shoes);

      final casualResult =
          engine.generateOutfits(wardrobe: [casualTop, bottom, shoe], context: context);
      final workResult =
          engine.generateOutfits(wardrobe: [workTop, bottom, shoe], context: context);

      // Casual + unknown should score higher than work + unknown (0.3 partial).
      expect(casualResult.first.occasionScore, greaterThan(workResult.first.occasionScore));
    });

    // ─── Generation result tests ──────────────────────────────────────────────

    test('generateOutfitResult primary is always the highest-scored outfit', () {
      final wardrobe = [
        item(id: 'hot-t', category: ClothingCategory.top, season: ClothingSeason.hot),
        item(id: 'cold-t', category: ClothingCategory.top, season: ClothingSeason.cold),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final result = engine.generateOutfitResult(wardrobe: wardrobe, context: casualHot());

      final allScores = result.allOutfits.map((o) => o.totalScore).toList();
      expect(result.primary!.totalScore, equals(allScores.reduce((a, b) => a > b ? a : b)));
    });

    test('alternatives are sorted descending by score', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 't2', category: ClothingCategory.top, season: ClothingSeason.cold),
        item(id: 't3', category: ClothingCategory.top, season: ClothingSeason.hot),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final result = engine.generateOutfitResult(wardrobe: wardrobe, context: casualHot());

      final altScores = result.alternatives.map((o) => o.totalScore).toList();
      for (int i = 1; i < altScores.length; i++) {
        expect(altScores[i - 1], greaterThanOrEqualTo(altScores[i]));
      }
    });

    test('totalCombinationsEvaluated matches tops × bottoms × shoes count', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 't2', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 'b2', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
        item(id: 's2', category: ClothingCategory.shoes),
      ];
      final result = engine.generateOutfitResult(wardrobe: wardrobe, context: casualHot());

      // 2 tops × 2 bottoms × 2 shoes = 8
      expect(result.totalCombinationsEvaluated, equals(8));
    });

    test('generatedAt in result matches the date in context', () {
      final context = OutfitContext(
        weatherSeason: WeatherSeason.allWeather,
        eventType: CalendarEventType.casual,
        date: today,
      );
      final result = engine.generateOutfitResult(
        wardrobe: minimalWardrobe(),
        context: context,
      );
      expect(result.generatedAt, equals(today));
    });
  });
}
