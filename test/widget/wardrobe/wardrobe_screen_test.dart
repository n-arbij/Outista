import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/features/wardrobe/presentation/widgets/clothing_item_card.dart';
import 'package:outista/features/wardrobe/presentation/screens/wardrobe_screen.dart';
import 'package:outista/shared/providers/repository_providers.dart';

ClothingItemModel _item(String id, ClothingCategory cat) => ClothingItemModel(
      id: id,
      imagePath: '/nonexistent/path.jpg',
      category: cat,
      season: ClothingSeason.allWeather,
      occasion: ClothingOccasion.casual,
      createdAt: DateTime(2024, 1, 1),
    );

Widget _buildApp({required List<ClothingItemModel> items}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const WardrobeScreen()),
    GoRoute(
      path: '/wardrobe/item/:id',
      builder: (_, state) =>
          Scaffold(body: Text('detail ${state.pathParameters['id']}')),
    ),
  ]);

  return ProviderScope(
    overrides: [
      allClothingItemsProvider.overrideWith((ref) => Stream.value(items)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('WardrobeScreen', () {
    testWidgets('shows empty state when item list is empty', (tester) async {
      await tester.pumpWidget(_buildApp(items: []));
      await tester.pumpAndSettle();
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.text('Add your first item'), findsOneWidget);
    });

    testWidgets('shows grid of cards when items exist', (tester) async {
      final items = [
        _item('1', ClothingCategory.top),
        _item('2', ClothingCategory.bottom),
      ];
      await tester.pumpWidget(_buildApp(items: items));
      await tester.pumpAndSettle();
      expect(find.byType(ClothingItemCard), findsNWidgets(2));
    });

    testWidgets('filter chip changes active filter', (tester) async {
      final items = [
        _item('1', ClothingCategory.top),
        _item('2', ClothingCategory.bottom),
      ];
      await tester.pumpWidget(_buildApp(items: items));
      await tester.pumpAndSettle();

      // ChoiceChips in FilterChipBar: index 0 = All, 1 = Top, 2 = Bottom ...
      await tester.tap(find.byType(ChoiceChip).at(1));
      await tester.pumpAndSettle();

      expect(find.byType(ClothingItemCard), findsOneWidget);
    });

    testWidgets('toggle button switches between grid and list view',
        (tester) async {
      final items = [_item('1', ClothingCategory.top)];
      await tester.pumpWidget(_buildApp(items: items));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.list), findsOneWidget);
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });

    testWidgets('tapping a card navigates to item detail route', (tester) async {
      final items = [_item('abc', ClothingCategory.top)];
      await tester.pumpWidget(_buildApp(items: items));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ClothingItemCard).first);
      await tester.pumpAndSettle();

      expect(find.text('detail abc'), findsOneWidget);
    });
  });
}
