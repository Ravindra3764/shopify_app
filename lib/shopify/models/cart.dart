import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/cart_line.dart';
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
  });

  /// Builds from a Storefront `Cart` node.
  factory Cart.fromJson(Map<String, dynamic> json) {
    final cost = parseMap(json, 'cost', model: _model);
    final taxMap = parseMap(cost, 'totalTaxAmount', model: _model);

    return Cart(
      id: parseString(json, 'id', model: _model),
      checkoutUrl: parseString(json, 'checkoutUrl', model: _model),
      totalQuantity: parseInt(json, 'totalQuantity', model: _model),
      subtotal: Money.fromJson(parseMap(cost, 'subtotalAmount', model: _model)),
      total: Money.fromJson(parseMap(cost, 'totalAmount', model: _model)),
      // Tax is null until an address is known (guest cart, pre-checkout).
      tax: taxMap.isEmpty ? null : Money.fromJson(taxMap),
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
      ),
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
  final List<CartLine> lines;

  /// Whether the cart holds no lines.
  bool get isEmpty => lines.isEmpty;
}
