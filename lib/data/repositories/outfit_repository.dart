import 'package:outista/data/models/outfit_model.dart';

abstract interface class OutfitRepository {
  Future<List<OutfitModel>> getRecent({int limit = 10});
  Future<OutfitModel?> getById(String id);
  Future<void> save(OutfitModel outfit);
  Future<void> delete(String id);
}
