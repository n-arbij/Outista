import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/local_clothing_datasource.dart';
import '../../data/datasources/local/local_outfit_datasource.dart';
import '../../data/datasources/local/local_wear_log_datasource.dart';
import '../../data/models/clothing_item_model.dart';
import '../../data/models/outfit_model.dart';
import '../../data/repositories/clothing_repository.dart';
import '../../data/repositories/outfit_repository.dart';
import 'database_provider.dart';

/// Provides the [LocalWearLogDatasource] backed by [databaseProvider].
final wearLogDatasourceProvider = Provider<LocalWearLogDatasource>((ref) {
  return LocalWearLogDatasource(ref.watch(databaseProvider));
});

/// Provides the [ClothingRepository] (concrete: [LocalClothingDatasource]).
final clothingRepositoryProvider = Provider<ClothingRepository>((ref) {
  return LocalClothingDatasource(
    ref.watch(databaseProvider),
    ref.watch(wearLogDatasourceProvider),
  );
});

/// Provides the [OutfitRepository] (concrete: [LocalOutfitDatasource]).
///
/// Casts [clothingRepositoryProvider] to [LocalClothingDatasource] so the
/// outfit datasource can call [LocalClothingDatasource.recordWear], which is
/// not part of the abstract interface.
final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  return LocalOutfitDatasource(
    ref.watch(databaseProvider),
    ref.watch(clothingRepositoryProvider) as LocalClothingDatasource,
    ref.watch(wearLogDatasourceProvider),
  );
});

/// Reactive stream of the full wardrobe — emits on every change.
final allClothingItemsProvider =
    StreamProvider<List<ClothingItemModel>>((ref) {
  return (ref.watch(clothingRepositoryProvider) as LocalClothingDatasource)
      .watchAllItems();
});

/// Reactive stream of today's highest-scoring outfit (or `null`).
final todaysOutfitProvider = StreamProvider<OutfitModel?>((ref) {
  return (ref.watch(outfitRepositoryProvider) as LocalOutfitDatasource)
      .watchTodaysOutfit();
});

/// Reactive stream of all outfits generated today, ordered by score descending.
final todaysOutfitsProvider = StreamProvider<List<OutfitModel>>((ref) {
  return ref.watch(outfitRepositoryProvider).watchTodaysOutfits();
});
