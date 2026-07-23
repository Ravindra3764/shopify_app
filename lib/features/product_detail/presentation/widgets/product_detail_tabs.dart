import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/reviews/domain/product_reviews_args.dart';
import 'package:shopify_app/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/review_tile.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/reviews_summary_card.dart';
import 'package:shopify_app/features/reviews/presentation/widgets/write_review_cta.dart';

/// Tabbed detail area: Description, an optional Reviews summary, and a
/// static Shipping & Return policy blurb.
class ProductDetailTabs extends StatefulWidget {
  const ProductDetailTabs({
    required this.description,
    super.key,
    this.productId,
    this.productTitle = '',
    this.showReviewsTab = false,
    this.averageRating,
    this.reviewsCount,
    this.shippingReturnCopy = '',
  });

  final String description;

  /// Product GID, required to load individual reviews when [showReviewsTab].
  final String? productId;
  final String productTitle;
  final bool showReviewsTab;
  final double? averageRating;
  final int? reviewsCount;

  /// Shop's shipping & refund policy copy, from `shop.shippingPolicy` /
  /// `shop.refundPolicy` on the Storefront API. Empty while loading or if
  /// the merchant hasn't configured either policy.
  final String shippingReturnCopy;

  @override
  State<ProductDetailTabs> createState() => _ProductDetailTabsState();
}

class _ProductDetailTabsState extends State<ProductDetailTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.showReviewsTab ? 3 : 2,
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _controller,
          isScrollable: true,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.only(right: AppSpacing.lg),
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.textPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            const Tab(text: 'Description'),
            if (widget.showReviewsTab) Tab(text: 'Reviews${_reviewsSuffix()}'),
            const Tab(text: 'Shipping & Return'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _TabContent(
          controller: _controller,
          children: [
            Text(
              widget.description.isEmpty
                  ? 'No description available.'
                  : widget.description,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (widget.showReviewsTab)
              _ReviewsTab(
                productId: widget.productId,
                productTitle: widget.productTitle,
                averageRating: widget.averageRating,
                reviewsCount: widget.reviewsCount,
              ),
            Text(
              widget.shippingReturnCopy.isEmpty
                  ? 'No shipping & return policy available.'
                  : widget.shippingReturnCopy,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _reviewsSuffix() =>
      widget.reviewsCount != null ? ' (${widget.reviewsCount})' : '';
}

/// Swaps content by [controller]'s index without building an actual
/// `TabBarView` (avoids fighting the outer page `ListView`'s scroll).
class _TabContent extends StatelessWidget {
  const _TabContent({required this.controller, required this.children});

  final TabController controller;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => children[controller.index],
    );
  }
}

/// Reviews tab body: the ratings summary, a preview of the latest reviews, and
/// a "See all reviews" action into the full screen. Falls back to the store's
/// aggregate rating while individual reviews load or if none are available.
class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab({
    this.productId,
    this.productTitle = '',
    this.averageRating,
    this.reviewsCount,
  });

  /// How many reviews to preview inline before "See all".
  static const _previewLimit = 3;

  final String? productId;
  final String productTitle;
  final double? averageRating;
  final int? reviewsCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    // Aggregate-only summary shown while loading, on error, or with no id.
    final aggregate = ReviewsSummaryCard(
      reviews: const [],
      averageRating: averageRating,
      reviewsCount: reviewsCount,
    );
    if (id == null || id.isEmpty) return aggregate;

    final args = ProductReviewsArgs(
      productId: id,
      productTitle: productTitle,
      averageRating: averageRating,
      reviewsCount: reviewsCount,
    );

    // Wraps the tab content with the write-review CTA (and an optional "See
    // all" link), so shoppers can review even when there are no reviews yet.
    Widget layout(Widget content, {bool showSeeAll = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        if (showSeeAll) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  context.push(AppRoutes.productReviews, extra: args),
              child: const Text('See all reviews'),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        WriteReviewCta(args: args),
      ],
    );

    return ref
        .watch(reviewsProvider(id))
        .when(
          loading: () => layout(aggregate),
          error: (_, _) => layout(aggregate),
          data: (data) {
            final preview = data.reviews.take(_previewLimit).toList();
            return layout(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReviewsSummaryCard(
                    reviews: data.reviews,
                    averageRating: averageRating,
                    reviewsCount: reviewsCount,
                  ),
                  for (final review in preview) ...[
                    const SizedBox(height: AppSpacing.md),
                    ReviewTile(review: review),
                  ],
                ],
              ),
              showSeeAll: data.reviews.length > _previewLimit || data.hasMore,
            );
          },
        );
  }
}
