import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/customer.dart';
import 'package:shopify_app/shopify/models/customer_access_token.dart';

/// Storefront classic customer authentication.
///
/// Every method returns a [Result] and never throws across the boundary;
/// `customerUserErrors` become an [AuthFailure], transport problems a
/// [NetworkFailure]/[ShopifyFailure] via [Failure.fromShopify].
abstract interface class AuthRepository {
  /// Signs a customer in with email + password.
  Future<Result<CustomerAccessToken, Failure>> login({
    required String email,
    required String password,
  });

  /// Registers a customer then signs them in (returns the new session token).
  Future<Result<CustomerAccessToken, Failure>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  });

  /// Invalidates [token] server-side (logout).
  Future<Result<void, Failure>> logout(String token);

  /// Renews an unexpired [token] to extend the session on launch.
  Future<Result<CustomerAccessToken, Failure>> renew(String token);

  /// Sends a Shopify password-reset email to [email].
  Future<Result<void, Failure>> recover(String email);

  /// Fetches the customer identified by [token].
  Future<Result<Customer, Failure>> fetchCustomer(String token);
}
