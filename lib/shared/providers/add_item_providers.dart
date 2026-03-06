import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_enums.dart';
import '../../core/services/image_storage_service.dart';
import '../../data/datasources/local/local_clothing_datasource.dart';
import '../../features/add_item/domain/usecases/add_item_usecase.dart';
import 'repository_providers.dart';

// ─── Service ────────────────────────────────────────────────────────────────

/// Provides the singleton [ImageStorageService] used for compressing and
/// persisting clothing item photos to the app's documents directory.
final imageStorageServiceProvider = Provider<ImageStorageService>(
  (ref) => ImageStorageService(),
);

// ─── Use Case ────────────────────────────────────────────────────────────────

/// Provides [AddItemUseCase] wired to the clothing repository and image
/// storage service.
final addItemUseCaseProvider = Provider<AddItemUseCase>((ref) {
  return AddItemUseCase(
    ref.watch(clothingRepositoryProvider) as LocalClothingDatasource,
    ref.watch(imageStorageServiceProvider),
  );
});

// ─── Tagging Form ────────────────────────────────────────────────────────────

/// Immutable state for the item tagging form.
class TaggingFormState {
  final ClothingCategory? category;
  final ClothingSeason? season;
  final ClothingOccasion? occasion;
  final EmotionalTag emotionalTag;

  const TaggingFormState({
    this.category,
    this.season,
    this.occasion,
    this.emotionalTag = EmotionalTag.none,
  });

  /// `true` when all required fields (category, season, occasion) are set.
  bool get isValid => category != null && season != null && occasion != null;

  TaggingFormState copyWith({
    ClothingCategory? category,
    ClothingSeason? season,
    ClothingOccasion? occasion,
    EmotionalTag? emotionalTag,
  }) {
    return TaggingFormState(
      category: category ?? this.category,
      season: season ?? this.season,
      occasion: occasion ?? this.occasion,
      emotionalTag: emotionalTag ?? this.emotionalTag,
    );
  }
}

/// Manages the mutable state of the item tagging form.
class TaggingFormNotifier extends Notifier<TaggingFormState> {
  @override
  TaggingFormState build() => const TaggingFormState();

  /// Updates the selected clothing category.
  void setCategory(ClothingCategory value) =>
      state = state.copyWith(category: value);

  /// Updates the selected season.
  void setSeason(ClothingSeason value) =>
      state = state.copyWith(season: value);

  /// Updates the selected occasion.
  void setOccasion(ClothingOccasion value) =>
      state = state.copyWith(occasion: value);

  /// Updates the optional emotional tag.
  void setEmotionalTag(EmotionalTag value) =>
      state = state.copyWith(emotionalTag: value);

  /// Resets all fields to their initial (null) values.
  void reset() => state = const TaggingFormState();
}

/// StateNotifier provider for the tagging form used on [ItemTaggingScreen].
final taggingFormProvider =
    NotifierProvider<TaggingFormNotifier, TaggingFormState>(
  TaggingFormNotifier.new,
);
