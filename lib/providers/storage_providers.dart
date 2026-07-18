import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/storage/address_storage.dart';
import 'package:shopify_app/core/storage/cart_storage.dart';
import 'package:shopify_app/core/storage/onboarding_storage.dart';
import 'package:shopify_app/core/storage/search_history_storage.dart';
import 'package:shopify_app/core/storage/wishlist_storage.dart';

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

/// Persistent wishlist storage. Overridden in `bootstrap()` with a
/// `SharedPreferences`-backed instance once prefs have loaded.
final wishlistStorageProvider = Provider<WishlistStorage>(
  (ref) => throw UnimplementedError('overridden in bootstrap()'),
);

/// Persistent onboarding-hint storage. Overridden in `bootstrap()` with a
/// `SharedPreferences`-backed instance once prefs have loaded.
final onboardingStorageProvider = Provider<OnboardingStorage>(
  (ref) => throw UnimplementedError('overridden in bootstrap()'),
);

/// Persistent search-history storage. Overridden in `bootstrap()` with a
/// `SharedPreferences`-backed instance once prefs have loaded.
final searchHistoryStorageProvider = Provider<SearchHistoryStorage>(
  (ref) => throw UnimplementedError('overridden in bootstrap()'),
);
