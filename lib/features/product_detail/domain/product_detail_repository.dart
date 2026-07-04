import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/models/product_detail.dart';

/// Loads a single product and its recommendations for the detail screen.
abstract interface class ProductDetailRepository {
  /// Fetches the full product identified by [handle].
  Future<Result<ProductDetail, Failure>> getProduct(String handle);

  /// Fetches Shopify's related products for [productId].
  Future<Result<List<Product>, Failure>> getRecommendations(String productId);
}
