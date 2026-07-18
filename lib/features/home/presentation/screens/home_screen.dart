import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/home/domain/home_data.dart';
import 'package:shopify_app/features/home/presentation/providers/home_providers.dart';
import 'package:shopify_app/features/home/presentation/widgets/collection_section.dart';
import 'package:shopify_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:shopify_app/features/home/presentation/widgets/home_header.dart';
import 'package:shopify_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:shopify_app/features/wishlist/presentation/widgets/wishlist_hint_trigger.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';

/// Storefront home: search, hero banners, and collection product rows.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final wishlistEnabled = ref.watch(featureFlagsProvider).wishlistEnabled;
    return CustomBackground(
      showAppBar: false,
      applyBottomInset: false,
      horizontalPadding: 0,
      contentTopPadding: 0,
      child: SafeArea(
        child: Column(
          children: [
            const WishlistHintTrigger(),
            HomeHeader(
              onCart: () => context.go(AppRoutes.cart),
              onWishlist: wishlistEnabled
                  ? () => context.push(AppRoutes.wishlist)
                  : null,
            ),
            Expanded(
              child: homeAsync.when(
                data: _HomeContent.new,
                loading: () => const LoadingShimmer.home(),
                error: (e, _) => ErrorView(
                  message: e is Failure ? e.message : 'Something went wrong.',
                  onRetry: () => ref.invalidate(homeProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent(this.home);

  final HomeData home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(homeProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.floatingNavClearance,
        ),
        children: [
          if (ref.watch(featureFlagsProvider).searchEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: HomeSearchBar(
                hintText: 'Search our collection',
                onTap: () => context.push(AppRoutes.search),
              ),
            ),
          if (home.banners.isNotEmpty)
            HomeBannerCarousel(
              banners: home.banners,
              onCta: (banner) {
                final handle = banner.ctaCollectionHandle;
                if (handle == null || handle.isEmpty) return;
                context.push(
                  AppRoutes.collectionPath(handle),
                  extra: banner.title,
                );
              },
            ),
          for (final collection in home.collections) ...[
            const SizedBox(height: AppSpacing.xl),
            CollectionSection(
              collection: collection,
              onSeeAll: () => context.push(
                AppRoutes.collectionPath(collection.handle),
                extra: collection.title,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
