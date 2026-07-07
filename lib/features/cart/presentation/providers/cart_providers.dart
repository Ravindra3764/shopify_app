import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/cart/data/cart_repository_impl.dart';
import 'package:shopify_app/features/cart/domain/cart_repository.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/cart.dart';

/// Cart repository, wired to the Storefront `ApiClient`.
final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The active guest cart, or `null` when nothing has been added yet.
final cartProvider = AsyncNotifierProvider<CartNotifier, Cart?>(
  CartNotifier.new,
);

/// Total item count in the cart — drives cart-icon badges. `0` when empty.
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).valueOrNull?.totalQuantity ?? 0,
);

/// Holds the guest cart and drives its mutations.
///
/// The `cartId` lives only in memory for the session (`ref.keepAlive` keeps
/// the notifier alive across screen changes); it is *not* persisted yet, so a
/// full restart starts an empty cart. Persisting it is a follow-up. The cart
/// is created lazily on the first [addVariant], so there's nothing to fetch
/// on startup.
class CartNotifier extends AsyncNotifier<Cart?> {
  String? _cartId;

  @override
  Future<Cart?> build() async {
    ref.keepAlive();
    return null;
  }

  CartRepository get _repo => ref.read(cartRepositoryProvider);

  /// Adds [quantity] of [variantId], creating the cart on first use.
  Future<void> addVariant(String variantId, {int quantity = 1}) {
    return _mutate(() {
      final id = _cartId;
      return id == null
          ? _repo.createCart(variantId, quantity)
          : _repo.addLine(id, variantId, quantity);
    });
  }

  /// Sets the quantity of [lineId]; removes the line when [quantity] hits 0.
  Future<void> setLineQuantity(String lineId, int quantity) {
    final id = _cartId;
    if (id == null) return Future<void>.value();
    if (quantity <= 0) return removeLine(lineId);
    return _mutate(() => _repo.updateLine(id, lineId, quantity));
  }

  /// Removes [lineId] from the cart.
  Future<void> removeLine(String lineId) {
    final id = _cartId;
    if (id == null) return Future<void>.value();
    return _mutate(() => _repo.removeLine(id, lineId));
  }

  /// Runs a mutation, keeping the previous cart visible while it's in flight
  /// and storing the returned cart ID on success.
  Future<void> _mutate(Future<Result<Cart, Failure>> Function() op) async {
    state = const AsyncValue<Cart?>.loading().copyWithPrevious(state);
    final result = await op();
    state = result.fold((cart) {
      _cartId = cart.id;
      return AsyncData<Cart?>(cart);
    }, (failure) => AsyncError<Cart?>(failure, StackTrace.current));
  }
}
