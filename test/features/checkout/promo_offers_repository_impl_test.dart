import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/features/checkout/data/promo_offers_repository_impl.dart';

class MockApiClient extends Mock implements ApiClient {}

Map<String, dynamic> _node({
  String? code,
  String? label,
  String? minSubtotal,
}) => {
  'node': {
    'id': 'gid://shopify/Metaobject/1',
    if (code != null) 'code': {'value': code},
    if (label != null) 'label': {'value': label},
    if (minSubtotal != null) 'minSubtotal': {'value': minSubtotal},
  },
};

void main() {
  late MockApiClient client;
  late PromoOffersRepositoryImpl repo;

  setUp(() {
    client = MockApiClient();
    repo = PromoOffersRepositoryImpl(client);
  });

  void stub(List<Map<String, dynamic>> edges) {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenAnswer(
      (_) async => {
        'metaobjects': {'edges': edges},
      },
    );
  }

  test('maps promo_offer metaobjects to PromoOffer', () async {
    stub([
      _node(code: 'SAVE10', label: '10% off', minSubtotal: '999.0'),
      _node(code: 'FREESHIP', label: 'Free shipping'),
    ]);

    final result = await repo.getPromoOffers();
    final offers = result.fold((o) => o, (_) => null);

    expect(result.isSuccess, isTrue);
    expect(offers, hasLength(2));
    expect(offers!.first.code, 'SAVE10');
    expect(offers.first.minSubtotal, 999.0);
    expect(offers[1].minSubtotal, isNull);
  });

  test('drops entries with no code', () async {
    stub([
      _node(label: 'orphan'),
      _node(code: 'WELCOME'),
    ]);

    final result = await repo.getPromoOffers();
    final offers = result.fold((o) => o, (_) => null);

    expect(offers!.map((o) => o.code), ['WELCOME']);
  });

  test('returns an empty list for a store with no promo_offer definition',
      () async {
    stub(const []);

    final result = await repo.getPromoOffers();
    expect(result.fold((o) => o, (_) => null), isEmpty);
  });

  test('maps a ShopifyException to a Failure', () async {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenThrow(const ShopifyException('boom', statusCode: 500));

    final result = await repo.getPromoOffers();
    expect(result.isSuccess, isFalse);
    expect(result.fold((_) => null, (f) => f), isA<Failure>());
  });
}
