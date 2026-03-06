import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wardrobe_providers.dart';
import '../widgets/delete_confirm_dialog.dart';

/// Displays the full metadata and image for a single clothing item.
///
/// Provides navigation to [EditItemScreen] and delete functionality
/// with a confirmation dialog.
class ItemDetailScreen extends ConsumerWidget {
  final String id;

  const ItemDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(allClothingItemsProvider);

    return itemAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Item Detail')),
        body: Center(child: Text(err.toString())),
      ),
      data: (items) {
        final item = items.where((i) => i.id == id).firstOrNull;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Item Detail')),
            body: const Center(child: Text('Item not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Item Detail'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit item',
                onPressed: () =>
                    context.push(AppRoutes.wardrobeItemEditPath(id)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image ──────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image(
                    image: FileImage(File(item.imagePath)),
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 280,
                      color: const Color(0xFFEEEEEE),
                      child: const Icon(
                        Icons.checkroom,
                        size: 64,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Details card ───────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow('Category', item.category.label),
                        _DetailRow('Season', item.season.label),
                        _DetailRow('Occasion', item.occasion.label),
                        _DetailRow('Emotional Tag', item.emotionalTag.label),
                        _DetailRow(
                          'Worn',
                          item.usageCount == 1
                              ? '1 time'
                              : '${item.usageCount} times',
                        ),
                        _DetailRow(
                          'Added on',
                          AppDateUtils.formatDate(item.createdAt),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Delete button ──────────────────────────────────────
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final confirmed =
                        await DeleteConfirmDialog.show(context);
                    if (!confirmed || !context.mounted) return;

                    await ref
                        .read(deleteItemUseCaseProvider)
                        .call(id);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item removed from wardrobe'),
                      ),
                    );
                    context.pop();
                  },
                  child: const Text('Delete Item'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}
