import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/orders/domain/order_page.dart';
import 'package:shopify_app/features/orders/domain/order_repository.dart';
import 'package:shopify_app/features/orders/presentation/providers/orders_providers.dart';
import 'package:shopify_app/features/reviews/presentation/providers/purchased_products_provider.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/order.dart';
import 'package:shopify_app/shopify/models/order_line.dart';

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository(this._pages);

  final List<OrderPage> _pages;
  int _call = 0;

  @override
  Future<Result<OrderPage, Failure>> getOrders({
    required String token,
    int first = 20,
    String? after,
  }) async {
    final page = _pages[_call.clamp(0, _pages.length - 1)];
    _call++;
    return Success(page);
  }
}

Order _order(List<String?> productIds) => Order(
  id: 'o1',
  name: '#1',
  orderNumber: 1,
  processedAt: DateTime(2026, 7),
  fulfillmentStatus: 'FULFILLED',
  total: const Money(amount: 10, currencyCode: 'USD'),
  lines: [
    for (final id in productIds)
      OrderLine(
        title: 'Item',
        quantity: 1,
        lineTotal: const Money(amount: 10, currencyCode: 'USD'),
        productId: id,
      ),
  ],
);

void main() {
  ProviderContainer makeContainer({
    required String? token,
    required List<OrderPage> pages,
  }) {
    final container = ProviderContainer(
      overrides: [
        authTokenProvider.overrideWithValue(token),
        orderRepositoryProvider.overrideWithValue(_FakeOrderRepository(pages)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('collects purchased product ids across pages', () async {
    final container = makeContainer(
      token: 'tok',
      pages: [
        OrderPage(
          orders: [
            _order(['gid://shopify/Product/1', null]),
          ],
          hasNextPage: true,
          endCursor: 'c1',
        ),
        OrderPage(
          orders: [
            _order(['gid://shopify/Product/2']),
          ],
          hasNextPage: false,
        ),
      ],
    );

    final ids = await container.read(purchasedProductIdsProvider.future);

    expect(ids, {'gid://shopify/Product/1', 'gid://shopify/Product/2'});
  });

  test('returns empty when signed out', () async {
    final container = makeContainer(token: null, pages: const []);

    final ids = await container.read(purchasedProductIdsProvider.future);

    expect(ids, isEmpty);
  });
}
