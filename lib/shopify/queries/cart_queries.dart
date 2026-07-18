// GraphQL documents for reading a Storefront cart.

/// Shared selection set for a `Cart` — reused by every cart query and
/// mutation so the parsed shape stays identical. Append it to any document
/// that spreads `...CartFields`.
const String kCartFragment = '''
fragment CartFields on Cart {
  id
  checkoutUrl
  totalQuantity
  buyerIdentity { email }
  discountCodes { code applicable }
  discountAllocations {
    discountedAmount { amount currencyCode }
  }
  cost {
    subtotalAmount { amount currencyCode }
    totalAmount { amount currencyCode }
    totalTaxAmount { amount currencyCode }
  }
  deliveryGroups(first: 10) {
    edges {
      node {
        id
        selectedDeliveryOption { handle }
        deliveryOptions {
          handle
          title
          code
          description
          estimatedCost { amount currencyCode }
        }
      }
    }
  }
  lines(first: 100) {
    edges {
      node {
        id
        quantity
        cost { totalAmount { amount currencyCode } }
        merchandise {
          ... on ProductVariant {
            id
            title
            quantityAvailable
            image { url altText width height }
            price { amount currencyCode }
            selectedOptions { name value }
            product { title }
          }
        }
      }
    }
  }
}
''';

/// Fetches an existing guest cart by ID.
const String kGetCartQuery = '''
query GetCart(\$cartId: ID!) {
  cart(id: \$cartId) { ...CartFields }
}
$kCartFragment''';
