import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/search/domain/search_repository.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/queries/search_queries.dart';

/// [SearchRepository] backed by the Shopify Storefront API.
class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._client);

  final ApiClient _client;

  static const _model = 'SearchRepository';
  static const _limit = 30;

  @override
  Future<Result<List<Product>, Failure>> searchProducts(
    String query, {
    String? sortKey,
    bool reverse = false,
  }) async {
    try {
      final data = await _client.query(
        kSearchProductsQuery,
        variables: {
          'query': query,
          'first': _limit,
          if (sortKey != null) 'sortKey': sortKey,
          'reverse': reverse,
        },
      );
      final connection = parseMap(data, 'products', model: _model);
      final products = parseList<Product>(
        connection,
        'edges',
        model: _model,
        fromItem: (item) {
          final edge = item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};
          return Product.fromJson(parseMap(edge, 'node', model: _model));
        },
      );
      return Success(products);
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }
}
