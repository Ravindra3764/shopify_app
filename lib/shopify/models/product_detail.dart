import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/core/utils/text_utils.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/product_option.dart';
import 'package:shopify_app/shopify/models/product_variant.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// Full Storefront `Product` for the product-detail screen: gallery,
/// options, variants, and description.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.title,
    required this.handle,
    required this.availableForSale,
    required this.price,
    required this.images,
    required this.options,
    required this.variants,
    this.vendor,
    this.description,
    this.compareAtPrice,
    this.averageRating,
    this.reviewsCount,
  });

  /// Builds from a Storefront `Product` node.
  factory ProductDetail.fromJson(Map<String, dynamic> json) {
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
    final descriptionHtml = parseStringOrNull(
      json,
      'descriptionHtml',
      model: _model,
    );

    return ProductDetail(
      id: parseString(json, 'id', model: _model),
      title: parseString(json, 'title', model: _model),
      handle: parseString(json, 'handle', model: _model),
      vendor: parseStringOrNull(json, 'vendor', model: _model),
      availableForSale: parseBool(json, 'availableForSale', model: _model),
      description: descriptionHtml == null
          ? null
          : stripHtmlTags(descriptionHtml),
      price: Money.fromJson(priceMap),
      compareAtPrice: (compareAt != null && compareAt.isPositive)
          ? compareAt
          : null,
      images: parseList<ShopifyImage>(
        parseMap(json, 'images', model: _model),
        'edges',
        model: _model,
        fromItem: (item) {
          final edge = item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};
          return ShopifyImage.fromJson(parseMap(edge, 'node', model: _model));
        },
      ),
      options: parseList<ProductOption>(
        json,
        'options',
        model: _model,
        fromItem: (item) => ProductOption.fromJson(
          item is Map<String, dynamic> ? item : <String, dynamic>{},
        ),
      ),
      variants: parseList<ProductVariant>(
        parseMap(json, 'variants', model: _model),
        'edges',
        model: _model,
        fromItem: (item) {
          final edge = item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};
          return ProductVariant.fromJson(parseMap(edge, 'node', model: _model));
        },
      ),
      averageRating: _parseRating(json),
      reviewsCount: _parseRatingCount(json),
    );
  }

  static const _model = 'ProductDetail';

  final String id;
  final String title;
  final String handle;
  final String? vendor;
  final bool availableForSale;
  final String? description;
  final Money price;
  final Money? compareAtPrice;
  final List<ShopifyImage> images;
  final List<ProductOption> options;
  final List<ProductVariant> variants;

  /// 0-5 average rating, from a `reviews.rating` metafield. `null` when the
  /// storefront has no reviews app/metafield configured.
  final double? averageRating;

  /// Review count, from a `reviews.rating_count` metafield.
  final int? reviewsCount;

  /// Color descriptors from Shopify's `shopify.color-pattern` category
  /// metafield — display-only taxonomy data, distinct from any real `Color`
  /// entry in [options]. Empty when the merchant hasn't set it.
  // final List<ProductColorSwatch> categoryColors;

  /// Whether [compareAtPrice] marks a genuine markdown over [price].
  bool get isOnSale =>
      compareAtPrice != null && compareAtPrice!.amount > price.amount;

  /// The variant matching every entry in [selection], if any.
  ProductVariant? variantFor(Map<String, String> selection) {
    for (final variant in variants) {
      if (variant.selectedOptions.length == selection.length &&
          variant.matches(selection)) {
        return variant;
      }
    }
    return null;
  }

  static double? _parseRating(Map<String, dynamic> json) {
    final raw = parseStringOrNull(
      parseMap(json, 'ratingMetafield', model: _model),
      'value',
      model: _model,
    );
    if (raw == null) return null;
    final match = RegExp(r'"value"\s*:\s*"?([\d.]+)"?').firstMatch(raw);
    return double.tryParse(match?.group(1) ?? raw);
  }

  static int? _parseRatingCount(Map<String, dynamic> json) {
    return parseIntOrNull(
      parseMap(json, 'ratingCountMetafield', model: _model),
      'value',
      model: _model,
    );
  }
}

/* static List<ProductColorSwatch> _parseCategoryColors(
    Map<String, dynamic> json,
  ) {
    final references = parseMap(
      parseMap(json, 'colorMetafield', model: _model),
      'references',
      model: _model,
    );
    return parseList<ProductColorSwatch>(
      references,
      'nodes',
      model: _model,
      fromItem: (item) {
        final node = item is Map<String, dynamic> ? item : <String, dynamic>{};
        final fields = node['fields'];
        return ProductColorSwatch.fromFields(fields is List ? fields : []);
      },
    );
  }
} */
