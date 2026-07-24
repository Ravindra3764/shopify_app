import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/providers/product_swatch_provider.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shared/widgets/price_tag.dart';
import 'package:shopify_app/shopify/models/product.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({
    required this.product,
    super.key,
    this.onTap,
    this.onDoubleTap,
    this.width,
    this.imageAspectRatio,
    this.isWishlisted = false,
    this.onWishlistToggle,
  });

  final Product product;
  final VoidCallback? onTap;

  /// Double-tap gesture — typically wired to toggle the wishlist.
  final VoidCallback? onDoubleTap;

  final double? width;

  /// Image aspect ratio (width / height). When set, the panel takes this ratio
  /// so cards vary in height — the masonry look. `null` → a square tile (the
  /// standard uniform grid). Either way the product sits `contain`ed on a
  /// color panel sampled from the image (see [productSwatchProvider]).
  final double? imageAspectRatio;

  /// Whether the wishlist heart renders filled. Ignored when
  /// [onWishlistToggle] is `null` (no heart shown).
  final bool isWishlisted;

  /// Tapped when the heart is pressed. `null` hides the heart entirely — e.g.
  /// for tenants with the wishlist feature disabled.
  final VoidCallback? onWishlistToggle;

  /// Cross-fade when the sampled panel color resolves from its fallback.
  static const _panelFadeDuration = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final soldOut = !product.availableForSale;
    final imageUrl = product.featuredImage?.url ?? '';
    final tintEnabled = ref.watch(featureFlagsProvider).cardImageTintEnabled;
    final isMasonry = imageAspectRatio != null;

    // Tinted look: panel color sampled from the image, product `contain`ed on
    // it with a little breathing room. Otherwise the flat look: masonry goes
    // full-bleed `cover`, standard `contain`s on the surface color.
    final tinted = tintEnabled && imageUrl.isNotEmpty;
    final panelColor = tinted
        ? ref
              .watch(productSwatchProvider(imageUrl))
              .maybeWhen(data: (c) => c, orElse: () => AppColors.surface)
        : AppColors.surface;
    final imageFit = tinted || !isMasonry ? BoxFit.contain : BoxFit.cover;
    final imagePadding = tinted
        ? const EdgeInsets.all(AppSpacing.sm)
        : EdgeInsets.zero;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: _panelFadeDuration,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: AppDimensions.cardShadowBlur,
                    offset: const Offset(0, AppDimensions.cardShadowOffsetY),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                child: AspectRatio(
                  aspectRatio: imageAspectRatio ?? 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: imagePadding,
                        child: CustomCachedImage(
                          fit: imageFit,
                          imageUrl: imageUrl,
                          placeholderName: product.title,
                        ),
                      ),
                      if (soldOut) const _SoldOutBadge(),
                      if (onWishlistToggle != null)
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: _WishlistHeart(
                            isWishlisted: isWishlisted,
                            onTap: onWishlistToggle!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            PriceTag(
              price: product.price,
              compareAtPrice: product.compareAtPrice,
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular wishlist toggle floated over a product image.
class _WishlistHeart extends StatelessWidget {
  const _WishlistHeart({required this.isWishlisted, required this.onTap});

  final bool isWishlisted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onTap,
        radius: AppDimensions.iconMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(
            isWishlisted ? Icons.favorite : Icons.favorite_border,
            size: AppDimensions.iconSm,
            color: isWishlisted ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Translucent "Sold out" overlay shown on unavailable products.
class _SoldOutBadge extends StatelessWidget {
  const _SoldOutBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Center(
        child: Text(
          'Sold out',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
