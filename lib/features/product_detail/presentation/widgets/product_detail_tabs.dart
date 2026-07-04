import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/rating_stars.dart';

/// Tabbed detail area: Description, an optional Reviews summary, and a
/// static Shipping & Return policy blurb.
class ProductDetailTabs extends StatefulWidget {
  const ProductDetailTabs({
    required this.description,
    super.key,
    this.showReviewsTab = false,
    this.averageRating,
    this.reviewsCount,
  });

  final String description;
  final bool showReviewsTab;
  final double? averageRating;
  final int? reviewsCount;

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
              _ReviewsSummary(
                averageRating: widget.averageRating,
                reviewsCount: widget.reviewsCount,
              ),
            Text(
              _shippingReturnCopy,
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

class _ReviewsSummary extends StatelessWidget {
  const _ReviewsSummary({this.averageRating, this.reviewsCount});

  final double? averageRating;
  final int? reviewsCount;

  @override
  Widget build(BuildContext context) {
    if (averageRating == null) {
      return Text(
        'No reviews yet.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }
    return RatingStars(rating: averageRating!, reviewCount: reviewsCount);
  }
}

const String _shippingReturnCopy =
    'Orders ship within 2-3 business days. Delivery typically takes 5-7 '
    'business days depending on your location.\n\n'
    'Not the right fit? Return unworn items within 30 days of delivery for '
    'a full refund.';
