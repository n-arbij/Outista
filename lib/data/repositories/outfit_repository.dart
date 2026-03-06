import '../models/outfit_model.dart';

/// Abstract interface for outfit persistence.
///
/// Handles saving and querying generated outfit combinations.
/// The Drift-backed concrete implementation is provided in Module 2.
abstract interface class OutfitRepository {
  /// Returns the most recently generated outfits, up to [limit].
  Future<List<OutfitModel>> getRecent({int limit = 10});

  /// Returns a single outfit by [id], or `null` if not found.
  Future<OutfitModel?> getById(String id);

  /// Inserts or replaces [outfit] in the local database.
  Future<void> save(OutfitModel outfit);

  /// Marks the outfit with [id] as worn and persists the change.
  Future<void> markAsWorn(String id);

  /// Permanently deletes the outfit with the given [id].
  Future<void> delete(String id);
}
