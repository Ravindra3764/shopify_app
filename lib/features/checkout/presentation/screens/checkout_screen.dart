import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_state.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/address_book_selector.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/address_form.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/checkout_step_header.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/checkout_summary.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/delivery_options_list.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
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

/// Step 1 — pick a saved address (prefill) or enter a new one.
class _AddressStep extends ConsumerStatefulWidget {
  const _AddressStep({required this.state});

  final CheckoutState state;

  @override
  ConsumerState<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends ConsumerState<_AddressStep> {
  MailingAddress? _prefill;

  @override
  void initState() {
    super.initState();
    _prefill = widget.state.selectedAddress;
  }

  Future<void> _submit(AddressSubmission submission) async {
    final flags = ref.read(featureFlagsProvider);
    if (flags.addressBookEnabled && submission.saveToBook) {
      await ref.read(addressBookProvider.notifier).add(submission.address);
    }
    await ref
        .read(checkoutProvider.notifier)
        .applyAddress(email: submission.email, address: submission.address);
  }

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider);
    final addresses = ref.watch(addressBookProvider);
    final isSubmitting = ref.watch(checkoutProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (flags.addressBookEnabled && addresses.isNotEmpty) ...[
          AddressBookSelector(
            addresses: addresses,
            selectedId: _prefill?.id,
            onSelect: (a) => setState(() => _prefill = a),
            onDelete: (id) {
              ref.read(addressBookProvider.notifier).remove(id);
              if (_prefill?.id == id) setState(() => _prefill = null);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _prefill == null ? 'New address' : 'Edit address',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AddressForm(
          // Re-key so the form re-initializes when a saved address is picked.
          key: ValueKey(_prefill?.id ?? 'new-address'),
          initialEmail: widget.state.email,
          initialAddress: _prefill,
          isSubmitting: isSubmitting,
          phoneRequired: flags.phoneRequired,
          showSaveOption: flags.addressBookEnabled,
          onSubmit: _submit,
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
          onApplyPromo: (_) => showAppSnackBar(
            context,
            'Promo codes are on the way.',
            icon: Icons.local_offer_outlined,
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
