import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// Storefront `ProductVariant` — one buyable combination of option values.
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.title,
    required this.availableForSale,
    required this.price,
    required this.selectedOptions,
    this.compareAtPrice,
    this.image,
    this.quantityAvailable,
  });

  /// Builds from a Storefront `ProductVariant` node.
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final compareMap = parseMap(json, 'compareAtPrice', model: _model);
    final compareAt = compareMap.isEmpty ? null : Money.fromJson(compareMap);

    final options = <String, String>{};
    for (final raw in parseList<Map<String, dynamic>>(
      json,
      'selectedOptions',
      model: _model,
      fromItem: (item) =>
          item is Map<String, dynamic> ? item : <String, dynamic>{},
    )) {
      final name = parseString(raw, 'name', model: _model);
      if (name.isEmpty) continue;
      options[name] = parseString(raw, 'value', model: _model);
    }

    return ProductVariant(
      id: parseString(json, 'id', model: _model),
      title: parseString(json, 'title', model: _model),
      availableForSale: parseBool(json, 'availableForSale', model: _model),
      quantityAvailable: parseIntOrNull(
        json,
        'quantityAvailable',
        model: _model,
      ),
      price: Money.fromJson(parseMap(json, 'price', model: _model)),
      compareAtPrice: (compareAt != null && compareAt.isPositive)
          ? compareAt
          : null,
      selectedOptions: options,
      image: ShopifyImage.fromJsonOrNull(
        parseMap(json, 'image', model: _model),
      ),
    );
  }

  static const _model = 'ProductVariant';

  final String id;
  final String title;
  final bool availableForSale;
  final Money price;
  final Money? compareAtPrice;

  /// Option name → selected value, e.g. `{'Color': 'Black', 'Size': 'M'}`.
  final Map<String, String> selectedOptions;
  final ShopifyImage? image;

  /// Units in stock; `null` when Shopify doesn't track inventory (unlimited).
  final int? quantityAvailable;

  /// Whether this variant matches every entry in [selection].
  bool matches(Map<String, String> selection) {
    for (final entry in selection.entries) {
      if (selectedOptions[entry.key] != entry.value) return false;
    }
    return true;
  }
}
