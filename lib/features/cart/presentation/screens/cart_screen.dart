import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:shopify_app/features/cart/presentation/widgets/cart_summary.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';
import 'package:shopify_app/shopify/models/cart.dart';

/// Cart tab — lists the guest cart's lines, cost breakdown, and checkout CTA.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final cart = cartAsync.valueOrNull;

    final Widget child;
    if (cartAsync.isLoading && cart == null) {
      child = const LoadingShimmer.cart();
    } else if (cartAsync.hasError && cart == null) {
      final error = cartAsync.error;
      child = ErrorView(
        message: error is Failure ? error.message : 'Something went wrong.',
        onRetry: () => ref.invalidate(cartProvider),
      );
    } else if (cart == null || cart.isEmpty) {
      child = EmptyStateView(
        icon: Icons.shopping_bag_outlined,
        message: 'Your cart is empty.',
        actionLabel: 'Continue Shopping',
        onAction: () => context.go(AppRoutes.home),
      );
    } else {
      child = _CartContent(cart: cart);
    }

    return CustomBackground(
      showAppBar: false,
      applyBottomInset: false,
      horizontalPadding: 0,
      contentTopPadding: 0,
      child: child,
    );
  }
}

class _CartContent extends ConsumerWidget {
  const _CartContent({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(cartProvider.notifier);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppDimensions.floatingNavClearance,
        ),
        children: [
          Text(
            'Your Cart',
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${cart.totalQuantity} '
            '${cart.totalQuantity == 1 ? 'item' : 'items'} in your selection',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final line in cart.lines) ...[
            CartItemTile(
              line: line,
              onIncrement: line.canIncrease
                  ? () => notifier.setLineQuantity(line.id, line.quantity + 1)
                  : null,
              onDecrement: line.quantity > 1
                  ? () => notifier.setLineQuantity(line.id, line.quantity - 1)
                  : null,
              onRemove: () => notifier.removeLine(line.id),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Divider(color: AppColors.divider, height: 1),
            ),
          ],
          CartSummary(
            cart: cart,
            onApplyPromo: (_) => showAppSnackBar(
              context,
              'Promo codes are on the way.',
              icon: Icons.local_offer_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton.primary(
            label: 'Proceed to Checkout',
            trailingIcon: const Icon(
              Icons.arrow_forward,
              size: AppDimensions.iconSm,
              color: AppColors.white,
            ),
            onPressed: () => context.push(AppRoutes.checkout),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text(
                'CONTINUE SHOPPING',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
