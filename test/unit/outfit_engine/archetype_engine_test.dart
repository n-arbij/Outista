import 'package:flutter_test/flutter_test.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/features/outfit_engine/engine/archetype_engine.dart';
import 'package:outista/features/outfit_engine/engine/outfit_scoring_engine.dart';
import 'package:outista/features/outfit_engine/models/outfit_context.dart';

void main() {
  late ArchetypeEngine engine;
  late DateTime today;

  setUp(() {
    engine = const ArchetypeEngine();
    today = DateTime(2024, 6, 15);
  });

  // Helper: build a ClothingItemModel for testing.
  ClothingItemModel item({
    required String id,
    required ClothingCategory category,
    ClothingSeason season = ClothingSeason.allWeather,
    ClothingOccasion occasion = ClothingOccasion.casual,
    ClothingSubcategory subcategory = ClothingSubcategory.none,
    ShoeFormality? shoeFormality,
    String? setId,
    bool isOnePiece = false,
  }) =>
      ClothingItemModel(
        id: id,
        imagePath: 'test/$id.jpg',
        category: category,
        season: season,
        occasion: occasion,
        createdAt: today.subtract(const Duration(days: 30)),
        subcategory: subcategory,
        shoeFormality: shoeFormality,
        setId: setId,
        isOnePiece: isOnePiece,
      );

  // ─── Archetype detection tests ─────────────────────────────────────────────

  group('detectAvailableArchetypes', () {
    test('detects separates when top + bottom + shoes exist', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final archetypes = engine.detectAvailableArchetypes(wardrobe);
      expect(archetypes, contains(OutfitArchetype.separates));
    });

    test('detects onePiece when dress + shoes exist', () {
      final wardrobe = [
        item(
          id: 'd1',
          category: ClothingCategory.onePiece,
          subcategory: ClothingSubcategory.dress,
          isOnePiece: true,
        ),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final archetypes = engine.detectAvailableArchetypes(wardrobe);
      expect(archetypes, contains(OutfitArchetype.onePiece));
    });

    test('detects coordSet when two items share setId + shoes', () {
      const setId = 'set-abc';
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top, setId: setId),
        item(id: 'b1', category: ClothingCategory.bottom, setId: setId),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final archetypes = engine.detectAvailableArchetypes(wardrobe);
      expect(archetypes, contains(OutfitArchetype.coordSet));
    });

    test('detects smartCasual when blazer + top + bottom + shoes', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
        item(
          id: 'bl1',
          category: ClothingCategory.outerwear,
          subcategory: ClothingSubcategory.blazer,
        ),
      ];
      final archetypes = engine.detectAvailableArchetypes(wardrobe);
      expect(archetypes, contains(OutfitArchetype.smartCasual));
    });

    test('returns empty when wardrobe has no shoes at all', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(
          id: 'd1',
          category: ClothingCategory.onePiece,
          isOnePiece: true,
        ),
      ];
      final archetypes = engine.detectAvailableArchetypes(wardrobe);
      expect(archetypes, isEmpty);
    });

    test('returns only onePiece when no separate tops/bottoms', () {
      final wardrobe = [
        item(
          id: 'd1',
          category: ClothingCategory.onePiece,
          subcategory: ClothingSubcategory.dress,
          isOnePiece: true,
        ),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final archetypes = engine.detectAvailableArchetypes(wardrobe);
      expect(archetypes, contains(OutfitArchetype.onePiece));
      expect(archetypes, isNot(contains(OutfitArchetype.separates)));
    });
  });

  // ─── Combination generation tests ─────────────────────────────────────────

  group('generateForArchetype', () {
    test('separates generates tops × bottoms × shoes combos', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 't2', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final combos = engine.generateForArchetype(
        wardrobe: wardrobe,
        archetype: OutfitArchetype.separates,
      );
      // 2 tops × 1 bottom × 1 shoe × 1 outerwear-option (null) = 2
      expect(combos.length, equals(2));
    });

    test('onePiece generates pieces × shoes combos', () {
      final wardrobe = [
        item(
          id: 'd1',
          category: ClothingCategory.onePiece,
          isOnePiece: true,
        ),
        item(
          id: 'd2',
          category: ClothingCategory.onePiece,
          isOnePiece: true,
        ),
        item(id: 's1', category: ClothingCategory.shoes),
        item(id: 's2', category: ClothingCategory.shoes),
      ];
      final combos = engine.generateForArchetype(
        wardrobe: wardrobe,
        archetype: OutfitArchetype.onePiece,
      );
      // 2 pieces × 2 shoes × 1 outerwear-option (null) = 4
      expect(combos.length, equals(4));
      expect(combos.every((c) => c.onePiece != null), isTrue);
    });

    test('onePiece skips formal dress + sporty shoes combo', () {
      final wardrobe = [
        item(
          id: 'd1',
          category: ClothingCategory.onePiece,
          occasion: ClothingOccasion.formal,
          isOnePiece: true,
        ),
        item(
          id: 's1',
          category: ClothingCategory.shoes,
          shoeFormality: ShoeFormality.sporty,
        ),
      ];
      final combos = engine.generateForArchetype(
        wardrobe: wardrobe,
        archetype: OutfitArchetype.onePiece,
      );
      expect(combos, isEmpty);
    });

    test('coordSet only links items with matching setId', () {
      const setId = 'coord-1';
      final wardrobe = [
        item(id: 'ct', category: ClothingCategory.top, setId: setId),
        item(id: 'cb', category: ClothingCategory.bottom, setId: setId),
        item(id: 't2', category: ClothingCategory.top), // no setId
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final combos = engine.generateForArchetype(
        wardrobe: wardrobe,
        archetype: OutfitArchetype.coordSet,
      );
      // Only 1 coord set × 1 shoe × 1 outerwear-option = 1
      expect(combos.length, equals(1));
      expect(combos.first.top!.id, equals('ct'));
      expect(combos.first.bottom!.id, equals('cb'));
    });

    test('incomplete coordSet (no bottom piece) is skipped', () {
      const setId = 'incomplete-set';
      final wardrobe = [
        item(id: 'ct', category: ClothingCategory.top, setId: setId),
        // no bottom in this set
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final combos = engine.generateForArchetype(
        wardrobe: wardrobe,
        archetype: OutfitArchetype.coordSet,
      );
      expect(combos, isEmpty);
    });

    test('season conflict filters hot + cold combination', () {
      final wardrobe = [
        item(
          id: 't1',
          category: ClothingCategory.top,
          season: ClothingSeason.hot,
        ),
        item(
          id: 'b1',
          category: ClothingCategory.bottom,
          season: ClothingSeason.cold,
        ),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final combos = engine.generateForArchetype(
        wardrobe: wardrobe,
        archetype: OutfitArchetype.separates,
      );
      expect(combos, isEmpty);
    });
  });

  // ─── Scoring tests ────────────────────────────────────────────────────────

  group('OutfitScoringEngine with archetypes', () {
    late OutfitScoringEngine scoringEngine;

    setUp(() {
      scoringEngine = const OutfitScoringEngine();
    });

    OutfitContext casualHot() => OutfitContext(
          weatherSeason: WeatherSeason.hot,
          eventType: CalendarEventType.casual,
          date: today,
        );

    test('shoe pairing bonus +3 for casual event + casual shoes', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(
          id: 's1',
          category: ClothingCategory.shoes,
          shoeFormality: ShoeFormality.casual,
        ),
      ];
      final results = scoringEngine.generateOutfits(
        wardrobe: wardrobe,
        context: casualHot(),
      );
      expect(results, isNotEmpty);
      // Bonus includes 8 (all never worn) + 3 (shoe pairing) = 11
      expect(results.first.bonusScore, equals(11.0));
    });

    test('coord set bonus +8 for coordSet archetype', () {
      const setId = 'coord-1';
      final wardrobe = [
        item(id: 'ct', category: ClothingCategory.top, setId: setId),
        item(id: 'cb', category: ClothingCategory.bottom, setId: setId),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final results = scoringEngine.generateOutfits(
        wardrobe: wardrobe,
        context: casualHot(),
        maxResults: 10,
      );
      final coordOutfit = results
          .where((r) => r.outfit.archetype == OutfitArchetype.coordSet)
          .firstOrNull;
      expect(coordOutfit, isNotNull);
      // 8 (all never worn) + 8 (coord set bonus) = 16
      expect(coordOutfit!.bonusScore, equals(16.0));
    });

    test('onePiece outfit scores without top/bottom fields', () {
      final wardrobe = [
        item(
          id: 'd1',
          category: ClothingCategory.onePiece,
          isOnePiece: true,
          season: ClothingSeason.hot,
          occasion: ClothingOccasion.casual,
        ),
        item(
          id: 's1',
          category: ClothingCategory.shoes,
          season: ClothingSeason.allWeather,
          occasion: ClothingOccasion.casual,
        ),
      ];
      final results = scoringEngine.generateOutfits(
        wardrobe: wardrobe,
        context: casualHot(),
      );
      expect(results, isNotEmpty);
      expect(results.first.outfit.onePieceId, equals('d1'));
    });

    test('smartCasual requires blazer subcategory as outerwear', () {
      final wardrobe = [
        item(id: 't1', category: ClothingCategory.top),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
        item(
          id: 'bl1',
          category: ClothingCategory.outerwear,
          subcategory: ClothingSubcategory.blazer,
        ),
      ];
      final results = scoringEngine.generateOutfits(
        wardrobe: wardrobe,
        context: casualHot(),
        maxResults: 20,
      );
      final smartCasualOutfits = results
          .where((r) => r.outfit.archetype == OutfitArchetype.smartCasual)
          .toList();
      expect(smartCasualOutfits, isNotEmpty);
      for (final outfit in smartCasualOutfits) {
        expect(outfit.outfit.outerwearId, equals('bl1'));
      }
    });
  });

  // ─── Backward compatibility tests ─────────────────────────────────────────

  group('backward compatibility', () {
    late OutfitScoringEngine scoringEngine;

    setUp(() {
      scoringEngine = const OutfitScoringEngine();
    });

    OutfitContext casualHot() => OutfitContext(
          weatherSeason: WeatherSeason.hot,
          eventType: CalendarEventType.casual,
          date: today,
        );

    test('existing top/bottom/shoes items generate valid combos', () {
      // Items with all default new fields.
      final wardrobe = [
        ClothingItemModel(
          id: 't1',
          imagePath: 'test/t1.jpg',
          category: ClothingCategory.top,
          season: ClothingSeason.allWeather,
          occasion: ClothingOccasion.casual,
          createdAt: today,
        ),
        ClothingItemModel(
          id: 'b1',
          imagePath: 'test/b1.jpg',
          category: ClothingCategory.bottom,
          season: ClothingSeason.allWeather,
          occasion: ClothingOccasion.casual,
          createdAt: today,
        ),
        ClothingItemModel(
          id: 's1',
          imagePath: 'test/s1.jpg',
          category: ClothingCategory.shoes,
          season: ClothingSeason.allWeather,
          occasion: ClothingOccasion.casual,
          createdAt: today,
        ),
      ];
      final results = scoringEngine.generateOutfits(
        wardrobe: wardrobe,
        context: casualHot(),
      );
      expect(results, isNotEmpty);
    });

    test('items with subcategory=none are not excluded', () {
      final wardrobe = [
        item(
          id: 't1',
          category: ClothingCategory.top,
          subcategory: ClothingSubcategory.none,
        ),
        item(id: 'b1', category: ClothingCategory.bottom),
        item(id: 's1', category: ClothingCategory.shoes),
      ];
      final combos = engine.generateForArchetype(
        wardrobe: wardrobe,
        archetype: OutfitArchetype.separates,
      );
      expect(combos, isNotEmpty);
    });

    test('shoes with null shoeFormality default to casual in validation', () {
      // A casual jumpsuit + shoes with null formality should NOT be blocked.
      final wardrobe = [
        item(
          id: 'j1',
          category: ClothingCategory.onePiece,
          subcategory: ClothingSubcategory.jumpsuit,
          occasion: ClothingOccasion.casual,
          isOnePiece: true,
        ),
        // shoeFormality is null (default) — should NOT be treated as heels
        item(
          id: 's1',
          category: ClothingCategory.shoes,
          // no shoeFormality, no subcategory — should not be blocked
        ),
      ];
      final combos = engine.generateForArchetype(
        wardrobe: wardrobe,
        archetype: OutfitArchetype.onePiece,
      );
      expect(combos, isNotEmpty);
    });
  });
}
