import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/checkout/domain/checkout_repository.dart';
import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';
import 'package:shopify_app/shopify/mutations/checkout_mutations.dart';

/// [CheckoutRepository] backed by the Shopify Storefront Cart API.
class CheckoutRepositoryImpl implements CheckoutRepository {
  const CheckoutRepositoryImpl(this._client);

  final ApiClient _client;

  static const _model = 'CheckoutRepository';

  @override
  Future<Result<Cart, Failure>> updateBuyerAddress(
    String cartId, {
    required String email,
    required MailingAddress address,
  }) async {
    try {
      final data = await _client.query(
        kCartBuyerIdentityUpdateMutation,
        variables: {
          'cartId': cartId,
          'buyerIdentity': {
            'email': email,
            // Deliberately NOT sending `countryCode`: it switches the cart to
            // that Shopify Market, and if the store doesn't sell there the
            // whole cart zeroes out (cost + line quantities → 0) with no
            // userError. The delivery address below still drives shipping.
            'deliveryAddressPreferences': [
              {'deliveryAddress': address.toInput()},
            ],
          },
        },
      );
      return _parsePayload(data, 'cartBuyerIdentityUpdate');
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<Cart, Failure>> selectDeliveryOption(
    String cartId, {
    required String deliveryGroupId,
    required String optionHandle,
  }) async {
    try {
      final data = await _client.query(
        kCartSelectedDeliveryOptionsUpdateMutation,
        variables: {
          'cartId': cartId,
          'selectedDeliveryOptions': [
            {
              'deliveryGroupId': deliveryGroupId,
              'deliveryOptionHandle': optionHandle,
            },
          ],
        },
      );
      return _parsePayload(data, 'cartSelectedDeliveryOptionsUpdate');
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

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
