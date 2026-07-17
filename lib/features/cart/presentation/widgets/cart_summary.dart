import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shopify/models/cart.dart';

/// Promo-code entry plus the Subtotal / Shipping / Tax / Total breakdown.
///
/// Promo codes aren't wired to the Storefront discount mutation yet — the
/// [onApplyPromo] callback surfaces the entered code so the screen can
/// decide what to do (currently a "coming soon" notice).
class CartSummary extends StatelessWidget {
  const CartSummary({
    required this.cart,
    required this.onApplyPromo,
    super.key,
  });

  final Cart cart;
  final ValueChanged<String> onApplyPromo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PromoCodeField(onApply: onApplyPromo),
        const SizedBox(height: AppSpacing.lg),
        _TotalsCard(cart: cart),
      ],
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
