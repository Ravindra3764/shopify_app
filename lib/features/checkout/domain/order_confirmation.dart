import 'package:shopify_app/shopify/models/cart_line.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';
import 'package:shopify_app/shopify/models/money.dart';

/// A snapshot of a just-placed order, captured from the checkout cart before
/// it's cleared, so the confirmation screen can show what was purchased.
///
/// Not a Storefront type — the guest Cart API doesn't return an order object
/// after the hosted checkout completes, so we surface the cart contents the
/// shopper paid for instead.
class OrderConfirmation {
  const OrderConfirmation({
    required this.lines,
    required this.subtotal,
    required this.total,
    this.email,
    this.address,
    this.shipping,
    this.tax,
    this.orderName,
  });

  final List<CartLine> lines;
  final Money subtotal;
  final Money total;
  final String? email;
  final MailingAddress? address;
  final Money? shipping;
  final Money? tax;

  /// The verified Shopify order name (e.g. `#1002`) when the order was
  /// confirmed server-side by polling `customer.orders`, or `null` when the
  /// confirmation is the cart snapshot alone (e.g. a guest checkout).
  final String? orderName;

  /// Whether this confirmation was verified against a real placed order.
  bool get isVerified => orderName != null;

  /// Total number of items ordered.
  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  OrderConfirmation copyWith({String? orderName}) => OrderConfirmation(
    lines: lines,
    subtotal: subtotal,
    total: total,
    email: email,
    address: address,
    shipping: shipping,
    tax: tax,
    orderName: orderName ?? this.orderName,
  );
}
