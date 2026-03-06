import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../shared/providers/add_item_providers.dart';
import '../../../wardrobe/presentation/widgets/tag_selector.dart';

/// Renders the four classification fields (category, season, occasion, mood)
/// for the item tagging form.
///
/// Reads current state from [notifier] and writes changes back through its
/// mutation methods.
class TaggingForm extends StatelessWidget {
  /// The notifier that owns the form state.
  final TaggingFormNotifier notifier;

  /// Current snapshot of the form state.
  final TaggingFormState formState;

  const TaggingForm({
    super.key,
    required this.notifier,
    required this.formState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagSelector<ClothingCategory>(
          label: 'Category',
          options: ClothingCategory.values,
          selected: formState.category,
          onSelected: notifier.setCategory,
          labelBuilder: (v) => v.label,
          isRequired: true,
        ),
        const SizedBox(height: 20),
        TagSelector<ClothingSeason>(
          label: 'Season',
          options: ClothingSeason.values,
          selected: formState.season,
          onSelected: notifier.setSeason,
          labelBuilder: (v) => v.label,
          isRequired: true,
        ),
        const SizedBox(height: 20),
        TagSelector<ClothingOccasion>(
          label: 'Occasion',
          options: ClothingOccasion.values,
          selected: formState.occasion,
          onSelected: notifier.setOccasion,
          labelBuilder: (v) => v.label,
          isRequired: true,
        ),
        const SizedBox(height: 20),
        TagSelector<EmotionalTag>(
          label: 'Mood Tag',
          options: EmotionalTag.values,
          selected: formState.emotionalTag,
          onSelected: notifier.setEmotionalTag,
          labelBuilder: (v) => v.label,
        ),
      ],
    );
  }
}
