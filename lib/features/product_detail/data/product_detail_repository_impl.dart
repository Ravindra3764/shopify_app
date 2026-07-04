import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/features/product_detail/domain/product_detail_repository.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/models/product_detail.dart';
import 'package:shopify_app/shopify/queries/products_queries.dart';

/// [ProductDetailRepository] backed by the Shopify Storefront API.
class ProductDetailRepositoryImpl implements ProductDetailRepository {
  const ProductDetailRepositoryImpl(this._client);

  final ApiClient _client;

  static const _variantsLimit = 100;
  static const _imagesLimit = 20;

  @override
  Future<Result<ProductDetail, Failure>> getProduct(String handle) async {
    try {
      final data = await _client.query(
        kProductByHandleQuery,
        variables: {
          'handle': handle,
          'variantsFirst': _variantsLimit,
          'imagesFirst': _imagesLimit,
        },
      );
      final node = parseMap(data, 'product', model: 'ProductDetailRepository');
      return Success(ProductDetail.fromJson(node));
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }

  @override
  Future<Result<List<Product>, Failure>> getRecommendations(
    String productId,
  ) async {
    try {
      final data = await _client.query(
        kProductRecommendationsQuery,
        variables: {'productId': productId},
      );
      final nodes = parseList<Product>(
        data,
        'productRecommendations',
        model: 'ProductDetailRepository',
        fromItem: (item) => Product.fromJson(
          item is Map<String, dynamic> ? item : <String, dynamic>{},
        ),
      );
      return Success(nodes);
    } on ShopifyException catch (e) {
      return Failed(Failure.fromShopify(e));
    }
  }
}
