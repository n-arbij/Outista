import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../features/outfit_engine/models/scored_outfit.dart';

/// Horizontally scrollable row of compact alternative outfit cards.
class AlternativesCarousel extends StatelessWidget {
  /// The list of alternative outfits to display.
  final List<ScoredOutfit> alternatives;

  /// Maps outfit item IDs to their [ClothingItemModel] for thumbnail display.
  final Map<String, ClothingItemModel> itemsById;

  /// Called when the user taps an alternative card.
  final void Function(ScoredOutfit) onOutfitSelected;

  /// The currently selected outfit ID (for highlighting).
  final String? selectedId;

  static const _accent = Color(0xFF4A90D9);

  const AlternativesCarousel({
    super.key,
    required this.alternatives,
    required this.itemsById,
    required this.onOutfitSelected,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    if (alternatives.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No alternatives\navailable',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemExtent: 130,
        itemCount: alternatives.length,
        itemBuilder: (context, index) {
          final scored = alternatives[index];
          final isSelected = scored.outfit.id == selectedId;
          return _AlternativeCard(
            scored: scored,
            itemsById: itemsById,
            isSelected: isSelected,
            onTap: () => onOutfitSelected(scored),
            accent: _accent,
          );
        },
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  final ScoredOutfit scored;
  final Map<String, ClothingItemModel> itemsById;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  const _AlternativeCard({
    required this.scored,
    required this.itemsById,
    required this.isSelected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final outfit = scored.outfit;
    final thumbIds = [
      outfit.topId,
      outfit.bottomId,
      outfit.shoesId,
      if (outfit.outerwearId != null) outfit.outerwearId!,
    ].take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: thumbIds.map((id) {
                  final item = itemsById[id];
                  return Expanded(child: _thumbnail(item));
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '⭐ ${scored.totalScore.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(ClothingItemModel? item) {
    if (item == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        color: Colors.grey.shade200,
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Image.file(
        File(item.imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
      ),
    );
  }
}
