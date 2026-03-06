import '../../../../core/errors/data_exception.dart';
import '../../../../data/datasources/local/local_clothing_datasource.dart';
import '../../../../data/models/clothing_item_model.dart';

/// Validates and persists changes to an existing clothing item.
class UpdateItemUseCase {
  final LocalClothingDatasource _repository;

  const UpdateItemUseCase(this._repository);

  /// Validates [item] and writes it to the datasource.
  ///
  /// Throws [DataException] if [item.id] or [item.imagePath] is empty.
  Future<void> call(ClothingItemModel item) async {
    if (item.id.isEmpty) {
      throw const DataException('Item id must not be empty');
    }
    if (item.imagePath.isEmpty) {
      throw const DataException('Item imagePath must not be empty');
    }
    await _repository.updateItem(item);
  }
}
