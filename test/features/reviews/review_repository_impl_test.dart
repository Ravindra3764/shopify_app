import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/features/reviews/data/review_repository_impl.dart';
import 'package:shopify_app/features/reviews/domain/review_draft.dart';
import 'package:shopify_app/shopify/models/product_review.dart';

class MockApiClient extends Mock implements ApiClient {}

Map<String, dynamic> _reviewNode({
  required String id,
  required String product,
  required String rating,
  String? author,
  String? title,
  String? body,
  String? createdAt,
  String? verified,
}) => {
  'node': {
    'id': id,
    'handle': id,
    'fields': [
      {'key': 'product', 'value': product},
      {'key': 'rating', 'value': rating},
      if (author != null) {'key': 'author', 'value': author},
      if (title != null) {'key': 'title', 'value': title},
      if (body != null) {'key': 'body', 'value': body},
      if (createdAt != null) {'key': 'created_at', 'value': createdAt},
      if (verified != null) {'key': 'verified', 'value': verified},
    ],
  },
};

void main() {
  const productId = 'gid://shopify/Product/1';
  late MockApiClient client;
  late ReviewRepositoryImpl repo;

  setUp(() {
    client = MockApiClient();
    repo = ReviewRepositoryImpl(client);
  });

  void stub(Map<String, dynamic> data) {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenAnswer((_) async => data);
  }

  test('maps metaobjects to reviews and filters to the product', () async {
    stub({
      'metaobjects': {
        'pageInfo': {'hasNextPage': true, 'endCursor': 'c1'},
        'edges': [
          _reviewNode(
            id: 'r1',
            product: productId,
            rating: '5',
            author: 'Ada',
            title: 'Great',
            body: 'Loved it',
            createdAt: '2026-07-01T10:00:00Z',
            verified: 'true',
          ),
          // Belongs to another product — must be filtered out.
          _reviewNode(
            id: 'r2',
            product: 'gid://shopify/Product/999',
            rating: '2',
          ),
        ],
      },
    });

    final result = await repo.getReviews(productId: productId);

    final page = result.fold((p) => p, (_) => null);
    expect(page, isNotNull);
    expect(page!.hasNextPage, isTrue);
    expect(page.endCursor, 'c1');
    expect(page.reviews, hasLength(1));

    final review = page.reviews.single;
    expect(review.rating, 5.0);
    expect(review.author, 'Ada');
    expect(review.title, 'Great');
    expect(review.verified, isTrue);
    expect(review.createdAt, isNotNull);
  });

  test('sorts reviews newest first', () async {
    stub({
      'metaobjects': {
        'pageInfo': {'hasNextPage': false, 'endCursor': null},
        'edges': [
          _reviewNode(
            id: 'old',
            product: productId,
            rating: '3',
            createdAt: '2026-01-01T00:00:00Z',
          ),
          _reviewNode(
            id: 'new',
            product: productId,
            rating: '4',
            createdAt: '2026-07-01T00:00:00Z',
          ),
        ],
      },
    });

    final result = await repo.getReviews(productId: productId);

    final reviews = result.fold((p) => p.reviews, (_) => <ProductReview>[]);
    expect(reviews.first.id, 'new');
    expect(reviews.last.id, 'old');
  });

  test('returns an empty page for a store with no metaobjects', () async {
    stub({
      'metaobjects': {
        'pageInfo': {'hasNextPage': false, 'endCursor': null},
        'edges': <dynamic>[],
      },
    });

    final result = await repo.getReviews(productId: productId);

    expect(result.fold((p) => p.reviews, (_) => null), isEmpty);
  });

  test('maps a ShopifyException to a Failure', () async {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenThrow(const ShopifyException('boom'));

    final result = await repo.getReviews(productId: productId);

    expect(result.fold((_) => null, (f) => f), isA<Failure>());
  });

  test('submitReview is not configured over Storefront', () async {
    final result = await repo.submitReview(
      const ReviewDraft(productId: productId, rating: 5),
    );

    expect(result.isSuccess, isFalse);
    expect(result.fold((_) => null, (f) => f), isA<ShopifyFailure>());
  });
}
