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

  /// Returns all items where [ClothingItemModel.isOnePiece] is `true`,
  /// ordered newest first.
  Future<List<ClothingItemModel>> getOnePieceItems();

  /// Returns all items that belong to the coord set identified by [setId].
  Future<List<ClothingItemModel>> getItemsBySetId(String setId);

  /// Returns a map of `setId → items` for every coord set in the wardrobe.
  ///
  /// Only items with a non-null [ClothingItemModel.setId] are included.
  Future<Map<String, List<ClothingItemModel>>> getCoordSets();

  /// Links [itemId1] and [itemId2] into a new coord set by generating
  /// a shared UUID and persisting it on both items atomically.
  Future<void> linkCoordSet(String itemId1, String itemId2);

  /// Removes the coord-set membership of the item with [itemId] by
  /// setting its [ClothingItemModel.setId] to `null`.
  Future<void> unlinkCoordSet(String itemId);
}
