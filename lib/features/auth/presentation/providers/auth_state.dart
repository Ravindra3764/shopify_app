import 'package:shopify_app/shopify/models/customer.dart';

/// The customer session. [Unauthenticated] before sign-in (or after logout);
/// [Authenticated] once a valid token + customer are held.
sealed class AuthState {
  const AuthState();
}

/// No active session — the shopper is browsing as a guest.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// An active session: the signed-in [customer] and their access [token].
final class Authenticated extends AuthState {
  const Authenticated({required this.customer, required this.token});

  final Customer customer;
  final String token;
}
