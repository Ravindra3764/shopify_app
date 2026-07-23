/// A tenant-advertised promo code surfaced to shoppers at checkout.
///
/// The Storefront API can't list a store's discount codes or their eligibility
/// rules (that's Admin-only), so surfaced offers are curated per tenant in
/// `.env` and applied through the normal cart discount mutation — an offer is
/// just a [code] the shopper would otherwise have to type, paired with a human
/// [label] and an optional [minSubtotal] gate so we only advertise codes the
/// current cart can actually use (a threshold Shopify won't tell us up front).
class PromoOffer {
  const PromoOffer({
    required this.code,
    required this.label,
    this.minSubtotal,
  });

  /// The discount code sent to Shopify (e.g. `SAVE10`). Uppercased on parse so
  /// it displays consistently; Shopify matches codes case-insensitively.
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

  /// Parses the `.env` offer list into [PromoOffer]s.
  ///
  /// Format: pipe-separated offers, each `CODE:Label:MinSubtotal`. The code is
  /// everything before the first colon; a trailing numeric field is read as
  /// [minSubtotal], and everything between is the [label]. Label and min are
  /// both optional — `FREESHIP` alone falls back to the code as label with no
  /// threshold. Blank/malformed (no code) entries are skipped.
  ///
  /// ```text
  /// SAVE10:10% off orders over ₹999:999|FREESHIP:Free shipping|WELCOME
  /// ```
  static List<PromoOffer> parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final offers = <PromoOffer>[];
    for (final entry in raw.split('|')) {
      final fields = entry.split(':');
      final code = fields.first.trim().toUpperCase();
      if (code.isEmpty) continue;

      // A trailing purely-numeric field is the min-subtotal threshold; strip it
      // out so a label with an inner colon ("Buy 1: get 1 free") stays intact.
      final rest = fields.sublist(1);
      double? minSubtotal;
      if (rest.isNotEmpty) {
        final parsed = double.tryParse(rest.last.trim());
        if (parsed != null) {
          minSubtotal = parsed;
          rest.removeLast();
        }
      }

      final label = rest.join(':').trim();
      offers.add(
        PromoOffer(
          code: code,
          label: label.isEmpty ? code : label,
          minSubtotal: minSubtotal,
        ),
      );
    }
    return offers;
  }
}
