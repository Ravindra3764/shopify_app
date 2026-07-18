import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shared/widgets/price_tag.dart';
import 'package:shopify_app/shopify/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    super.key,
    this.onTap,
    this.onDoubleTap,
    this.width,
    this.isWishlisted = false,
    this.onWishlistToggle,
  });

  final Product product;
  final VoidCallback? onTap;

  /// Double-tap gesture — typically wired to toggle the wishlist.
  final VoidCallback? onDoubleTap;

  final double? width;

  /// Whether the wishlist heart renders filled. Ignored when
  /// [onWishlistToggle] is `null` (no heart shown).
  final bool isWishlisted;

  /// Tapped when the heart is pressed. `null` hides the heart entirely — e.g.
  /// for tenants with the wishlist feature disabled.
  final VoidCallback? onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final soldOut = !product.availableForSale;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomCachedImage(
                    fit: BoxFit.contain,
                    imageUrl: product.featuredImage?.url ?? '',
                    placeholderName: product.title,
                    borderRadius: AppDimensions.cardRadius,
                    backgroundColor: AppColors.surface,
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
