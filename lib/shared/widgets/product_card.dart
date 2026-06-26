import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shared/widgets/price_tag.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// Product tile used in home/listing grids.
///
/// Shows the featured image, title, and a [PriceTag] (with sale strikethrough).
/// Tapping calls [onTap]. Sold-out products get a muted "Sold out" marker.
///
/// ```dart
/// ProductCard(product: product, onTap: () => openProduct(product));
/// ```
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key, this.onTap, this.width});

  final Product product;
  final VoidCallback? onTap;

  /// Fixed card width (for horizontal lists). Null = fill parent.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final soldOut = !product.availableForSale;

    return GestureDetector(
      onTap: onTap,
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
