import 'package:shopify_app/core/utils/json_parse.dart';

/// A shipping / delivery address.
///
/// Doubles as a Storefront `MailingAddress` (via [MailingAddress.fromJson]) and
/// a locally-stored address-book entry (via [toJson] / [MailingAddress.fromJson]).
/// Feeds the
/// cart's `deliveryAddressPreferences` through [toInput], which yields the
/// Storefront `MailingAddressInput` shape.
///
/// [country] and [province] are stored as ISO codes (e.g. `US`, `CA`) so they
/// can also seed `buyerIdentity.countryCode`.
class MailingAddress {
  const MailingAddress({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.address1,
    required this.city,
    required this.province,
    required this.zip,
    required this.country,
    this.address2,
    this.phone,
  });

  /// Builds from a Storefront `MailingAddress` node or a locally-stored entry.
  factory MailingAddress.fromJson(Map<String, dynamic> json) {
    return MailingAddress(
      // Locally-stored entries carry an `id`; Storefront nodes may not, so a
      // stable-enough fallback keeps address-book de-duplication working.
      id: parseString(json, 'id', fallback: _fallbackId(json), model: _model),
      firstName: parseString(json, 'firstName', model: _model),
      lastName: parseString(json, 'lastName', model: _model),
      address1: parseString(json, 'address1', model: _model),
      address2: parseStringOrNull(json, 'address2', model: _model),
      city: parseString(json, 'city', model: _model),
      province: parseString(json, 'province', model: _model),
      zip: parseString(json, 'zip', model: _model),
      country: parseString(json, 'country', model: _model),
      phone: parseStringOrNull(json, 'phone', model: _model),
    );
  }

  static const _model = 'MailingAddress';

  /// Local address-book identifier (not sent to Shopify).
  final String id;
  final String firstName;
  final String lastName;
  final String address1;

  /// Apartment / suite / unit, optional.
  final String? address2;
  final String city;

  /// Province / state ISO code (e.g. `CA` for California).
  final String province;
  final String zip;

  /// Country ISO code (e.g. `US`).
  final String country;
  final String? phone;

  /// Full name for display.
  String get fullName => '$firstName $lastName'.trim();

  /// Multi-line address summary for display.
  String get formatted {
    final line2 = address2;
    return [
      if (line2 != null && line2.isNotEmpty) '$address1, $line2' else address1,
      '$city, $province $zip',
      country,
    ].join('\n');
  }

  /// Storefront `MailingAddressInput` map; omits empty optional fields.
  Map<String, dynamic> toInput() => <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'address1': address1,
    if (address2 != null && address2!.isNotEmpty) 'address2': address2,
    'city': city,
    'province': province,
    'zip': zip,
    'country': country,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
  };

  /// Serializes for local (address-book) storage.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'address1': address1,
    if (address2 != null) 'address2': address2,
    'city': city,
    'province': province,
    'zip': zip,
    'country': country,
    if (phone != null) 'phone': phone,
  };

  MailingAddress copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? address1,
    String? address2,
    String? city,
    String? province,
    String? zip,
    String? country,
    String? phone,
  }) => MailingAddress(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    address1: address1 ?? this.address1,
    address2: address2 ?? this.address2,
    city: city ?? this.city,
    province: province ?? this.province,
    zip: zip ?? this.zip,
    country: country ?? this.country,
    phone: phone ?? this.phone,
  );

  /// Derives a stable id from the address fields when none is present.
  static String _fallbackId(Map<String, dynamic> json) {
    final zip = parseString(json, 'zip', model: _model);
    final line = parseString(json, 'address1', model: _model);
    return 'addr_${line.hashCode ^ zip.hashCode}';
  }
}
