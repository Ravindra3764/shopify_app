// GraphQL documents for collections.

/// Fetches a single collection (by handle) with a page of its products —
/// backs the "View All" product grid.
const String kCollectionProductsQuery = r'''
query CollectionProducts($handle: String!, $first: Int!) {
  collection(handle: $handle) {
    handle
    title
    image { url altText width height }
    products(first: $first) {
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
}
''';
