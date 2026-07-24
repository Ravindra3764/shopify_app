import 'package:shopify_app/core/utils/json_parse.dart';

/// A tenant-advertised promo code surfaced to shoppers at checkout.
///
/// Sourced from a `promo_offer` metaobject in Shopify Admin (Storefront-
/// exposed) — the Storefront API can't list discount codes or their rules
/// (that's Admin-only), so tenants curate the offers they want to advertise as
/// metaobjects. An offer is just a [code] the shopper would otherwise type,
/// paired with a human [label] and an optional [minSubtotal] gate so we only
/// advertise codes the current cart can actually use.
class PromoOffer {
  const PromoOffer({required this.code, required this.label, this.minSubtotal});

  /// Builds from a `promo_offer` metaobject node whose fields were aliased in
  /// the query as `code`, `label`, and `minSubtotal` (each `{ value }`, or
  /// null when the metaobject leaves an optional field unset).
  factory PromoOffer.fromJson(Map<String, dynamic> json) {
    String? aliasedValue(String key) {
      final field = json[key];
      if (field is! Map<String, dynamic>) return null;
      return parseStringOrNull(field, 'value', model: _model);
    }

    final code = (aliasedValue('code') ?? '').trim().toUpperCase();
    final label = (aliasedValue('label') ?? '').trim();
    return PromoOffer(
      code: code,
      label: label.isEmpty ? code : label,
      minSubtotal: double.tryParse(aliasedValue('minSubtotal')?.trim() ?? ''),
    );
  }

  static const _model = 'PromoOffer';

  /// The discount code sent to Shopify (e.g. `SAVE10`). Uppercased so it
  /// displays consistently; Shopify matches codes case-insensitively.
  final String code;

  /// Shopper-facing description of the offer (e.g. `10% off orders over ₹999`).
  final String label;

  /// Minimum cart subtotal (in the store currency's major units) required for
  /// this offer to be eligible. Null means no threshold — always eligible.
  /// Mirror the discount's Admin minimum here so the offer is hidden until the
  /// cart qualifies (Shopify would otherwise reject it as not applicable).
  final double? minSubtotal;

  /// Whether this offer is eligible for a cart with [subtotal] (major units).
  bool isEligible(double subtotal) =>
      minSubtotal == null || subtotal >= minSubtotal!;
}
