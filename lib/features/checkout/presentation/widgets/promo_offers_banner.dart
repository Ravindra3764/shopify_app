import 'package:flutter/material.dart';
import 'package:shopify_app/config/promo_offer.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Surfaces the tenant's advertised promo codes ([offers]) as tappable rows so
/// a shopper can apply a deal without knowing the code.
///
/// Each row shows the code + a human label and an APPLY action wired to
/// [onApply] (the same path as manual entry). Offers whose code is already in
/// [appliedCodes] are hidden. Renders nothing when nothing is left to show —
/// the caller can drop it in unconditionally.
///
/// ```dart
/// PromoOffersBanner(offers: config.promoOffers, appliedCodes: applied,
///     onApply: (code) => applyPromo(code))
/// ```
class PromoOffersBanner extends StatelessWidget {
  const PromoOffersBanner({
    required this.offers,
    required this.appliedCodes,
    required this.onApply,
    super.key,
  });

  final List<PromoOffer> offers;

  /// Codes already on the cart — matching offers are hidden to avoid re-apply.
  final List<String> appliedCodes;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context) {
    final applied = {for (final c in appliedCodes) c.toLowerCase()};
    final available = [
      for (final o in offers)
        if (!applied.contains(o.code.toLowerCase())) o,
    ];
    if (available.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.boxFill,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: AppDimensions.iconSm,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Available offers',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          for (final offer in available) ...[
            const SizedBox(height: AppSpacing.md),
            _OfferRow(offer: offer, onApply: () => onApply(offer.code)),
          ],
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer, required this.onApply});

  final PromoOffer offer;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CodeChip(code: offer.code),
              const SizedBox(height: AppSpacing.xs),
              Text(
                offer.label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton(
          onPressed: onApply,
          child: Text(
            'APPLY',
            style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

/// The code rendered as a dashed-border tag, mirroring an offline coupon.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.primary),
      ),
      child: Text(
        code,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
