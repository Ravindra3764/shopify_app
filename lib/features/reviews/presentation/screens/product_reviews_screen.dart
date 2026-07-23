import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/reviews/domain/product_reviews_args.dart';
import 'package:shopify_app/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/review_tile.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/reviews_summary_card.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/write_review_cta.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';
import 'package:shopify_app/shared/widgets/pull_to_refresh.dart';

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

  Future<void> _refresh() async {
    final id = widget.args.productId;
    ref.invalidate(reviewsProvider(id));
    await ref.read(reviewsProvider(id).future);
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
          final cta = WriteReviewCta(args: widget.args);
          if (data.reviews.isEmpty) {
            return PullToRefresh(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
              ),
            );
          }
          return PullToRefresh(
            onRefresh: _refresh,
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
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
