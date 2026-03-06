import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/clothing_item_model.dart';

/// Displays a single clothing item as a card.
///
/// Supports two visual variants controlled by [isGridMode]:
/// - Grid: square card, image fills top ~70%, chips row at bottom.
/// - List: horizontal card, image 80×80 on the left, details on the right.
class ClothingItemCard extends StatelessWidget {
  final ClothingItemModel item;

  /// Whether to render the grid (square) variant; list variant when false.
  final bool isGridMode;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Called when the card is long-pressed (e.g., show quick-delete).
  final VoidCallback? onLongPress;

  const ClothingItemCard({
    super.key,
    required this.item,
    required this.isGridMode,
    required this.onTap,
    this.onLongPress,
  });

  static const _accentColor = Color(0xFF4A90D9);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: isGridMode ? _buildGridLayout() : _buildListLayout(),
      ),
    );
  }

  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image + usage badge
        Expanded(
          flex: 7,
          child: Stack(
            children: [
              _buildImage(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _buildUsageBadge(),
              ),
            ],
          ),
        ),
        // Chips row
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildChip(item.category.label),
                const SizedBox(width: 4),
                _buildChip(item.occasion.label),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListLayout() {
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: Stack(
              children: [
                _buildImage(
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _buildUsageBadge(),
                ),
              ],
            ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.category.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildChip(item.season.label, small: true),
                      const SizedBox(width: 4),
                      _buildChip(item.occasion.label, small: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage({
    required BoxFit fit,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    final image = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image(
        image: FileImage(File(item.imagePath)),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFFEEEEEE),
          child: const Icon(
            Icons.checkroom,
            size: 36,
            color: Color(0xFFBDBDBD),
          ),
        ),
      ),
    );
    return image;
  }

  Widget _buildUsageBadge() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: _accentColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${item.usageCount}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChip(String label, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 10 : 11,
          color: const Color(0xFF555555),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
