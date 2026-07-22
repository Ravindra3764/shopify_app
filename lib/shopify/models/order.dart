import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/order_line.dart';

/// A placed customer order, mapped from a Storefront `Order` node.
///
/// Carries enough for both the history list (name, date, status, total) and
/// the detail view (lines, price breakdown, shipping address), so the detail
/// screen renders from an already-loaded [Order] without a second fetch.
class Order {
  const Order({
    required this.id,
    required this.name,
    required this.orderNumber,
    required this.processedAt,
    required this.fulfillmentStatus,
    required this.total,
    required this.lines,
    this.financialStatus,
    this.email,
    this.subtotal,
    this.shipping,
    this.tax,
    this.shippingAddress,
  });

  /// Builds from a Storefront `Order` node.
  factory Order.fromJson(Map<String, dynamic> json) {
    final address = parseMap(json, 'shippingAddress', model: _model);
    return Order(
      id: parseString(json, 'id', model: _model),
      name: parseString(json, 'name', model: _model),
      orderNumber: parseInt(json, 'orderNumber', model: _model),
      processedAt: parseDateTime(json, 'processedAt', model: _model),
      fulfillmentStatus: parseString(
        json,
        'fulfillmentStatus',
        fallback: 'UNFULFILLED',
        model: _model,
      ),
      financialStatus: parseStringOrNull(
        json,
        'financialStatus',
        model: _model,
      ),
      total: Money.fromJson(parseMap(json, 'totalPrice', model: _model)),
      subtotal: _moneyOrNull(json, 'subtotalPrice'),
      shipping: _moneyOrNull(json, 'totalShippingPrice'),
      tax: _moneyOrNull(json, 'totalTax'),
      email: parseStringOrNull(json, 'email', model: _model),
      shippingAddress: address.isEmpty
          ? null
          : MailingAddress.fromJson(address),
      lines: _parseLines(json),
    );
  }

  static const _model = 'Order';

  final String id;

  /// Merchant-facing order name, e.g. `#1001`.
  final String name;
  final int orderNumber;
  final DateTime processedAt;

  /// Raw Storefront fulfillment status (e.g. `FULFILLED`, `UNFULFILLED`).
  final String fulfillmentStatus;

  /// Raw Storefront financial status (e.g. `PAID`), or `null` if unavailable.
  final String? financialStatus;

  final Money total;
  final Money? subtotal;
  final Money? shipping;
  final Money? tax;
  final String? email;
  final MailingAddress? shippingAddress;
  final List<OrderLine> lines;

  /// Total number of items across all lines.
  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  /// Human-readable fulfillment status, e.g. `Partially fulfilled`.
  String get fulfillmentLabel => _humanize(fulfillmentStatus);

  /// Human-readable financial status, or `null` when unknown.
  String? get financialLabel {
    final status = financialStatus;
    return status == null ? null : _humanize(status);
  }

  /// Turns a SCREAMING_SNAKE status into `Sentence case`.
  static String _humanize(String status) {
    final words = status.toLowerCase().split('_').where((w) => w.isNotEmpty);
    if (words.isEmpty) return status;
    final joined = words.join(' ');
    return joined[0].toUpperCase() + joined.substring(1);
  }

  static Money? _moneyOrNull(Map<String, dynamic> json, String field) {
    final node = parseMap(json, field, model: _model);
    return node.isEmpty ? null : Money.fromJson(node);
  }

  static List<OrderLine> _parseLines(Map<String, dynamic> json) {
    final connection = parseMap(json, 'lineItems', model: _model);
    return parseList<OrderLine>(
      connection,
      'edges',
      model: _model,
      fromItem: (edge) => OrderLine.fromJson(
        parseMap(
          edge is Map<String, dynamic> ? edge : const {},
          'node',
          model: _model,
        ),
      ),
    );
  }
}
