import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';

/// Horizontally scrollable row of [FilterChip] widgets for category filtering.
///
/// Renders an 'All' chip plus one chip per [ClothingCategory].
/// Calls [onFilterChanged] with `null` when 'All' is selected.
class FilterChipBar extends StatelessWidget {
  /// Currently active filter, or `null` if 'All' is selected.
  final ClothingCategory? activeFilter;

  /// Called when the user selects a new filter.
  final ValueChanged<ClothingCategory?> onFilterChanged;

  const FilterChipBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const _accent = Color(0xFF4A90D9);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(label: 'All', isSelected: activeFilter == null, onTap: () => onFilterChanged(null)),
          ...ClothingCategory.values.map(
            (cat) => _chip(
              label: cat.label,
              isSelected: activeFilter == cat,
              onTap: () => onFilterChanged(cat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: _accent,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF555555),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: const Color(0xFFF0F0F0),
        side: BorderSide.none,
        showCheckmark: false,
      ),
    );
  }
}
