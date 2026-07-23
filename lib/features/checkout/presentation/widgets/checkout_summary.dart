import 'package:flutter/material.dart';
import 'package:shopify_app/config/promo_offer.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/checkout/presentation/widgets/promo_offers_banner.dart';
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
    this.promoOffers = const [],
    this.onApplyPromo,
    this.onRemovePromo,
  });

  final Cart cart;
  final VoidCallback onPay;
  final bool isPaying;
  final bool showPromo;

  /// Tenant-advertised offers surfaced as a one-tap banner above the promo
  /// field. Empty hides the banner. Applied through [onApplyPromo].
  final List<PromoOffer> promoOffers;
  final ValueChanged<String>? onApplyPromo;
  final ValueChanged<String>? onRemovePromo;

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
    final applied = cart.appliedDiscountCodes;
    return Column(
      children: [
        if (promoOffers.isNotEmpty && onApplyPromo != null) ...[
          PromoOffersBanner(
            offers: promoOffers,
            appliedCodes: [for (final c in cart.discountCodes) c.code],
            onApply: onApplyPromo!,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (showPromo && onApplyPromo != null) ...[
          _PromoField(onApply: onApplyPromo!),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (applied.isNotEmpty && onRemovePromo != null) ...[
          _AppliedCodes(
            codes: [for (final c in applied) c.code],
            onRemove: onRemovePromo!,
          ),
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
              if (cart.discount case final discount?) ...[
                const SizedBox(height: AppSpacing.sm),
                _Row(
                  label: 'Discount',
                  value: '-${discount.formatted}',
                  highlighted: true,
                ),
              ],
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
        Builder(
          builder: (context) {
            // Never allow paying a zeroed order (e.g. an unserviceable
            // address Shopify silently zeroed).
            final payable = cart.total.amount > 0;
            if (!payable) {
              return Text(
                'This order total is unavailable. Please revisit your '
                'delivery address.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
              );
            }
            return CustomButton.primary(
              label: 'Pay ${cart.total.formatted}',
              isLoading: isPaying,
              leadingIcon: const Icon(
                Icons.lock_outline,
                size: AppDimensions.iconSm,
                color: AppColors.white,
              ),
              onPressed: isPaying ? null : onPay,
            );
          },
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
    _controller.clear();
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
