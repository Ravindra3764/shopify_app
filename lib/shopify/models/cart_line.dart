import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// One line in a Storefront `Cart` — a single product variant plus its
/// quantity, with a snapshot of the variant's display data.
class CartLine {
  const CartLine({
    required this.id,
    required this.variantId,
    required this.productTitle,
    required this.variantTitle,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.selectedOptions,
    this.image,
  });

  /// Builds from a Storefront `CartLine` node (with `merchandise` resolved as
  /// a `ProductVariant`).
  factory CartLine.fromJson(Map<String, dynamic> json) {
    final merchandise = parseMap(json, 'merchandise', model: _model);
    final product = parseMap(merchandise, 'product', model: _model);

    final options = <String, String>{};
    for (final raw in parseList<Map<String, dynamic>>(
      merchandise,
      'selectedOptions',
      model: _model,
      fromItem: (item) =>
          item is Map<String, dynamic> ? item : <String, dynamic>{},
    )) {
      final name = parseString(raw, 'name', model: _model);
      if (name.isEmpty) continue;
      options[name] = parseString(raw, 'value', model: _model);
    }

    return CartLine(
      id: parseString(json, 'id', model: _model),
      variantId: parseString(merchandise, 'id', model: _model),
      productTitle: parseString(product, 'title', model: _model),
      variantTitle: parseString(merchandise, 'title', model: _model),
      quantity: parseInt(json, 'quantity', fallback: 1, model: _model),
      unitPrice: Money.fromJson(parseMap(merchandise, 'price', model: _model)),
      lineTotal: Money.fromJson(
        parseMap(
          parseMap(json, 'cost', model: _model),
          'totalAmount',
          model: _model,
        ),
      ),
      selectedOptions: options,
      image: ShopifyImage.fromJsonOrNull(
        parseMap(merchandise, 'image', model: _model),
      ),
    );
  }

  static const _model = 'CartLine';

  /// Cart-line ID (`gid://.../CartLine/...`) — the handle for update/remove.
  final String id;

  /// Purchased variant ID (`merchandiseId`).
  final String variantId;
  final String productTitle;

  /// Shopify's variant title, e.g. `M / Charcoal` (or `Default Title`).
  final String variantTitle;
  final int quantity;

  /// Price of a single unit.
  final Money unitPrice;

  /// Total for this line (`unitPrice * quantity`), from the Storefront cost.
  final Money lineTotal;

  /// Option name → value, e.g. `{'Size': 'M', 'Color': 'Charcoal'}`.
  final Map<String, String> selectedOptions;
  final ShopifyImage? image;

  /// Human-readable option summary, e.g. `M | Charcoal`. Drops Shopify's
  /// synthetic `Default Title` shown on products that have no real variants.
  String get optionsSummary => selectedOptions.values
      .where((v) => v.toLowerCase() != 'default title')
      .join(' | ');
}
