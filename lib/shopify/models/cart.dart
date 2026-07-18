import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/cart_discount_code.dart';
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
    this.discount,
    this.buyerEmail,
    this.deliveryGroups = const [],
    this.discountCodes = const [],
  });

  /// Builds from a Storefront `Cart` node.
  factory Cart.fromJson(Map<String, dynamic> json) {
    final cost = parseMap(json, 'cost', model: _model);
    final taxMap = parseMap(cost, 'totalTaxAmount', model: _model);
    final buyer = parseMap(json, 'buyerIdentity', model: _model);
    final total = Money.fromJson(parseMap(cost, 'totalAmount', model: _model));

    // Sum of all order-level code discounts applied to the cart.
    final discountAmount = parseList<double>(
      json,
      'discountAllocations',
      model: _model,
      fromItem: (item) {
        final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
        final amount = parseMap(map, 'discountedAmount', model: _model);
        return amount.isEmpty
            ? 0.0
            : parseDouble(amount, 'amount', model: _model);
      },
    ).fold<double>(0, (sum, amount) => sum + amount);

    return Cart(
      id: parseString(json, 'id', model: _model),
      checkoutUrl: parseString(json, 'checkoutUrl', model: _model),
      totalQuantity: parseInt(json, 'totalQuantity', model: _model),
      subtotal: Money.fromJson(parseMap(cost, 'subtotalAmount', model: _model)),
      total: total,
      // Tax is null until an address is known (guest cart, pre-checkout).
      tax: taxMap.isEmpty ? null : Money.fromJson(taxMap),
      discount: discountAmount > 0
          ? Money(amount: discountAmount, currencyCode: total.currencyCode)
          : null,
      discountCodes: parseList<CartDiscountCode>(
        json,
        'discountCodes',
        model: _model,
        fromItem: (item) => CartDiscountCode.fromJson(
          item is Map<String, dynamic> ? item : <String, dynamic>{},
        ),
      ),
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
      discount: discount,
      buyerEmail: buyerEmail,
      deliveryGroups: deliveryGroups,
      discountCodes: discountCodes,
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

  /// Total order-level discount from applied promo codes; `null` when no
  /// applicable code reduces the cart.
  final Money? discount;

  /// Discount codes attached to the cart, each flagged
  /// [CartDiscountCode.applicable].
  final List<CartDiscountCode> discountCodes;

  /// Buyer email attached via `cartBuyerIdentityUpdate`; `null` for a fresh
  /// guest cart.
  final String? buyerEmail;

  /// Shipping option groups; empty until a delivery address is applied.
  final List<DeliveryGroup> deliveryGroups;
  final List<CartLine> lines;

  /// Whether the cart holds no lines.
  bool get isEmpty => lines.isEmpty;

  /// Codes that are actually reducing the total (Shopify accepted + applied).
  List<CartDiscountCode> get appliedDiscountCodes => [
    for (final c in discountCodes)
      if (c.applicable) c,
  ];

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
