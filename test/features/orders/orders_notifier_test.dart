import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/orders/domain/order_page.dart';
import 'package:shopify_app/features/orders/domain/order_repository.dart';
import 'package:shopify_app/features/orders/presentation/providers/orders_providers.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/order.dart';

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository(this._page);

  final OrderPage _page;

  @override
  Future<Result<OrderPage, Failure>> getOrders({
    required String token,
    int first = 20,
    String? after,
  }) async => Success(_page);
}

Order _order(String name) => Order(
  id: name,
  name: name,
  orderNumber: 1,
  processedAt: DateTime(2026, 7),
  fulfillmentStatus: 'FULFILLED',
  total: const Money(amount: 10, currencyCode: 'USD'),
  lines: const [],
);

void main() {
  ProviderContainer makeContainer({required String? token, OrderPage? page}) {
    final container = ProviderContainer(
      overrides: [
        authTokenProvider.overrideWithValue(token),
        orderRepositoryProvider.overrideWithValue(
          _FakeOrderRepository(
            page ?? OrderPage(orders: [_order('#1001')], hasNextPage: false),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loads orders into data when signed in', () async {
    final container = makeContainer(token: 'tok');

    final state = await container.read(ordersProvider.future);

    expect(state.orders, hasLength(1));
    expect(state.orders.first.name, '#1001');
    expect(state.hasMore, isFalse);
  });

  test('errors with an AuthFailure when signed out', () async {
    final container = makeContainer(token: null);

    await expectLater(
      container.read(ordersProvider.future),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('exposes hasMore from the page', () async {
    final container = makeContainer(
      token: 'tok',
      page: OrderPage(
        orders: [_order('#1001')],
        hasNextPage: true,
        endCursor: 'c1',
      ),
    );

    final state = await container.read(ordersProvider.future);

    expect(state.hasMore, isTrue);
  });
}
