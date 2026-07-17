import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shopify/models/delivery_group.dart';
import 'package:shopify_app/shopify/models/delivery_option.dart';

/// Callback fired when a shipping option is chosen for a delivery group.
typedef DeliverySelection =
    void Function(String deliveryGroupId, String optionHandle);

/// Radio-style list of shipping options across the cart's delivery [groups].
///
/// Each group renders its available [DeliveryOption]s; tapping one calls
/// [onSelect]. The currently selected option per group is highlighted.
class DeliveryOptionsList extends StatelessWidget {
  const DeliveryOptionsList({
    required this.groups,
    required this.onSelect,
    super.key,
  });

  final List<DeliveryGroup> groups;
  final DeliverySelection onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          for (final option in group.options) ...[
            _OptionTile(
              option: option,
              selected: group.selectedOptionHandle == option.handle,
              onTap: () => onSelect(group.id, option.handle),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DeliveryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = option.description;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.boxFill : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected
                ? AppDimensions.swatchRingWidth
                : AppDimensions.hairline,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textTertiary,
              size: AppDimensions.iconMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              option.isFree ? 'Free' : option.price.formatted,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
