import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/config/product_grid_style.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/browse/presentation/providers/browse_providers.dart';
import 'package:shopify_app/features/product_detail/presentation/product_navigation.dart';
import 'package:shopify_app/features/product_listing/presentation/providers/collection_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';
import 'package:shopify_app/shared/widgets/product_feed.dart';
import 'package:shopify_app/shared/widgets/pull_to_refresh.dart';
import 'package:shopify_app/shopify/models/collection_summary.dart';

/// Browse tab: a collection chip bar (default: first collection) over a
/// waterfall/standard product feed for the selected collection.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(collectionsListProvider);
    return CustomBackground(
      title: 'Shop',
      showBackButton: false,
      horizontalPadding: 0,
      contentTopPadding: 0,
      applyBottomInset: false,
      child: listAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return const EmptyStateView(
              icon: Icons.category_outlined,
              message: 'No collections to browse yet.',
            );
          }
          final selected =
              ref.watch(selectedCollectionProvider) ?? collections.first.handle;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CollectionChips(
                collections: collections,
                selected: selected,
                onSelect: (handle) => ref
                    .read(selectedCollectionProvider.notifier)
                    .select(handle),
              ),
              Expanded(child: _CollectionFeed(handle: selected)),
            ],
          );
        },
        loading: () => const LoadingShimmer.grid(),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Something went wrong.',
          onRetry: () => ref.invalidate(collectionsListProvider),
        ),
      ),
    );
  }
}

/// Horizontal, scrollable row of collection selector chips.
class _CollectionChips extends StatelessWidget {
  const _CollectionChips({
    required this.collections,
    required this.selected,
    required this.onSelect,
  });

  final List<CollectionSummary> collections;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final collection in collections)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _CollectionChip(
                label: collection.title,
                selected: collection.handle == selected,
                onTap: () => onSelect(collection.handle),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single pill-shaped collection chip; filled when [selected].
class _CollectionChip extends StatelessWidget {
  const _CollectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _animDuration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Product feed for the selected browse collection.
class _CollectionFeed extends ConsumerWidget {
  const _CollectionFeed({required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionProvider(handle));

    Future<void> refresh() async {
      ref.invalidate(collectionProvider(handle));
      await ref.read(collectionProvider(handle).future);
    }

    return async.when(
      data: (collection) {
        final products = collection.products;
        if (products.isEmpty) {
          return PullToRefresh(
            onRefresh: refresh,
            scrollable: false,
            child: const EmptyStateView(
              icon: Icons.inventory_2_outlined,
              message: 'No products in this collection yet.',
            ),
          );
        }
        return PullToRefresh(
          onRefresh: refresh,
          child: ProductFeed(
            products: products,
            onTapIndex: (i) => openProductFromList(context, products, i),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppDimensions.floatingNavClearance,
            ),
          ),
        );
      },
      loading: () =>
          ref.watch(appConfigProvider).productGridStyle ==
              ProductGridStyle.masonry
          ? const LoadingShimmer.masonry()
          : const LoadingShimmer.grid(),
      error: (e, _) => ErrorView(
        message: e is Failure ? e.message : 'Something went wrong.',
        onRetry: () => ref.invalidate(collectionProvider(handle)),
      ),
    );
  }
}
