import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/product_card.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// [ProductCard] wired to the wishlist: shows a heart and toggles on tap or
/// double-tap. Falls back to a plain card for tenants with the wishlist
/// feature disabled, so callers can use it everywhere without gating.
class WishlistProductCard extends ConsumerWidget {
  const WishlistProductCard({
    required this.product,
    super.key,
    this.onTap,
    this.width,
  });

  final Product product;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(featureFlagsProvider).wishlistEnabled;
    if (!enabled) {
      return ProductCard(product: product, onTap: onTap, width: width);
    }

    final isWishlisted = ref.watch(isInWishlistProvider(product.id));
    return ProductCard(
      product: product,
      width: width,
      onTap: onTap,
      isWishlisted: isWishlisted,
      onWishlistToggle: () =>
          _toggle(context, ref, wasWishlisted: isWishlisted),
      onDoubleTap: () => _toggle(context, ref, wasWishlisted: isWishlisted),
    );
  }

  void _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool wasWishlisted,
  }) {
    ref.read(wishlistProvider.notifier).toggle(product);
    showAppSnackBar(
      context,
      wasWishlisted ? 'Removed from wishlist' : 'Added to wishlist',
      icon: wasWishlisted ? Icons.favorite_border : Icons.favorite,
    );
  }
}
