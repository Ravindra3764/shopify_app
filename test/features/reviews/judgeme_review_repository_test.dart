import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/features/reviews/data/judgeme_client.dart';
import 'package:shopify_app/features/reviews/data/judgeme_review_repository.dart';
import 'package:shopify_app/features/reviews/domain/review_draft.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

class MockJudgeMeClient extends Mock implements JudgeMeClient {}

const _gid = 'gid://shopify/Product/42';

void main() {
  late MockJudgeMeClient client;
  late JudgeMeReviewRepository repo;

  setUp(() {
    client = MockJudgeMeClient();
    repo = JudgeMeReviewRepository(client);
  });

  group('getReviews', () {
    test('maps Judge.me reviews and resolves the internal id', () async {
      when(() => client.productInternalId('42')).thenAnswer((_) async => 100);
      when(
        () => client.listReviews(
          productId: 100,
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => {
          'reviews': [
            {
              'id': 7,
              'rating': 5,
              'title': 'Superb',
              'body': 'Loved it',
              'created_at': '2026-07-01T00:00:00Z',
              'verified_buyer': true,
              'reviewer': {'name': 'Ada'},
            },
          ],
        },
      );

      final result = await repo.getReviews(productId: _gid);

      final review = result.fold((p) => p.reviews.single, (_) => null);
      expect(review, isA<ProductReview>());
      expect(review!.rating, 5.0);
      expect(review.author, 'Ada');
      expect(review.title, 'Superb');
      expect(review.verified, isTrue);
      expect(review.productRef, _gid);
    });

    test('a full page implies more, exposing the next-page cursor', () async {
      when(() => client.productInternalId('42')).thenAnswer((_) async => 100);
      when(
        () => client.listReviews(
          productId: 100,
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => {
          'reviews': List.generate(
            2,
            (i) => {
              'id': i,
              'rating': 4,
              'body': 'x',
              'reviewer': {'name': 'A'},
            },
          ),
        },
      );

      final result = await repo.getReviews(productId: _gid, first: 2);

      final page = result.fold((p) => p, (_) => null);
      expect(page!.hasNextPage, isTrue);
      expect(page.endCursor, '2');
    });

    test('no Judge.me product record yields an empty page', () async {
      when(() => client.productInternalId('42')).thenAnswer((_) async => null);

      final result = await repo.getReviews(productId: _gid);

      expect(result.fold((p) => p.reviews, (_) => null), isEmpty);
      verifyNever(
        () => client.listReviews(
          productId: any(named: 'productId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      );
    });

    test('maps a JudgeMeException to a Failure', () async {
      when(
        () => client.productInternalId('42'),
      ).thenThrow(const JudgeMeException('boom', statusCode: 500));

      final result = await repo.getReviews(productId: _gid);

      expect(result.fold((_) => null, (f) => f), isA<ShopifyFailure>());
    });
  });

  group('submitReview', () {
    test('rejects when reviewer identity is missing', () async {
      final result = await repo.submitReview(
        const ReviewDraft(productId: _gid, rating: 5, body: 'Great'),
      );

      expect(result.fold((_) => null, (f) => f), isA<AuthFailure>());
      verifyNever(
        () => client.createReview(
          externalProductId: any(named: 'externalProductId'),
          name: any(named: 'name'),
          email: any(named: 'email'),
          rating: any(named: 'rating'),
          body: any(named: 'body'),
        ),
      );
    });

    test('rejects an empty body', () async {
      final result = await repo.submitReview(
        const ReviewDraft(
          productId: _gid,
          rating: 5,
          body: '   ',
          reviewerName: 'Ada',
          reviewerEmail: 'ada@x.com',
        ),
      );

      expect(result.isSuccess, isFalse);
    });

    test('creates the review with the numeric product id', () async {
      when(
        () => client.createReview(
          externalProductId: any(named: 'externalProductId'),
          name: any(named: 'name'),
          email: any(named: 'email'),
          rating: any(named: 'rating'),
          body: any(named: 'body'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.submitReview(
        const ReviewDraft(
          productId: _gid,
          rating: 4,
          title: 'Nice',
          body: 'Works well',
          reviewerName: 'Ada',
          reviewerEmail: 'ada@x.com',
        ),
      );

      expect(result.isSuccess, isTrue);
      verify(
        () => client.createReview(
          externalProductId: '42',
          name: 'Ada',
          email: 'ada@x.com',
          rating: 4,
          body: 'Works well',
          title: 'Nice',
        ),
      ).called(1);
    });

    test('maps a JudgeMeException to a Failure', () async {
      when(
        () => client.createReview(
          externalProductId: any(named: 'externalProductId'),
          name: any(named: 'name'),
          email: any(named: 'email'),
          rating: any(named: 'rating'),
          body: any(named: 'body'),
          title: any(named: 'title'),
        ),
      ).thenThrow(const JudgeMeException('offline'));

      final result = await repo.submitReview(
        const ReviewDraft(
          productId: _gid,
          rating: 4,
          body: 'Works well',
          reviewerName: 'Ada',
          reviewerEmail: 'ada@x.com',
        ),
      );

      expect(result.fold((_) => null, (f) => f), isA<NetworkFailure>());
    });
  });
}
