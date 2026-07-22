import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/core/utils/text_utils.dart';
import 'package:shopify_app/features/profile/domain/content_repository.dart';
import 'package:shopify_app/shopify/models/shop_content_page.dart';
import 'package:shopify_app/shopify/queries/content_queries.dart';

/// [ContentRepository] backed by the Shopify Storefront API.
class ContentRepositoryImpl implements ContentRepository {
  const ContentRepositoryImpl(this._client);

  final ApiClient _client;

  static const _model = 'ContentRepository';

  @override
  Future<Result<Set<String>, Failure>> getAvailablePolicyFields() async {
    try {
      final data = await _client.query(kShopPolicyLinksQuery);
      final shop = parseMap(data, 'shop', model: _model);
      // Storefront returns a non-null node even for a blank policy, so treat a
      // policy as "set" only when its body has real text after stripping HTML.
      final available = <String>{};
      for (final entry in shop.entries) {
        final node = entry.value;
        if (node is! Map<String, dynamic>) continue;
        final body = parseStringOrNull(node, 'body', model: _model);
        if (body != null && htmlToPlainText(body).isNotEmpty) {
          available.add(entry.key);
        }
      }
      return Success(available);
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<ShopContentPage, Failure>> getPolicy(String field) async {
    try {
      final data = await _client.query(shopPolicyQuery(field));
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
