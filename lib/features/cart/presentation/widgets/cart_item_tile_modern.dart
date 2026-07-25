import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/core/utils/shopify_image_url.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/quantity_stepper.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/providers/product_swatch_provider.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shopify/models/cart_line.dart';

/// Modern cart row (`CART_LAYOUT=modern`): rounded thumbnail, title, an accent
/// price, and a quantity stepper. It has **no** inline remove button — the
/// cart wraps it in a `Dismissible` so items are removed by swiping the row
/// right-to-left.
///
/// ```dart
/// CartItemTileModern(
///   line: line,
///   onIncrement: () => notifier.setLineQuantity(line.id, line.quantity + 1),
///   onDecrement: () => notifier.setLineQuantity(line.id, line.quantity - 1),
/// );
/// ```
class CartItemTileModern extends ConsumerWidget {
  const CartItemTileModern({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  final CartLine line;

  /// `null` disables `+`/`-` respectively (stock cap / at quantity 1).
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  /// Clamp for the requested thumbnail width (device pixels).
  static const _minPx = 200;
  static const _maxPx = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;

    // Tinted thumbnail: panel colour sampled from the image, product
    // `contain`ed on it — the same look as home product cards. Gated by the
    // shared `cardImageTintEnabled` flag; otherwise a plain `cover` thumbnail.
    final tintEnabled = ref.watch(
      featureFlagsProvider.select((f) => f.cardImageTintEnabled),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetPx = (AppDimensions.cartThumbSizeLarge * dpr).round().clamp(
      _minPx,
      _maxPx,
    );
    final imageUrl = sizedShopifyImageUrl(
      line.image?.url ?? '',
      width: targetPx,
    );
    final tinted = tintEnabled && imageUrl.isNotEmpty;
    final panelColor = tinted
        ? ref
              .watch(productSwatchProvider(imageUrl))
              .maybeWhen(data: (c) => c, orElse: () => AppColors.surface)
        : AppColors.surface;

    return Row(
      children: [
        CustomCachedImage(
          imageUrl: imageUrl,
          placeholderName: line.productTitle,
          height: AppDimensions.cartThumbSizeLarge,
          width: AppDimensions.cartThumbSizeLarge,
          borderRadius: AppDimensions.radiusLg,
          fit: tinted ? BoxFit.contain : BoxFit.cover,
          backgroundColor: panelColor,
          memCacheWidth: targetPx,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.productTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (line.optionsSummary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  line.optionsSummary,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      line.lineTotal.formatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  QuantityStepper(
                    quantity: line.quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
