import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/orders/data/order_repository_impl.dart';
import 'package:shopify_app/features/orders/domain/order_repository.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/order.dart';

/// Order repository, wired to the Storefront `ApiClient`.
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepositoryImpl(ref.watch(apiClientProvider)),
);

/// How many orders to fetch per page.
const _pageSize = 20;

/// Accumulated, paginated order history.
class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<Order> orders;
  final bool hasMore;
  final bool loadingMore;

  OrdersState copyWith({
    List<Order>? orders,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// The signed-in customer's order history, newest first. Rethrows `Failure`
/// for `AsyncValue.error` (including an `AuthFailure` when signed out). Call
/// [OrdersNotifier.loadMore] to append the next page. Auto-disposes with the
/// screen so it refetches fresh orders on reopen.
final ordersProvider =
    AsyncNotifierProvider.autoDispose<OrdersNotifier, OrdersState>(
      OrdersNotifier.new,
    );

/// Loads and paginates orders for the active buyer token.
class OrdersNotifier extends AutoDisposeAsyncNotifier<OrdersState> {
  String? _cursor;

  @override
  Future<OrdersState> build() async {
    final token = ref.watch(authTokenProvider);
    if (token == null) {
      throw const AuthFailure('Sign in to view your orders.');
    }
    final repo = ref.watch(orderRepositoryProvider);
    final result = await repo.getOrders(token: token, first: _pageSize);
    final page = result.fold((p) => p, (failure) => throw failure);
    _cursor = page.endCursor;
    return OrdersState(orders: page.orders, hasMore: page.hasNextPage);
  }

  /// Fetches and appends the next page. No-op while loading, at the end, or
  /// before the first page has loaded.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final token = ref.read(authTokenProvider);
    if (current == null || !current.hasMore || current.loadingMore) return;
    if (token == null) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    final result = await ref
        .read(orderRepositoryProvider)
        .getOrders(token: token, first: _pageSize, after: _cursor);
    state = AsyncData(
      result.fold(
        (page) {
          _cursor = page.endCursor;
          return OrdersState(
            orders: [...current.orders, ...page.orders],
            hasMore: page.hasNextPage,
          );
        },
        // Keep the current page on error; scrolling again retries.
        (_) => current.copyWith(loadingMore: false),
      ),
    );
  }
}
