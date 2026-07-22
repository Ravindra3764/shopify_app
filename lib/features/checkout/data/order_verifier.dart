import 'package:shopify_app/features/orders/domain/order_repository.dart';
import 'package:shopify_app/shopify/models/order.dart';

/// Confirms a just-placed order server-side by polling `customer.orders`.
///
/// Shopify's guest Cart API returns no order object after the hosted checkout
/// completes, so — for a signed-in shopper — the only trustworthy proof of a
/// paid order is that a new order appears on their account. This polls for one
/// that wasn't there before payment.
///
/// Comparing order *ids* (not timestamps) makes detection immune to device /
/// server clock skew: we snapshot the newest order id before payment, then wait
/// for a different newest id to show up.
class OrderVerifier {
  const OrderVerifier(this._repo, this._token);

  final OrderRepository _repo;
  final String? _token;

  /// Whether verification is possible (a customer is signed in).
  bool get canVerify => _token != null;

  /// The id of the customer's most recent order, or `null` if they have none
  /// (or aren't signed in). Call before payment to snapshot the baseline.
  Future<String?> latestOrderId() async {
    final token = _token;
    if (token == null) return null;
    final result = await _repo.getOrders(token: token, first: 1);
    return result.fold(
      (page) => page.orders.isEmpty ? null : page.orders.first.id,
      (_) => null,
    );
  }

  /// Polls for an order newer than [previousLatestOrderId] (the baseline from
  /// [latestOrderId]). Returns the new [Order] once it appears, or `null` if
  /// none shows up within the retry budget or the shopper is a guest.
  Future<Order?> awaitNewOrder({
    required String? previousLatestOrderId,
    int attempts = 6,
    Duration interval = const Duration(seconds: 2),
  }) async {
    final token = _token;
    if (token == null) return null;

    for (var attempt = 0; attempt < attempts; attempt++) {
      final result = await _repo.getOrders(token: token, first: 1);
      final newest = result.fold(
        (page) => page.orders.isEmpty ? null : page.orders.first,
        (_) => null,
      );
      if (newest != null && newest.id != previousLatestOrderId) {
        return newest;
      }
      if (attempt < attempts - 1) {
        await Future<void>.delayed(interval);
      }
    }
    return null;
  }
}
