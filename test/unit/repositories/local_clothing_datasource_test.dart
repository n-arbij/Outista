import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/database/app_database.dart';
import 'package:outista/data/datasources/local/local_clothing_datasource.dart';
import 'package:outista/data/datasources/local/local_wear_log_datasource.dart';
import 'package:outista/data/models/clothing_item_model.dart';

void main() {
  late AppDatabase db;
  late LocalWearLogDatasource wearLogDs;
  late LocalClothingDatasource clothingDs;

  final _base = DateTime(2024, 6, 15, 12);
  final _sample = ClothingItemModel(
    id: 'item-1',
    imagePath: 'test/item-1.jpg',
    category: ClothingCategory.top,
    season: ClothingSeason.allWeather,
    occasion: ClothingOccasion.casual,
    createdAt: _base,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    wearLogDs = LocalWearLogDatasource(db);
    clothingDs = LocalClothingDatasource(db, wearLogDs);
  });

  tearDown(() async => db.close());

  group('LocalClothingDatasource', () {
    test('addItem then getAllItems returns the item', () async {
      await clothingDs.addItem(_sample);
      final items = await clothingDs.getAllItems();
      expect(items.length, 1);
      expect(items.first.id, _sample.id);
      expect(items.first.category, ClothingCategory.top);
    });

    test('updateItem persists changes correctly', () async {
      await clothingDs.addItem(_sample);
      final updated = ClothingItemModel(
        id: _sample.id,
        imagePath: _sample.imagePath,
        category: _sample.category,
        season: ClothingSeason.cold,
        occasion: ClothingOccasion.work,
        createdAt: _sample.createdAt,
      );
      await clothingDs.updateItem(updated);
      final result = await clothingDs.getItemById(_sample.id);
      expect(result?.season, ClothingSeason.cold);
      expect(result?.occasion, ClothingOccasion.work);
    });

    test('deleteItem removes item and its wear logs', () async {
      await clothingDs.addItem(_sample);
      await clothingDs.recordWear(_sample.id);
      await clothingDs.deleteItem(_sample.id);
      final items = await clothingDs.getAllItems();
      final logs = await wearLogDs.getLogsForItem(_sample.id);
      expect(items, isEmpty);
      expect(logs, isEmpty);
    });

    test('recordWear increments usageCount and sets lastWornAt', () async {
      await clothingDs.addItem(_sample);
      await clothingDs.recordWear(_sample.id);
      final result = await clothingDs.getItemById(_sample.id);
      expect(result?.usageCount, 1);
      expect(result?.lastWornAt, isNotNull);
    });

    test('watchAllItems emits updated list after insert', () async {
      final future = expectLater(
        clothingDs.watchAllItems(),
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );
      // Allow the initial empty-list emission before writing.
      await Future.delayed(Duration.zero);
      await clothingDs.addItem(_sample);
      await future;
    });
  });
}
