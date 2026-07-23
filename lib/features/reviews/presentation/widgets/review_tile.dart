import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/rating_stars.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

/// A single review: rating, author + date, an optional "Verified" badge, and
/// the review title/body.
///
/// ```dart
/// ReviewTile(review: review);
/// ```
class ReviewTile extends StatelessWidget {
  const ReviewTile({required this.review, super.key});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final author = review.author;
    final title = review.title;
    final body = review.body;
    final createdAt = review.createdAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(rating: review.rating),
              if (review.verified) ...[
                const SizedBox(width: AppSpacing.sm),
                const _VerifiedBadge(),
              ],
            ],
          ),
          if (title != null && title.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              if (author != null && author.isNotEmpty) author,
              if (createdAt != null) DateFormat.yMMMMd().format(createdAt),
            ].join(' · '),
            style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Small pill marking a verified-purchase review.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: AppDimensions.chipFillAlpha),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_outlined,
            size: AppDimensions.iconSm,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Verified',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
