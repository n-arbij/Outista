import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wardrobe_providers.dart';
import '../widgets/tag_selector.dart';

/// Allows the user to edit the category, season, occasion, and emotional
/// tag of an existing clothing item.
///
/// All required fields must be selected before saving. On a successful
/// save the screen pops and shows a SnackBar.
class EditItemScreen extends ConsumerStatefulWidget {
  final String id;

  const EditItemScreen({super.key, required this.id});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  ClothingItemModel? _original;

  // Mutable form state
  ClothingCategory? _category;
  ClothingSeason? _season;
  ClothingOccasion? _occasion;
  EmotionalTag? _emotionalTag;

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(allClothingItemsProvider);

    return itemAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Item')),
        body: Center(child: Text(err.toString())),
      ),
      data: (items) {
        final item = items.where((i) => i.id == widget.id).firstOrNull;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Item')),
            body: const Center(child: Text('Item not found.')),
          );
        }

        // Seed form state on first load.
        if (_original == null) {
          _original = item;
          _category = item.category;
          _season = item.season;
          _occasion = item.occasion;
          _emotionalTag = item.emotionalTag;
        }

        final isValid =
            _category != null && _season != null && _occasion != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Item'),
            actions: [
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                tooltip: 'Save',
                onPressed: isValid && !_isSaving ? _save : null,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image preview ──────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: FileImage(File(item.imagePath)),
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFFEEEEEE),
                      child: const Icon(
                        Icons.checkroom,
                        size: 48,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Category ───────────────────────────────────────────
                TagSelector<ClothingCategory>(
                  label: 'Category',
                  isRequired: true,
                  options: ClothingCategory.values,
                  selected: _category,
                  labelBuilder: (c) => c.label,
                  onSelected: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 20),

                // ── Season ─────────────────────────────────────────────
                TagSelector<ClothingSeason>(
                  label: 'Season',
                  isRequired: true,
                  options: ClothingSeason.values,
                  selected: _season,
                  labelBuilder: (s) => s.label,
                  onSelected: (s) => setState(() => _season = s),
                ),
                const SizedBox(height: 20),

                // ── Occasion ───────────────────────────────────────────
                TagSelector<ClothingOccasion>(
                  label: 'Occasion',
                  isRequired: true,
                  options: ClothingOccasion.values,
                  selected: _occasion,
                  labelBuilder: (o) => o.label,
                  onSelected: (o) => setState(() => _occasion = o),
                ),
                const SizedBox(height: 20),

                // ── Emotional Tag ──────────────────────────────────────
                TagSelector<EmotionalTag>(
                  label: 'Feeling',
                  options: EmotionalTag.values,
                  selected: _emotionalTag,
                  labelBuilder: (e) => e.label,
                  onSelected: (e) => setState(() => _emotionalTag = e),
                ),
                const SizedBox(height: 32),

                // ── Save button ────────────────────────────────────────
                FilledButton(
                  onPressed: isValid && !_isSaving ? _save : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_original == null) return;
    setState(() => _isSaving = true);

    try {
      final updated = ClothingItemModel(
        id: _original!.id,
        imagePath: _original!.imagePath,
        category: _category!,
        season: _season!,
        occasion: _occasion!,
        emotionalTag: _emotionalTag ?? EmotionalTag.none,
        usageCount: _original!.usageCount,
        createdAt: _original!.createdAt,
        lastWornAt: _original!.lastWornAt,
      );

      await ref.read(updateItemUseCaseProvider).call(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
