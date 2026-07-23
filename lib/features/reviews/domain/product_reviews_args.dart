/// Navigation payload for the full reviews screen: which product to load,
/// plus the store's aggregate rating so the summary shows immediately even
/// before individual reviews finish loading.
class ProductReviewsArgs {
  const ProductReviewsArgs({
    required this.productId,
    required this.productTitle,
    this.averageRating,
    this.reviewsCount,
  });

  /// Product GID to fetch reviews for.
  final String productId;
  final String productTitle;

  /// Aggregate average from the `reviews.rating` metafield, if any.
  final double? averageRating;

  /// Aggregate count from the `reviews.rating_count` metafield, if any.
  final int? reviewsCount;
}
