import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/profile/domain/content_repository.dart';
import 'package:shopify_app/shopify/models/shop_content_page.dart';
import 'package:shopify_app/shopify/queries/content_queries.dart';

/// [ContentRepository] backed by the Shopify Storefront API.
class ContentRepositoryImpl implements ContentRepository {
  const ContentRepositoryImpl(this._client);

  final ApiClient _client;

  static const _model = 'ContentRepository';

  @override
  Future<Result<ShopContentPage, Failure>> getPrivacyPolicy() =>
      _policy(kPrivacyPolicyQuery, 'privacyPolicy');

  @override
  Future<Result<ShopContentPage, Failure>> getTermsOfService() =>
      _policy(kTermsOfServiceQuery, 'termsOfService');

  /// Reads a single `shop.<field>` policy node into a [ShopContentPage]. An
  /// unset policy comes back as an empty node → an empty-body page.
  Future<Result<ShopContentPage, Failure>> _policy(
    String query,
    String field,
  ) async {
    try {
      final data = await _client.query(query);
      final shop = parseMap(data, 'shop', model: _model);
      final node = parseMap(shop, field, model: _model);
      return Success(ShopContentPage.fromJson(node));
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<ShopContentPage, Failure>> getPage(String handle) async {
    try {
      final data = await _client.query(
        kContentPageQuery,
        variables: {'handle': handle},
      );
      final node = parseMap(data, 'page', model: _model);
      return Success(ShopContentPage.fromJson(node));
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }
}
