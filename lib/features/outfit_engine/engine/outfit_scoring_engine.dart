import 'package:outista/core/constants/app_constants.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/data/models/outfit_model.dart';

// Module 5 — Core outfit scoring algorithm
class OutfitScoringEngine {
  /// Scores a candidate outfit given context signals.
  double score({
    required List<ClothingItemModel> items,
    required double weatherScore,
    required double calendarScore,
    required double recencyScore,
    required double preferenceScore,
  }) {
    return (weatherScore * AppConstants.weightWeather) +
        (calendarScore * AppConstants.weightCalendar) +
        (recencyScore * AppConstants.weightRecency) +
        (preferenceScore * AppConstants.weightPreference);
  }

  /// Ranks and returns the top [limit] outfits from [candidates].
  List<OutfitModel> rank(List<OutfitModel> candidates, {int? limit}) {
    final sorted = [...candidates]..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(limit ?? AppConstants.maxOutfitSuggestions).toList();
  }
}
