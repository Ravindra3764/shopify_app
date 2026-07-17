import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/features/checkout/data/checkout_repository_impl.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late CheckoutRepositoryImpl repo;

  const address = MailingAddress(
    id: 'addr_1',
    firstName: 'Ada',
    lastName: 'Lovelace',
    address1: '1 Analytical Way',
    city: 'London',
    province: 'CA',
    zip: '94016',
    country: 'US',
  );

  final cartNode =
      jsonDecode(
            File('test/fixtures/cart_with_delivery.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  setUp(() {
    client = MockApiClient();
    repo = CheckoutRepositoryImpl(client);
  });

  group('updateBuyerAddress', () {
    test('maps a successful payload to a Cart with delivery groups', () async {
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenAnswer(
        (_) async => {
          'cartBuyerIdentityUpdate': {
            'cart': cartNode,
            'userErrors': <dynamic>[],
          },
        },
      );

      final result = await repo.updateBuyerAddress(
        'gid://shopify/Cart/abc123',
        email: 'shopper@example.com',
        address: address,
      );

      final cart = result.fold((c) => c, (_) => null);
      expect(cart, isNotNull);
      expect(cart!.deliveryGroups, hasLength(1));
      expect(cart.deliveryGroups.first.options, hasLength(2));
      expect(cart.selectedShipping?.amount, 5.0);
      expect(cart.buyerEmail, 'shopper@example.com');
      expect(cart.tax?.amount, 5.40);
    });

    test('maps userErrors to a ShopifyFailure', () async {
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenAnswer(
        (_) async => {
          'cartBuyerIdentityUpdate': {
            'cart': null,
            'userErrors': [
              {'field': 'address', 'message': 'Address is undeliverable'},
            ],
          },
        },
      );

      final result = await repo.updateBuyerAddress(
        'gid://shopify/Cart/abc123',
        email: 'shopper@example.com',
        address: address,
      );

      final failure = result.fold((_) => null, (f) => f);
      expect(failure, isA<ShopifyFailure>());
      expect(failure!.message, 'Address is undeliverable');
    });

    test('maps a ShopifyException to a Failure', () async {
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenThrow(const ShopifyException('boom', statusCode: 500));

      final result = await repo.updateBuyerAddress(
        'gid://shopify/Cart/abc123',
        email: 'shopper@example.com',
        address: address,
      );

      expect(result.isSuccess, isFalse);
      expect(result.fold((_) => null, (f) => f), isA<Failure>());
    });
  });

  group('selectDeliveryOption', () {
    test('maps a successful payload to a Cart', () async {
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenAnswer(
        (_) async => {
          'cartSelectedDeliveryOptionsUpdate': {
            'cart': cartNode,
            'userErrors': <dynamic>[],
          },
        },
      );

      final result = await repo.selectDeliveryOption(
        'gid://shopify/Cart/abc123',
        deliveryGroupId: 'gid://shopify/CartDeliveryGroup/g1',
        optionHandle: 'standard',
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
