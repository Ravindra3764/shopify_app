import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/promo_offer.dart';

/// Reads the tenant's advertised checkout promos (`promo_offer` metaobjects).
// ignore: one_member_abstracts
abstract interface class PromoOffersRepository {
  /// Fetches the advertised offers. Returns an empty list (not a failure) when
  /// the tenant has defined none.
  Future<Result<List<PromoOffer>, Failure>> getPromoOffers();
}
