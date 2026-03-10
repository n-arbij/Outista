import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../shared/providers/add_item_providers.dart';
import '../../../wardrobe/presentation/widgets/tag_selector.dart';

/// Subcategory options grouped by [ClothingCategory].
const _topSubcategories = [
  ClothingSubcategory.tee,
  ClothingSubcategory.shirt,
  ClothingSubcategory.blouse,
  ClothingSubcategory.sweater,
  ClothingSubcategory.hoodie,
  ClothingSubcategory.tank,
  ClothingSubcategory.polo,
];

const _bottomSubcategories = [
  ClothingSubcategory.trousers,
  ClothingSubcategory.jeans,
  ClothingSubcategory.skirt,
  ClothingSubcategory.shorts,
  ClothingSubcategory.leggings,
  ClothingSubcategory.chinos,
];

const _onePieceSubcategories = [
  ClothingSubcategory.dress,
  ClothingSubcategory.jumpsuit,
  ClothingSubcategory.romper,
  ClothingSubcategory.playsuit,
  ClothingSubcategory.dungarees,
  ClothingSubcategory.maxi,
  ClothingSubcategory.midi,
];

const _shoeSubcategories = [
  ClothingSubcategory.heels,
  ClothingSubcategory.oxfords,
  ClothingSubcategory.loafers,
  ClothingSubcategory.sneakers,
  ClothingSubcategory.sandals,
  ClothingSubcategory.boots,
  ClothingSubcategory.flats,
  ClothingSubcategory.trainers,
  ClothingSubcategory.mules,
];

const _outerwearSubcategories = [
  ClothingSubcategory.jacket,
  ClothingSubcategory.coat,
  ClothingSubcategory.blazer,
  ClothingSubcategory.cardigan,
  ClothingSubcategory.denimJacket,
  ClothingSubcategory.trench,
  ClothingSubcategory.bomber,
];

/// Returns the valid subcategory options for [category], or `null` if the
/// category has no subcategories.
List<ClothingSubcategory>? _subcategoriesFor(ClothingCategory? category) {
  switch (category) {
    case ClothingCategory.top:
      return _topSubcategories;
    case ClothingCategory.bottom:
      return _bottomSubcategories;
    case ClothingCategory.onePiece:
      return _onePieceSubcategories;
    case ClothingCategory.shoes:
      return _shoeSubcategories;
    case ClothingCategory.outerwear:
      return _outerwearSubcategories;
    case null:
      return null;
  }
}

/// Renders the classification fields for the item tagging form.
///
/// Reads current state from [notifier] and writes changes back through its
/// mutation methods. Fields shown adapt dynamically to the selected category.
class TaggingForm extends StatelessWidget {
  /// The notifier that owns the form state.
  final TaggingFormNotifier notifier;

  /// Current snapshot of the form state.
  final TaggingFormState formState;

  const TaggingForm({
    super.key,
    required this.notifier,
    required this.formState,
  });

  @override
  Widget build(BuildContext context) {
    final subcategoryOptions = _subcategoriesFor(formState.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagSelector<ClothingCategory>(
          label: 'Category',
          options: ClothingCategory.values,
          selected: formState.category,
          onSelected: notifier.setCategory,
          labelBuilder: (v) => v.label,
          isRequired: true,
        ),
        // ── Subcategory (category-specific) ───────────────────────────────────
        if (subcategoryOptions != null) ...[
          const SizedBox(height: 20),
          TagSelector<ClothingSubcategory>(
            label: 'Style',
            options: subcategoryOptions,
            selected: formState.subcategory,
            onSelected: notifier.setSubcategory,
            labelBuilder: (v) => v.label,
            isRequired: formState.category == ClothingCategory.onePiece,
          ),
        ],
        // ── Shoe formality ────────────────────────────────────────────────────
        if (formState.category == ClothingCategory.shoes) ...[
          const SizedBox(height: 20),
          TagSelector<ShoeFormality>(
            label: 'Formality',
            options: ShoeFormality.values,
            selected: formState.shoeFormality,
            onSelected: notifier.setShoeFormality,
            labelBuilder: (v) => v.label,
            isRequired: true,
          ),
        ],
        const SizedBox(height: 20),
        TagSelector<ClothingSeason>(
          label: 'Season',
          options: ClothingSeason.values,
          selected: formState.season,
          onSelected: notifier.setSeason,
          labelBuilder: (v) => v.label,
          isRequired: true,
        ),
        const SizedBox(height: 20),
        TagSelector<ClothingOccasion>(
          label: 'Occasion',
          options: ClothingOccasion.values,
          selected: formState.occasion,
          onSelected: notifier.setOccasion,
          labelBuilder: (v) => v.label,
          isRequired: true,
        ),
        const SizedBox(height: 20),
        TagSelector<EmotionalTag>(
          label: 'Mood Tag',
          options: EmotionalTag.values,
          selected: formState.emotionalTag,
          onSelected: notifier.setEmotionalTag,
          labelBuilder: (v) => v.label,
        ),
        // ── Co-ord set section ────────────────────────────────────────────────
        if (formState.category == ClothingCategory.top ||
            formState.category == ClothingCategory.bottom) ...[
          const SizedBox(height: 20),
          _CoordSetSection(notifier: notifier, formState: formState),
        ],
      ],
    );
  }
}

/// Expandable section that lets the user mark an item as a co-ord set piece.
class _CoordSetSection extends StatelessWidget {
  final TaggingFormNotifier notifier;
  final TaggingFormState formState;

  const _CoordSetSection({
    required this.notifier,
    required this.formState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: formState.isCoordPiece,
              onChanged: (v) {
                if (v == true) {
                  notifier.setAsCoordPiece(null);
                } else {
                  notifier.clearCoordLink();
                }
              },
            ),
            const Text('This is a co-ord set piece'),
          ],
        ),
        if (formState.isCoordPiece) ...[
          const SizedBox(height: 8),
          const Text(
            'You are adding one piece of a co-ord set.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pieceTypeChip(context, 'top', 'Top piece'),
              const SizedBox(width: 8),
              _pieceTypeChip(context, 'bottom', 'Bottom piece'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _pieceTypeChip(BuildContext context, String type, String label) {
    final selected = formState.coordPieceType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => notifier.setCoordPieceType(type),
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF555555),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: const Color(0xFFF0F0F0),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}
