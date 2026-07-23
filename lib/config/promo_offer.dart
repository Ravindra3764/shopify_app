/// A tenant-advertised promo code surfaced to shoppers at checkout.
///
/// The Storefront API can't list a store's discount codes (that's Admin-only),
/// so surfaced offers are curated per tenant in `.env` and applied through the
/// normal cart discount mutation — an offer is just a [code] the shopper would
/// otherwise have to type, paired with a human [label] describing the deal.
class PromoOffer {
  const PromoOffer({required this.code, required this.label});

  /// The discount code sent to Shopify (e.g. `SAVE10`). Uppercased on parse so
  /// it displays consistently; Shopify matches codes case-insensitively.
  final String code;

  /// Shopper-facing description of the offer (e.g. `10% off orders over ₹999`).
  final String label;

  /// Parses the `.env` offer list into [PromoOffer]s.
  ///
  /// Format: pipe-separated offers, each `CODE:Label` (first colon splits).
  /// A label is optional — `FREESHIP` alone falls back to the code as label.
  /// Blank/malformed (no code) entries are skipped.
  ///
  /// ```text
  /// SAVE10:10% off orders over ₹999|FREESHIP:Free shipping|WELCOME
  /// ```
  static List<PromoOffer> parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final offers = <PromoOffer>[];
    for (final entry in raw.split('|')) {
      final colon = entry.indexOf(':');
      final code = (colon == -1 ? entry : entry.substring(0, colon))
          .trim()
          .toUpperCase();
      if (code.isEmpty) continue;
      final label = colon == -1 ? '' : entry.substring(colon + 1).trim();
      offers.add(PromoOffer(code: code, label: label.isEmpty ? code : label));
    }
    return offers;
  }
}
