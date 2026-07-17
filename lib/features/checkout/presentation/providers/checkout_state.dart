import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// The stage the checkout wizard is currently on.
enum CheckoutStep {
  /// Collecting / selecting the delivery address + email.
  address,

  /// Choosing a shipping option from the cart's delivery groups.
  delivery,

  /// Final review of amounts before payment.
  review,
}

/// Immutable snapshot of the in-progress checkout.
///
/// Holds the working [cart] (updated as address/shipping are applied) plus the
/// shopper's selections. Rebuilt via [copyWith] — never mutated in place.
class CheckoutState {
  const CheckoutState({
    required this.cart,
    this.step = CheckoutStep.address,
    this.email,
    this.selectedAddress,
    this.error,
  });

  /// The live checkout cart, reflecting the latest Storefront response.
  final Cart cart;

  /// Which wizard step is active.
  final CheckoutStep step;

  /// Buyer email applied to the cart, or `null` before the address step.
  final String? email;

  /// The delivery address applied to the cart, or `null` before it's set.
  final MailingAddress? selectedAddress;

  /// A recoverable, step-local message (e.g. an unserviceable address) shown
  /// inline without tearing down the wizard. `null` when there's nothing wrong.
  final String? error;

  CheckoutState copyWith({
    Cart? cart,
    CheckoutStep? step,
    String? email,
    MailingAddress? selectedAddress,
    // Sentinel default so `error: null` can explicitly clear the message.
    Object? error = _unset,
  }) => CheckoutState(
    cart: cart ?? this.cart,
    step: step ?? this.step,
    email: email ?? this.email,
    selectedAddress: selectedAddress ?? this.selectedAddress,
    error: identical(error, _unset) ? this.error : error as String?,
  );

  static const Object _unset = Object();
}
