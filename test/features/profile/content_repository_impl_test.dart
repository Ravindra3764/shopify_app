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

  group('getPrivacyPolicy', () {
    test('maps a policy node to a page with flattened body', () async {
      stub({
        'shop': {
          'privacyPolicy': {
            'title': 'Privacy Policy',
            'body': '<p>We respect your data.</p><p>Contact &amp; us.</p>',
            'url': 'https://acme.example/policies/privacy-policy',
          },
        },
      });

      final result = await repo.getPrivacyPolicy();

      final page = result.fold((p) => p, (_) => null);
      expect(page, isNotNull);
      expect(page!.title, 'Privacy Policy');
      expect(page.hasContent, isTrue);
      // Block tags become paragraph breaks; entities are decoded.
      expect(page.body, 'We respect your data.\n\nContact & us.');
      expect(page.url, 'https://acme.example/policies/privacy-policy');
    });

    test('maps an unset policy (null node) to an empty-body page', () async {
      stub({
        'shop': {'privacyPolicy': null},
      });

      final result = await repo.getPrivacyPolicy();

      final page = result.fold((p) => p, (_) => null);
      expect(page, isNotNull);
      expect(page!.hasContent, isFalse);
      expect(page.body, isEmpty);
    });

    test('maps a ShopifyException to a Failure', () async {
      stubThrows(const ShopifyException('network down'));

      final result = await repo.getPrivacyPolicy();

      final failure = result.fold((_) => null, (f) => f);
      expect(failure, isA<Failure>());
    });
  });

  group('getTermsOfService', () {
    test('reads the termsOfService field', () async {
      stub({
        'shop': {
          'termsOfService': {
            'title': 'Terms of Service',
            'body': '<p>Use the store fairly.</p>',
            'url': 'https://acme.example/policies/terms-of-service',
          },
        },
      });

      final result = await repo.getTermsOfService();

      final page = result.fold((p) => p, (_) => null);
      expect(page!.title, 'Terms of Service');
      expect(page.body, 'Use the store fairly.');
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
