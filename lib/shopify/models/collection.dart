import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// Storefront collection with its first page of [products].
class Collection {
  const Collection({
    required this.handle,
    required this.title,
    required this.products,
    this.image,
  });

  /// Builds from a Storefront `Collection` node (with nested `products` edges).
  factory Collection.fromJson(Map<String, dynamic> json) {
    final productsConn = parseMap(json, 'products', model: _model);
    return Collection(
      handle: parseString(json, 'handle', model: _model),
      title: parseString(json, 'title', model: _model),
      image: ShopifyImage.fromJsonOrNull(
        parseMap(json, 'image', model: _model),
      ),
      products: parseList<Product>(
        productsConn,
        'edges',
        model: _model,
        fromItem: (item) {
          final edge = item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};
          return Product.fromJson(parseMap(edge, 'node', model: _model));
        },
      ),
    );
  }

  static const _model = 'Collection';

  final String handle;
  final String title;
  final List<Product> products;
  final ShopifyImage? image;
}
