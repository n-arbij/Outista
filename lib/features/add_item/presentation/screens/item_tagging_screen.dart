import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../features/add_item/domain/usecases/add_item_usecase.dart';
import '../../../../shared/providers/add_item_providers.dart';
import '../widgets/image_preview_card.dart';
import '../widgets/tagging_form.dart';

/// Tagging screen where the user classifies the captured clothing item.
///
/// Displays the cropped image preview and a form to set category, season,
/// occasion and optional mood tag. The save button is disabled until all
/// required fields are filled.
class ItemTaggingScreen extends ConsumerStatefulWidget {
  /// The absolute path of the cropped image to tag.
  final String imagePath;

  const ItemTaggingScreen({super.key, required this.imagePath});

  @override
  ConsumerState<ItemTaggingScreen> createState() => _ItemTaggingScreenState();
}

class _ItemTaggingScreenState extends ConsumerState<ItemTaggingScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Reset any stale form state from a previous add-item session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taggingFormProvider.notifier).reset();
    });
  }

  Future<void> _saveItem() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final formState = ref.read(taggingFormProvider);
      final useCase = ref.read(addItemUseCaseProvider);

      await useCase.call(
        AddItemInput(
          imagePath: widget.imagePath,
          category: formState.category!,
          season: formState.season!,
          occasion: formState.occasion!,
          emotionalTag: formState.emotionalTag,
          subcategory: formState.subcategory ?? ClothingSubcategory.none,
          shoeFormality: formState.shoeFormality,
          setId: formState.setId,
          isCoordPiece: formState.isCoordPiece,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added to wardrobe')),
      );
      context.go(AppRoutes.wardrobe);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(taggingFormProvider);
    final notifier = ref.read(taggingFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tag Item')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImagePreviewCard(
                  imagePath: widget.imagePath,
                  onRetake: () => context.pop(),
                ),
                const SizedBox(height: 24),
                TaggingForm(notifier: notifier, formState: formState),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: FilledButton(
                onPressed: formState.isValid && !_isSaving ? _saveItem : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Item'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
