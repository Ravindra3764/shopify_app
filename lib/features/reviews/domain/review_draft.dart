/// A review the shopper wants to submit.
///
/// Fully typed so the submit seam (`ReviewRepository.submitReview`) is ready
/// to wire to a write provider (Judge.me / Yotpo / app-proxy) without touching
/// callers. No write path exists via the Storefront API today.
class ReviewDraft {
  const ReviewDraft({
    required this.productId,
    required this.rating,
    this.title,
    this.body,
    this.reviewerName,
    this.reviewerEmail,
  });

  /// The reviewed product's GID.
  final String productId;

  /// Rating on a 0–5 scale.
  final double rating;

  final String? title;
  final String? body;

  /// Reviewer identity, required by write providers (e.g. Judge.me). Populated
  /// from the signed-in customer at submit time.
  final String? reviewerName;
  final String? reviewerEmail;
}
