import '../../../data/models/outfit_model.dart';

/// An [OutfitModel] paired with its per-criterion score breakdown.
///
/// All score values are in raw points (not fractions):
/// * [seasonScore]  — 0 to 40 pts
/// * [occasionScore] — 0 to 35 pts
/// * [usageScore]   — 0 to 25 pts
/// * [bonusScore]   — emotional + diversity bonus pts (flat)
/// * [totalScore]   — sum of all four components
class ScoredOutfit {
  final OutfitModel outfit;
  final double totalScore;
  final double seasonScore;
  final double occasionScore;
  final double usageScore;
  final double bonusScore;

  const ScoredOutfit({
    required this.outfit,
    required this.totalScore,
    required this.seasonScore,
    required this.occasionScore,
    required this.usageScore,
    required this.bonusScore,
  });

  /// Alias for [totalScore] — provided for backward compatibility.
  double get score => totalScore;

  /// Human-readable breakdown of the score components.
  ///
  /// Example: `'Season: 38/40 | Occasion: 28/35 | Usage: 20/25 | Bonus: +15'`
  String get scoreBreakdown =>
      'Season: ${seasonScore.toStringAsFixed(0)}/40 | '
      'Occasion: ${occasionScore.toStringAsFixed(0)}/35 | '
      'Usage: ${usageScore.toStringAsFixed(0)}/25 | '
      'Bonus: +${bonusScore.toStringAsFixed(0)}';

  /// Returns a copy with selected fields replaced.
  ScoredOutfit copyWith({
    OutfitModel? outfit,
    double? totalScore,
    double? seasonScore,
    double? occasionScore,
    double? usageScore,
    double? bonusScore,
  }) {
    return ScoredOutfit(
      outfit: outfit ?? this.outfit,
      totalScore: totalScore ?? this.totalScore,
      seasonScore: seasonScore ?? this.seasonScore,
      occasionScore: occasionScore ?? this.occasionScore,
      usageScore: usageScore ?? this.usageScore,
      bonusScore: bonusScore ?? this.bonusScore,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoredOutfit &&
          outfit.id == other.outfit.id &&
          totalScore == other.totalScore;

  @override
  int get hashCode => Object.hash(outfit.id, totalScore);

  @override
  String toString() => 'ScoredOutfit(id: ${outfit.id}, score: $totalScore, '
      '$scoreBreakdown)';
}
