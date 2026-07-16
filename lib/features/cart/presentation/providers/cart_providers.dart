import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/cart/data/cart_repository_impl.dart';
import 'package:shopify_app/features/cart/domain/cart_repository.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/models/money.dart';

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

  /// Last cart returned by Shopify — the truth we snap back to if a debounced
  /// quantity sync fails after an optimistic edit.
  Cart? _serverCart;

  /// Per-line debounce timers and their pending target quantities. A burst of
  /// stepper taps updates state optimistically each time but collapses into a
  /// single [_flushQuantity] once the taps stop.
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, int> _pendingQuantities = {};

  /// Idle window after the last stepper tap before the quantity is sent.
  static const _stepperDebounce = Duration(milliseconds: 400);

  @override
  Future<Cart?> build() async {
    ref
      ..keepAlive()
      ..onDispose(_cancelDebounces);
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
  ///
  /// Applies the new quantity to local state immediately so the stepper reacts
  /// without waiting on the network, then debounces the Storefront write: a
  /// burst of taps sends only the final quantity once, [_stepperDebounce]
  /// after the last tap.
  void setLineQuantity(String lineId, int quantity) {
    final id = _cartId;
    if (id == null) return;
    if (quantity <= 0) {
      _debounceTimers.remove(lineId)?.cancel();
      _pendingQuantities.remove(lineId);
      unawaited(removeLine(lineId));
      return;
    }
    _applyOptimisticQuantity(lineId, quantity);
    _pendingQuantities[lineId] = quantity;
    _debounceTimers[lineId]?.cancel();
    _debounceTimers[lineId] = Timer(
      _stepperDebounce,
      () => unawaited(_flushQuantity(id, lineId)),
    );
  }

  /// Sends the latest pending quantity for [lineId] to Shopify and reconciles.
  /// Skips reconciliation if a newer tap has since queued a different target —
  /// that tap's own flush becomes the source of truth instead.
  Future<void> _flushQuantity(String cartId, String lineId) async {
    _debounceTimers.remove(lineId);
    final target = _pendingQuantities[lineId];
    if (target == null) return;

    final result = await _repo.updateLine(cartId, lineId, target);

    // A tap landed while this request was in flight; let its flush win.
    if (_pendingQuantities[lineId] != target) return;
    _pendingQuantities.remove(lineId);

    state = result.fold(
      (cart) {
        _cartId = cart.id;
        _serverCart = cart;
        return AsyncData<Cart?>(cart);
      },
      (failure) {
        // Sync failed — snap the optimistic value back to server truth.
        final reverted = _serverCart;
        return reverted == null
            ? AsyncError<Cart?>(failure, StackTrace.current)
            : AsyncData<Cart?>(reverted);
      },
    );
  }

  void _cancelDebounces() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pendingQuantities.clear();
  }

  /// Rewrites [lineId]'s quantity (and line total) in the current cart and
  /// publishes it, so the UI updates ahead of the Storefront round-trip.
  void _applyOptimisticQuantity(String lineId, int quantity) {
    final current = state.valueOrNull;
    if (current == null) return;
    final lines = [
      for (final line in current.lines)
        if (line.id == lineId)
          line.copyWith(
            quantity: quantity,
            lineTotal: Money(
              amount: line.unitPrice.amount * quantity,
              currencyCode: line.unitPrice.currencyCode,
            ),
          )
        else
          line,
    ];
    state = AsyncData<Cart?>(current.withLines(lines));
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
      _serverCart = cart;
      return AsyncData<Cart?>(cart);
    }, (failure) => AsyncError<Cart?>(failure, StackTrace.current));
  }
}
