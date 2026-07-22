// GraphQL queries for the signed-in customer's order history.

/// Fetches a page of the customer's orders (newest first) with enough detail
/// to render both the history list and an order-detail view.
const String kCustomerOrdersQuery = r'''
query CustomerOrders($token: String!, $first: Int!, $after: String) {
  customer(customerAccessToken: $token) {
    orders(
      first: $first
      after: $after
      sortKey: PROCESSED_AT
      reverse: true
    ) {
      pageInfo { hasNextPage endCursor }
      edges {
        node {
          id
          name
          orderNumber
          processedAt
          financialStatus
          fulfillmentStatus
          email
          totalPrice { amount currencyCode }
          subtotalPrice { amount currencyCode }
          totalShippingPrice { amount currencyCode }
          totalTax { amount currencyCode }
          shippingAddress {
            firstName
            lastName
            address1
            address2
            city
            province
            zip
            country
            phone
          }
          lineItems(first: 100) {
            edges {
              node {
                title
                quantity
                originalTotalPrice { amount currencyCode }
                variant {
                  title
                  image { url altText width height }
                }
              }
            }
          }
        }
      }
    }
  }
}
''';
