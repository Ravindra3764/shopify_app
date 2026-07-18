import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// Picker over the shopper's saved delivery [addresses].
///
/// Tapping an entry calls [onSelect] (used to prefill the address form);
/// [selectedId] highlights the active one. The delete affordance calls
/// [onDelete]. Rendered only when the address book is enabled and non-empty.
class AddressBookSelector extends StatelessWidget {
  const AddressBookSelector({
    required this.addresses,
    required this.onSelect,
    required this.onDelete,
    super.key,
    this.selectedId,
  });

  final List<MailingAddress> addresses;
  final ValueChanged<MailingAddress> onSelect;
  final ValueChanged<String> onDelete;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved addresses',
          style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final address in addresses) ...[
          _AddressCard(
            address: address,
            selected: address.id == selectedId,
            onTap: () => onSelect(address),
            onDelete: () => onDelete(address.id),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final MailingAddress address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    address.fullName,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    address.formatted,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.textTertiary,
                  size: AppDimensions.iconMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
