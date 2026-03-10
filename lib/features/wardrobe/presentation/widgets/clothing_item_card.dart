import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';
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
        // Image + badges
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
              if (item.isOnePiece)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildOnePieceBadge(),
                ),
              if (item.setId != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _buildCoordSetBadge(),
                ),
            ],
          ),
        ),
        // Chips row
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    _buildChip(_categoryLabel()),
                    const SizedBox(width: 4),
                    _buildChip(item.occasion.label),
                  ],
                ),
                if (item.category == ClothingCategory.shoes &&
                    item.shoeFormality != null) ...[
                  const SizedBox(height: 2),
                  _buildFormalityChip(item.shoeFormality!),
                ],
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
                    _categoryLabel(),
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
                      if (item.category == ClothingCategory.shoes &&
                          item.shoeFormality != null) ...[
                        const SizedBox(width: 4),
                        _buildFormalityChip(item.shoeFormality!, small: true),
                      ],
                    ],
                  ),
                  if (item.setId != null) ...[
                    const SizedBox(height: 4),
                    _buildCoordSetBadge(small: true),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the display label for the item's category/subcategory.
  String _categoryLabel() {
    if (item.subcategory != ClothingSubcategory.none) {
      return item.subcategory.label;
    }
    return item.category.label;
  }

  Widget _buildImage({
    required BoxFit fit,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
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

  /// Badge shown on one-piece items.
  Widget _buildOnePieceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'ONE PIECE',
        style: TextStyle(
          fontSize: 9,
          color: Colors.purple.shade700,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Badge shown on coord-set items.
  Widget _buildCoordSetBadge({bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: small ? 10 : 12, color: Colors.teal.shade600),
          const SizedBox(width: 2),
          Text(
            'Co-ord',
            style: TextStyle(
              fontSize: small ? 9 : 10,
              color: Colors.teal.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormalityChip(ShoeFormality formality, {bool small = false}) {
    final Color bgColor;
    final Color textColor;
    switch (formality) {
      case ShoeFormality.formal:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
      case ShoeFormality.casual:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
      case ShoeFormality.sporty:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formality.label,
        style: TextStyle(
          fontSize: small ? 10 : 11,
          color: textColor,
          fontWeight: FontWeight.w500,
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
