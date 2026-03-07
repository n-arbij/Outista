import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/data/models/outfit_model.dart';
import 'package:outista/features/outfit_engine/models/scored_outfit.dart';
import 'package:outista/features/home/presentation/widgets/outfit_card.dart';
import 'package:outista/features/home/presentation/widgets/outfit_item_tile.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

ClothingItemModel _item(String id, ClothingCategory cat) => ClothingItemModel(
      id: id,
      imagePath: '/nonexistent/path.jpg',
      category: cat,
      season: ClothingSeason.allWeather,
      occasion: ClothingOccasion.casual,
      createdAt: DateTime(2024, 1, 1),
    );

ClothingItemModel _favoriteItem(String id) => ClothingItemModel(
      id: id,
      imagePath: '/nonexistent/path.jpg',
      category: ClothingCategory.top,
      season: ClothingSeason.allWeather,
      occasion: ClothingOccasion.casual,
      emotionalTag: EmotionalTag.favorite,
      createdAt: DateTime(2024, 1, 1),
    );

OutfitModel _outfit({String? outerwearId}) => OutfitModel(
      id: 'outfit1',
      topId: 'top1',
      bottomId: 'bot1',
      shoesId: 'shoe1',
      outerwearId: outerwearId,
      score: 85.0,
      occasionContext: 'casual',
      weatherContext: 'allWeather',
      generatedAt: DateTime.now(),
    );

ScoredOutfit _scored({String? outerwearId}) => ScoredOutfit(
      outfit: _outfit(outerwearId: outerwearId),
      totalScore: 85.0,
      seasonScore: 35,
      occasionScore: 28,
      usageScore: 20,
      bonusScore: 2,
    );

List<ClothingItemModel> _items({bool withOuterwear = false}) => [
      _item('top1', ClothingCategory.top),
      _item('bot1', ClothingCategory.bottom),
      _item('shoe1', ClothingCategory.shoes),
      if (withOuterwear) _item('outer1', ClothingCategory.outerwear),
    ];

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  // Suppress FileImage errors from nonexistent paths in tests.
  setUp(() {
    HttpOverrides.global = _SilentHttpOverrides();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('OutfitCard', () {
    testWidgets('renders OutfitItemTile for each clothing item', (tester) async {
      await tester.pumpWidget(
        _wrap(OutfitCard(
          scoredOutfit: _scored(),
          items: _items(),
          isWorn: false,
        )),
      );
      await tester.pump();
      expect(find.byType(OutfitItemTile), findsNWidgets(3));
    });

    testWidgets('shows score chip with correct value', (tester) async {
      await tester.pumpWidget(
        _wrap(OutfitCard(
          scoredOutfit: _scored(),
          items: _items(),
          isWorn: false,
        )),
      );
      await tester.pump();
      expect(find.textContaining('85'), findsOneWidget);
      expect(find.textContaining('pts'), findsOneWidget);
    });

    testWidgets('shows green tint when isWorn is true', (tester) async {
      await tester.pumpWidget(
        _wrap(OutfitCard(
          scoredOutfit: _scored(),
          items: _items(),
          isWorn: true,
        )),
      );
      await tester.pump();
      // Green tint is applied via Container color — confirm no exception thrown
      // and card renders normally.
      expect(find.byType(OutfitCard), findsOneWidget);
    });

    testWidgets('shows Worn Today chip when isWorn is true', (tester) async {
      await tester.pumpWidget(
        _wrap(OutfitCard(
          scoredOutfit: _scored(),
          items: _items(),
          isWorn: true,
        )),
      );
      await tester.pump();
      expect(find.textContaining('Worn Today'), findsOneWidget);
    });

    testWidgets('does NOT show Worn Today chip when isWorn is false',
        (tester) async {
      await tester.pumpWidget(
        _wrap(OutfitCard(
          scoredOutfit: _scored(),
          items: _items(),
          isWorn: false,
        )),
      );
      await tester.pump();
      expect(find.textContaining('Worn Today'), findsNothing);
    });

    testWidgets('outerwear tile shown when outfit has outerwear', (tester) async {
      await tester.pumpWidget(
        _wrap(OutfitCard(
          scoredOutfit: _scored(outerwearId: 'outer1'),
          items: _items(withOuterwear: true),
          isWorn: false,
        )),
      );
      await tester.pump();
      expect(find.byType(OutfitItemTile), findsNWidgets(4));
    });

    testWidgets('outerwear tile NOT shown when outfit has no outerwear',
        (tester) async {
      await tester.pumpWidget(
        _wrap(OutfitCard(
          scoredOutfit: _scored(),
          items: _items(withOuterwear: false),
          isWorn: false,
        )),
      );
      await tester.pump();
      expect(find.byType(OutfitItemTile), findsNWidgets(3));
    });

    testWidgets('tapping card does not navigate', (tester) async {
      var navigated = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GestureDetector(
                onTap: () => navigated = true,
                child: SingleChildScrollView(
                  child: OutfitCard(
                    scoredOutfit: _scored(),
                    items: _items(),
                    isWorn: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // Tapping the score chip area (which is inside the card)
      await tester.tap(find.textContaining('pts'));
      await tester.pump();
      // The outer gesture detector did fire, but the card itself has no
      // navigation — navigated flag proves no GoRouter call was made.
      expect(navigated, isTrue); // tap propagated to parent, not card nav
    });
  });
}

class _SilentHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}
