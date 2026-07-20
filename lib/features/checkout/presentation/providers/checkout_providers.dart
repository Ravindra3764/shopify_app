import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/storage/address_storage.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart'
    show PromoOutcome, cartProvider, cartRepositoryProvider;
import 'package:shopify_app/features/checkout/data/checkout_repository_impl.dart';
import 'package:shopify_app/features/checkout/domain/checkout_repository.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_state.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/providers/storage_providers.dart';
import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// Checkout repository, wired to the Storefront `ApiClient` and the tenant's
/// market country (kept consistent with how the cart was created).
final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepositoryImpl(
    ref.watch(apiClientProvider),
    countryCode: ref.watch(appConfigProvider).defaultCountry,
  ),
);

/// The shopper's locally-saved delivery addresses, newest-first.
final addressBookProvider =
    NotifierProvider<AddressBookNotifier, List<MailingAddress>>(
      AddressBookNotifier.new,
    );

/// The in-progress checkout wizard state. `autoDispose` so leaving checkout
/// resets it — a new checkout always starts from the current cart.
final checkoutProvider =
    AsyncNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(
      CheckoutNotifier.new,
    );

/// Manages the persisted address book.
class AddressBookNotifier extends Notifier<List<MailingAddress>> {
  @override
  List<MailingAddress> build() => _storage.readAddresses();

  AddressStorage get _storage => ref.read(addressStorageProvider);

  /// Saves [address] (newest-first), replacing any entry with the same id.
  Future<void> add(MailingAddress address) async {
    final next = [
      address,
      for (final a in state)
        if (a.id != address.id) a,
    ];
    state = next;
    await _storage.writeAddresses(next);
  }

  /// Removes the address with [id].
  Future<void> remove(String id) async {
    final next = [
      for (final a in state)
        if (a.id != id) a,
    ];
    state = next;
    await _storage.writeAddresses(next);
  }
}

/// Drives the checkout wizard: applies the delivery address, selects a
/// shipping option, and advances through [CheckoutStep]s. Seeds from the
/// active cart; surfaces loading/error via `AsyncValue`.
class CheckoutNotifier extends AutoDisposeAsyncNotifier<CheckoutState> {
  @override
  Future<CheckoutState> build() async {
    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null || cart.isEmpty) {
      throw const ShopifyFailure('Your cart is empty.');
    }
    // Prefill the last-used email so the address step isn't blank.
    final email = ref.read(addressStorageProvider).readEmail();
    return CheckoutState(cart: cart, email: email);
  }

  CheckoutRepository get _repo => ref.read(checkoutRepositoryProvider);

  /// Attaches [email] + [address] to the cart, then advances to the shipping
  /// or review step depending on whether Shopify returned delivery options.
  Future<void> applyAddress({
    required String email,
    required MailingAddress address,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = const AsyncLoading<CheckoutState>().copyWithPrevious(state);
    final result = await _repo.updateBuyerAddress(
      current.cart.id,
      email: email,
      address: address,
      // Associate the order with the shopper's account when signed in.
      customerAccessToken: ref.read(authTokenProvider),
    );
    state = result.fold(
      (cart) {
        // Shopify zeroes the cart (lines → qty 0, cost → 0) when the address
        // is in a market the store doesn't sell/ship to — with no userError.
        // Surface it inline and stay on the address step.
        if (cart.isEmpty || cart.totalQuantity == 0) {
          return AsyncData(
            current.copyWith(
              email: email,
              selectedAddress: address,
              error:
                  "We can't deliver to this address. Please try a different "
                  'one.',
            ),
          );
        }
        unawaited(ref.read(addressStorageProvider).writeEmail(email));
        return AsyncData(
          current.copyWith(
            cart: cart,
            email: email,
            selectedAddress: address,
            step: _stepAfterAddress(cart),
            error: null,
          ),
        );
      },
      (failure) => AsyncError<CheckoutState>(
        failure,
        StackTrace.current,
      ).copyWithPrevious(state),
    );
  }

  /// Selects shipping option [optionHandle] for [deliveryGroupId], updating the
  /// cart with the shipping-inclusive total. Stays on the shipping step so the
  /// shopper can review the choice (or pick options for other groups) before
  /// continuing via [proceedToReview].
  Future<void> selectDelivery({
    required String deliveryGroupId,
    required String optionHandle,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = const AsyncLoading<CheckoutState>().copyWithPrevious(state);
    final result = await _repo.selectDeliveryOption(
      current.cart.id,
      deliveryGroupId: deliveryGroupId,
      optionHandle: optionHandle,
    );
    state = result.fold(
      (cart) => AsyncData(current.copyWith(cart: cart)),
      (failure) => AsyncError<CheckoutState>(
        failure,
        StackTrace.current,
      ).copyWithPrevious(state),
    );
  }

  /// Applies promo [code] to the checkout cart, merging with any already-
  /// applicable codes. Returns a [PromoOutcome] for the UI to message. Reuses
  /// the cart repository's discount mutation (same underlying Storefront cart).
  Future<PromoOutcome> applyPromoCode(String code) async {
    final current = state.valueOrNull;
    final normalized = code.trim();
    if (current == null || normalized.isEmpty) return PromoOutcome.error;

    final codes = <String>[
      for (final c in current.cart.discountCodes)
        if (c.applicable) c.code,
    ];
    if (!codes.any((c) => c.toLowerCase() == normalized.toLowerCase())) {
      codes.add(normalized);
    }

    final cart = await _applyDiscountCodes(current.cart.id, codes);
    if (cart == null) return PromoOutcome.error;

    final applicable = cart.discountCodes.any(
      (c) => c.code.toLowerCase() == normalized.toLowerCase() && c.applicable,
    );
    if (applicable) return PromoOutcome.applied;

    // Non-applicable — strip it back out so it doesn't linger on the cart.
    final valid = [
      for (final c in cart.discountCodes)
        if (c.applicable) c.code,
    ];
    await _applyDiscountCodes(current.cart.id, valid);
    return PromoOutcome.notApplicable;
  }

  /// Removes promo [code] from the checkout cart.
  Future<void> removePromoCode(String code) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final remaining = <String>[
      for (final c in current.cart.discountCodes)
        if (c.code.toLowerCase() != code.toLowerCase()) c.code,
    ];
    await _applyDiscountCodes(current.cart.id, remaining);
  }

  /// Sends [codes] to Shopify and folds the returned cart into the checkout
  /// state (preserving step/address/email). Returns the new cart, or `null` on
  /// failure (state set to error).
  Future<Cart?> _applyDiscountCodes(String cartId, List<String> codes) async {
    final current = state.valueOrNull;
    if (current == null) return null;
    state = const AsyncLoading<CheckoutState>().copyWithPrevious(state);
    final result = await ref
        .read(cartRepositoryProvider)
        .updateDiscountCodes(cartId, codes);
    return result.fold(
      (cart) {
        state = AsyncData(current.copyWith(cart: cart));
        return cart;
      },
      (failure) {
        state = AsyncError<CheckoutState>(
          failure,
          StackTrace.current,
        ).copyWithPrevious(state);
        return null;
      },
    );
  }

  /// Advances from the shipping step to the review step. No-op if a delivery
  /// selection is still outstanding.
  void proceedToReview() {
    final current = state.valueOrNull;
    if (current == null || current.cart.needsDeliverySelection) return;
    state = AsyncData(current.copyWith(step: CheckoutStep.review));
  }

  /// Steps the wizard back one stage. Returns `false` when already on the
  /// first step, so the caller can pop the route instead.
  bool back() {
    final current = state.valueOrNull;
    if (current == null) return false;
    final previous = switch (current.step) {
      CheckoutStep.address => null,
      CheckoutStep.delivery => CheckoutStep.address,
      CheckoutStep.review =>
        current.cart.hasDeliveryOptions
            ? CheckoutStep.delivery
            : CheckoutStep.address,
    };
    if (previous == null) return false;
    state = AsyncData(current.copyWith(step: previous));
    return true;
  }

  // Always stop on the shipping step when the address yields delivery options,
  // even though Shopify pre-selects a default rate — the shopper should see and
  // be able to change the shipping method rather than skip straight to review.
  CheckoutStep _stepAfterAddress(Cart cart) =>
      cart.hasDeliveryOptions ? CheckoutStep.delivery : CheckoutStep.review;
}
