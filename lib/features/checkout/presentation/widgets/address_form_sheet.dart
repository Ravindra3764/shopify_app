import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/address_form.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// Opens the [AddressForm] in a modal bottom sheet and resolves with the
/// entered [MailingAddress], or `null` if dismissed.
///
/// Pass [initial] to edit an existing address; [phoneRequired] mirrors the
/// checkout flag.
Future<MailingAddress?> showAddressFormSheet(
  BuildContext context, {
  MailingAddress? initial,
  bool phoneRequired = false,
}) {
  return showModalBottomSheet<MailingAddress>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusLg),
      ),
    ),
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      final viewInsets = MediaQuery.of(sheetContext).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg + viewInsets,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                initial == null ? 'Add address' : 'Edit address',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AddressForm(
                initialAddress: initial,
                phoneRequired: phoneRequired,
                onSubmit: (address) => Navigator.of(sheetContext).pop(address),
              ),
            ],
          ),
        ),
      );
    },
  );
}
