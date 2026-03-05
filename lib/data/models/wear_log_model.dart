class WearLogModel {
  final String id;
  final String clothingItemId;
  final String? outfitId;
  final DateTime wornAt;

  const WearLogModel({
    required this.id,
    required this.clothingItemId,
    this.outfitId,
    required this.wornAt,
  });
}
