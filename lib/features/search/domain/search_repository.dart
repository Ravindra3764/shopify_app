import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// Searches the Storefront catalog. Keeps presentation independent of Shopify.
// ignore: one_member_abstracts
abstract interface class SearchRepository {
  /// Returns products matching [query] (Shopify full-text syntax), or a
  /// [Failure] on transport/GraphQL error.
  Future<Result<List<Product>, Failure>> searchProducts(String query);
}
