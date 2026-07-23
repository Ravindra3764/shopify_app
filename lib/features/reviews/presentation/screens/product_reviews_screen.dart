import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/reviews/domain/product_reviews_args.dart';
import 'package:shopify_app/features/reviews/presentation/providers/purchased_products_provider.dart';
import 'package:shopify_app/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/review_tile.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/reviews_summary_card.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';

/// Full-screen list of a product's reviews with a ratings summary header and
/// infinite scroll.
class ProductReviewsScreen extends ConsumerStatefulWidget {
  const ProductReviewsScreen({required this.args, super.key});

  final ProductReviewsArgs args;

  @override
  ConsumerState<ProductReviewsScreen> createState() =>
      _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends ConsumerState<ProductReviewsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads the next page when the shopper nears the end of the list.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - AppDimensions.loadMoreThreshold) {
      ref.read(reviewsProvider(widget.args.productId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.args.productId;
    final reviewsAsync = ref.watch(reviewsProvider(productId));

    return CustomBackground(
      title: 'Reviews',
      child: reviewsAsync.when(
        data: (data) {
          final summary = ReviewsSummaryCard(
            reviews: data.reviews,
            averageRating: widget.args.averageRating,
            reviewsCount: widget.args.reviewsCount,
          );
          final cta = _WriteReviewCta(args: widget.args);
          if (data.reviews.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              children: [
                summary,
                const SizedBox(height: AppSpacing.lg),
                cta,
                const SizedBox(height: AppSpacing.xl),
                const EmptyStateView(
                  icon: Icons.reviews_outlined,
                  message: 'No reviews for this product yet.',
                ),
              ],
            );
          }
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: AppDimensions.floatingNavClearance,
            ),
            // +1 header (summary), +1 trailing loader when more remain.
            itemCount: data.reviews.length + 1 + (data.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summary,
                      const SizedBox(height: AppSpacing.lg),
                      cta,
                    ],
                  ),
                );
              }
              final reviewIndex = index - 1;
              if (reviewIndex >= data.reviews.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return ReviewTile(review: data.reviews[reviewIndex]);
            },
          );
        },
        loading: () => const LoadingShimmer.orders(),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Something went wrong.',
          onRetry: () => ref.invalidate(reviewsProvider(productId)),
        ),
      ),
    );
  }
}

/// "Write a review" action, shown only when the tenant enables review
/// submission. When `reviewOnlyPurchased` is on, it's offered only for products
/// the signed-in customer has bought; otherwise any signed-in shopper can
/// review. Prompts sign-in when signed out.
class _WriteReviewCta extends ConsumerWidget {
  const _WriteReviewCta({required this.args});

  final ProductReviewsArgs args;

  void _open(BuildContext context, WidgetRef ref) {
    if (ref.read(isAuthenticatedProvider)) {
      context.push(AppRoutes.productReviewWrite, extra: args);
    } else {
      showAppSnackBar(context, 'Sign in to write a review.');
      context.push(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    if (!flags.reviewSubmissionEnabled) return const SizedBox.shrink();

    Widget button({required bool enabled}) => CustomButton.outline(
      label: 'Write a review',
      leadingIcon: const Icon(Icons.rate_review_outlined),
      onPressed: enabled ? () => _open(context, ref) : null,
    );

    // Any signed-in shopper can review anything.
    if (!flags.reviewOnlyPurchased) return button(enabled: true);

    // Purchase-gated: signed-out shoppers still get a button that routes to
    // sign-in; signed-in shoppers only see it for products they've purchased.
    if (!ref.watch(isAuthenticatedProvider)) return button(enabled: true);

    return ref
        .watch(purchasedProductIdsProvider)
        .when(
          loading: () => button(enabled: false),
          error: (_, _) => const SizedBox.shrink(),
          data: (ids) => ids.contains(args.productId)
              ? button(enabled: true)
              : _PurchaseGateNote(),
        );
  }
}

/// Shown in place of the CTA when purchase-gated reviews are on and the
/// customer hasn't bought this product.
class _PurchaseGateNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.lock_outline,
          size: AppDimensions.iconSm,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Only customers who bought this product can review it.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
