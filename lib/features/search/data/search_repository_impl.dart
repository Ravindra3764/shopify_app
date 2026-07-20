import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/search/domain/product_search_page.dart';
import 'package:shopify_app/features/search/domain/search_repository.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/queries/search_queries.dart';

/// [SearchRepository] backed by the Shopify Storefront API.
class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._client);

  final ApiClient _client;

  static const _model = 'SearchRepository';
  static const _pageSize = 20;

  @override
  Future<Result<ProductSearchPage, Failure>> searchProducts(
    String query, {
    String? sortKey,
    bool reverse = false,
    String? after,
  }) async {
    try {
      final data = await _client.query(
        kSearchProductsQuery,
        variables: {
          'query': query,
          'first': _pageSize,
          if (after != null) 'after': after,
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
      final pageInfo = parseMap(connection, 'pageInfo', model: _model);
      return Success(
        ProductSearchPage(
          products: products,
          hasNextPage: parseBool(pageInfo, 'hasNextPage', model: _model),
          endCursor: parseStringOrNull(pageInfo, 'endCursor', model: _model),
        ),
      );
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }
}
