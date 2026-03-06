import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/database/app_database.dart';
import 'package:outista/data/datasources/local/local_clothing_datasource.dart';
import 'package:outista/data/datasources/local/local_outfit_datasource.dart';
import 'package:outista/data/datasources/local/local_wear_log_datasource.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/data/models/outfit_model.dart';

void main() {
  late AppDatabase db;
  late LocalWearLogDatasource wearLogDs;
  late LocalClothingDatasource clothingDs;
  late LocalOutfitDatasource outfitDs;

  final _now = DateTime.now(); // must match today for getTodaysOutfit queries

  final _top = ClothingItemModel(
    id: 'top-1',
    imagePath: 'top.jpg',
    category: ClothingCategory.top,
    season: ClothingSeason.allWeather,
    occasion: ClothingOccasion.casual,
    createdAt: _now,
  );
  final _bottom = ClothingItemModel(
    id: 'bot-1',
    imagePath: 'bot.jpg',
    category: ClothingCategory.bottom,
    season: ClothingSeason.allWeather,
    occasion: ClothingOccasion.casual,
    createdAt: _now,
  );
  final _shoe = ClothingItemModel(
    id: 'shoe-1',
    imagePath: 'shoe.jpg',
    category: ClothingCategory.shoes,
    season: ClothingSeason.allWeather,
    occasion: ClothingOccasion.casual,
    createdAt: _now,
  );

  OutfitModel _makeOutfit({
    required String id,
    required double score,
    DateTime? generatedAt,
  }) =>
      OutfitModel(
        id: id,
        topId: _top.id,
        bottomId: _bottom.id,
        shoesId: _shoe.id,
        score: score,
        occasionContext: CalendarEventType.casual.name,
        weatherContext: WeatherSeason.hot.name,
        generatedAt: generatedAt ?? _now,
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    wearLogDs = LocalWearLogDatasource(db);
    clothingDs = LocalClothingDatasource(db, wearLogDs);
    outfitDs = LocalOutfitDatasource(db, clothingDs, wearLogDs);
  });

  tearDown(() async => db.close());

  Future<void> insertItems() async {
    await clothingDs.addItem(_top);
    await clothingDs.addItem(_bottom);
    await clothingDs.addItem(_shoe);
  }

  group('LocalOutfitDatasource', () {
    test('saveOutfit persists all fields correctly', () async {
      await insertItems();
      final outfit = _makeOutfit(id: 'o-1', score: 85.0);
      await outfitDs.saveOutfit(outfit);
      final history = await outfitDs.getOutfitHistory();
      expect(history.length, 1);
      expect(history.first.id, 'o-1');
      expect(history.first.score, 85.0);
      expect(history.first.topId, _top.id);
      expect(history.first.wasWorn, isFalse);
    });

    test('getTodaysOutfit returns null when no outfit exists for today',
        () async {
      final result = await outfitDs.getTodaysOutfit();
      expect(result, isNull);
    });

    test('getTodaysOutfit returns highest scoring outfit for today', () async {
      await insertItems();
      await outfitDs.saveOutfit(_makeOutfit(id: 'low', score: 40.0));
      await outfitDs.saveOutfit(_makeOutfit(id: 'high', score: 90.0));
      final result = await outfitDs.getTodaysOutfit();
      expect(result?.id, 'high');
    });

    test('markOutfitAsWorn sets wasWorn = true and logs wear per item',
        () async {
      await insertItems();
      final outfit = _makeOutfit(id: 'o-worn', score: 75.0);
      await outfitDs.saveOutfit(outfit);
      await outfitDs.markOutfitAsWorn(outfit.id);

      final history = await outfitDs.getOutfitHistory();
      expect(history.first.wasWorn, isTrue);

      final topLogs = await wearLogDs.getLogsForItem(_top.id);
      expect(topLogs, isNotEmpty);
    });

    test('getOutfitHistory returns results ordered by date descending',
        () async {
      await insertItems();
      await outfitDs.saveOutfit(_makeOutfit(
        id: 'old',
        score: 70.0,
        generatedAt: _now.subtract(const Duration(days: 2)),
      ));
      await outfitDs.saveOutfit(_makeOutfit(
        id: 'new',
        score: 70.0,
        generatedAt: _now,
      ));
      final history = await outfitDs.getOutfitHistory();
      expect(history.first.id, 'new');
      expect(history.last.id, 'old');
    });
  });
}
