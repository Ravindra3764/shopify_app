import 'package:shopify_app/core/utils/json_parse.dart';

/// Storefront `CustomerAccessToken` — the bearer credential for a signed-in
/// customer, returned by `customerAccessTokenCreate`/`Renew`.
///
/// [accessToken] is sent as the `customerAccessToken` argument on customer
/// queries/mutations; [expiresAt] lets the app renew or drop the session before
/// Shopify rejects it.
class CustomerAccessToken {
  const CustomerAccessToken({
    required this.accessToken,
    required this.expiresAt,
  });

  /// Builds from a Storefront `CustomerAccessToken` node.
  factory CustomerAccessToken.fromJson(Map<String, dynamic> json) =>
      CustomerAccessToken(
        accessToken: parseString(json, 'accessToken', model: _model),
        expiresAt: parseDateTime(json, 'expiresAt', model: _model),
      );

  static const _model = 'CustomerAccessToken';

  final String accessToken;
  final DateTime expiresAt;

  /// Whether the token is still valid (with a small safety margin so it isn't
  /// used right at the edge of expiry).
  bool isValidAt(DateTime now) =>
      expiresAt.isAfter(now.add(const Duration(minutes: 5)));
}
