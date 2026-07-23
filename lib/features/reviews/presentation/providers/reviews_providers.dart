import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/reviews/data/judgeme_client.dart';
import 'package:shopify_app/features/reviews/data/judgeme_review_repository.dart';
import 'package:shopify_app/features/reviews/data/review_repository_impl.dart';
import 'package:shopify_app/features/reviews/domain/review_repository.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

/// Review repository. Uses Judge.me (read + submit) when the tenant configures
/// it, otherwise reads Storefront `product_review` metaobjects (read-only).
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.hasJudgeMe) {
    return JudgeMeReviewRepository(
      JudgeMeClient(
        shopDomain: config.judgeMeShopDomain!,
        apiToken: config.judgeMeApiToken!,
      ),
    );
  }
  return ReviewRepositoryImpl(ref.watch(apiClientProvider));
});

/// How many reviews to fetch per page.
const _pageSize = 20;

/// Accumulated, paginated reviews for one product.
class ReviewsState {
  const ReviewsState({
    this.reviews = const [],
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<ProductReview> reviews;
  final bool hasMore;
  final bool loadingMore;

  /// Mean of the loaded ratings, or `null` when none are loaded.
  double? get averageRating {
    if (reviews.isEmpty) return null;
    final sum = reviews.fold<double>(0, (total, r) => total + r.rating);
    return sum / reviews.length;
  }

  ReviewsState copyWith({
    List<ProductReview>? reviews,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return ReviewsState(
      reviews: reviews ?? this.reviews,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// A product's reviews, keyed by product GID. Rethrows `Failure` for
/// `AsyncValue.error`. Call [ReviewsNotifier.loadMore] to append the next
/// page. Auto-disposes with its last listener.
final reviewsProvider = AsyncNotifierProvider.autoDispose
    .family<ReviewsNotifier, ReviewsState, String>(ReviewsNotifier.new);

/// Loads and paginates reviews for one product.
class ReviewsNotifier
    extends AutoDisposeFamilyAsyncNotifier<ReviewsState, String> {
  String? _cursor;

  @override
  Future<ReviewsState> build(String productId) async {
    final repo = ref.watch(reviewRepositoryProvider);
    final result = await repo.getReviews(
      productId: productId,
      first: _pageSize,
    );
    final page = result.fold((p) => p, (failure) => throw failure);
    _cursor = page.endCursor;
    return ReviewsState(reviews: page.reviews, hasMore: page.hasNextPage);
  }

  /// Fetches and appends the next page. No-op while loading, at the end, or
  /// before the first page has loaded.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    final result = await ref
        .read(reviewRepositoryProvider)
        .getReviews(productId: arg, first: _pageSize, after: _cursor);
    state = AsyncData(
      result.fold(
        (page) {
          _cursor = page.endCursor;
          return ReviewsState(
            reviews: [...current.reviews, ...page.reviews],
            hasMore: page.hasNextPage,
          );
        },
        // Keep the current page on error; scrolling again retries.
        (_) => current.copyWith(loadingMore: false),
      ),
    );
  }
}
