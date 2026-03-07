import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../data/models/clothing_item_model.dart';

/// A single row showing a clothing item's image, category, tags, and
/// emotional tag indicator.
class OutfitItemTile extends StatelessWidget {
  /// The clothing item to display.
  final ClothingItemModel item;

  static const _accent = Color(0xFF4A90D9);

  const OutfitItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          // ── Item image ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.file(
                File(item.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.checkroom, size: 24,
                      color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Category + chip tags ────────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category.label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _chip(
                      item.occasion.label,
                      background: _accent,
                      textColor: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    _chip(
                      item.season.label,
                      background: Colors.grey.shade200,
                      textColor: Colors.black87,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Emotional tag icon ──────────────────────────────────────────
          if (item.emotionalTag != EmotionalTag.none)
            _emotionalIcon(item.emotionalTag),
        ],
      ),
    );
  }

  Widget _chip(String label,
      {required Color background, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      height: 20,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _emotionalIcon(EmotionalTag tag) {
    switch (tag) {
      case EmotionalTag.favorite:
        return const Icon(Icons.favorite, size: 18, color: Colors.red);
      case EmotionalTag.confident:
        return const Icon(Icons.star, size: 18, color: Colors.amber);
      case EmotionalTag.none:
        return const SizedBox.shrink();
    }
  }
}
