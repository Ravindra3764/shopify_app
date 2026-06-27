import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_listing/presentation/providers/collection_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';
import 'package:shopify_app/shared/widgets/product_card.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// All products of a collection, opened from a "View All" action or a
/// `/collection/:handle` deep link.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({required this.handle, super.key, this.title});
  final String handle;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionProvider(handle));
    final appBarTitle = async.maybeWhen(
      data: (collection) => collection.title,
      orElse: () => title ?? '',
    );

    return CustomBackground(
      title: appBarTitle,
      horizontalPadding: 0,
      contentTopPadding: 0,
      child: async.when(
        data: (collection) => _Grid(products: collection.products),
        loading: () => const LoadingShimmer.grid(),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Something went wrong.',
          onRetry: () => ref.invalidate(collectionProvider(handle)),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyStateView(
        icon: Icons.inventory_2_outlined,
        message: 'No products in this collection yet.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: AppDimensions.productCardHeight,
      ),
      itemBuilder: (_, i) => ProductCard(product: products[i]),
    );
  }
}
