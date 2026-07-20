import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_detail/presentation/product_navigation.dart';
import 'package:shopify_app/features/wishlist/presentation/widgets/wishlist_product_card.dart';
import 'package:shopify_app/shared/widgets/section_header.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// "You May Also Like" row of related [products] on the product-detail
/// screen. Renders nothing when [products] is empty.
class RelatedProductsSection extends StatelessWidget {
  const RelatedProductsSection({
    required this.products,
    super.key,
    this.title = 'You May Also Like',
  });

  final List<Product> products;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SectionHeader(title: title),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppDimensions.productCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              return WishlistProductCard(
                product: products[i],
                width: AppDimensions.productCardWidth,
                onTap: () => openProductFromList(context, products, i),
              );
            },
          ),
        ),
      ],
    );
  }
}
