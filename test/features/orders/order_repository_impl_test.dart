import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/features/orders/data/order_repository_impl.dart';

class MockApiClient extends Mock implements ApiClient {}

Map<String, dynamic> _money(String amount) => {
  'amount': amount,
  'currencyCode': 'USD',
};

void main() {
  late MockApiClient client;
  late OrderRepositoryImpl repo;

  setUp(() {
    client = MockApiClient();
    repo = OrderRepositoryImpl(client);
  });

  void stub(Map<String, dynamic> data) {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenAnswer((_) async => data);
  }

  test('maps a customer.orders connection to a page of orders', () async {
    stub({
      'customer': {
        'orders': {
          'pageInfo': {'hasNextPage': true, 'endCursor': 'cursor_1'},
          'edges': [
            {
              'node': {
                'id': 'gid://shopify/Order/1',
                'name': '#1001',
                'orderNumber': 1001,
                'processedAt': '2026-07-01T10:00:00Z',
                'financialStatus': 'PAID',
                'fulfillmentStatus': 'FULFILLED',
                'email': 'a@b.com',
                'totalPrice': _money('42.00'),
                'subtotalPrice': _money('40.00'),
                'totalShippingPrice': _money('2.00'),
                'totalTax': _money('0.00'),
                'shippingAddress': {
                  'firstName': 'Ada',
                  'lastName': 'Lovelace',
                  'address1': '1 Analytical Way',
                  'city': 'London',
                  'province': 'England',
                  'zip': 'EC1',
                  'country': 'United Kingdom',
                },
                'lineItems': {
                  'edges': [
                    {
                      'node': {
                        'title': 'Noir Trench',
                        'quantity': 2,
                        'originalTotalPrice': _money('40.00'),
                        'variant': {
                          'title': 'Large',
                          'image': {'url': 'https://cdn/x.jpg'},
                        },
                      },
                    },
                  ],
                },
              },
            },
          ],
        },
      },
    });

    final result = await repo.getOrders(token: 'tok');

    final page = result.fold((p) => p, (_) => null);
    expect(page, isNotNull);
    expect(page!.hasNextPage, isTrue);
    expect(page.endCursor, 'cursor_1');
    expect(page.orders, hasLength(1));

    final order = page.orders.first;
    expect(order.name, '#1001');
    expect(order.orderNumber, 1001);
    expect(order.fulfillmentLabel, 'Fulfilled');
    expect(order.financialLabel, 'Paid');
    expect(order.total.amount, 42.0);
    expect(order.itemCount, 2);
    expect(order.lines.single.title, 'Noir Trench');
    expect(order.lines.single.variantTitle, 'Large');
    expect(order.shippingAddress?.fullName, 'Ada Lovelace');
  });

  test('hides the "Default Title" variant label', () async {
    stub({
      'customer': {
        'orders': {
          'pageInfo': {'hasNextPage': false, 'endCursor': null},
          'edges': [
            {
              'node': {
                'id': '1',
                'name': '#1',
                'orderNumber': 1,
                'processedAt': '2026-07-01T10:00:00Z',
                'fulfillmentStatus': 'UNFULFILLED',
                'totalPrice': _money('10.00'),
                'lineItems': {
                  'edges': [
                    {
                      'node': {
                        'title': 'Sticker',
                        'quantity': 1,
                        'originalTotalPrice': _money('10.00'),
                        'variant': {'title': 'Default Title'},
                      },
                    },
                  ],
                },
              },
            },
          ],
        },
      },
    });

    final result = await repo.getOrders(token: 'tok');

    final order = result.fold((p) => p.orders.first, (_) => null);
    expect(order!.lines.single.variantTitle, isNull);
  });

  test('maps a null customer (invalid token) to an AuthFailure', () async {
    stub({'customer': null});

    final result = await repo.getOrders(token: 'bad');

    expect(result.fold((_) => null, (f) => f), isA<AuthFailure>());
  });

  test('maps a ShopifyException to a Failure', () async {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenThrow(const ShopifyException('boom'));

    final result = await repo.getOrders(token: 'tok');

    expect(result.fold((_) => null, (f) => f), isA<Failure>());
  });
}
