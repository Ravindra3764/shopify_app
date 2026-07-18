import 'package:shopify_app/shopify/models/product.dart';

/// One page of search results plus the cursor needed to fetch the next.
class ProductSearchPage {
  const ProductSearchPage({
    required this.products,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<Product> products;
  final bool hasNextPage;

  /// Cursor to pass as `after` for the next page; `null` when there is none.
  final String? endCursor;
}
