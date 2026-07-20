// GraphQL queries for the signed-in customer.

/// Fetches the customer identified by a valid access token — used to populate
/// the Profile screen after login / session restore.
const String kCustomerQuery = r'''
query Customer($customerAccessToken: String!) {
  customer(customerAccessToken: $customerAccessToken) {
    id
    email
    firstName
    lastName
    phone
  }
}''';
