import 'package:outista/core/constants/app_enums.dart';

class ClothingItemModel {
  final String id;
  final String name;
  final ClothingCategory category;
  final List<Season> seasons;
  final List<Formality> formalities;
  final String? imagePath;
  final DateTime createdAt;

  const ClothingItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.seasons,
    required this.formalities,
    this.imagePath,
    required this.createdAt,
  });
}
