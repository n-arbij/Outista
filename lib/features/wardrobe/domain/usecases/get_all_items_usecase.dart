import '../../../../data/datasources/local/local_clothing_datasource.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../core/constants/app_enums.dart';

/// Returns all clothing items, optionally filtered by [category].
class GetAllItemsUseCase {
  final LocalClothingDatasource _repository;

  const GetAllItemsUseCase(this._repository);

  /// Fetches items from the datasource, applying [filter] if provided.
  Future<List<ClothingItemModel>> call({ClothingCategory? filter}) async {
    final items = await _repository.getAllItems();
    if (filter == null) return items;
    return items.where((item) => item.category == filter).toList();
  }
}
