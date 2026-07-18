// GraphQL documents for product search.

/// Full-text product search over the Storefront `products` connection.
/// Returns the same summary fields as listings so results render with the
/// standard product card. Shopify's `query` syntax matches title, type,
/// vendor, tags, etc.
const String kSearchProductsQuery = r'''
query SearchProducts($query: String!, $first: Int!) {
  products(first: $first, query: $query) {
    edges {
      node {
        id
        title
        handle
        availableForSale
        featuredImage { url altText width height }
        priceRange { minVariantPrice { amount currencyCode } }
        compareAtPriceRange { minVariantPrice { amount currencyCode } }
      }
    }
  }
}
''';
