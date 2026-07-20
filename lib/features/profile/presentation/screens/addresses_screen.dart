import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/address_book_selector.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/address_form_sheet.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// Manage the shopper's saved delivery addresses.
///
/// Reads and writes the same [addressBookProvider] the checkout flow uses, so
/// addresses added here appear on checkout and vice-versa. Works signed-out —
/// the address book is local (SharedPreferences), no account required.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    MailingAddress? initial,
  }) async {
    final address = await showAddressFormSheet(
      context,
      initial: initial,
      phoneRequired: ref.read(featureFlagsProvider).phoneRequired,
      defaultCountry: ref.read(appConfigProvider).defaultCountry,
    );
    if (address == null) return;
    await ref.read(addressBookProvider.notifier).add(address);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressBookProvider);

    return CustomBackground(
      title: 'Addresses',
      child: Column(
        children: [
          Expanded(
            child: addresses.isEmpty
                ? EmptyStateView(
                    icon: Icons.location_off_outlined,
                    message: 'No saved addresses yet.',
                    actionLabel: 'Add address',
                    onAction: () => _openForm(context, ref),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    children: [
                      AddressBookSelector(
                        addresses: addresses,
                        // Tapping a card edits it (same id replaces in place).
                        onSelect: (address) =>
                            _openForm(context, ref, initial: address),
                        onDelete: (id) =>
                            ref.read(addressBookProvider.notifier).remove(id),
                      ),
                    ],
                  ),
          ),
          if (addresses.isNotEmpty) ...[
            CustomButton.primary(
              label: 'Add address',
              onPressed: () => _openForm(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
