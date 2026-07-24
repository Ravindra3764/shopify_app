import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shopify_app/config/product_grid_style.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/core/utils/product_layout.dart';
import 'package:shopify_app/features/wishlist/presentation/widgets/wishlist_product_card.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// Scrollable 2-column product feed whose layout follows the tenant's
/// [ProductGridStyle] (`appConfigProvider.productGridStyle`):
///
/// - [ProductGridStyle.standard] → uniform fixed-height grid.
/// - [ProductGridStyle.masonry] → staggered waterfall; each card's height
///   follows its image aspect ratio.
///
/// Both variants render every card through [WishlistProductCard] so the heart /
/// double-tap behavior stays identical everywhere.
///
/// ```dart
/// ProductFeed(
///   products: collection.products,
///   onTapIndex: (i) => openProductFromList(context, collection.products, i),
/// );
/// ```
class ProductFeed extends ConsumerWidget {
  const ProductFeed({
    required this.products,
    required this.onTapIndex,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  final List<Product> products;

  /// Called with the tapped product's index (into [products]).
  final void Function(int index) onTapIndex;

  /// Padding around the feed; pass extra bottom room when a floating nav bar
  /// overlaps the content.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(appConfigProvider).productGridStyle;
    return switch (style) {
      ProductGridStyle.masonry => MasonryGridView.count(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        crossAxisCount: _columns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        itemCount: products.length,
        itemBuilder: (context, i) {
          final product = products[i];
          return WishlistProductCard(
            product: product,
            imageAspectRatio: productMasonryAspectRatio(product),
            onTap: () => onTapIndex(i),
          );
        },
      ),
      ProductGridStyle.standard => GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: AppDimensions.productCardHeight,
        ),
        itemBuilder: (context, i) => WishlistProductCard(
          product: products[i],
          onTap: () => onTapIndex(i),
        ),
      ),
    };
  }

  static const int _columns = 2;
}
