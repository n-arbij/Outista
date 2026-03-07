import 'package:flutter/material.dart';
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

  /// Resolved clothing items in display order: top, bottom, shoes, outerwear.
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
                // ── Item tiles ─────────────────────────────────────────────
                ...items.map((item) => _tileWithDivider(item, items.last)),
                const SizedBox(height: 12),
                // ── Footer row ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _scoreChip(scoredOutfit.totalScore),
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
        // ── Worn overlay chip ───────────────────────────────────────────────
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

  Widget _tileWithDivider(ClothingItemModel item, ClothingItemModel last) {
    return Column(
      children: [
        OutfitItemTile(item: item),
        if (item != last)
          const Divider(height: 1, indent: 56, thickness: 0.5),
      ],
    );
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

  String _generatedLabel(DateTime generatedAt) {
    final diff = DateTime.now().difference(generatedAt);
    if (diff.inMinutes < 2) return 'Generated just now';
    return 'Generated at ${_pad(generatedAt.hour)}:${_pad(generatedAt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
