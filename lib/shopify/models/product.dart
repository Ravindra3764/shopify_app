import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// Storefront product summary as shown in listings / cards.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.handle,
    required this.availableForSale,
    required this.price,
    this.featuredImage,
    this.compareAtPrice,
    this.firstVariantId,
  });

  /// Builds from a Storefront `Product` node.
  factory Product.fromJson(Map<String, dynamic> json) {
    final priceMap = parseMap(
      parseMap(json, 'priceRange', model: _model),
      'minVariantPrice',
      model: _model,
    );
    final compareMap = parseMap(
      parseMap(json, 'compareAtPriceRange', model: _model),
      'minVariantPrice',
      model: _model,
    );
    final compareAt = compareMap.isEmpty ? null : Money.fromJson(compareMap);

    // First purchasable variant id — used for quick-add from a card. Null when
    // the summary query didn't request variants (or the product has none).
    final variantIds = parseList<String>(
      parseMap(json, 'variants', model: _model),
      'nodes',
      model: _model,
      fromItem: (item) =>
          item is Map<String, dynamic> ? (item['id'] as String? ?? '') : '',
    ).where((id) => id.isNotEmpty);

    return Product(
      id: parseString(json, 'id', model: _model),
      title: parseString(json, 'title', model: _model),
      handle: parseString(json, 'handle', model: _model),
      availableForSale: parseBool(json, 'availableForSale', model: _model),
      price: Money.fromJson(priceMap),
      featuredImage: ShopifyImage.fromJsonOrNull(
        parseMap(json, 'featuredImage', model: _model),
      ),
      // Treat a zero compare-at as "no discount".
      compareAtPrice: (compareAt != null && compareAt.isPositive)
          ? compareAt
          : null,
      firstVariantId: variantIds.isEmpty ? null : variantIds.first,
    );
  }

  /// Serializes back to the Storefront `Product` shape [Product.fromJson]
  /// reads, so a cached product (e.g. a wishlist entry) round-trips losslessly.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'handle': handle,
    'availableForSale': availableForSale,
    'priceRange': {'minVariantPrice': price.toJson()},
    'compareAtPriceRange': {'minVariantPrice': compareAtPrice?.toJson()},
    'featuredImage': featuredImage?.toJson(),
    if (firstVariantId != null)
      'variants': {
        'nodes': [
          {'id': firstVariantId},
        ],
      },
  };

  static const _model = 'Product';

  final String id;
  final String title;
  final String handle;
  final bool availableForSale;
  final Money price;
  final ShopifyImage? featuredImage;
  final Money? compareAtPrice;

  /// Id of the first purchasable variant, for quick-add from a card. Null when
  /// the summary query didn't request variants — quick-add is then unavailable.
  final String? firstVariantId;

  /// Whether [compareAtPrice] marks a genuine markdown over [price].
  bool get isOnSale =>
      compareAtPrice != null && compareAtPrice!.amount > price.amount;
}
