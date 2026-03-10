import '../../core/constants/app_enums.dart';

/// Domain model representing a single clothing item in the wardrobe.
class ClothingItemModel {
  final String id;
  final String imagePath;
  final ClothingCategory category;
  final ClothingSeason season;
  final ClothingOccasion occasion;
  final EmotionalTag emotionalTag;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? lastWornAt;

  /// Subcategory refinement within [category].
  ///
  /// Defaults to [ClothingSubcategory.none] for items tagged before
  /// subcategories were introduced.
  final ClothingSubcategory subcategory;

  /// Formality of this shoe item.
  ///
  /// `null` for all non-shoe items; pre-existing shoe items without an
  /// explicit formality default to [ShoeFormality.casual] at query time.
  final ShoeFormality? shoeFormality;

  /// UUID linking coord-set pieces together.
  ///
  /// Items that share the same [setId] are treated as a co-ord set by the
  /// archetype engine. `null` for ordinary items.
  final String? setId;

  /// `true` when [category] == [ClothingCategory.onePiece].
  ///
  /// Stored for query performance rather than being derived each time.
  final bool isOnePiece;

  /// `true` for one-piece and dungaree items that replace the top slot.
  final bool replacesTop;

  /// `true` for one-piece and dungaree items that replace the bottom slot.
  final bool replacesBottom;

  const ClothingItemModel({
    required this.id,
    required this.imagePath,
    required this.category,
    required this.season,
    required this.occasion,
    this.emotionalTag = EmotionalTag.none,
    this.usageCount = 0,
    required this.createdAt,
    this.lastWornAt,
    this.subcategory = ClothingSubcategory.none,
    this.shoeFormality,
    this.setId,
    this.isOnePiece = false,
    this.replacesTop = false,
    this.replacesBottom = false,
  });

  /// Returns a copy of this item with selected fields replaced.
  ClothingItemModel copyWith({
    String? id,
    String? imagePath,
    ClothingCategory? category,
    ClothingSeason? season,
    ClothingOccasion? occasion,
    EmotionalTag? emotionalTag,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastWornAt,
    ClothingSubcategory? subcategory,
    ShoeFormality? shoeFormality,
    String? setId,
    bool? isOnePiece,
    bool? replacesTop,
    bool? replacesBottom,
  }) {
    return ClothingItemModel(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      season: season ?? this.season,
      occasion: occasion ?? this.occasion,
      emotionalTag: emotionalTag ?? this.emotionalTag,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastWornAt: lastWornAt ?? this.lastWornAt,
      subcategory: subcategory ?? this.subcategory,
      shoeFormality: shoeFormality ?? this.shoeFormality,
      setId: setId ?? this.setId,
      isOnePiece: isOnePiece ?? this.isOnePiece,
      replacesTop: replacesTop ?? this.replacesTop,
      replacesBottom: replacesBottom ?? this.replacesBottom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothingItemModel &&
          id == other.id &&
          imagePath == other.imagePath &&
          category == other.category &&
          season == other.season &&
          occasion == other.occasion &&
          emotionalTag == other.emotionalTag &&
          usageCount == other.usageCount &&
          createdAt == other.createdAt &&
          lastWornAt == other.lastWornAt &&
          subcategory == other.subcategory &&
          shoeFormality == other.shoeFormality &&
          setId == other.setId &&
          isOnePiece == other.isOnePiece &&
          replacesTop == other.replacesTop &&
          replacesBottom == other.replacesBottom;

  @override
  int get hashCode => Object.hash(
        id,
        imagePath,
        category,
        season,
        occasion,
        emotionalTag,
        usageCount,
        createdAt,
        lastWornAt,
        subcategory,
        shoeFormality,
        setId,
        isOnePiece,
        replacesTop,
        replacesBottom,
      );
}
