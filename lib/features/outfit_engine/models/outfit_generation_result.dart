import 'outfit_context.dart';
import 'scored_outfit.dart';

/// The complete output of an outfit generation pass.
///
/// Contains the highest-scoring [primary] outfit, up to three
/// [alternatives], and metadata about the generation run.
class OutfitGenerationResult {
  /// The highest-scoring outfit, or `null` if no valid combinations exist.
  final ScoredOutfit? primary;

  /// The next 2–3 best outfits, sorted descending by score.
  final List<ScoredOutfit> alternatives;

  /// The context (weather + calendar) used during generation.
  final OutfitContext context;

  /// When this result was produced.
  final DateTime generatedAt;

  /// Total outfit combinations evaluated (tops × bottoms × shoes).
  final int totalCombinationsEvaluated;

  const OutfitGenerationResult({
    required this.primary,
    required this.alternatives,
    required this.context,
    required this.generatedAt,
    required this.totalCombinationsEvaluated,
  });

  /// All outfits in descending score order: `[primary, ...alternatives]`.
  List<ScoredOutfit> get allOutfits => [
        if (primary != null) primary!,
        ...alternatives,
      ];

  /// `true` when no valid outfit combinations were found.
  bool get isEmpty => primary == null;
}
