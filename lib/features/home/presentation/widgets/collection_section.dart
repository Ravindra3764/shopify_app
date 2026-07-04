import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/product_card.dart';
import 'package:shopify_app/shared/widgets/section_header.dart';
import 'package:shopify_app/shopify/models/collection.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// A collection rendered as a titled header plus a horizontal product row.
class CollectionSection extends StatelessWidget {
  const CollectionSection({
    required this.collection,
    super.key,
    this.onSeeAll,
    this.onProductTap,
  });

  final Collection collection;
  final VoidCallback? onSeeAll;
  final void Function(Product product)? onProductTap;

  @override
  Widget build(BuildContext context) {
    final products = collection.products;
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SectionHeader(title: collection.title, onSeeAll: onSeeAll),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppDimensions.productCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) {
              final product = products[i];
              return ProductCard(
                product: product,
                width: AppDimensions.productCardWidth,
                onTap: onProductTap == null
                    ? null
                    : () => onProductTap!(product),
              );
            },
          ),
        ),
      ],
    );
  }
}
