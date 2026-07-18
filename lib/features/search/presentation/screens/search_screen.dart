import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_detail/presentation/product_navigation.dart';
import 'package:shopify_app/features/search/domain/search_filters.dart';
import 'package:shopify_app/features/search/presentation/providers/search_providers.dart';
import 'package:shopify_app/features/search/presentation/widgets/search_filter_sheet.dart';
import 'package:shopify_app/features/search/presentation/widgets/search_initial_view.dart';
import 'package:shopify_app/features/wishlist/presentation/widgets/wishlist_product_card.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';

/// Full-text product search: a debounced field with recent/popular suggestions,
/// a filter sheet, and a results grid.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs a committed search (submit or a chip tap): syncs the field, sets the
  /// term immediately, and records it in history.
  void _runSearch(String term) {
    final trimmed = term.trim();
    if (trimmed.length < kMinSearchLength) return;
    _controller.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    ref.read(searchQueryProvider.notifier).setTerm(trimmed);
    ref.read(searchHistoryProvider.notifier).record(trimmed);
    FocusScope.of(context).unfocus();
  }

  Future<void> _openFilters() async {
    final next = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          SearchFilterSheet(initial: ref.read(searchFiltersProvider)),
    );
    if (next != null) {
      ref.read(searchFiltersProvider.notifier).apply(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtersActive = ref.watch(searchFiltersProvider).isActive;
    return CustomBackground(
      title: 'Search',
      horizontalPadding: 0,
      contentTopPadding: 0,
      actions: [
        IconButton(
          onPressed: _openFilters,
          icon: Icon(
            filtersActive ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: filtersActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: CustomTextBox.search(
              controller: _controller,
              hintText: 'Search our collection',
              onChanged: ref.read(searchQueryProvider.notifier).update,
              onSubmitted: _runSearch,
            ),
          ),
          Expanded(child: _SearchBody(onTermSelected: _runSearch)),
        ],
      ),
    );
  }
}

class _SearchBody extends ConsumerWidget {
  const _SearchBody({required this.onTermSelected});

  final void Function(String term) onTermSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    if (query.length < kMinSearchLength) {
      return SearchInitialView(onTermSelected: onTermSelected);
    }

    return ref
        .watch(searchResultsProvider)
        .when(
          data: (results) => results.items.isEmpty
              ? EmptyStateView(
                  icon: Icons.search_off,
                  message: 'No products found for "$query".',
                )
              : _ResultsGrid(
                  results: results,
                  onLoadMore: () =>
                      ref.read(searchResultsProvider.notifier).loadMore(),
                ),
          loading: () => const LoadingShimmer.grid(),
          error: (e, _) => ErrorView(
            message: e is Failure ? e.message : 'Something went wrong.',
            onRetry: () => ref.invalidate(searchResultsProvider),
          ),
        );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.results, required this.onLoadMore});

  final SearchResults results;
  final VoidCallback onLoadMore;

  /// Distance from the bottom (px) at which to prefetch the next page.
  static const _prefetchExtent = 400.0;

  @override
  Widget build(BuildContext context) {
    final products = results.items;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final m = notification.metrics;
        if (results.hasMore &&
            !results.loadingMore &&
            m.pixels >= m.maxScrollExtent - _prefetchExtent) {
          onLoadMore();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: AppDimensions.productCardHeight,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                return WishlistProductCard(
                  product: products[i],
                  onTap: () => openProductFromList(context, products, i),
                );
              }, childCount: products.length),
            ),
          ),
          if (results.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
