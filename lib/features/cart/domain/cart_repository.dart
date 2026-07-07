import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/cart.dart';

/// Guest cart operations backed by the Storefront Cart API.
///
/// No customer token is involved — carts are anonymous and identified by the
/// [Cart.id] returned from [createCart], which the caller replays on every
/// subsequent mutation.
abstract interface class CartRepository {
  /// Creates a new cart seeded with [quantity] of [variantId].
  Future<Result<Cart, Failure>> createCart(String variantId, int quantity);

  /// Fetches the current state of the cart identified by [cartId].
  Future<Result<Cart, Failure>> getCart(String cartId);

  /// Adds [quantity] of [variantId] to the cart [cartId].
  Future<Result<Cart, Failure>> addLine(
    String cartId,
    String variantId,
    int quantity,
  );

  /// Sets the [quantity] of the line [lineId] in cart [cartId].
  Future<Result<Cart, Failure>> updateLine(
    String cartId,
    String lineId,
    int quantity,
  );

  /// Removes the line [lineId] from cart [cartId].
  Future<Result<Cart, Failure>> removeLine(String cartId, String lineId);
}
