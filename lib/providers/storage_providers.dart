import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/storage/address_storage.dart';
import 'package:shopify_app/core/storage/cart_storage.dart';

/// Persistent cart storage. Overridden in `bootstrap()` with a
/// `SharedPreferences`-backed instance once prefs have loaded.
final cartStorageProvider = Provider<CartStorage>(
  (ref) => throw UnimplementedError('overridden in bootstrap()'),
);

/// Persistent address-book storage. Overridden in `bootstrap()` with a
/// `SharedPreferences`-backed instance once prefs have loaded.
final addressStorageProvider = Provider<AddressStorage>(
  (ref) => throw UnimplementedError('overridden in bootstrap()'),
);
