import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/cart/domain/cart_repository.dart';
import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/mutations/cart_mutations.dart';
import 'package:shopify_app/shopify/queries/cart_queries.dart';

/// [CartRepository] backed by the Shopify Storefront Cart API.
class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._client, {required this.countryCode});

  final ApiClient _client;

  /// Tenant market country (ISO code) that pins cart pricing/availability.
  final String countryCode;

  static const _model = 'CartRepository';

  @override
  Future<Result<Cart, Failure>> createCart(
    String variantId,
    int quantity,
  ) async {
    try {
      final data = await _client.query(
        kCartCreateMutation,
        variables: {
          'lines': _lineInputs(variantId, quantity),
          'countryCode': countryCode,
        },
      );
      return _parsePayload(data, 'cartCreate');
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<Cart, Failure>> getCart(String cartId) async {
    try {
      final data = await _client.query(
        kGetCartQuery,
        variables: {'cartId': cartId},
      );
      final cartMap = parseMap(data, 'cart', model: _model);
      if (cartMap.isEmpty) {
        // Shopify returns `cart: null` when the ID is expired/invalid.
        return const Failed(
          ShopifyFailure('This cart is no longer available.'),
        );
      }
      return Success(Cart.fromJson(cartMap));
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<Cart, Failure>> addLine(
    String cartId,
    String variantId,
    int quantity,
  ) async {
    try {
      final data = await _client.query(
        kCartLinesAddMutation,
        variables: {
          'cartId': cartId,
          'lines': _lineInputs(variantId, quantity),
        },
      );
      return _parsePayload(data, 'cartLinesAdd');
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<Cart, Failure>> updateLine(
    String cartId,
    String lineId,
    int quantity,
  ) async {
    try {
      final data = await _client.query(
        kCartLinesUpdateMutation,
        variables: {
          'cartId': cartId,
          'lines': [
            {'id': lineId, 'quantity': quantity},
          ],
        },
      );
      return _parsePayload(data, 'cartLinesUpdate');
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<Cart, Failure>> removeLine(String cartId, String lineId) async {
    try {
      final data = await _client.query(
        kCartLinesRemoveMutation,
        variables: {
          'cartId': cartId,
          'lineIds': [lineId],
        },
      );
      return _parsePayload(data, 'cartLinesRemove');
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  List<Map<String, dynamic>> _lineInputs(String variantId, int quantity) => [
    {'merchandiseId': variantId, 'quantity': quantity},
  ];

  /// Reads a cart mutation payload ([field] → `{cart, userErrors}`), turning a
  /// non-empty `userErrors` array into a [ShopifyFailure].
  Result<Cart, Failure> _parsePayload(Map<String, dynamic> data, String field) {
    final payload = parseMap(data, field, model: _model);
    final errors = parseList<String>(
      payload,
      'userErrors',
      model: _model,
      fromItem: (item) => item is Map<String, dynamic>
          ? parseString(item, 'message', model: _model)
          : '',
    ).where((message) => message.isNotEmpty).toList();
    if (errors.isNotEmpty) {
      return Failed(ShopifyFailure(errors.join(', ')));
    }
    return Success(Cart.fromJson(parseMap(payload, 'cart', model: _model)));
  }
}
