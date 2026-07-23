import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/reviews/domain/review_draft.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

/// Reads product reviews and (when a tenant configures a write provider)
/// submits new ones. Presentation depends on this interface only; the Shopify
/// backend stays swappable.
abstract interface class ReviewRepository {
  /// Fetches one page of reviews for [productId] (a product GID), newest
  /// first. Returns an empty page for stores with no `product_review`
  /// metaobjects rather than failing.
  Future<Result<ReviewsPage, Failure>> getReviews({
    required String productId,
    int first,
    String? after,
  });

  /// Submits a review. **Not supported over the Storefront API** — the default
  /// implementation returns a `Failure`. A tenant that adopts a write provider
  /// swaps in an implementation here without changing any caller.
  Future<Result<void, Failure>> submitReview(ReviewDraft draft);
}
