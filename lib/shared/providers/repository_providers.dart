import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/clothing_repository.dart';
import '../../data/repositories/outfit_repository.dart';

/// Provider for the [ClothingRepository] implementation.
///
/// Overridden in Module 2 with the Drift-backed [LocalClothingDataSource].
final clothingRepositoryProvider = Provider<ClothingRepository>(
  (ref) => throw UnimplementedError(
    'clothingRepositoryProvider has not been overridden. '
    'A concrete implementation will be wired in Module 2.',
  ),
);

/// Provider for the [OutfitRepository] implementation.
///
/// Overridden in Module 2 with the Drift-backed [LocalOutfitDataSource].
final outfitRepositoryProvider = Provider<OutfitRepository>(
  (ref) => throw UnimplementedError(
    'outfitRepositoryProvider has not been overridden. '
    'A concrete implementation will be wired in Module 2.',
  ),
);
