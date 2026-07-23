// GraphQL documents for tenant-advertised checkout promos.

/// Fetches `promo_offer` metaobjects — the Storefront-native, app-agnostic
/// source for advertised discount codes. The tenant defines the `promo_offer`
/// metaobject definition (Storefront access: read) in Shopify Admin with
/// fields: `code` (the discount code), `label` (shopper-facing text), and an
/// optional `min_subtotal` (eligibility threshold, decimal).
///
/// The Storefront `metaobjects` connection has no server-side field filter, so
/// eligibility (min-subtotal) is applied client-side. Stores that haven't
/// defined this metaobject return an empty connection — the banner then hides.
const String kPromoOffersQuery = r'''
query PromoOffers($first: Int!) {
  metaobjects(type: "promo_offer", first: $first) {
    edges {
      node {
        id
        code: field(key: "code") { value }
        label: field(key: "label") { value }
        minSubtotal: field(key: "min_subtotal") { value }
      }
    }
  }
}
''';
