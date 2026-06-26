import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/home/domain/home_data.dart';
import 'package:shopify_app/features/home/domain/home_repository.dart';
import 'package:shopify_app/shopify/queries/home_queries.dart';

/// [HomeRepository] backed by the Shopify Storefront API.
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._client);

  final ApiClient _client;

  static const _bannerCount = 10;
  static const _collectionCount = 10;
  static const _productCount = 6;

  @override
  Future<Result<HomeData, Failure>> getHome() async {
    try {
      final data = await _client.query(
        kHomeQuery,
        variables: {
          'bannerCount': _bannerCount,
          'collectionCount': _collectionCount,
          'productCount': _productCount,
        },
      );
      return Success(HomeData.fromJson(data));
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }
}
