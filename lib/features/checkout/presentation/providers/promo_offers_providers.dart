import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/checkout/data/promo_offers_repository_impl.dart';
import 'package:shopify_app/features/checkout/domain/promo_offers_repository.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/promo_offer.dart';

/// Repository for advertised checkout promos (Storefront `promo_offer`
/// metaobjects).
final promoOffersRepositoryProvider = Provider<PromoOffersRepository>(
  (ref) => PromoOffersRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The tenant's advertised checkout offers. Auto-disposes with its last
/// listener. Rethrows `Failure` for `AsyncValue.error`; the checkout treats
/// offers as non-critical and renders nothing while loading or on error.
final promoOffersProvider =
    AsyncNotifierProvider.autoDispose<PromoOffersNotifier, List<PromoOffer>>(
      PromoOffersNotifier.new,
    );

/// Loads the advertised offers once per listener.
class PromoOffersNotifier extends AutoDisposeAsyncNotifier<List<PromoOffer>> {
  @override
  Future<List<PromoOffer>> build() async {
    final repo = ref.watch(promoOffersRepositoryProvider);
    final result = await repo.getPromoOffers();
    return result.fold((offers) => offers, (failure) => throw failure);
  }
}
