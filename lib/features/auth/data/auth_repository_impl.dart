import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/auth/domain/auth_repository.dart';
import 'package:shopify_app/shopify/models/customer.dart';
import 'package:shopify_app/shopify/models/customer_access_token.dart';
import 'package:shopify_app/shopify/mutations/customer_mutations.dart';
import 'package:shopify_app/shopify/queries/customer_queries.dart';

/// [AuthRepository] backed by the Shopify Storefront customer API.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._client);

  final ApiClient _client;

  static const _model = 'AuthRepository';

  @override
  Future<Result<CustomerAccessToken, Failure>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _client.query(
        kCustomerAccessTokenCreateMutation,
        variables: {
          'input': {'email': email, 'password': password},
        },
      );
      return _parseToken(data, 'customerAccessTokenCreate');
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<CustomerAccessToken, Failure>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final data = await _client.query(
        kCustomerCreateMutation,
        variables: {
          'input': {
            'email': email,
            'password': password,
            if (firstName != null && firstName.isNotEmpty)
              'firstName': firstName,
            if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
          },
        },
      );
      final errors = _errorsIn(data, 'customerCreate');
      if (errors != null) return Failed(errors);
      // Shopify's customerCreate doesn't return a token — sign the new
      // customer in to obtain one.
      return login(email: email, password: password);
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<void, Failure>> logout(String token) async {
    try {
      final data = await _client.query(
        kCustomerAccessTokenDeleteMutation,
        variables: {'customerAccessToken': token},
      );
      final errors = _errorsIn(data, 'customerAccessTokenDelete');
      return errors != null ? Failed(errors) : const Success(null);
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<CustomerAccessToken, Failure>> renew(String token) async {
    try {
      final data = await _client.query(
        kCustomerAccessTokenRenewMutation,
        variables: {'customerAccessToken': token},
      );
      return _parseToken(data, 'customerAccessTokenRenew');
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<void, Failure>> recover(String email) async {
    try {
      final data = await _client.query(
        kCustomerRecoverMutation,
        variables: {'email': email},
      );
      final errors = _errorsIn(data, 'customerRecover');
      return errors != null ? Failed(errors) : const Success(null);
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<Customer, Failure>> fetchCustomer(String token) async {
    try {
      final data = await _client.query(
        kCustomerQuery,
        variables: {'customerAccessToken': token},
      );
      final customerMap = parseMap(data, 'customer', model: _model);
      if (customerMap.isEmpty) {
        // Shopify returns `customer: null` when the token is invalid/expired.
        return const Failed(AuthFailure('Your session has expired.'));
      }
      return Success(Customer.fromJson(customerMap));
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  /// Reads a token payload ([field] → `{customerAccessToken, ...Errors}`),
  /// mapping non-empty errors — or a missing token — to an [AuthFailure].
  Result<CustomerAccessToken, Failure> _parseToken(
    Map<String, dynamic> data,
    String field,
  ) {
    final errors = _errorsIn(data, field);
    if (errors != null) return Failed(errors);
    final payload = parseMap(data, field, model: _model);
    final tokenMap = parseMap(payload, 'customerAccessToken', model: _model);
    if (tokenMap.isEmpty) {
      // No error but no token → Shopify rejected the credentials silently.
      return const Failed(AuthFailure('Incorrect email or password.'));
    }
    return Success(CustomerAccessToken.fromJson(tokenMap));
  }

  /// Joins any `customerUserErrors`/`userErrors` messages in [field]'s payload
  /// into an [AuthFailure], or returns `null` when there are none.
  AuthFailure? _errorsIn(Map<String, dynamic> data, String field) {
    final payload = parseMap(data, field, model: _model);
    final key = payload.containsKey('customerUserErrors')
        ? 'customerUserErrors'
        : 'userErrors';
    final messages = parseList<String>(
      payload,
      key,
      model: _model,
      fromItem: (item) => item is Map<String, dynamic>
          ? parseString(item, 'message', model: _model)
          : '',
    ).where((message) => message.isNotEmpty).toList();
    return messages.isEmpty ? null : AuthFailure(messages.join(', '));
  }
}
