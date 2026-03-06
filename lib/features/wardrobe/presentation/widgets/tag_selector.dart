import 'package:flutter/material.dart';

/// A generic chip-based selector for any enum type [T].
///
/// Renders a labelled [Wrap] of tappable chips. The selected value is
/// highlighted with the accent colour; unselected chips are outlined.
class TagSelector<T> extends StatelessWidget {
  /// Section label shown above the chips.
  final String label;

  /// All available options to display.
  final List<T> options;

  /// The currently selected value, or `null` if nothing is selected.
  final T? selected;

  /// Called when the user taps a chip.
  final ValueChanged<T> onSelected;

  /// Converts an option value to a display string.
  final String Function(T) labelBuilder;

  /// When `true`, an asterisk (*) is appended to [label].
  final bool isRequired;

  const TagSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.isRequired = false,
  });

  static const _accent = Color(0xFF4A90D9);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selected;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _accent : const Color(0xFFCCCCCC),
                  ),
                ),
                child: Text(
                  labelBuilder(option),
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : const Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
