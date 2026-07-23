import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/checkout/domain/promo_offers_repository.dart';
import 'package:shopify_app/shopify/models/promo_offer.dart';
import 'package:shopify_app/shopify/queries/promo_queries.dart';

/// [PromoOffersRepository] backed by Storefront `promo_offer` metaobjects.
class PromoOffersRepositoryImpl implements PromoOffersRepository {
  const PromoOffersRepositoryImpl(this._client);

  final ApiClient _client;

  /// Upper bound on advertised offers fetched in one round trip.
  static const _first = 20;

  static const _model = 'PromoOffersRepositoryImpl';

  @override
  Future<Result<List<PromoOffer>, Failure>> getPromoOffers() async {
    try {
      final data = await _client.query(
        kPromoOffersQuery,
        variables: {'first': _first},
      );
      final connection = parseMap(data, 'metaobjects', model: _model);
      final offers = parseList<PromoOffer>(
        connection,
        'edges',
        model: _model,
        fromItem: (item) {
          final edge =
              item is Map<String, dynamic> ? item : <String, dynamic>{};
          return PromoOffer.fromJson(parseMap(edge, 'node', model: _model));
        },
      );
      // Drop malformed entries (a metaobject with no code can't be applied).
      return Success([
        for (final offer in offers)
          if (offer.code.isNotEmpty) offer,
      ]);
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }
}
