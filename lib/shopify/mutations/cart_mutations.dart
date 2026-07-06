// GraphQL mutations for the Storefront guest cart lifecycle.
//
// All reuse the shared `CartFields` fragment from `cart_queries.dart` and
// return `userErrors` so the repository can surface Shopify validation
// problems (e.g. sold-out variant) as a `Failure`.

import 'package:shopify_app/shopify/queries/cart_queries.dart';

/// Creates a new guest cart, optionally seeded with lines. No buyer identity
/// is sent — the cart is anonymous until checkout.
const String kCartCreateMutation = '''
mutation CartCreate(\$lines: [CartLineInput!]) {
  cartCreate(input: { lines: \$lines }) {
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

/// Removes lines from a cart by their line IDs.
const String kCartLinesRemoveMutation = '''
mutation CartLinesRemove(\$cartId: ID!, \$lineIds: [ID!]!) {
  cartLinesRemove(cartId: \$cartId, lineIds: \$lineIds) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$kCartFragment''';
