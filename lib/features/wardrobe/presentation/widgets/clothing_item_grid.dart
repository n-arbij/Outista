import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../core/constants/app_routes.dart';
import 'clothing_item_card.dart';

/// Displays clothing items as a 2-column grid.
///
/// Shows [ShimmerLoadingGrid] when [items] is `null` (loading state).
class ClothingItemGrid extends StatelessWidget {
  /// Items to display. Pass `null` to show the shimmer loading placeholder.
  final List<ClothingItemModel>? items;

  const ClothingItemGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items == null) return const ShimmerLoadingGrid();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items!.length,
      itemBuilder: (context, index) {
        final item = items![index];
        return ClothingItemCard(
          item: item,
          isGridMode: true,
          onTap: () => context.push(AppRoutes.wardrobeItemPath(item.id)),
        );
      },
    );
  }
}

/// Shimmer placeholder grid that mirrors the real [ClothingItemGrid] layout.
class ShimmerLoadingGrid extends StatelessWidget {
  const ShimmerLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
