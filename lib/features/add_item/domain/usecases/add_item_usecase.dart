import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/data_exception.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../data/datasources/local/local_clothing_datasource.dart';
import '../../../../data/models/clothing_item_model.dart';
import 'package:uuid/uuid.dart';

/// Input data required to add a new clothing item.
class AddItemInput {
  final String imagePath;
  final ClothingCategory category;
  final ClothingSeason season;
  final ClothingOccasion occasion;
  final EmotionalTag emotionalTag;

  const AddItemInput({
    required this.imagePath,
    required this.category,
    required this.season,
    required this.occasion,
    this.emotionalTag = EmotionalTag.none,
  });
}

/// Validates, compresses and persists a new clothing item.
///
/// Delegates image storage to [ImageStorageService] and persistence to
/// [LocalClothingDatasource].
class AddItemUseCase {
  final LocalClothingDatasource _repository;
  final ImageStorageService _imageStorage;

  static const _uuid = Uuid();

  const AddItemUseCase(this._repository, this._imageStorage);

  /// Saves the image, builds a [ClothingItemModel] and stores it.
  ///
  /// Returns the saved model. Throws [DataException] on any failure.
  Future<ClothingItemModel> call(AddItemInput input) async {
    try {
      final savedPath = await _imageStorage.saveImage(input.imagePath);

      final model = ClothingItemModel(
        id: _uuid.v4(),
        imagePath: savedPath,
        category: input.category,
        season: input.season,
        occasion: input.occasion,
        emotionalTag: input.emotionalTag,
        usageCount: 0,
        createdAt: DateTime.now(),
      );

      await _repository.addItem(model);
      return model;
    } on DataException {
      rethrow;
    } catch (e) {
      throw DataException('Failed to add item', cause: e);
    }
  }
}
