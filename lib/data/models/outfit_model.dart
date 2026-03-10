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
  });
}
