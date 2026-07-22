import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/orders/domain/order_page.dart';
import 'package:shopify_app/features/orders/domain/order_repository.dart';
import 'package:shopify_app/shopify/models/order.dart';
import 'package:shopify_app/shopify/queries/orders_queries.dart';

/// [OrderRepository] backed by the Shopify Storefront API.
class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._client);

  final ApiClient _client;

  static const _model = 'OrderRepository';

  @override
  Future<Result<OrderPage, Failure>> getOrders({
    required String token,
    int first = 20,
    String? after,
  }) async {
    try {
      final data = await _client.query(
        kCustomerOrdersQuery,
        variables: {'token': token, 'first': first, 'after': after},
      );
      final customer = parseMap(data, 'customer', model: _model);
      if (customer.isEmpty) {
        // A null customer means the token is invalid/expired.
        return const Failed(AuthFailure('Your session has expired.'));
      }
      final connection = parseMap(customer, 'orders', model: _model);
      final orders = parseList<Order>(
        connection,
        'edges',
        model: _model,
        fromItem: (edge) => Order.fromJson(
          parseMap(
            edge is Map<String, dynamic> ? edge : const {},
            'node',
            model: _model,
          ),
        ),
      );
      final pageInfo = parseMap(connection, 'pageInfo', model: _model);
      return Success(
        OrderPage(
          orders: orders,
          hasNextPage: parseBool(pageInfo, 'hasNextPage', model: _model),
          endCursor: parseStringOrNull(pageInfo, 'endCursor', model: _model),
        ),
      );
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }
}
