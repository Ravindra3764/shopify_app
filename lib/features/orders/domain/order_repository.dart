import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/orders/domain/order_page.dart';

/// Reads the signed-in customer's order history from the Storefront API.
// ignore: one_member_abstracts
abstract interface class OrderRepository {
  /// Fetches a page of orders for the customer identified by [token],
  /// newest first. Pass [after] (a cursor) to page forward.
  Future<Result<OrderPage, Failure>> getOrders({
    required String token,
    int first,
    String? after,
  });
}
