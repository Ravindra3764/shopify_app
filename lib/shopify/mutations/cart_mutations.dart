// GraphQL mutations for the Storefront guest cart lifecycle.
//
// All reuse the shared `CartFields` fragment from `cart_queries.dart` and
// return `userErrors` so the repository can surface Shopify validation
// problems (e.g. sold-out variant) as a `Failure`.

import 'package:shopify_app/shopify/queries/cart_queries.dart';

/// Creates a new guest cart seeded with lines, in the tenant's [\$countryCode]
/// market context. The country pins pricing/availability to the store's market
/// (Shopify Markets) so products resolve correctly; without it the cart falls
/// back to the store's default market, where the catalog may be unavailable.
const String kCartCreateMutation = '''
mutation CartCreate(\$lines: [CartLineInput!], \$countryCode: CountryCode) {
  cartCreate(
    input: { lines: \$lines, buyerIdentity: { countryCode: \$countryCode } }
  ) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$kCartFragment''';

/// Adds lines to an existing cart.
const String kCartLinesAddMutation = '''
mutation CartLinesAdd(\$cartId: ID!, \$lines: [CartLineInput!]!) {
  cartLinesAdd(cartId: \$cartId, lines: \$lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$kCartFragment''';

/// Updates existing lines (typically to change quantity).
const String kCartLinesUpdateMutation = '''
mutation CartLinesUpdate(\$cartId: ID!, \$lines: [CartLineUpdateInput!]!) {
  cartLinesUpdate(cartId: \$cartId, lines: \$lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$kCartFragment''';

/// Replaces the cart's discount codes with [\$discountCodes] (send the full set
/// each time — it's a replace, not a merge). Shopify echoes each code back with
/// `applicable`: `false` means invalid or not usable on this cart (unmet
/// minimum, wrong products, expired). An empty list clears all codes. The list
/// is non-null (`[String!]!`) — pass `[]` to clear, never omit the argument.
const String kCartDiscountCodesUpdateMutation = '''
mutation CartDiscountCodesUpdate(\$cartId: ID!, \$discountCodes: [String!]!) {
  cartDiscountCodesUpdate(cartId: \$cartId, discountCodes: \$discountCodes) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$kCartFragment''';

/// Removes lines from a cart by their line IDs.
const String kCartLinesRemoveMutation = '''
mutation CartLinesRemove(\$cartId: ID!, \$lineIds: [ID!]!) {
  cartLinesRemove(cartId: \$cartId, lineIds: \$lineIds) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$kCartFragment''';
