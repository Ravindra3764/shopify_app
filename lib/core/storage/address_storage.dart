import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

/// Persists the guest shopper's saved delivery addresses and last-used email
/// locally, so returning shoppers can reuse them at checkout without an
/// account. No customer token is involved.
///
/// An interface so tests can inject a fake instead of touching disk.
abstract interface class AddressStorage {
  /// The saved addresses, newest-first. Empty when nothing is stored.
  List<MailingAddress> readAddresses();

  /// Replaces the stored address book with [addresses].
  Future<void> writeAddresses(List<MailingAddress> addresses);

  /// The last email the shopper used at checkout, or `null`.
  String? readEmail();

  /// Persists [email] as the last-used checkout email.
  Future<void> writeEmail(String email);
}

/// [AddressStorage] backed by `SharedPreferences` (addresses as a JSON array).
class SharedPrefsAddressStorage implements AddressStorage {
  const SharedPrefsAddressStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _addressesKey = 'guest_addresses';
  static const _emailKey = 'guest_checkout_email';

  @override
  List<MailingAddress> readAddresses() {
    final raw = _prefs.getString(_addressesKey);
    if (raw == null || raw.isEmpty) return const [];
    // Tolerate any legacy/corrupt payload by returning an empty book rather
    // than throwing across the storage boundary.
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MailingAddress.fromJson)
        .toList();
  }

  @override
  Future<void> writeAddresses(List<MailingAddress> addresses) {
    final payload = jsonEncode(
      addresses.map((a) => a.toJson()).toList(),
    );
    return _prefs.setString(_addressesKey, payload);
  }

  @override
  String? readEmail() => _prefs.getString(_emailKey);

  @override
  Future<void> writeEmail(String email) => _prefs.setString(_emailKey, email);
}
