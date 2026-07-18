import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart'
    show PromoOutcome;
import 'package:shopify_app/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_state.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/address_book_selector.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/address_form_sheet.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/checkout_step_header.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/checkout_summary.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/delivery_options_list.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// Guest checkout wizard: Address → Shipping → Review → Pay.
///
/// Enforces the `guestCheckoutEnabled` white-label flag — when it's off, the
/// flow is gated behind sign-in (including via deep link, since the gate lives
/// on the screen itself).
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestAllowed = ref.watch(featureFlagsProvider).guestCheckoutEnabled;

    if (!guestAllowed) {
      return CustomBackground(
        title: 'Checkout',
        child: EmptyStateView(
          icon: Icons.lock_outline,
          message:
              'Please sign in to check out.\nGuest checkout is disabled for '
              'this store.',
          actionLabel: 'Back to cart',
          onAction: () => context.pop(),
        ),
      );
    }

    final checkoutAsync = ref.watch(checkoutProvider);

    return CustomBackground(
      title: 'Checkout',
      onBackPressed: () {
        // Step back through the wizard first; pop the route only from step 1.
        if (!ref.read(checkoutProvider.notifier).back()) context.pop();
      },
      child: checkoutAsync.when(
        skipLoadingOnReload: true,
        data: (state) => _CheckoutBody(state: state),
        loading: () => const LoadingShimmer.cart(),
        error: (error, _) => ErrorView(
          message: error is Failure ? error.message : 'Something went wrong.',
          onRetry: () => ref.invalidate(checkoutProvider),
        ),
      ),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        CheckoutStepHeader(current: state.step),
        const SizedBox(height: AppSpacing.xl),
        switch (state.step) {
          CheckoutStep.address => _AddressStep(state: state),
          CheckoutStep.delivery => _DeliveryStep(state: state),
          CheckoutStep.review => _ReviewStep(state: state),
        },
      ],
    );
  }
}

/// Step 1 — choose a saved delivery address or add a new one.
///
/// Shows the buyer email, the list of addresses, and an "Add address" button
/// that opens the form in a sheet. When the address-book flag is off, added
/// addresses are kept only for this session (not persisted).
class _AddressStep extends ConsumerStatefulWidget {
  const _AddressStep({required this.state});

  final CheckoutState state;

  @override
  ConsumerState<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends ConsumerState<_AddressStep> {
  final _emailKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.state.email);

  /// Session-only addresses, used when the address-book flag is off.
  final List<MailingAddress> _session = [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.state.selectedAddress?.id;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  List<MailingAddress> _addresses(bool bookEnabled) =>
      bookEnabled ? ref.watch(addressBookProvider) : _session;

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
    return null;
  }

  Future<void> _addAddress({
    required bool bookEnabled,
    required bool phoneRequired,
  }) async {
    final address = await showAddressFormSheet(
      context,
      phoneRequired: phoneRequired,
      defaultCountry: ref.read(appConfigProvider).defaultCountry,
    );
    if (address == null) return;
    if (bookEnabled) {
      await ref.read(addressBookProvider.notifier).add(address);
    } else {
      setState(() => _session.insert(0, address));
    }
    setState(() => _selectedId = address.id);
  }

  void _delete({required bool bookEnabled, required String id}) {
    if (bookEnabled) {
      ref.read(addressBookProvider.notifier).remove(id);
    } else {
      setState(() => _session.removeWhere((a) => a.id == id));
    }
    if (_selectedId == id) setState(() => _selectedId = null);
  }

  Future<void> _continue(List<MailingAddress> addresses) async {
    if (!(_emailKey.currentState?.validate() ?? false)) return;
    MailingAddress? selected;
    for (final a in addresses) {
      if (a.id == _selectedId) {
        selected = a;
        break;
      }
    }
    if (selected == null) {
      showAppSnackBar(
        context,
        'Please select a delivery address.',
        icon: Icons.location_on_outlined,
      );
      return;
    }
    await ref
        .read(checkoutProvider.notifier)
        .applyAddress(email: _email.text.trim(), address: selected);
  }

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider);
    final bookEnabled = flags.addressBookEnabled;
    final addresses = _addresses(bookEnabled);
    final isSubmitting = ref.watch(checkoutProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    final error = widget.state.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: AppDimensions.iconMd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    error,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Form(
          key: _emailKey,
          child: CustomTextBox(
            label: 'Email',
            hintText: 'you@example.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Delivery address',
          style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (addresses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No address yet. Add one to continue.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          )
        else
          AddressBookSelector(
            addresses: addresses,
            selectedId: _selectedId,
            onSelect: (a) => setState(() => _selectedId = a.id),
            onDelete: (id) => _delete(bookEnabled: bookEnabled, id: id),
          ),
        const SizedBox(height: AppSpacing.md),
        CustomButton.outline(
          label: 'Add address',
          leadingIcon: Icon(
            Icons.add,
            size: AppDimensions.iconSm,
            color: AppColors.primary,
          ),
          onPressed: () => _addAddress(
            bookEnabled: bookEnabled,
            phoneRequired: flags.phoneRequired,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomButton.primary(
          label: 'Continue to shipping',
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : () => _continue(addresses),
        ),
      ],
    );
  }
}

/// Step 2 — choose a shipping option.
class _DeliveryStep extends ConsumerWidget {
  const _DeliveryStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = state.cart;
    final canContinue = !cart.needsDeliverySelection;

    if (!cart.hasDeliveryOptions) {
      return const EmptyStateView(
        icon: Icons.local_shipping_outlined,
        message: 'No shipping options are available for this address.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping method',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        DeliveryOptionsList(
          groups: cart.deliveryGroups,
          onSelect: (groupId, handle) => ref
              .read(checkoutProvider.notifier)
              .selectDelivery(deliveryGroupId: groupId, optionHandle: handle),
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomButton.primary(
          label: 'Continue to review',
          onPressed: canContinue
              ? () => ref.read(checkoutProvider.notifier).proceedToReview()
              : null,
        ),
      ],
    );
  }
}

/// Step 3 — review address + amounts, then pay.
class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.state});

  final CheckoutState state;

  Future<void> _applyPromo(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final outcome = await ref
        .read(checkoutProvider.notifier)
        .applyPromoCode(code);
    if (!context.mounted) return;
    switch (outcome) {
      case PromoOutcome.applied:
        showAppSnackBar(
          context,
          'Promo code applied.',
          icon: Icons.check_circle_outline,
        );
      case PromoOutcome.notApplicable:
        showAppSnackBar(
          context,
          "That code can't be applied to this order.",
          icon: Icons.error_outline,
        );
      case PromoOutcome.error:
        showAppSnackBar(
          context,
          "Couldn't apply the code. Please try again.",
          icon: Icons.error_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    final address = state.selectedAddress;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (address != null) ...[
          _ReviewCard(
            title: 'Deliver to',
            body:
                '${address.fullName}\n${address.formatted}'
                '${state.email != null ? '\n${state.email}' : ''}',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Order summary',
          style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        CheckoutSummary(
          cart: state.cart,
          showPromo: flags.promoCodesEnabled,
          onApplyPromo: (code) => unawaited(_applyPromo(context, ref, code)),
          onRemovePromo: (code) => unawaited(
            ref.read(checkoutProvider.notifier).removePromoCode(code),
          ),
          onPay: () => context.push(
            AppRoutes.checkoutPay,
            extra: state.cart.checkoutUrl,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
