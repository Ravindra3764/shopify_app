import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/core/utils/color_swatch_utils.dart';
import 'package:shopify_app/shopify/models/product_option.dart';

/// Selectable row for one product [option] (e.g. `Size`, `Color`).
///
/// Renders solid color-swatch circles when [option] looks like a color
/// option, and bordered text pills otherwise. Selecting an unavailable
/// combination is allowed — availability is reflected on the Add to Cart
/// action, not by disabling values here.
class ProductOptionSelector extends StatelessWidget {
  const ProductOptionSelector({
    required this.option,
    required this.selectedValue,
    required this.onSelected,
    super.key,
  });

  final ProductOption option;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  bool get _isColorOption {
    final name = option.name.toLowerCase();
    return name.contains('color') || name.contains('colour');
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in option.values)
          _isColorOption ? _buildSwatch(value) : _buildChip(context, value),
      ],
    );
  }

  Widget _buildSwatch(String value) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        width: AppDimensions.swatchSize,
        height: AppDimensions.swatchSize,
        padding: EdgeInsets.all(isSelected ? AppSpacing.xs : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : Colors.transparent,
            width: AppDimensions.swatchRingWidth,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorForSwatchName(value),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String value) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        constraints: const BoxConstraints(minWidth: AppDimensions.swatchSize),
        height: AppDimensions.optionChipHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
