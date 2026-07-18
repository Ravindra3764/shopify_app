import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:shopify_app/features/wishlist/presentation/widgets/wishlist_product_card.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';

/// The shopper's saved products. Local-only for now; hearts toggle from here,
/// the home header, cards, and the product-detail gallery all stay in sync via
/// [wishlistProvider].
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(wishlistProvider);

    return CustomBackground(
      title: 'Wishlist',
      horizontalPadding: 0,
      contentTopPadding: 0,
      child: products.isEmpty
          ? EmptyStateView(
              icon: Icons.favorite_border,
              message:
                  'Your wishlist is empty.\nTap the heart on a product to '
                  'save it here.',
              actionLabel: 'Start shopping',
              onAction: () => context.go(AppRoutes.home),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: AppDimensions.productCardHeight,
              ),
              itemBuilder: (context, i) {
                final product = products[i];
                return WishlistProductCard(
                  product: product,
                  onTap: () =>
                      context.push(AppRoutes.productDetailPath(product.handle)),
                );
              },
            ),
    );
  }
}
