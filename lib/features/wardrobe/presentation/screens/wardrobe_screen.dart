import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/wardrobe_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/clothing_item_grid.dart';
import '../widgets/clothing_item_list.dart';
import '../widgets/filter_chip_bar.dart';
/// Main wardrobe screen — browses all clothing items with filter and
/// grid/list toggle.
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(wardrobeViewModeProvider);
    final activeFilter = ref.watch(activeCategoryFilterProvider);
    final filteredAsync = ref.watch(filteredClothingItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
        actions: [
          IconButton(
            tooltip: viewMode == WardrobeViewMode.grid
                ? 'Switch to list'
                : 'Switch to grid',
            icon: Icon(
              viewMode == WardrobeViewMode.grid
                  ? Icons.list
                  : Icons.grid_view,
            ),
            onPressed: () =>
                ref.read(wardrobeViewModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Column(
        children: [
          FilterChipBar(
            activeFilter: activeFilter,
            onFilterChanged: (cat) =>
                ref.read(activeCategoryFilterProvider.notifier).setFilter(cat),
          ),
          Expanded(
            child: filteredAsync.when(
              loading: () => viewMode == WardrobeViewMode.grid
                  ? const ClothingItemGrid(items: null)
                  : const ClothingItemList(items: null),
              error: (err, _) => _ErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(allClothingItemsProvider),
              ),
              data: (items) {
                if (items.isEmpty) return const _EmptyState();
                return viewMode == WardrobeViewMode.grid
                    ? ClothingItemGrid(items: items)
                    : ClothingItemList(items: items);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.checkroom_outlined,
            size: 80,
            color: Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 16),
          const Text(
            'No items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first item',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
