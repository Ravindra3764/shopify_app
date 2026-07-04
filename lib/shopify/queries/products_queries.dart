// GraphQL documents for single-product lookups.

/// Fetches one product (by handle) with its full gallery, options, variants,
/// and description — backs the product-detail screen.
///
/// `ratingMetafield` / `ratingCountMetafield` read the `reviews.rating` and
/// `reviews.rating_count` metafields written by common review apps
/// (e.g. Judge.me, Shopify Product Reviews). Both are `null` when no such
/// app/metafield is configured for the store.
///
/// `colorMetafield` reads Shopify's standard `shopify.color-pattern`
/// category metafield — a display-only color descriptor set separate from
/// purchasable variant options (see `ProductColorSwatch`).
const String kProductByHandleQuery = r'''
query ProductByHandle($handle: String!, $variantsFirst: Int!, $imagesFirst: Int!) {
  product(handle: $handle) {
    id
    title
    handle
    vendor
    availableForSale
    descriptionHtml
    priceRange { minVariantPrice { amount currencyCode } }
    compareAtPriceRange { minVariantPrice { amount currencyCode } }
    images(first: $imagesFirst) {
      edges { node { url altText width height } }
    }
    options { name values }
    variants(first: $variantsFirst) {
      edges {
        node {
          id
          title
          availableForSale
          selectedOptions { name value }
          price { amount currencyCode }
          compareAtPrice { amount currencyCode }
          image { url altText width height }
        }
      }
    }
    ratingMetafield: metafield(namespace: "reviews", key: "rating") { value }
    ratingCountMetafield: metafield(namespace: "reviews", key: "rating_count") {
      value
    }
    colorMetafield: metafield(namespace: "shopify", key: "color-pattern") {
      references(first: 10) {
        nodes {
          ... on Metaobject {
            fields { key value }
          }
        }
      }
    }
  }
}
''';

/// Fetches Shopify's algorithmic "related products" for a given product ID —
/// backs the "You may also like" row on the product-detail screen.
const String kProductRecommendationsQuery = r'''
query ProductRecommendations($productId: ID!) {
  productRecommendations(productId: $productId) {
    id
    title
    handle
    availableForSale
    featuredImage { url altText width height }
    priceRange { minVariantPrice { amount currencyCode } }
    compareAtPriceRange { minVariantPrice { amount currencyCode } }
  }
}
''';
