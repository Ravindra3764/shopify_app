// GraphQL mutations for the guest checkout flow — attaching a delivery
// address to the cart and selecting a shipping rate.
//
// Both reuse the shared `CartFields` fragment from `cart_queries.dart` and
// return `userErrors` so the repository can surface Shopify validation
// problems (e.g. undeliverable address) as a `Failure`.

import 'package:shopify_app/shopify/queries/cart_queries.dart';

/// Attaches the buyer's email + delivery address to the cart. Shopify then
/// computes tax and populates `deliveryGroups` with shipping options.
const String kCartBuyerIdentityUpdateMutation = '''
mutation CartBuyerIdentityUpdate(\$cartId: ID!, \$buyerIdentity: CartBuyerIdentityInput!) {
  cartBuyerIdentityUpdate(cartId: \$cartId, buyerIdentity: \$buyerIdentity) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$kCartFragment''';

/// Selects a shipping rate for one or more delivery groups. The returned cart
/// `cost.totalAmount` includes the chosen shipping.
const String kCartSelectedDeliveryOptionsUpdateMutation = '''
mutation CartSelectedDeliveryOptionsUpdate(\$cartId: ID!, \$selectedDeliveryOptions: [CartSelectedDeliveryOptionInput!]!) {
  cartSelectedDeliveryOptionsUpdate(cartId: \$cartId, selectedDeliveryOptions: \$selectedDeliveryOptions) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$kCartFragment''';
