import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/reviews/domain/review_draft.dart';
import 'package:shopify_app/features/reviews/domain/review_repository.dart';
import 'package:shopify_app/shopify/models/product_review.dart';
import 'package:shopify_app/shopify/queries/reviews_queries.dart';

/// [ReviewRepository] backed by the Shopify Storefront API (read-only).
class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl(this._client);

  final ApiClient _client;

  static const _model = 'ReviewRepository';

  @override
  Future<Result<ReviewsPage, Failure>> getReviews({
    required String productId,
    int first = 20,
    String? after,
  }) async {
    try {
      final data = await _client.query(
        kProductReviewsQuery,
        variables: {'first': first, 'after': after},
      );
      final connection = parseMap(data, 'metaobjects', model: _model);
      final all = parseList<ProductReview>(
        connection,
        'edges',
        model: _model,
        fromItem: (edge) => ProductReview.fromMetaobject(
          parseMap(
            edge is Map<String, dynamic> ? edge : const {},
            'node',
            model: _model,
          ),
        ),
      );
      // The Storefront `metaobjects` connection can't filter by field, so keep
      // only reviews whose `product` reference matches this product.
      final reviews = all
          .where((review) => review.productRef == productId)
          .toList()
        ..sort(_newestFirst);
      final pageInfo = parseMap(connection, 'pageInfo', model: _model);
      return Success(
        ReviewsPage(
          reviews: reviews,
          hasNextPage: parseBool(pageInfo, 'hasNextPage', model: _model),
          endCursor: parseStringOrNull(pageInfo, 'endCursor', model: _model),
        ),
      );
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<void, Failure>> submitReview(ReviewDraft draft) async {
    // The Storefront API is read-only; writing a review needs a dedicated
    // provider (Admin API / app-proxy / Judge.me / Yotpo). Until a tenant
    // wires one in, submission is unavailable rather than silently faked.
    return const Failed(
      ShopifyFailure('Review submission is not configured for this store.'),
    );
  }

  /// Newest first; reviews without a date sort last.
  static int _newestFirst(ProductReview a, ProductReview b) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }
}
