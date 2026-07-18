import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/providers/storage_providers.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// Holds the shopper's wishlist and keeps it persisted.
///
/// State is the list of saved [Product]s, most-recently-added last (matching
/// insertion order). Mutations update state synchronously for instant UI, then
/// persist in the background via the wishlist storage.
class WishlistNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    final stored = ref.watch(wishlistStorageProvider).readProducts();
    return stored.map(Product.fromJson).toList();
  }

  /// Adds [product] if absent, removes it if already saved.
  void toggle(Product product) {
    contains(product.id) ? remove(product.id) : add(product);
  }

  /// Saves [product]; no-op when already wishlisted.
  void add(Product product) {
    if (contains(product.id)) return;
    state = [...state, product];
    _persist();
  }

  /// Removes the product with [productId]; no-op when absent.
  void remove(String productId) {
    if (!contains(productId)) return;
    state = state.where((p) => p.id != productId).toList();
    _persist();
  }

  /// Empties the wishlist.
  void clear() {
    if (state.isEmpty) return;
    state = const [];
    _persist();
  }

  /// Whether a product with [productId] is currently wishlisted.
  bool contains(String productId) => state.any((p) => p.id == productId);

  void _persist() {
    unawaited(
      ref
          .read(wishlistStorageProvider)
          .writeProducts(state.map((p) => p.toJson()).toList()),
    );
  }
}

/// The shopper's wishlist. Kept alive for the app session so the badge and
/// hearts stay in sync across screens.
final wishlistProvider = NotifierProvider<WishlistNotifier, List<Product>>(
  WishlistNotifier.new,
);

/// Whether the product with the given id is wishlisted. Use in cards/detail so
/// only the affected widget rebuilds on toggle.
final isInWishlistProvider = Provider.family<bool, String>(
  (ref, productId) => ref.watch(wishlistProvider).any((p) => p.id == productId),
);

/// Number of saved products — drives the header badge.
final wishlistCountProvider = Provider<int>(
  (ref) => ref.watch(wishlistProvider).length,
);
