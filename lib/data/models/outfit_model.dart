import 'package:outista/data/models/clothing_item_model.dart';

class OutfitModel {
  final String id;
  final List<ClothingItemModel> items;
  final double score;
  final DateTime generatedAt;

  const OutfitModel({
    required this.id,
    required this.items,
    required this.score,
    required this.generatedAt,
  });
}
