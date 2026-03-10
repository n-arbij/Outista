import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../features/outfit_engine/models/scored_outfit.dart';
import 'outfit_item_tile.dart';

/// Full-width card showing all clothing items in the primary outfit.
///
/// Accepts [items] pre-resolved from the wardrobe so the card stays
/// stateless and free of repository calls.
class OutfitCard extends StatelessWidget {
  /// The scored outfit to display.
  final ScoredOutfit scoredOutfit;

  /// Resolved clothing items in display order.
  final List<ClothingItemModel> items;

  /// Whether today's outfit has already been confirmed as worn.
  final bool isWorn;

  const OutfitCard({
    super.key,
    required this.scoredOutfit,
    required this.items,
    this.isWorn = false,
  });

  @override
  Widget build(BuildContext context) {
    final outfit = scoredOutfit.outfit;
    final generatedLabel = _generatedLabel(outfit.generatedAt);

    return Stack(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isWorn ? Colors.green.withOpacity(0.05) : Colors.white,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Item tiles ───────────────────────────────────────────────
                ..._buildItemTiles(outfit.archetype),
                const SizedBox(height: 12),
                // ── Footer row ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _scoreChip(scoredOutfit.totalScore),
                        const SizedBox(width: 6),
                        _archetypeChip(outfit.archetype),
                      ],
                    ),
                    Text(
                      generatedLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // ── Worn overlay chip ─────────────────────────────────────────────────
        if (isWorn)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Worn Today ✓',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildItemTiles(OutfitArchetype archetype) {
    if (items.isEmpty) return [];
    final result = <Widget>[];

    if (archetype == OutfitArchetype.coordSet && items.length >= 2) {
      // Show first two items with a link indicator between them.
      result.add(OutfitItemTile(item: items[0]));
      result.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Icon(Icons.link, size: 14, color: Colors.teal.shade400),
              const SizedBox(width: 4),
              Text(
                'Co-ord Set',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.teal.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
      for (int i = 1; i < items.length; i++) {
        result.add(OutfitItemTile(item: items[i]));
        if (i < items.length - 1) {
          result.add(const Divider(height: 1, indent: 56, thickness: 0.5));
        }
      }
      return result;
    }

    // Default: render items with dividers.
    for (int i = 0; i < items.length; i++) {
      result.add(OutfitItemTile(item: items[i]));
      if (i < items.length - 1) {
        result.add(const Divider(height: 1, indent: 56, thickness: 0.5));
      }
    }
    return result;
  }

  Widget _scoreChip(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '⭐ ${score.toStringAsFixed(0)} pts',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  /// Small pill chip showing the outfit archetype.
  Widget _archetypeChip(OutfitArchetype archetype) {
    final Color bgColor;
    final Color textColor;
    switch (archetype) {
      case OutfitArchetype.separates:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
      case OutfitArchetype.onePiece:
      case OutfitArchetype.onePieceLayered:
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
      case OutfitArchetype.coordSet:
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
      case OutfitArchetype.smartCasual:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        archetype.label,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _generatedLabel(DateTime generatedAt) {
    final diff = DateTime.now().difference(generatedAt);
    if (diff.inMinutes < 2) return 'Generated just now';
    return 'Generated at ${_pad(generatedAt.hour)}:${_pad(generatedAt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
