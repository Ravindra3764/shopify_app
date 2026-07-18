import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/search/data/search_repository_impl.dart';
import 'package:shopify_app/features/search/domain/search_filters.dart';
import 'package:shopify_app/features/search/domain/search_repository.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/providers/storage_providers.dart';
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
class SearchQueryNotifier extends AutoDisposeNotifier<String> {
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

  /// Sets the term immediately (e.g. tapping a recent/popular chip).
  void setTerm(String term) {
    _timer?.cancel();
    state = term.trim();
  }

  /// Clears the term immediately.
  void clear() {
    _timer?.cancel();
    state = '';
  }
}

final searchQueryProvider =
    NotifierProvider.autoDispose<SearchQueryNotifier, String>(
      SearchQueryNotifier.new,
    );

/// Active result refinements (sort + filters). Applied from the filter sheet.
/// Auto-disposes with the search screen so filters reset on reopen.
class SearchFiltersNotifier extends AutoDisposeNotifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  // ignore: use_setters_to_change_properties
  void apply(SearchFilters filters) => state = filters;

  void reset() => state = const SearchFilters();
}

final searchFiltersProvider =
    NotifierProvider.autoDispose<SearchFiltersNotifier, SearchFilters>(
      SearchFiltersNotifier.new,
    );

/// The shopper's recent search terms, most-recent first. Persisted locally.
class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _max = 8;

  @override
  List<String> build() => ref.watch(searchHistoryStorageProvider).readTerms();

  /// Records [term] as the newest entry, de-duplicated (case-insensitive) and
  /// capped at [_max].
  void record(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final lower = trimmed.toLowerCase();
    state = [
      trimmed,
      ...state.where((t) => t.toLowerCase() != lower),
    ].take(_max).toList();
    _persist();
  }

  void remove(String term) {
    state = state.where((t) => t != term).toList();
    _persist();
  }

  void clear() {
    if (state.isEmpty) return;
    state = const [];
    _persist();
  }

  void _persist() {
    unawaited(ref.read(searchHistoryStorageProvider).writeTerms(state));
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
      SearchHistoryNotifier.new,
    );

/// Accumulated, paginated search results.
class SearchResults {
  const SearchResults({
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<Product> items;
  final bool hasMore;
  final bool loadingMore;

  SearchResults copyWith({
    List<Product>? items,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return SearchResults(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Paginated product results for the current term + filters. Empty until the
/// term reaches [kMinSearchLength]; rethrows `Failure` for `AsyncValue.error`.
/// Call [loadMore] to append the next page. Auto-disposes with the screen.
class SearchResultsNotifier extends AutoDisposeAsyncNotifier<SearchResults> {
  String? _cursor;

  String _queryFor(String term, SearchFilters filters) =>
      [term, filters.queryTokens].where((s) => s.isNotEmpty).join(' ');

  @override
  Future<SearchResults> build() async {
    final term = ref.watch(searchQueryProvider);
    if (term.length < kMinSearchLength) {
      _cursor = null;
      return const SearchResults();
    }
    final filters = ref.watch(searchFiltersProvider);
    final repo = ref.watch(searchRepositoryProvider);
    final result = await repo.searchProducts(
      _queryFor(term, filters),
      sortKey: filters.sort.sortKey,
      reverse: filters.sort.reverse,
    );
    final page = result.fold((p) => p, (failure) => throw failure);
    _cursor = page.endCursor;
    return SearchResults(items: page.products, hasMore: page.hasNextPage);
  }

  /// Fetches and appends the next page. No-op while loading, at the end, or
  /// before the first page has loaded.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    final filters = ref.read(searchFiltersProvider);
    final result = await ref
        .read(searchRepositoryProvider)
        .searchProducts(
          _queryFor(ref.read(searchQueryProvider), filters),
          sortKey: filters.sort.sortKey,
          reverse: filters.sort.reverse,
          after: _cursor,
        );
    state = AsyncData(
      result.fold(
        (page) {
          _cursor = page.endCursor;
          return SearchResults(
            items: [...current.items, ...page.products],
            hasMore: page.hasNextPage,
          );
        },
        // Keep the current page on error; scrolling again retries.
        (_) => current.copyWith(loadingMore: false),
      ),
    );
  }
}

final searchResultsProvider =
    AsyncNotifierProvider.autoDispose<SearchResultsNotifier, SearchResults>(
      SearchResultsNotifier.new,
    );
