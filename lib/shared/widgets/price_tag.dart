import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shopify/models/money.dart';

/// Displays a [price], with an optional struck-through [compareAtPrice] when
/// the product is on sale.
///
/// ```dart
/// PriceTag(price: product.price, compareAtPrice: product.compareAtPrice);
/// ```
class PriceTag extends StatelessWidget {
  const PriceTag({required this.price, super.key, this.compareAtPrice});

  final Money price;
  final Money? compareAtPrice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasDiscount =
        compareAtPrice != null && compareAtPrice!.amount > price.amount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          price.formatted,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            compareAtPrice!.formatted,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}
