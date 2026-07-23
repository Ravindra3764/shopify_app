import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/reviews/data/judgeme_client.dart';
import 'package:shopify_app/features/reviews/domain/review_draft.dart';
import 'package:shopify_app/features/reviews/domain/review_repository.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

/// [ReviewRepository] backed by the Judge.me REST API (read + write).
class JudgeMeReviewRepository implements ReviewRepository {
  JudgeMeReviewRepository(this._client);

  final JudgeMeClient _client;

  static const _model = 'JudgeMeReviewRepository';

  /// Shopify GID → Judge.me internal product id, cached per product for the
  /// life of the repository (avoids re-resolving on each page).
  final Map<String, int?> _internalIdCache = {};

  @override
  Future<Result<ReviewsPage, Failure>> getReviews({
    required String productId,
    int first = 20,
    String? after,
  }) async {
    try {
      final internalId = await _resolveInternalId(productId);
      // No Judge.me record for this product → no reviews yet.
      if (internalId == null) {
        return const Success(ReviewsPage(reviews: [], hasNextPage: false));
      }
      final page = int.tryParse(after ?? '1') ?? 1;
      final data = await _client.listReviews(
        productId: internalId,
        page: page,
        perPage: first,
      );
      final reviews = parseList<ProductReview>(
        data,
        'reviews',
        model: _model,
        fromItem: (item) => _reviewFrom(
          item is Map<String, dynamic> ? item : const {},
          productId,
        ),
      );
      // Judge.me paginates by page number; a full page implies more may exist.
      final hasNext = reviews.length >= first;
      return Success(
        ReviewsPage(
          reviews: reviews,
          hasNextPage: hasNext,
          endCursor: hasNext ? '${page + 1}' : null,
        ),
      );
    } on JudgeMeException catch (e) {
      return Failed(_toFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> submitReview(ReviewDraft draft) async {
    final name = draft.reviewerName;
    final email = draft.reviewerEmail;
    final body = draft.body;
    if (name == null || name.isEmpty || email == null || email.isEmpty) {
      return const Failed(AuthFailure('Sign in to submit a review.'));
    }
    if (body == null || body.trim().isEmpty) {
      return const Failed(
        ShopifyFailure('Write a few words about the product.'),
      );
    }
    try {
      await _client.createReview(
        externalProductId: _numericId(draft.productId),
        name: name,
        email: email,
        rating: draft.rating.round().clamp(1, 5),
        body: body.trim(),
        title: draft.title,
      );
      return const Success(null);
    } on JudgeMeException catch (e) {
      return Failed(_toFailure(e));
    }
  }

  Future<int?> _resolveInternalId(String productId) async {
    if (_internalIdCache.containsKey(productId)) {
      return _internalIdCache[productId];
    }
    final id = await _client.productInternalId(_numericId(productId));
    _internalIdCache[productId] = id;
    return id;
  }

  /// Extracts the trailing numeric id from a Shopify GID
  /// (`gid://shopify/Product/123` → `123`); returns the input unchanged if it
  /// is already numeric.
  static String _numericId(String gid) => gid.split('/').last;

  ProductReview _reviewFrom(Map<String, dynamic> json, String productRef) {
    final reviewer = parseMap(json, 'reviewer', model: _model);
    return ProductReview(
      id: parseString(json, 'id', model: _model),
      rating: parseDouble(json, 'rating', model: _model),
      productRef: productRef,
      author: parseStringOrNull(reviewer, 'name', model: _model),
      title: parseStringOrNull(json, 'title', model: _model),
      body: parseStringOrNull(json, 'body', model: _model),
      createdAt: parseDateTimeOrNull(json, 'created_at', model: _model),
      verified: parseBool(json, 'verified_buyer', model: _model),
    );
  }

  Failure _toFailure(JudgeMeException e) => e.statusCode == null
      ? NetworkFailure(e.message)
      : ShopifyFailure(e.message, statusCode: e.statusCode);
}
