import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/cart_line.dart';
import 'package:shopify_app/shopify/models/delivery_group.dart';
import 'package:shopify_app/shopify/models/money.dart';

/// Storefront `Cart` — a guest shopping cart, its lines, and cost breakdown.
///
/// Guest carts need no customer token; they're identified only by [id], which
/// the app holds for the session and replays on every mutation.
class Cart {
  const Cart({
    required this.id,
    required this.checkoutUrl,
    required this.totalQuantity,
    required this.subtotal,
    required this.total,
    required this.lines,
    this.tax,
    this.buyerEmail,
    this.deliveryGroups = const [],
  });

  /// Builds from a Storefront `Cart` node.
  factory Cart.fromJson(Map<String, dynamic> json) {
    final cost = parseMap(json, 'cost', model: _model);
    final taxMap = parseMap(cost, 'totalTaxAmount', model: _model);
    final buyer = parseMap(json, 'buyerIdentity', model: _model);

    return Cart(
      id: parseString(json, 'id', model: _model),
      checkoutUrl: parseString(json, 'checkoutUrl', model: _model),
      totalQuantity: parseInt(json, 'totalQuantity', model: _model),
      subtotal: Money.fromJson(parseMap(cost, 'subtotalAmount', model: _model)),
      total: Money.fromJson(parseMap(cost, 'totalAmount', model: _model)),
      // Tax is null until an address is known (guest cart, pre-checkout).
      tax: taxMap.isEmpty ? null : Money.fromJson(taxMap),
      buyerEmail: buyer.isEmpty
          ? null
          : parseStringOrNull(buyer, 'email', model: _model),
      deliveryGroups: parseList<DeliveryGroup>(
        parseMap(json, 'deliveryGroups', model: _model),
        'edges',
        model: _model,
        fromItem: (item) {
          final edge = item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};
          return DeliveryGroup.fromJson(parseMap(edge, 'node', model: _model));
        },
      ),
      lines: parseList<CartLine>(
        parseMap(json, 'lines', model: _model),
        'edges',
        model: _model,
        fromItem: (item) {
          final edge = item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};
          return CartLine.fromJson(parseMap(edge, 'node', model: _model));
        },
        // Defensively drop any zero-quantity line (a removed / unavailable
        // merchandise) so it never renders as a ghost ₹0 row.
      ).where((line) => line.quantity > 0).toList(),
    );
  }

  /// Copies this cart with new [lines], recomputing [totalQuantity] and the
  /// [subtotal]/[total] from the lines. Used for optimistic stepper updates
  /// before the Storefront response lands; tax/shipping stay untouched.
  Cart withLines(List<CartLine> lines) {
    final quantity = lines.fold(0, (sum, l) => sum + l.quantity);
    final amount = lines.fold<double>(0, (sum, l) => sum + l.lineTotal.amount);
    return Cart(
      id: id,
      checkoutUrl: checkoutUrl,
      totalQuantity: quantity,
      subtotal: Money(amount: amount, currencyCode: subtotal.currencyCode),
      total: Money(amount: amount, currencyCode: total.currencyCode),
      tax: tax,
      buyerEmail: buyerEmail,
      deliveryGroups: deliveryGroups,
      lines: lines,
    );
  }

  static const _model = 'Cart';

  final String id;

  /// Hosted Shopify checkout URL for this cart (used once checkout ships).
  final String checkoutUrl;

  /// Sum of every line's quantity — drives the nav badge.
  final int totalQuantity;
  final Money subtotal;
  final Money total;

  /// Estimated tax; `null` before an address is provided.
  final Money? tax;

  /// Buyer email attached via `cartBuyerIdentityUpdate`; `null` for a fresh
  /// guest cart.
  final String? buyerEmail;

  /// Shipping option groups; empty until a delivery address is applied.
  final List<DeliveryGroup> deliveryGroups;
  final List<CartLine> lines;

  /// Whether the cart holds no lines.
  bool get isEmpty => lines.isEmpty;

  /// The selected shipping cost across all delivery groups, or `null` when no
  /// option has been chosen yet.
  Money? get selectedShipping {
    var amount = 0.0;
    var currency = total.currencyCode;
    var found = false;
    for (final group in deliveryGroups) {
      final option = group.selectedOption;
      if (option == null) continue;
      found = true;
      amount += option.price.amount;
      currency = option.price.currencyCode;
    }
    return found ? Money(amount: amount, currencyCode: currency) : null;
  }

  /// Whether the cart has shipping options that still need a selection — i.e.
  /// some delivery group offers options but none is selected.
  bool get needsDeliverySelection => deliveryGroups.any(
    (g) => g.options.isNotEmpty && g.selectedOptionHandle == null,
  );

  /// Whether Shopify has returned any shipping options (address applied).
  bool get hasDeliveryOptions =>
      deliveryGroups.any((g) => g.options.isNotEmpty);
}
