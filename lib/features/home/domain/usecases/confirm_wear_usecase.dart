import '../../../../core/errors/data_exception.dart';
import '../../../../data/repositories/outfit_repository.dart';

/// Marks an outfit as worn in the local database.
class ConfirmWearUseCase {
  final OutfitRepository _outfitRepository;

  const ConfirmWearUseCase({required OutfitRepository outfitRepository})
      : _outfitRepository = outfitRepository;

  /// Marks the outfit identified by [outfitId] as worn today.
  ///
  /// Throws [DataException] on persistence failure.
  Future<void> call(String outfitId) async {
    try {
      await _outfitRepository.markAsWorn(outfitId);
    } catch (e) {
      if (e is DataException) rethrow;
      throw DataException('Failed to confirm outfit as worn', cause: e);
    }
  }
}
