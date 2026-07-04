import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/models/product_detail.dart';
import 'package:shopify_app/shopify/models/shop_policies.dart';

/// Loads a single product, its recommendations, and shop-wide policy copy
/// for the detail screen.
abstract interface class ProductDetailRepository {
  /// Fetches the full product identified by [handle].
  Future<Result<ProductDetail, Failure>> getProduct(String handle);

  /// Fetches Shopify's related products for [productId].
  Future<Result<List<Product>, Failure>> getRecommendations(String productId);

  /// Fetches the shop's shipping & refund policy text (Settings → Policies
  /// in Shopify admin) for the "Shipping & Return" tab.
  Future<Result<ShopPolicies, Failure>> getShopPolicies();
}
