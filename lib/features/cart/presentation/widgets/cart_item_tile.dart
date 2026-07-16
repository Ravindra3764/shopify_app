import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/quantity_stepper.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shopify/models/cart_line.dart';

/// A single row in the cart: variant thumbnail, title + options, a quantity
/// stepper, a remove action, and the line total.
///
/// [onDecrement] is `null` at quantity 1 so the stepper disables it (use the
/// [onRemove] X to delete the line instead).
///
/// ```dart
/// CartItemTile(
///   line: line,
///   onIncrement: () => notifier.setLineQuantity(line.id, line.quantity + 1),
///   onDecrement: () => notifier.setLineQuantity(line.id, line.quantity - 1),
///   onRemove: () => notifier.removeLine(line.id),
/// );
/// ```
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    super.key,
  });

  final CartLine line;

  /// `null` disables `+` — e.g. once quantity reaches available stock.
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCachedImage(
          imageUrl: line.image?.url ?? '',
          placeholderName: line.productTitle,
          height: AppDimensions.cartThumbSize,
          width: AppDimensions.cartThumbSize,
          borderRadius: AppDimensions.radiusSm,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      line.productTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.close,
                        size: AppDimensions.iconSm,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  QuantityStepper(
                    quantity: line.quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  ),
                  Text(
                    line.lineTotal.formatted,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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
