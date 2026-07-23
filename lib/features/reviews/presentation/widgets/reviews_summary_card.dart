import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/rating_stars.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

/// Ratings overview: the average score with stars, a total count, and a 5→1
/// star distribution built from [reviews].
///
/// [averageRating] / [reviewsCount] fall back to the store's aggregate
/// metafields when no individual reviews are loaded, so the card still shows a
/// meaningful summary. Renders nothing when there is no rating at all.
///
/// ```dart
/// ReviewsSummaryCard(reviews: state.reviews, averageRating: avg);
/// ```
class ReviewsSummaryCard extends StatelessWidget {
  const ReviewsSummaryCard({
    required this.reviews,
    super.key,
    this.averageRating,
    this.reviewsCount,
  });

  final List<ProductReview> reviews;

  /// Aggregate average (e.g. from the `reviews.rating` metafield); used when
  /// [reviews] is empty.
  final double? averageRating;

  /// Aggregate count (e.g. from `reviews.rating_count`); used when [reviews]
  /// is empty.
  final int? reviewsCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final average = reviews.isNotEmpty
        ? reviews.fold<double>(0, (t, r) => t + r.rating) / reviews.length
        : averageRating;
    if (average == null) {
      return Text(
        'No reviews yet.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }
    final total = reviews.isNotEmpty ? reviews.length : (reviewsCount ?? 0);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              average.toStringAsFixed(1),
              style: textTheme.displaySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RatingStars(rating: average),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$total ${total == 1 ? 'review' : 'reviews'}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        if (reviews.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: _Distribution(reviews: reviews)),
        ],
      ],
    );
  }
}

/// Five stacked bars (5★ → 1★) showing the share of reviews at each rating.
class _Distribution extends StatelessWidget {
  const _Distribution({required this.reviews});

  final List<ProductReview> reviews;

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.filled(5, 0);
    for (final review in reviews) {
      final bucket = review.rating.round().clamp(1, 5);
      counts[bucket - 1]++;
    }
    final max = reviews.length;

    return Column(
      children: [
        for (var star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _DistributionRow(
              star: star,
              fraction: max == 0 ? 0 : counts[star - 1] / max,
            ),
          ),
      ],
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.star, required this.fraction});

  final int star;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(
          width: AppSpacing.md,
          child: Text(
            '$star',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: AppSpacing.sm,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.rating),
            ),
          ),
        ),
      ],
    );
  }
}
