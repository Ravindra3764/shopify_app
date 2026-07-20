import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// Checkout operations layered on top of the Storefront Cart API.
///
/// These attach buyer/delivery details to the same cart identified by
/// [Cart.id]. When a shopper is signed in, their customer access token is
/// attached so the resulting order associates with their account; guests pass
/// `null`. Each returns the updated [Cart] (with recomputed cost +
/// `deliveryGroups`).
abstract interface class CheckoutRepository {
  /// Attaches [email] and [address] to cart [cartId] — plus the signed-in
  /// shopper's [customerAccessToken] when present. Shopify then computes tax
  /// and populates shipping options in `deliveryGroups`.
  Future<Result<Cart, Failure>> updateBuyerAddress(
    String cartId, {
    required String email,
    required MailingAddress address,
    String? customerAccessToken,
  });

  /// Selects shipping option [optionHandle] for delivery group
  /// [deliveryGroupId] in cart [cartId]. The returned cart total includes the
  /// chosen shipping.
  Future<Result<Cart, Failure>> selectDeliveryOption(
    String cartId, {
    required String deliveryGroupId,
    required String optionHandle,
  });
}
