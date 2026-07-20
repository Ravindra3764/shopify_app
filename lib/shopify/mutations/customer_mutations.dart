// GraphQL mutations for Storefront classic customer authentication.
//
// All return `customerUserErrors { code field message }` so the repository can
// surface Shopify validation problems (bad credentials, taken email, weak
// password) as an `AuthFailure`.

/// Signs a customer in with email + password, returning an access token.
const String kCustomerAccessTokenCreateMutation = r'''
mutation CustomerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
  customerAccessTokenCreate(input: $input) {
    customerAccessToken { accessToken expiresAt }
    customerUserErrors { code field message }
  }
}''';

/// Registers a new customer. Does not return a token — the repository follows
/// this with `customerAccessTokenCreate` to sign the new customer in.
const String kCustomerCreateMutation = r'''
mutation CustomerCreate($input: CustomerCreateInput!) {
  customerCreate(input: $input) {
    customer { id }
    customerUserErrors { code field message }
  }
}''';

/// Invalidates an access token server-side (logout).
const String kCustomerAccessTokenDeleteMutation = r'''
mutation CustomerAccessTokenDelete($customerAccessToken: String!) {
  customerAccessTokenDelete(customerAccessToken: $customerAccessToken) {
    deletedAccessToken
    userErrors { field message }
  }
}''';

/// Renews an unexpired access token — used to restore a session on launch.
const String kCustomerAccessTokenRenewMutation = r'''
mutation CustomerAccessTokenRenew($customerAccessToken: String!) {
  customerAccessTokenRenew(customerAccessToken: $customerAccessToken) {
    customerAccessToken { accessToken expiresAt }
    userErrors { field message }
  }
}''';

/// Sends a Shopify password-reset email. The reset completes via the emailed
/// web link, not in-app.
const String kCustomerRecoverMutation = r'''
mutation CustomerRecover($email: String!) {
  customerRecover(email: $email) {
    customerUserErrors { code field message }
  }
}''';
