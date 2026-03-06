import '../models/clothing_item_model.dart';

/// Abstract interface for clothing item persistence.
///
/// All wardrobe CRUD operations go through this contract.
/// The Drift-backed concrete implementation is provided in Module 2.
abstract interface class ClothingRepository {
  /// Returns every clothing item in the wardrobe, newest first.
  Future<List<ClothingItemModel>> getAll();

  /// Returns a single item by [id], or `null` if not found.
  Future<ClothingItemModel?> getById(String id);

  /// Inserts or replaces [item] in the local database.
  Future<void> save(ClothingItemModel item);

  /// Permanently deletes the item with the given [id].
  Future<void> delete(String id);

  /// Returns items filtered by any combination of [category],
  /// [season], and [occasion] (enum name strings).
  Future<List<ClothingItemModel>> getFiltered({
    String? category,
    String? season,
    String? occasion,
  });
}
