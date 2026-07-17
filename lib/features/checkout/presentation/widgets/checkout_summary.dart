import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';
import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/models/money.dart';

/// Final order summary: Subtotal / Shipping / Tax / Total, an optional promo
/// entry, and the Pay call-to-action.
///
/// Shipping reflects the shopper's selected delivery option; tax and total are
/// the Storefront-computed amounts on [cart]. [showPromo] gates the promo
/// field (white-label toggle). [onPay] opens the hosted payment page.
class CheckoutSummary extends StatelessWidget {
  const CheckoutSummary({
    required this.cart,
    required this.onPay,
    super.key,
    this.isPaying = false,
    this.showPromo = false,
    this.onApplyPromo,
  });

  final Cart cart;
  final VoidCallback onPay;
  final bool isPaying;
  final bool showPromo;
  final ValueChanged<String>? onApplyPromo;

  String _shippingLabel() {
    final shipping = cart.selectedShipping;
    if (shipping != null) {
      return shipping.amount <= 0 ? 'Free' : shipping.formatted;
    }
    if (cart.hasDeliveryOptions) return 'Select option';
    return 'Free';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showPromo && onApplyPromo != null) ...[
          _PromoField(onApply: onApplyPromo!),
          const SizedBox(height: AppSpacing.lg),
        ],
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.boxFill,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            children: [
              _Row(label: 'Subtotal', value: cart.subtotal.formatted),
              const SizedBox(height: AppSpacing.sm),
              _Row(label: 'Shipping', value: _shippingLabel()),
              const SizedBox(height: AppSpacing.sm),
              _Row(
                label: 'Tax',
                value:
                    cart.tax?.formatted ??
                    Money(
                      amount: 0,
                      currencyCode: cart.subtotal.currencyCode,
                    ).formatted,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(
                  color: AppColors.border,
                  height: AppDimensions.hairline,
                ),
              ),
              _Row(
                label: 'Total',
                value: cart.total.formatted,
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomButton.primary(
          label: 'Pay ${cart.total.formatted}',
          isLoading: isPaying,
          leadingIcon: const Icon(
            Icons.lock_outline,
            size: AppDimensions.iconSm,
            color: AppColors.white,
          ),
          onPressed: isPaying ? null : onPay,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized
        ? textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          )
        : textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _PromoField extends StatefulWidget {
  const _PromoField({required this.onApply});

  final ValueChanged<String> onApply;

  @override
  State<_PromoField> createState() => _PromoFieldState();
}

class _PromoFieldState extends State<_PromoField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    widget.onApply(code);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextBox(
            hintText: 'Promo code',
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(),
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
