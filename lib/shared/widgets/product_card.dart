import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/config/product_card_style.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/core/utils/shopify_image_url.dart';
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
    this.onAddToCart,
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

  /// Tapped when the quick-add ("+") button is pressed. Only rendered by the
  /// [ProductCardStyle.floating] card, and only when the product is in stock.
  /// `null` hides the button.
  final VoidCallback? onAddToCart;

  /// Cross-fade when the sampled panel color resolves from its fallback.
  static const _panelFadeDuration = Duration(milliseconds: 350);

  /// Grid columns the card width is estimated against when no explicit [width].
  static const _columns = 2;

  /// Clamp for the requested thumbnail width (device pixels).
  static const _minPx = 200;
  static const _maxPx = 1000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soldOut = !product.availableForSale;
    final tintEnabled = ref.watch(
      featureFlagsProvider.select((f) => f.cardImageTintEnabled),
    );
    final style = ref.watch(
      appConfigProvider.select((c) => c.productCardStyle),
    );
    final isMasonry = imageAspectRatio != null;

    // Ask Shopify for a card-sized thumbnail (not the full-res original) and
    // decode it at that pixel width — cuts network, decode, memory and the
    // palette-sampling cost. Bucketed so we don't spawn many distinct URLs.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logicalWidth = width ?? MediaQuery.sizeOf(context).width / _columns;
    final targetPx = (logicalWidth * dpr).round().clamp(_minPx, _maxPx);
    final rawUrl = product.featuredImage?.url ?? '';
    final imageUrl = sizedShopifyImageUrl(rawUrl, width: targetPx);

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

    final imagePanel = _ImagePanel(
      panelColor: panelColor,
      imageUrl: imageUrl,
      imageFit: imageFit,
      imagePadding: imagePadding,
      imageAspectRatio: imageAspectRatio,
      targetPx: targetPx,
      placeholder: product.title,
      soldOut: soldOut,
      isWishlisted: isWishlisted,
      onWishlistToggle: onWishlistToggle,
      fadeDuration: _panelFadeDuration,
      // The floating style paints the shadow on the outer card, not the panel.
      elevated: style == ProductCardStyle.classic,
    );

    final card = switch (style) {
      ProductCardStyle.classic => _ClassicCard(
        product: product,
        imagePanel: imagePanel,
      ),
      ProductCardStyle.floating => _FloatingCard(
        product: product,
        imagePanel: imagePanel,
        onAddToCart: soldOut ? null : onAddToCart,
      ),
    };

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: SizedBox(width: width, child: card),
    );
  }
}

/// The rounded image panel shared by both card styles: the sampled color panel,
/// the `contain`/`cover` image, the sold-out badge and the wishlist heart.
class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.panelColor,
    required this.imageUrl,
    required this.imageFit,
    required this.imagePadding,
    required this.imageAspectRatio,
    required this.targetPx,
    required this.placeholder,
    required this.soldOut,
    required this.isWishlisted,
    required this.onWishlistToggle,
    required this.fadeDuration,
    required this.elevated,
  });

  final Color panelColor;
  final String imageUrl;
  final BoxFit imageFit;
  final EdgeInsets imagePadding;
  final double? imageAspectRatio;
  final int targetPx;
  final String placeholder;
  final bool soldOut;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;
  final Duration fadeDuration;

  /// Whether to draw the soft drop shadow under the panel (classic card). The
  /// floating card draws its own shadow on the outer surface instead.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: fadeDuration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: AppDimensions.cardShadowBlur,
                  offset: const Offset(0, AppDimensions.cardShadowOffsetY),
                ),
              ]
            : null,
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
                  placeholderName: placeholder,
                  memCacheWidth: targetPx,
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
    );
  }
}

/// Flat card: image panel with the title and price stacked beneath it.
class _ClassicCard extends StatelessWidget {
  const _ClassicCard({required this.product, required this.imagePanel});

  final Product product;
  final Widget imagePanel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imagePanel,
        const SizedBox(height: AppSpacing.sm),
        Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        PriceTag(price: product.price, compareAtPrice: product.compareAtPrice),
      ],
    );
  }
}

/// Elevated white card: rounded image on top, title + price below, and a
/// circular quick-add button aligned with the price.
class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.product,
    required this.imagePanel,
    required this.onAddToCart,
  });

  final Product product;
  final Widget imagePanel;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: AppDimensions.cardShadowBlur,
            offset: const Offset(0, AppDimensions.cardShadowOffsetY),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imagePanel,
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    // Scale the price down (rather than wrap/overflow) so a
                    // compare-at price still fits the one line beside the
                    // quick-add button on narrow cards.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: PriceTag(
                        price: product.price,
                        compareAtPrice: product.compareAtPrice,
                      ),
                    ),
                  ),
                ),
                if (onAddToCart != null) _QuickAddButton(onTap: onAddToCart!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular "quick add to cart" button on the floating card.
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkResponse(
        onTap: onTap,
        radius: AppDimensions.circleIconButtonSize,
        child: SizedBox(
          width: AppDimensions.circleIconButtonSize,
          height: AppDimensions.circleIconButtonSize,
          child: Icon(
            Icons.add,
            size: AppDimensions.iconMd,
            color: colorScheme.onPrimary,
          ),
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
