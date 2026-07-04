// GraphQL documents for shop-wide (non-product) Storefront data.

/// Fetches the shop's shipping and refund policy bodies (Settings →
/// Policies in Shopify admin) — backs the product-detail "Shipping &
/// Return" tab, same across every product.
const String kShopPoliciesQuery = '''
query ShopPolicies {
  shop {
    shippingPolicy { body }
    refundPolicy { body }
  }
}
''';
