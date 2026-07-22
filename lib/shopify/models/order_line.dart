import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// A single line on a placed `Order` — a purchased variant with its quantity
/// and the price paid. Mapped from a Storefront `OrderLineItem` node.
class OrderLine {
  const OrderLine({
    required this.title,
    required this.quantity,
    required this.lineTotal,
    this.variantTitle,
    this.image,
  });

  /// Builds from a Storefront `OrderLineItem` node.
  factory OrderLine.fromJson(Map<String, dynamic> json) {
    final variant = parseMap(json, 'variant', model: _model);
    final rawVariantTitle = parseStringOrNull(variant, 'title', model: _model);
    return OrderLine(
      title: parseString(json, 'title', model: _model),
      quantity: parseInt(json, 'quantity', model: _model),
      lineTotal: Money.fromJson(
        parseMap(json, 'originalTotalPrice', model: _model),
      ),
      // Shopify uses "Default Title" for single-variant products; hide it.
      variantTitle: rawVariantTitle == 'Default Title' ? null : rawVariantTitle,
      image: ShopifyImage.fromJsonOrNull(
        parseMap(variant, 'image', model: _model),
      ),
    );
  }

  static const _model = 'OrderLine';

  final String title;
  final int quantity;
  final Money lineTotal;

  /// Variant label (e.g. `Large / Blue`), or `null` for single-variant items.
  final String? variantTitle;
  final ShopifyImage? image;
}
