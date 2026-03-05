import 'package:outista/data/models/clothing_item_model.dart';

abstract interface class ClothingRepository {
  Future<List<ClothingItemModel>> getAll();
  Future<ClothingItemModel?> getById(String id);
  Future<void> save(ClothingItemModel item);
  Future<void> delete(String id);
}
