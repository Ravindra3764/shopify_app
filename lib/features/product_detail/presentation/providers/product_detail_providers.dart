import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/product_detail/data/product_detail_repository_impl.dart';
import 'package:shopify_app/features/product_detail/domain/product_detail_repository.dart';
import 'package:shopify_app/features/product_detail/presentation/providers/product_selection.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/models/product_detail.dart';
import 'package:shopify_app/shopify/models/shop_policies.dart';

/// Product-detail repository, wired to the Storefront `ApiClient`.
final productDetailRepositoryProvider = Provider<ProductDetailRepository>(
  (ref) => ProductDetailRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Loads a [ProductDetail] by handle, keyed per handle.
final productDetailProvider =
    AsyncNotifierProvider.family<ProductDetailNotifier, ProductDetail, String>(
      ProductDetailNotifier.new,
    );

/// Fetches one product via [ProductDetailRepository]; rethrows `Failure` for
/// `AsyncValue.error`.
class ProductDetailNotifier extends FamilyAsyncNotifier<ProductDetail, String> {
  @override
  Future<ProductDetail> build(String handle) async {
    final repo = ref.watch(productDetailRepositoryProvider);
    final result = await repo.getProduct(handle);
    return result.fold((product) => product, (failure) => throw failure);
  }
}

/// Loads related products for a product ID, keyed per ID.
final productRecommendationsProvider =
    AsyncNotifierProvider.family<
      ProductRecommendationsNotifier,
      List<Product>,
      String
    >(ProductRecommendationsNotifier.new);

/// Fetches related products via [ProductDetailRepository]; rethrows
/// `Failure` for `AsyncValue.error`.
class ProductRecommendationsNotifier
    extends FamilyAsyncNotifier<List<Product>, String> {
  @override
  Future<List<Product>> build(String productId) async {
    final repo = ref.watch(productDetailRepositoryProvider);
    final result = await repo.getRecommendations(productId);
    return result.fold((products) => products, (failure) => throw failure);
  }
}

/// Shop-wide shipping/return policy copy — identical across every product,
/// so it's kept alive for the app session once loaded instead of refetching
/// per product handle.
final shopPoliciesProvider =
    AsyncNotifierProvider<ShopPoliciesNotifier, ShopPolicies>(
      ShopPoliciesNotifier.new,
    );

/// Fetches shop policies via [ProductDetailRepository]; rethrows `Failure`
/// for `AsyncValue.error`.
class ShopPoliciesNotifier extends AsyncNotifier<ShopPolicies> {
  @override
  Future<ShopPolicies> build() async {
    ref.keepAlive();
    final repo = ref.watch(productDetailRepositoryProvider);
    final result = await repo.getShopPolicies();
    return result.fold((policies) => policies, (failure) => throw failure);
  }
}

/// In-progress option/quantity selection for the product-detail screen,
/// keyed per product handle.
final productSelectionProvider =
    NotifierProvider.family<ProductSelectionNotifier, ProductSelection, String>(
      ProductSelectionNotifier.new,
    );

/// Holds the selected option values and quantity; seeds the default
/// selection (first value of each option) once the product loads.
class ProductSelectionNotifier
    extends FamilyNotifier<ProductSelection, String> {
  @override
  ProductSelection build(String handle) {
    final detail = ref.watch(productDetailProvider(handle)).valueOrNull;
    if (detail == null) return const ProductSelection.initial();

    final defaults = <String, String>{
      for (final option in detail.options)
        if (option.values.isNotEmpty) option.name: option.values.first,
    };
    return ProductSelection(selectedOptions: defaults, quantity: 1);
  }

  /// Picks [value] for option [name].
  void selectOption(String name, String value) {
    state = state.copyWith(
      selectedOptions: {...state.selectedOptions, name: value},
    );
  }

  /// Increments quantity by one.
  void incrementQuantity() =>
      state = state.copyWith(quantity: state.quantity + 1);

  /// Decrements quantity by one, never below 1.
  void decrementQuantity() {
    if (state.quantity <= 1) return;
    state = state.copyWith(quantity: state.quantity - 1);
  }
}
