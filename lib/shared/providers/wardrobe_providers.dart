import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/clothing_item_model.dart';
import '../../core/constants/app_enums.dart';
import '../../data/datasources/local/local_clothing_datasource.dart';
import 'repository_providers.dart';
import '../../features/wardrobe/domain/usecases/get_all_items_usecase.dart';
import '../../features/wardrobe/domain/usecases/update_item_usecase.dart';
import '../../features/wardrobe/domain/usecases/delete_item_usecase.dart';

/// View mode toggle for the wardrobe screen.
enum WardrobeViewMode { grid, list }

// ── View mode ────────────────────────────────────────────────────────────────

class _ViewModeNotifier extends Notifier<WardrobeViewMode> {
  @override
  WardrobeViewMode build() => WardrobeViewMode.grid;

  /// Toggles between grid and list view.
  void toggle() {
    state = state == WardrobeViewMode.grid
        ? WardrobeViewMode.list
        : WardrobeViewMode.grid;
  }
}

/// Tracks which view mode (grid or list) is active in the wardrobe screen.
final wardrobeViewModeProvider =
    NotifierProvider<_ViewModeNotifier, WardrobeViewMode>(
        _ViewModeNotifier.new);

// ── Category filter ──────────────────────────────────────────────────────────

class _CategoryFilterNotifier extends Notifier<ClothingCategory?> {
  @override
  ClothingCategory? build() => null;

  /// Sets the active category filter. Pass `null` to show all items.
  void setFilter(ClothingCategory? category) => state = category;
}

/// Tracks the currently selected category filter (`null` = show all).
final activeCategoryFilterProvider =
    NotifierProvider<_CategoryFilterNotifier, ClothingCategory?>(
        _CategoryFilterNotifier.new);

// ── Derived providers ────────────────────────────────────────────────────────

/// Combines [allClothingItemsProvider] with [activeCategoryFilterProvider]
/// to produce the filtered list that the wardrobe screen renders.
final filteredClothingItemsProvider =
    Provider<AsyncValue<List<ClothingItemModel>>>((ref) {
  final asyncItems = ref.watch(allClothingItemsProvider);
  final filter = ref.watch(activeCategoryFilterProvider);
  return asyncItems.whenData((items) {
    if (filter == null) return items;
    return items.where((item) => item.category == filter).toList();
  });
});

/// Provides [GetAllItemsUseCase] backed by [clothingRepositoryProvider].
final getAllItemsUseCaseProvider = Provider<GetAllItemsUseCase>((ref) {
  return GetAllItemsUseCase(
    ref.watch(clothingRepositoryProvider) as LocalClothingDatasource,
  );
});

/// Provides [UpdateItemUseCase] backed by [clothingRepositoryProvider].
final updateItemUseCaseProvider = Provider<UpdateItemUseCase>((ref) {
  return UpdateItemUseCase(
    ref.watch(clothingRepositoryProvider) as LocalClothingDatasource,
  );
});

/// Provides [DeleteItemUseCase] backed by [clothingRepositoryProvider].
final deleteItemUseCaseProvider = Provider<DeleteItemUseCase>((ref) {
  return DeleteItemUseCase(
    ref.watch(clothingRepositoryProvider) as LocalClothingDatasource,
  );
});
