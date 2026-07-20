import 'package:shopify_app/core/utils/json_parse.dart';

/// Storefront `Customer` — the signed-in shopper's identity, fetched with a
/// valid access token. Names/phone are optional on a Shopify customer record.
class Customer {
  const Customer({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  /// Builds from a Storefront `Customer` node.
  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: parseString(json, 'id', model: _model),
    email: parseString(json, 'email', model: _model),
    firstName: parseStringOrNull(json, 'firstName', model: _model),
    lastName: parseStringOrNull(json, 'lastName', model: _model),
    phone: parseStringOrNull(json, 'phone', model: _model),
  );

  static const _model = 'Customer';

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;

  /// Best available display name: full name, first name, else the email.
  String get displayName {
    final full = [
      ?firstName,
      ?lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    return full.isNotEmpty ? full : email;
  }
}
