import 'package:shopify_app/core/utils/json_parse.dart';

/// A single customer review of a product, read from a `product_review`
/// Shopify metaobject via the Storefront API.
class ProductReview {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.productRef,
    this.author,
    this.title,
    this.body,
    this.createdAt,
    this.verified = false,
  });

  /// Builds from a Storefront metaobject node (`{id, handle, fields}` where
  /// `fields` is a `[{key, value}]` list). Unknown/missing fields degrade to
  /// null rather than throwing.
  factory ProductReview.fromMetaobject(Map<String, dynamic> node) {
    final fields = _flattenFields(node);
    return ProductReview(
      id: parseString(node, 'id', model: _model),
      rating: parseDouble(fields, 'rating', model: _model),
      productRef: parseStringOrNull(fields, 'product', model: _model) ?? '',
      author: parseStringOrNull(fields, 'author', model: _model),
      title: parseStringOrNull(fields, 'title', model: _model),
      body: parseStringOrNull(fields, 'body', model: _model),
      createdAt: parseDateTimeOrNull(fields, 'created_at', model: _model),
      verified: parseBool(fields, 'verified', model: _model),
    );
  }

  static const _model = 'ProductReview';

  /// Flattens the metaobject `fields: [{key, value}]` list into a
  /// `{key: value}` map the `parse*` helpers can read directly.
  static Map<String, dynamic> _flattenFields(Map<String, dynamic> node) {
    final out = <String, dynamic>{};
    final raw = node['fields'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final key = item['key'];
          if (key is String) out[key] = item['value'];
        }
      }
    }
    return out;
  }

  final String id;

  /// Rating on a 0–5 scale.
  final double rating;

  /// The reviewed product's GID (`gid://shopify/Product/…`), used to match a
  /// review to its product.
  final String productRef;

  final String? author;
  final String? title;
  final String? body;
  final DateTime? createdAt;

  /// Whether the merchant marked this as a verified purchase.
  final bool verified;
}

/// One page of a product's reviews, mirroring the Storefront connection shape.
class ReviewsPage {
  const ReviewsPage({
    required this.reviews,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<ProductReview> reviews;
  final bool hasNextPage;
  final String? endCursor;
}
