import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/features/wardrobe/presentation/widgets/clothing_item_card.dart';

ClothingItemModel _makeItem({
  String imagePath = '/nonexistent/image.jpg',
  int usageCount = 3,
}) =>
    ClothingItemModel(
      id: 'test-id',
      imagePath: imagePath,
      category: ClothingCategory.top,
      season: ClothingSeason.allWeather,
      occasion: ClothingOccasion.casual,
      emotionalTag: EmotionalTag.favorite,
      usageCount: usageCount,
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  group('ClothingItemCard', () {
    testWidgets('renders fallback icon when image file is missing',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 300,
                child: ClothingItemCard(
                  item: _makeItem(imagePath: '/no/such/file.jpg'),
                  isGridMode: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        // Allow FileImage to attempt the load and fail
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byIcon(Icons.checkroom), findsOneWidget);
    });

    testWidgets('displays correct category chip label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: ClothingItemCard(
                item: _makeItem(),
                isGridMode: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Top'), findsWidgets);
    });

    testWidgets('displays correct occasion chip label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: ClothingItemCard(
                item: _makeItem(),
                isGridMode: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Casual'), findsWidgets);
    });

    testWidgets('shows correct usage count badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: ClothingItemCard(
                item: _makeItem(usageCount: 7),
                isGridMode: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('onTap callback is triggered on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: ClothingItemCard(
                item: _makeItem(),
                isGridMode: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(ClothingItemCard));
      expect(tapped, isTrue);
    });
  });
}
