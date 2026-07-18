import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/search/presentation/providers/search_providers.dart';
import 'package:shopify_app/features/wishlist/presentation/widgets/wishlist_product_card.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// Full-text product search: a debounced field over a results grid.
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

  @override
  Widget build(BuildContext context) {
    return CustomBackground(
      title: 'Search',
      horizontalPadding: 0,
      contentTopPadding: 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: CustomTextBox.search(
              controller: _controller,
              hintText: 'Search our collection',
              onChanged: ref.read(searchQueryProvider.notifier).update,
            ),
          ),
          const Expanded(child: _SearchBody()),
        ],
      ),
    );
  }
}

class _SearchBody extends ConsumerWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    if (query.length < kMinSearchLength) {
      return const EmptyStateView(
        icon: Icons.search,
        message: 'Search for products by name, brand, or type.',
      );
    }

    return ref
        .watch(searchResultsProvider)
        .when(
          data: (products) => products.isEmpty
              ? EmptyStateView(
                  icon: Icons.search_off,
                  message: 'No products found for "$query".',
                )
              : _ResultsGrid(products: products),
          loading: () => const LoadingShimmer.grid(),
          error: (e, _) => ErrorView(
            message: e is Failure ? e.message : 'Something went wrong.',
            onRetry: () => ref.invalidate(searchResultsProvider),
          ),
        );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: AppDimensions.productCardHeight,
      ),
      itemBuilder: (context, i) {
        final product = products[i];
        return WishlistProductCard(
          product: product,
          onTap: () =>
              context.push(AppRoutes.productDetailPath(product.handle)),
        );
      },
    );
  }
}
