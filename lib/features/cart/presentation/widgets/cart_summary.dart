import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shopify/models/cart.dart';

/// Promo-code entry, applied-code chips, and the Subtotal / Discount /
/// Shipping / Tax / Total breakdown.
///
/// [onApplyPromo] submits an entered code; [onRemovePromo] clears an applied
/// one. Both drive the Storefront `cartDiscountCodesUpdate` mutation via the
/// cart notifier.
class CartSummary extends StatelessWidget {
  const CartSummary({
    required this.cart,
    required this.onApplyPromo,
    required this.onRemovePromo,
    super.key,
  });

  final Cart cart;
  final ValueChanged<String> onApplyPromo;
  final ValueChanged<String> onRemovePromo;

  @override
  Widget build(BuildContext context) {
    final applied = cart.appliedDiscountCodes;
    return Column(
      children: [
        _PromoCodeField(onApply: onApplyPromo),
        if (applied.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _AppliedCodes(
            codes: [for (final c in applied) c.code],
            onRemove: onRemovePromo,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _TotalsCard(cart: cart),
      ],
    );
  }
}

/// Removable chips for each applied discount code.
class _AppliedCodes extends StatelessWidget {
  const _AppliedCodes({required this.codes, required this.onRemove});

  final List<String> codes;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final code in codes)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: AppDimensions.iconSm,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    code,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: () => onRemove(code),
                    child: Icon(
                      Icons.close,
                      size: AppDimensions.iconSm,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoCodeField extends StatefulWidget {
  const _PromoCodeField({required this.onApply});

  final ValueChanged<String> onApply;

  @override
  State<_PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<_PromoCodeField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    widget.onApply(code);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: AppDimensions.buttonHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.boxFill,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _apply(),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Promo Code',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: AppColors.hint,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        CustomButton.outline(
          label: 'APPLY',
          width: AppDimensions.retryButtonWidth / 1.6,
          onPressed: _apply,
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.boxFill,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: cart.subtotal.formatted),
          if (cart.discount case final discount?) ...[
            const SizedBox(height: AppSpacing.sm),
            _SummaryRow(
              label: 'Discount',
              value: '-${discount.formatted}',
              highlighted: true,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const _SummaryRow(label: 'Shipping', value: 'Calculated at checkout'),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            label: 'Tax',
            value: cart.tax?.formatted ?? 'Calculated at checkout',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: AppColors.border, height: 1),
          ),
          _SummaryRow(
            label: 'Total',
            value: cart.total.formatted,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  /// Tints the row with the brand primary — used for the discount saving.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized
        ? textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          )
        : textTheme.bodyMedium?.copyWith(
            color: highlighted ? AppColors.primary : AppColors.textSecondary,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
