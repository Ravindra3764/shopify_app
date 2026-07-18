// GraphQL documents for product search.

/// Full-text product search over the Storefront `products` connection.
/// Returns the same summary fields as listings so results render with the
/// standard product card. Shopify's `query` syntax matches title, type,
/// vendor, tags, price (`variants.price:>10`), availability
/// (`available_for_sale:true`), etc. `sortKey`/`reverse` drive result order.
const String kSearchProductsQuery = r'''
query SearchProducts(
  $query: String!
  $first: Int!
  $sortKey: ProductSortKeys
  $reverse: Boolean
) {
  products(first: $first, query: $query, sortKey: $sortKey, reverse: $reverse) {
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
