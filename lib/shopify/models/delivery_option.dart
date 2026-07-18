import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/money.dart';

/// One shipping rate offered for a cart delivery group, e.g. "Standard —
/// $5.00". Selected via `cartSelectedDeliveryOptionsUpdate` using [handle].
class DeliveryOption {
  const DeliveryOption({
    required this.handle,
    required this.title,
    required this.price,
    this.code,
    this.description,
  });

  /// Builds from a Storefront `CartDeliveryOption` node.
  factory DeliveryOption.fromJson(Map<String, dynamic> json) {
    return DeliveryOption(
      handle: parseString(json, 'handle', model: _model),
      title: parseString(json, 'title', fallback: 'Shipping', model: _model),
      price: Money.fromJson(parseMap(json, 'estimatedCost', model: _model)),
      code: parseStringOrNull(json, 'code', model: _model),
      description: parseStringOrNull(json, 'description', model: _model),
    );
  }

  static const _model = 'DeliveryOption';

  /// Stable handle used to select this option.
  final String handle;
  final String title;

  /// Estimated shipping cost for this option.
  final Money price;

  /// Carrier/service code, when provided.
  final String? code;
  final String? description;

  /// Whether this option is free of charge.
  bool get isFree => price.amount <= 0;
}
