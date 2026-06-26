// GraphQL documents for the home screen.

/// Fetches home banners (`home_banner` metaobjects) and the storefront
/// collections with a first page of products — one round trip for the whole
/// home screen.
const String kHomeQuery = r'''
query Home($bannerCount: Int!, $collectionCount: Int!, $productCount: Int!) {
  banners: metaobjects(type: "home_banner", first: $bannerCount) {
    edges {
      node {
        id
        handle
        eyebrow: field(key: "eyebrow") { value }
        title: field(key: "title") { value }
        ctaLabel: field(key: "cta_label") { value }
        image: field(key: "image") {
          reference {
            ... on MediaImage {
              image { url altText width height }
            }
          }
        }
        ctaCollection: field(key: "cta_collection") {
          reference {
            ... on Collection { handle }
          }
        }
      }
    }
  }
  collections(first: $collectionCount) {
    edges {
      node {
        handle
        title
        image { url altText width height }
        products(first: $productCount) {
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
  }
}
''';
