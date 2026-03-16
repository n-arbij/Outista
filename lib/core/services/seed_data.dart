import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/app_database.dart';
import '../constants/app_enums.dart';

class SeedData {
  static const uuid = Uuid();
  
  static Future<void> seedSampleItems(AppDatabase db) async {
    try {
      // Check if items already exist
      final query = db.select(db.clothingItems);
      final existingItems = await query.get();
      
      if (existingItems.isNotEmpty) {
        return; // Already seeded
      }
      
      final now = DateTime.now();
      
      // Create sample clothing items
      final items = [
        ClothingItemsCompanion.insert(
          id: uuid.v4(),
          imagePath: 'assets/images/sample_white_tshirt.png',
          category: ClothingCategory.top.name,
          season: ClothingSeason.allWeather.name,
          occasion: ClothingOccasion.casual.name,
          emotionalTag: Value(EmotionalTag.none.name),
          usageCount: Value(0),
          createdAt: now,
          subcategory: Value(ClothingSubcategory.tee.name),
        ),
        ClothingItemsCompanion.insert(
          id: uuid.v4(),
          imagePath: 'assets/images/sample_blue_jeans.png',
          category: ClothingCategory.bottom.name,
          season: ClothingSeason.allWeather.name,
          occasion: ClothingOccasion.casual.name,
          emotionalTag: Value(EmotionalTag.none.name),
          usageCount: Value(0),
          createdAt: now,
          subcategory: Value(ClothingSubcategory.jeans.name),
        ),
        ClothingItemsCompanion.insert(
          id: uuid.v4(),
          imagePath: 'assets/images/sample_sneakers.png',
          category: ClothingCategory.shoes.name,
          season: ClothingSeason.allWeather.name,
          occasion: ClothingOccasion.casual.name,
          emotionalTag: Value(EmotionalTag.none.name),
          usageCount: Value(0),
          createdAt: now,
          subcategory: Value(ClothingSubcategory.sneakers.name),
        ),
        ClothingItemsCompanion.insert(
          id: uuid.v4(),
          imagePath: 'assets/images/sample_black_blazer.png',
          category: ClothingCategory.outerwear.name,
          season: ClothingSeason.allWeather.name,
          occasion: ClothingOccasion.work.name,
          emotionalTag: Value(EmotionalTag.confident.name),
          usageCount: Value(0),
          createdAt: now,
          subcategory: Value(ClothingSubcategory.blazer.name),
        ),
        ClothingItemsCompanion.insert(
          id: uuid.v4(),
          imagePath: 'assets/images/sample_sweater.png',
          category: ClothingCategory.top.name,
          season: ClothingSeason.cold.name,
          occasion: ClothingOccasion.casual.name,
          emotionalTag: Value(EmotionalTag.none.name),
          usageCount: Value(0),
          createdAt: now,
          subcategory: Value(ClothingSubcategory.sweater.name),
        ),
      ];
      
      // Insert all items
      for (final item in items) {
        await db.into(db.clothingItems).insert(item);
      }
    } catch (e) {
      print('[SeedData] Error seeding items: $e');
    }
  }
}
