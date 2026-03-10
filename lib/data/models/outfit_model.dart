import '../../core/constants/app_enums.dart';

/// Domain model representing a generated outfit combination.
class OutfitModel {
  final String id;
  final String topId;
  final String bottomId;
  final String shoesId;
  final String? outerwearId;
  final double score;
  final String occasionContext;
  final String weatherContext;
  final DateTime generatedAt;
  final bool wasWorn;
  final bool isUserAdded;

  /// The ID of the one-piece garment, when [archetype] is
  /// [OutfitArchetype.onePiece] or [OutfitArchetype.onePieceLayered].
  ///
  /// `null` for separates-based outfits.
  final String? onePieceId;

  /// Structural archetype of this outfit.
  ///
  /// Defaults to [OutfitArchetype.separates] for outfits generated before
  /// archetypes were introduced.
  final OutfitArchetype archetype;

  const OutfitModel({
    required this.id,
    required this.topId,
    required this.bottomId,
    required this.shoesId,
    this.outerwearId,
    required this.score,
    required this.occasionContext,
    required this.weatherContext,
    required this.generatedAt,
    this.wasWorn = false,
    this.isUserAdded = false,
    this.onePieceId,
    this.archetype = OutfitArchetype.separates,
  });

  /// `true` when this outfit is built around a single one-piece garment.
  bool get isOnePieceOutfit => onePieceId != null;
}
