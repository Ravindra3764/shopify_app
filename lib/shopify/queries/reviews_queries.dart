// GraphQL documents for product reviews (read-only, Storefront-native).

/// Fetches `product_review` metaobjects — the app-agnostic, Storefront-native
/// way to expose individual reviews (a merchant defines a `product_review`
/// metaobject with fields: `product` (product reference), `rating`, `author`,
/// `title`, `body`, `created_at`, `verified`).
///
/// The Storefront `metaobjects` connection has no server-side field filter, so
/// this pages the whole `product_review` set and the repository filters to the
/// target product by the `product` field value (a product GID). Stores without
/// this metaobject definition return an empty connection — the UI then shows
/// the aggregate rating + "No reviews yet".
const String kProductReviewsQuery = r'''
query ProductReviews($first: Int!, $after: String) {
  metaobjects(type: "product_review", first: $first, after: $after) {
    edges {
      node {
        id
        handle
        fields { key value }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
''';
