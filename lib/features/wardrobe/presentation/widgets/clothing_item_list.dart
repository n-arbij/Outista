import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../core/constants/app_routes.dart';
import 'clothing_item_card.dart';

/// Displays clothing items as a vertically scrolling list.
///
/// Shows [ShimmerLoadingList] when [items] is `null` (loading state).
class ClothingItemList extends StatelessWidget {
  /// Items to display. Pass `null` to show the shimmer loading placeholder.
  final List<ClothingItemModel>? items;

  const ClothingItemList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items == null) return const ShimmerLoadingList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items![index];
        return ClothingItemCard(
          item: item,
          isGridMode: false,
          onTap: () => context.push(AppRoutes.wardrobeItemPath(item.id)),
        );
      },
    );
  }
}

/// Shimmer placeholder list that mirrors the real [ClothingItemList] layout.
class ShimmerLoadingList extends StatelessWidget {
  const ShimmerLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
