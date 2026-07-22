import 'package:shopify_app/shopify/models/order.dart';

/// One page of a customer's order history, plus the cursor to fetch the next.
class OrderPage {
  const OrderPage({
    required this.orders,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<Order> orders;
  final bool hasNextPage;
  final String? endCursor;
}
