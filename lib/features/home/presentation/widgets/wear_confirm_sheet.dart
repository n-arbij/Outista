import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../features/outfit_engine/models/scored_outfit.dart';

/// Bottom sheet asking the user to confirm they will wear the outfit today.
class WearConfirmSheet extends StatelessWidget {
  /// The outfit being confirmed.
  final ScoredOutfit scoredOutfit;

  /// Resolved clothing items for thumbnail display.
  final List<ClothingItemModel> items;

  /// Called when the user taps 'Confirm — Wear Today'.
  final VoidCallback onConfirm;

  const WearConfirmSheet({
    super.key,
    required this.scoredOutfit,
    required this.items,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirm Outfit',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mark these items as worn today?',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Thumbnails
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.take(4).map((item) {
              return Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(item.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.checkroom, size: 20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onConfirm,
              child: const Text('Confirm — Wear Today'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
