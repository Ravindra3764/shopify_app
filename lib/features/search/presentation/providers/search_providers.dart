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

/// Product results for the current term + filters. Returns an empty list until
/// the term reaches [kMinSearchLength]; rethrows `Failure` for
/// `AsyncValue.error`. Auto-disposes when the search screen closes.
class SearchResultsNotifier extends AutoDisposeAsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final term = ref.watch(searchQueryProvider);
    if (term.length < kMinSearchLength) return const [];

    final filters = ref.watch(searchFiltersProvider);
    final query = [
      term,
      filters.queryTokens,
    ].where((s) => s.isNotEmpty).join(' ');

    final repo = ref.watch(searchRepositoryProvider);
    final result = await repo.searchProducts(
      query,
      sortKey: filters.sort.sortKey,
      reverse: filters.sort.reverse,
    );
    return result.fold((products) => products, (failure) => throw failure);
  }
}

final searchResultsProvider =
    AsyncNotifierProvider.autoDispose<SearchResultsNotifier, List<Product>>(
      SearchResultsNotifier.new,
    );
