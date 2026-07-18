import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/search/domain/product_search_page.dart';

/// Searches the Storefront catalog. Keeps presentation independent of Shopify.
// ignore: one_member_abstracts
abstract interface class SearchRepository {
  /// Returns one page of products matching [query] (Shopify full-text syntax),
  /// ordered by [sortKey]/[reverse] (Storefront `ProductSortKeys`). Pass
  /// [after] (a previous page's `endCursor`) to page forward. Yields a
  /// [Failure] on transport/GraphQL error.
  Future<Result<ProductSearchPage, Failure>> searchProducts(
    String query, {
    String? sortKey,
    bool reverse,
    String? after,
  });
}
