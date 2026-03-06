import '../../core/constants/app_enums.dart';

/// Domain model representing a single clothing item in the wardrobe.
class ClothingItemModel {
  final String id;
  final String imagePath;
  final ClothingCategory category;
  final ClothingSeason season;
  final ClothingOccasion occasion;
  final EmotionalTag emotionalTag;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? lastWornAt;

  const ClothingItemModel({
    required this.id,
    required this.imagePath,
    required this.category,
    required this.season,
    required this.occasion,
    this.emotionalTag = EmotionalTag.none,
    this.usageCount = 0,
    required this.createdAt,
    this.lastWornAt,
  });
}
