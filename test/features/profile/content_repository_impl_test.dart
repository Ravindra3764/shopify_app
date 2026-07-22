import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/features/profile/data/content_repository_impl.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late ContentRepositoryImpl repo;

  setUp(() {
    client = MockApiClient();
    repo = ContentRepositoryImpl(client);
  });

  void stub(Map<String, dynamic> data) {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenAnswer((_) async => data);
  }

  void stubThrows(ShopifyException e) {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenThrow(e);
  }

  group('getAvailablePolicyFields', () {
    test('includes only policies whose body has real text', () async {
      stub({
        'shop': {
          'privacyPolicy': {'body': '<p>We respect your data.</p>'},
          'termsOfService': {'body': '<p>Use fairly.</p>'},
          'refundPolicy': {'body': '<p>30 days.</p>'},
          // Blank policies: empty tags / null node → excluded.
          'shippingPolicy': {'body': '<p></p>'},
          'subscriptionPolicy': null,
        },
      });

      final result = await repo.getAvailablePolicyFields();

      final fields = result.fold((f) => f, (_) => <String>{});
      expect(fields, {'privacyPolicy', 'termsOfService', 'refundPolicy'});
    });

    test('maps a ShopifyException to a Failure', () async {
      stubThrows(const ShopifyException('network down'));

      final result = await repo.getAvailablePolicyFields();

      expect(result.fold((_) => null, (f) => f), isA<Failure>());
    });
  });

  group('getPolicy', () {
    test('maps a policy node to a page with flattened body', () async {
      stub({
        'shop': {
          'refundPolicy': {
            'title': 'Return & Refund Policy',
            'body': '<p>Return within 30 days.</p><p>Contact &amp; us.</p>',
            'url': 'https://acme.example/policies/refund-policy',
          },
        },
      });

      final result = await repo.getPolicy('refundPolicy');

      final page = result.fold((p) => p, (_) => null);
      expect(page, isNotNull);
      expect(page!.title, 'Return & Refund Policy');
      expect(page.hasContent, isTrue);
      // Block tags become paragraph breaks; entities are decoded.
      expect(page.body, 'Return within 30 days.\n\nContact & us.');
      expect(page.url, 'https://acme.example/policies/refund-policy');
    });

    test('maps an unset policy (null node) to an empty-body page', () async {
      stub({
        'shop': {'shippingPolicy': null},
      });

      final result = await repo.getPolicy('shippingPolicy');

      final page = result.fold((p) => p, (_) => null);
      expect(page, isNotNull);
      expect(page!.hasContent, isFalse);
      expect(page.body, isEmpty);
    });

    test('maps a ShopifyException to a Failure', () async {
      stubThrows(const ShopifyException('network down'));

      final result = await repo.getPolicy('privacyPolicy');

      expect(result.fold((_) => null, (f) => f), isA<Failure>());
    });
  });

  group('getPage', () {
    test('maps a page node, tolerating onlineStoreUrl for the link', () async {
      stub({
        'page': {
          'title': 'About Us',
          'body': '<p>We started in 2020.</p>',
          'onlineStoreUrl': 'https://acme.example/pages/about-us',
        },
      });

      final result = await repo.getPage('about-us');

      final page = result.fold((p) => p, (_) => null);
      expect(page!.title, 'About Us');
      expect(page.body, 'We started in 2020.');
      expect(page.url, 'https://acme.example/pages/about-us');
    });

    test('maps a missing page (null) to an empty-body page', () async {
      stub({'page': null});

      final result = await repo.getPage('missing');

      final page = result.fold((p) => p, (_) => null);
      expect(page!.hasContent, isFalse);
    });
  });
}
