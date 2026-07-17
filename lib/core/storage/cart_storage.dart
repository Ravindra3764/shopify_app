import 'package:shared_preferences/shared_preferences.dart';

/// Persists the guest cart's ID across app launches so a returning shopper
/// keeps their cart. Only the ID is stored; the cart itself is re-fetched
/// from Shopify on startup.
///
/// An interface so tests can inject a fake instead of touching disk.
abstract interface class CartStorage {
  /// The saved cart ID, or `null` when nothing has been persisted.
  String? readCartId();

  /// Persists [cartId] as the active guest cart.
  Future<void> writeCartId(String cartId);

  /// Forgets the saved cart ID — e.g. once Shopify reports it expired.
  Future<void> clearCartId();
}

/// [CartStorage] backed by `SharedPreferences`.
class SharedPrefsCartStorage implements CartStorage {
  const SharedPrefsCartStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _cartIdKey = 'guest_cart_id';

  @override
  String? readCartId() => _prefs.getString(_cartIdKey);

  @override
  Future<void> writeCartId(String cartId) =>
      _prefs.setString(_cartIdKey, cartId);

  @override
  Future<void> clearCartId() => _prefs.remove(_cartIdKey);
}
