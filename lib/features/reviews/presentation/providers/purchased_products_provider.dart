import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/orders/presentation/providers/orders_providers.dart';

/// GIDs of every product the signed-in customer has purchased, gathered by
/// walking their order history. Empty when signed out. Used to gate reviews to
/// purchased products (`FeatureFlags.reviewOnlyPurchased`).
///
/// Caps the walk at [_maxPages] pages so a customer with a very long history
/// doesn't trigger an unbounded fetch; the newest orders are covered first.
final purchasedProductIdsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return const {};

  final repo = ref.watch(orderRepositoryProvider);
  final ids = <String>{};
  String? cursor;
  for (var page = 0; page < _maxPages; page++) {
    final result = await repo.getOrders(
      token: token,
      first: _pageSize,
      after: cursor,
    );
    final orderPage = result.fold((p) => p, (_) => null);
    if (orderPage == null) break;
    for (final order in orderPage.orders) {
      for (final line in order.lines) {
        final id = line.productId;
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    if (!orderPage.hasNextPage) break;
    cursor = orderPage.endCursor;
  }
  return ids;
});

const _pageSize = 50;
const _maxPages = 10;
