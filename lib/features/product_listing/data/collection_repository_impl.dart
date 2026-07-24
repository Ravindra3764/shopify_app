import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/product_listing/domain/collection_repository.dart';
import 'package:shopify_app/shopify/models/collection.dart';
import 'package:shopify_app/shopify/models/collection_summary.dart';
import 'package:shopify_app/shopify/queries/collections_queries.dart';

/// [CollectionRepository] backed by the Shopify Storefront API.
class CollectionRepositoryImpl implements CollectionRepository {
  const CollectionRepositoryImpl(this._client);

  final ApiClient _client;

  static const _productLimit = 50;

  @override
  Future<Result<Collection, Failure>> getCollection(String handle) async {
    try {
      final data = await _client.query(
        kCollectionProductsQuery,
        variables: {'handle': handle, 'first': _productLimit},
      );
      final node = parseMap(data, 'collection', model: 'CollectionRepository');
      return Success(Collection.fromJson(node));
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<List<CollectionSummary>, Failure>> getCollections({
    int first = 20,
  }) async {
    try {
      final data = await _client.query(
        kCollectionsListQuery,
        variables: {'first': first},
      );
      final conn = parseMap(data, 'collections', model: 'CollectionRepository');
      final list = parseList<CollectionSummary>(
        conn,
        'edges',
        model: 'CollectionRepository',
        fromItem: (item) {
          final edge = item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};
          return CollectionSummary.fromJson(
            parseMap(edge, 'node', model: 'CollectionRepository'),
          );
        },
      );
      return Success(list);
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }
}
