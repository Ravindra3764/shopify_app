import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the shopper's wishlist across app launches.
///
/// Stores each product as its Storefront-shaped JSON so the wishlist grid
/// renders offline without re-fetching. Local-only for now (guest); once
/// customer auth ships this can sync per-account.
///
/// An interface so tests can inject a fake instead of touching disk.
abstract interface class WishlistStorage {
  /// The saved wishlist products as raw JSON maps, oldest first. Empty when
  /// nothing has been persisted.
  List<Map<String, dynamic>> readProducts();

  /// Persists [products] as the full wishlist, replacing any previous value.
  Future<void> writeProducts(List<Map<String, dynamic>> products);

  /// Forgets the entire wishlist.
  Future<void> clear();
}

/// [WishlistStorage] backed by `SharedPreferences`.
class SharedPrefsWishlistStorage implements WishlistStorage {
  const SharedPrefsWishlistStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'wishlist_products';

  @override
  List<Map<String, dynamic>> readProducts() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Future<void> writeProducts(List<Map<String, dynamic>> products) =>
      _prefs.setString(_key, jsonEncode(products));

  @override
  Future<void> clear() => _prefs.remove(_key);
}
