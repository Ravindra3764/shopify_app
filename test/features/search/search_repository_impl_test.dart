import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/features/search/data/search_repository_impl.dart';

class MockApiClient extends Mock implements ApiClient {}

Map<String, dynamic> _productNode(String id) => {
  'id': 'gid://shopify/Product/$id',
  'title': 'Aviator $id',
  'handle': 'aviator-$id',
  'availableForSale': true,
  'featuredImage': {'url': 'https://cdn/$id.png', 'altText': null},
  'priceRange': {
    'minVariantPrice': {'amount': '150.0', 'currencyCode': 'INR'},
  },
  'compareAtPriceRange': {
    'minVariantPrice': {'amount': '0.0', 'currencyCode': 'INR'},
  },
};

void main() {
  late MockApiClient client;
  late SearchRepositoryImpl repo;

  setUp(() {
    client = MockApiClient();
    repo = SearchRepositoryImpl(client);
  });

  group('searchProducts', () {
    test('maps a products connection to a list of Product', () async {
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenAnswer(
        (_) async => {
          'products': {
            'edges': [
              {'node': _productNode('1')},
              {'node': _productNode('2')},
            ],
          },
        },
      );

      final result = await repo.searchProducts('aviator');
      final products = result.fold((p) => p, (_) => null);

      expect(result.isSuccess, isTrue);
      expect(products, hasLength(2));
      expect(products!.first.title, 'Aviator 1');
      expect(products.first.handle, 'aviator-1');
    });

    test('returns an empty list when there are no matches', () async {
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenAnswer(
        (_) async => {
          'products': {'edges': <dynamic>[]},
        },
      );

      final result = await repo.searchProducts('zzzzz');

      expect(result.isSuccess, isTrue);
      expect(result.fold((p) => p, (_) => null), isEmpty);
    });

    test('maps a ShopifyException to a Failure', () async {
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenThrow(const ShopifyException('boom', statusCode: 500));

      final result = await repo.searchProducts('aviator');

      expect(result.isSuccess, isFalse);
      expect(result.fold((_) => null, (f) => f), isNotNull);
    });
  });
}
