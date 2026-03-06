import '../../../../data/datasources/local/local_clothing_datasource.dart';

/// Permanently removes a clothing item and all related data.
class DeleteItemUseCase {
  final LocalClothingDatasource _repository;

  const DeleteItemUseCase(this._repository);

  /// Deletes the item identified by [itemId] from the datasource.
  Future<void> call(String itemId) async {
    await _repository.deleteItem(itemId);
  }
}
