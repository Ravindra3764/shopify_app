import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/cart_added_overlay.dart';
import 'package:shopify_app/shared/widgets/product_card.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// [ProductCard] wired to the wishlist: shows a heart and toggles on tap or
/// double-tap. Falls back to a plain card for tenants with the wishlist
/// feature disabled, so callers can use it everywhere without gating.
///
/// When the floating card style is active, the card's quick-add ("+") button is
/// wired to add the product's first variant straight to the cart.
class WishlistProductCard extends ConsumerWidget {
  const WishlistProductCard({
    required this.product,
    super.key,
    this.onTap,
    this.width,
    this.imageAspectRatio,
  });

  final Product product;
  final VoidCallback? onTap;
  final double? width;

  /// Image aspect ratio (width / height) forwarded to [ProductCard] for the
  /// masonry look; `null` renders the standard square tile.
  final double? imageAspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Quick-add is only possible when the summary carried a variant id.
    final variantId = product.firstVariantId;
    final onAddToCart = variantId == null
        ? null
        : () => _addToCart(context, ref, variantId);

    final enabled = ref.watch(featureFlagsProvider).wishlistEnabled;
    if (!enabled) {
      return ProductCard(
        product: product,
        onTap: onTap,
        width: width,
        imageAspectRatio: imageAspectRatio,
        onAddToCart: onAddToCart,
      );
    }

    final isWishlisted = ref.watch(isInWishlistProvider(product.id));
    return ProductCard(
      product: product,
      width: width,
      imageAspectRatio: imageAspectRatio,
      onTap: onTap,
      isWishlisted: isWishlisted,
      onWishlistToggle: () =>
          _toggle(context, ref, wasWishlisted: isWishlisted),
      onDoubleTap: () => _toggle(context, ref, wasWishlisted: isWishlisted),
      onAddToCart: onAddToCart,
    );
  }

  void _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool wasWishlisted,
  }) {
    ref.read(wishlistProvider.notifier).toggle(product);
    if (wasWishlisted) {
      showAppSnackBar(
        context,
        'Removed from wishlist',
        icon: Icons.favorite_border,
      );
      return;
    }
    showAddedFeedback(
      context,
      ref,
      icon: Icons.favorite,
      toastIcon: Icons.favorite,
      toastMessage: 'Added to wishlist',
      overlayMessage: 'Added to\nwishlist',
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    String variantId,
  ) async {
    await ref.read(cartProvider.notifier).addVariant(variantId);
    if (!context.mounted) return;
    if (ref.read(cartProvider).hasError) {
      showAppSnackBar(
        context,
        'Could not add to cart. Please try again.',
        icon: Icons.error_outline,
      );
      return;
    }
    showCartAddedFeedback(context, ref);
  }
}
