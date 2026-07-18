import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/search/data/search_repository_impl.dart';
import 'package:shopify_app/features/search/domain/search_repository.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// Search repository, wired to the Storefront `ApiClient`.
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Minimum query length before a search fires — avoids noisy 1-char lookups.
const kMinSearchLength = 2;

/// Debounce window so results only fetch after the shopper pauses typing.
const _debounce = Duration(milliseconds: 350);

/// The debounced, trimmed search term. The text field pushes raw input through
/// [update]; the term only changes after the shopper stops typing.
class SearchQueryNotifier extends Notifier<String> {
  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  /// Debounced update from the text field.
  void update(String raw) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => state = raw.trim());
  }

  /// Clears the term immediately (e.g. the clear button).
  void clear() {
    _timer?.cancel();
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Product results for the current [searchQueryProvider]. Returns an empty list
/// until the term reaches [kMinSearchLength]; rethrows `Failure` for
/// `AsyncValue.error`. Auto-disposes when the search screen closes.
class SearchResultsNotifier extends AutoDisposeAsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final query = ref.watch(searchQueryProvider);
    if (query.length < kMinSearchLength) return const [];
    final repo = ref.watch(searchRepositoryProvider);
    final result = await repo.searchProducts(query);
    return result.fold((products) => products, (failure) => throw failure);
  }
}

final searchResultsProvider =
    AsyncNotifierProvider.autoDispose<SearchResultsNotifier, List<Product>>(
      SearchResultsNotifier.new,
    );
