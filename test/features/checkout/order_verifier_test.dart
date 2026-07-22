import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/checkout/data/order_verifier.dart';
import 'package:shopify_app/features/orders/domain/order_page.dart';
import 'package:shopify_app/features/orders/domain/order_repository.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/order.dart';

/// Returns a scripted sequence of results, one per `getOrders` call.
class _ScriptedOrderRepository implements OrderRepository {
  _ScriptedOrderRepository(this._results);

  final List<Result<OrderPage, Failure>> _results;
  int calls = 0;

  @override
  Future<Result<OrderPage, Failure>> getOrders({
    required String token,
    int first = 20,
    String? after,
  }) async {
    final index = calls < _results.length ? calls : _results.length - 1;
    calls++;
    return _results[index];
  }
}

Order _order(String id) => Order(
  id: id,
  name: '#$id',
  orderNumber: 1,
  processedAt: DateTime(2026, 7),
  fulfillmentStatus: 'UNFULFILLED',
  total: const Money(amount: 10, currencyCode: 'USD'),
  lines: const [],
);

Result<OrderPage, Failure> _page(List<Order> orders) =>
    Success(OrderPage(orders: orders, hasNextPage: false));

void main() {
  const noWait = Duration.zero;

  group('canVerify', () {
    test('false when signed out', () {
      final verifier = OrderVerifier(_ScriptedOrderRepository([]), null);
      expect(verifier.canVerify, isFalse);
    });

    test('true when a token is present', () {
      final verifier = OrderVerifier(_ScriptedOrderRepository([]), 'tok');
      expect(verifier.canVerify, isTrue);
    });
  });

  group('latestOrderId', () {
    test('returns the newest order id', () async {
      final repo = _ScriptedOrderRepository([
        _page([_order('100')]),
      ]);
      final verifier = OrderVerifier(repo, 'tok');

      expect(await verifier.latestOrderId(), '100');
    });

    test('returns null when there are no orders', () async {
      final repo = _ScriptedOrderRepository([_page([])]);
      final verifier = OrderVerifier(repo, 'tok');

      expect(await verifier.latestOrderId(), isNull);
    });
  });

  group('awaitNewOrder', () {
    test('returns the new order once a different newest id appears', () async {
      final repo = _ScriptedOrderRepository([
        _page([_order('100')]), // still the old newest
        _page([_order('101')]), // the new order shows up
      ]);
      final verifier = OrderVerifier(repo, 'tok');

      final order = await verifier.awaitNewOrder(
        previousLatestOrderId: '100',
        interval: noWait,
      );

      expect(order, isNotNull);
      expect(order!.id, '101');
      expect(repo.calls, 2);
    });

    test('detects the first order for a customer who had none', () async {
      final repo = _ScriptedOrderRepository([
        _page([_order('1')]),
      ]);
      final verifier = OrderVerifier(repo, 'tok');

      final order = await verifier.awaitNewOrder(
        previousLatestOrderId: null,
        interval: noWait,
      );

      expect(order!.id, '1');
    });

    test('returns null when no new order appears within the budget', () async {
      final repo = _ScriptedOrderRepository([
        _page([_order('100')]),
      ]);
      final verifier = OrderVerifier(repo, 'tok');

      final order = await verifier.awaitNewOrder(
        previousLatestOrderId: '100',
        attempts: 3,
        interval: noWait,
      );

      expect(order, isNull);
      expect(repo.calls, 3);
    });

    test('returns null for a guest without polling', () async {
      final repo = _ScriptedOrderRepository([]);
      final verifier = OrderVerifier(repo, null);

      final order = await verifier.awaitNewOrder(
        previousLatestOrderId: null,
        interval: noWait,
      );

      expect(order, isNull);
      expect(repo.calls, 0);
    });
  });
}
