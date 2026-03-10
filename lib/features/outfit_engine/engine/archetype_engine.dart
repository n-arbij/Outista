import '../../../core/constants/app_enums.dart';
import '../../../data/models/clothing_item_model.dart';

/// A single outfit combination produced by [ArchetypeEngine].
///
/// Exactly one of [top]+[bottom] or [onePiece] is set, depending on
/// [archetype].
class OutfitCombination {
  /// Top garment for separates/coordSet/smartCasual archetypes; `null` for
  /// one-piece archetypes.
  final ClothingItemModel? top;

  /// Bottom garment for separates/coordSet/smartCasual archetypes; `null` for
  /// one-piece archetypes.
  final ClothingItemModel? bottom;

  /// The one-piece garment for [OutfitArchetype.onePiece] /
  /// [OutfitArchetype.onePieceLayered]; `null` for separates-based archetypes.
  final ClothingItemModel? onePiece;

  /// The shoe item — always required.
  final ClothingItemModel shoes;

  /// Optional outerwear item.
  final ClothingItemModel? outerwear;

  /// Structural archetype of this combination.
  final OutfitArchetype archetype;

  const OutfitCombination({
    this.top,
    this.bottom,
    this.onePiece,
    required this.shoes,
    this.outerwear,
    required this.archetype,
  });
}

/// A validated coord set: one top-category and one bottom-category item
/// that share the same [setId].
class CoordSet {
  /// The shared set identifier.
  final String setId;

  /// The top piece of the set.
  final ClothingItemModel topPiece;

  /// The bottom piece of the set.
  final ClothingItemModel bottomPiece;

  const CoordSet({
    required this.setId,
    required this.topPiece,
    required this.bottomPiece,
  });
}

/// Generates outfit combinations for each [OutfitArchetype].
///
/// This class is a pure Dart value with no Flutter or I/O dependencies.
/// [OutfitScoringEngine] delegates combination generation to this class.
class ArchetypeEngine {
  const ArchetypeEngine();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns all archetypes that can be formed from [wardrobe].
  ///
  /// An archetype is only included when every required item category is
  /// present in the wardrobe.
  List<OutfitArchetype> detectAvailableArchetypes(
    List<ClothingItemModel> wardrobe,
  ) {
    final hasShoes =
        wardrobe.any((i) => i.category == ClothingCategory.shoes);
    final hasTops =
        wardrobe.any((i) => i.category == ClothingCategory.top);
    final hasBottoms =
        wardrobe.any((i) => i.category == ClothingCategory.bottom);
    final hasOnePiece = wardrobe.any((i) => i.isOnePiece);
    final hasOuterwear =
        wardrobe.any((i) => i.category == ClothingCategory.outerwear);
    final hasBlazer = wardrobe.any(
      (i) =>
          i.category == ClothingCategory.outerwear &&
          i.subcategory == ClothingSubcategory.blazer,
    );

    final separatesAvailable = hasTops && hasBottoms && hasShoes;
    final onePieceAvailable = hasOnePiece && hasShoes;
    final coordSets = _groupBySetId(wardrobe);
    final coordSetAvailable = coordSets.isNotEmpty && hasShoes;

    final result = <OutfitArchetype>[];

    if (separatesAvailable) result.add(OutfitArchetype.separates);
    if (onePieceAvailable) result.add(OutfitArchetype.onePiece);
    if (onePieceAvailable && hasOuterwear) {
      result.add(OutfitArchetype.onePieceLayered);
    }
    if (coordSetAvailable) result.add(OutfitArchetype.coordSet);
    if (separatesAvailable && hasBlazer) {
      result.add(OutfitArchetype.smartCasual);
    }

    return result;
  }

  /// Generates all valid [OutfitCombination]s for the given [archetype].
  ///
  /// Season-conflicting combinations are silently filtered out.
  /// Invalid shoe pairings (for one-piece archetypes) are also filtered.
  List<OutfitCombination> generateForArchetype({
    required List<ClothingItemModel> wardrobe,
    required OutfitArchetype archetype,
  }) {
    switch (archetype) {
      case OutfitArchetype.separates:
        return _generateSeparates(wardrobe);
      case OutfitArchetype.onePiece:
        return _generateOnePiece(wardrobe, requireOuterwear: false);
      case OutfitArchetype.onePieceLayered:
        return _generateOnePiece(wardrobe, requireOuterwear: true);
      case OutfitArchetype.coordSet:
        return _generateCoordSet(wardrobe);
      case OutfitArchetype.smartCasual:
        return _generateSmartCasual(wardrobe);
    }
  }

  // ─── Private generators ────────────────────────────────────────────────────

  List<OutfitCombination> _generateSeparates(
      List<ClothingItemModel> wardrobe) {
    final tops =
        wardrobe.where((i) => i.category == ClothingCategory.top).toList();
    final bottoms =
        wardrobe.where((i) => i.category == ClothingCategory.bottom).toList();
    final shoes =
        wardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    final outers = wardrobe
        .where((i) => i.category == ClothingCategory.outerwear)
        .toList();

    final result = <OutfitCombination>[];
    for (final top in tops) {
      for (final bottom in bottoms) {
        for (final shoe in shoes) {
          for (final outerwear in <ClothingItemModel?>[null, ...outers]) {
            final items = [
              top,
              bottom,
              shoe,
              if (outerwear != null) outerwear,
            ];
            if (_hasSeasonConflict(items)) continue;
            result.add(OutfitCombination(
              top: top,
              bottom: bottom,
              shoes: shoe,
              outerwear: outerwear,
              archetype: OutfitArchetype.separates,
            ));
          }
        }
      }
    }
    return result;
  }

  List<OutfitCombination> _generateOnePiece(
    List<ClothingItemModel> wardrobe, {
    required bool requireOuterwear,
  }) {
    final pieces = wardrobe.where((i) => i.isOnePiece).toList();
    final shoes =
        wardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    final outers = wardrobe
        .where((i) => i.category == ClothingCategory.outerwear)
        .toList();

    final archetype = requireOuterwear
        ? OutfitArchetype.onePieceLayered
        : OutfitArchetype.onePiece;

    final result = <OutfitCombination>[];
    for (final piece in pieces) {
      for (final shoe in shoes) {
        if (requireOuterwear) {
          for (final outer in outers) {
            final items = [piece, shoe, outer];
            if (_hasSeasonConflict(items)) continue;
            if (!_validateShoePairing(piece, shoe)) continue;
            result.add(OutfitCombination(
              onePiece: piece,
              shoes: shoe,
              outerwear: outer,
              archetype: archetype,
            ));
          }
        } else {
          for (final outerwear in <ClothingItemModel?>[null, ...outers]) {
            final items = [
              piece,
              shoe,
              if (outerwear != null) outerwear,
            ];
            if (_hasSeasonConflict(items)) continue;
            if (!_validateShoePairing(piece, shoe)) continue;
            result.add(OutfitCombination(
              onePiece: piece,
              shoes: shoe,
              outerwear: outerwear,
              archetype: archetype,
            ));
          }
        }
      }
    }
    return result;
  }

  List<OutfitCombination> _generateCoordSet(
      List<ClothingItemModel> wardrobe) {
    final coordSets = _groupBySetId(wardrobe);
    final shoes =
        wardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    final outers = wardrobe
        .where((i) => i.category == ClothingCategory.outerwear)
        .toList();

    final result = <OutfitCombination>[];
    for (final set in coordSets.values) {
      for (final shoe in shoes) {
        for (final outerwear in <ClothingItemModel?>[null, ...outers]) {
          final items = [
            set.topPiece,
            set.bottomPiece,
            shoe,
            if (outerwear != null) outerwear,
          ];
          if (_hasSeasonConflict(items)) continue;
          result.add(OutfitCombination(
            top: set.topPiece,
            bottom: set.bottomPiece,
            shoes: shoe,
            outerwear: outerwear,
            archetype: OutfitArchetype.coordSet,
          ));
        }
      }
    }
    return result;
  }

  List<OutfitCombination> _generateSmartCasual(
      List<ClothingItemModel> wardrobe) {
    final tops =
        wardrobe.where((i) => i.category == ClothingCategory.top).toList();
    final bottoms =
        wardrobe.where((i) => i.category == ClothingCategory.bottom).toList();
    final shoes =
        wardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    // Smart casual requires a blazer as the outerwear.
    final blazers = wardrobe
        .where(
          (i) =>
              i.category == ClothingCategory.outerwear &&
              i.subcategory == ClothingSubcategory.blazer,
        )
        .toList();

    final result = <OutfitCombination>[];
    for (final top in tops) {
      for (final bottom in bottoms) {
        for (final blazer in blazers) {
          for (final shoe in shoes) {
            final items = [top, bottom, blazer, shoe];
            if (_hasSeasonConflict(items)) continue;
            result.add(OutfitCombination(
              top: top,
              bottom: bottom,
              shoes: shoe,
              outerwear: blazer,
              archetype: OutfitArchetype.smartCasual,
            ));
          }
        }
      }
    }
    return result;
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  /// Returns `true` when a one-piece + shoe pairing is invalid.
  ///
  /// Invalid combinations:
  /// * Formal one-piece + sporty shoes.
  /// * Casual jumpsuit + heels.
  /// * Casual romper + formal shoes.
  bool _validateShoePairing(
    ClothingItemModel piece,
    ClothingItemModel shoe,
  ) {
    // Formal occasion + sporty shoes → invalid.
    if (piece.occasion == ClothingOccasion.formal &&
        (shoe.shoeFormality ?? ShoeFormality.casual) == ShoeFormality.sporty) {
      return false;
    }
    // Casual jumpsuit + heels → invalid.
    if (piece.subcategory == ClothingSubcategory.jumpsuit &&
        shoe.subcategory == ClothingSubcategory.heels &&
        piece.occasion == ClothingOccasion.casual) {
      return false;
    }
    // Casual romper + formal shoes → invalid.
    if (piece.subcategory == ClothingSubcategory.romper &&
        (shoe.shoeFormality ?? ShoeFormality.casual) == ShoeFormality.formal &&
        piece.occasion == ClothingOccasion.casual) {
      return false;
    }
    return true;
  }

  /// Returns `true` when the combination contains both a hot-season and a
  /// cold-season item (excluding [ClothingSeason.allWeather] items).
  bool _hasSeasonConflict(List<ClothingItemModel> items) {
    bool hasHot = false;
    bool hasCold = false;
    for (final item in items) {
      if (item.season == ClothingSeason.hot) hasHot = true;
      if (item.season == ClothingSeason.cold) hasCold = true;
    }
    return hasHot && hasCold;
  }

  /// Groups wardrobe items by [ClothingItemModel.setId].
  ///
  /// Only groups that contain exactly one top-category and one
  /// bottom-category item are returned as valid [CoordSet]s.
  Map<String, CoordSet> _groupBySetId(List<ClothingItemModel> wardrobe) {
    final groups = <String, List<ClothingItemModel>>{};
    for (final item in wardrobe) {
      if (item.setId == null) continue;
      groups.putIfAbsent(item.setId!, () => []).add(item);
    }

    final result = <String, CoordSet>{};
    for (final entry in groups.entries) {
      final setId = entry.key;
      final items = entry.value;
      final topPieces =
          items.where((i) => i.category == ClothingCategory.top).toList();
      final bottomPieces =
          items.where((i) => i.category == ClothingCategory.bottom).toList();
      if (topPieces.isEmpty || bottomPieces.isEmpty) continue;
      result[setId] = CoordSet(
        setId: setId,
        topPiece: topPieces.first,
        bottomPiece: bottomPieces.first,
      );
    }
    return result;
  }
}
