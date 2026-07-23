import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/reviews/domain/review_draft.dart';
import 'package:shopify_app/features/reviews/domain/review_repository.dart';
import 'package:shopify_app/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

const _productId = 'gid://shopify/Product/1';

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository(this._pages);

  final List<ReviewsPage> _pages;
  int _call = 0;

  @override
  Future<Result<ReviewsPage, Failure>> getReviews({
    required String productId,
    int first = 20,
    String? after,
  }) async {
    final page = _pages[_call.clamp(0, _pages.length - 1)];
    _call++;
    return Success(page);
  }

  @override
  Future<Result<void, Failure>> submitReview(ReviewDraft draft) async =>
      const Failed(ShopifyFailure('nope'));
}

class _FailingReviewRepository implements ReviewRepository {
  @override
  Future<Result<ReviewsPage, Failure>> getReviews({
    required String productId,
    int first = 20,
    String? after,
  }) async => const Failed(NetworkFailure('offline'));

  @override
  Future<Result<void, Failure>> submitReview(ReviewDraft draft) async =>
      const Failed(ShopifyFailure('nope'));
}

ProductReview _review(String id) =>
    ProductReview(id: id, rating: 4, productRef: _productId);

void main() {
  ProviderContainer makeContainer(ReviewRepository repo) {
    final container = ProviderContainer(
      overrides: [reviewRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loads the first page into data', () async {
    final container = makeContainer(
      _FakeReviewRepository([
        ReviewsPage(reviews: [_review('r1')], hasNextPage: false),
      ]),
    );

    final state = await container.read(reviewsProvider(_productId).future);

    expect(state.reviews, hasLength(1));
    expect(state.hasMore, isFalse);
  });

  test('empty store yields an empty state', () async {
    final container = makeContainer(
      _FakeReviewRepository([
        const ReviewsPage(reviews: [], hasNextPage: false),
      ]),
    );

    final state = await container.read(reviewsProvider(_productId).future);

    expect(state.reviews, isEmpty);
    expect(state.averageRating, isNull);
  });

  test('loadMore appends the next page and clears hasMore', () async {
    final container = makeContainer(
      _FakeReviewRepository([
        ReviewsPage(
          reviews: [_review('r1')],
          hasNextPage: true,
          endCursor: 'c',
        ),
        ReviewsPage(reviews: [_review('r2')], hasNextPage: false),
      ]),
    );

    await container.read(reviewsProvider(_productId).future);
    await container.read(reviewsProvider(_productId).notifier).loadMore();

    final state = container.read(reviewsProvider(_productId)).requireValue;
    expect(state.reviews.map((r) => r.id), ['r1', 'r2']);
    expect(state.hasMore, isFalse);
  });

  test('rethrows Failure as AsyncError', () async {
    final container = makeContainer(_FailingReviewRepository());

    await expectLater(
      container.read(reviewsProvider(_productId).future),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
