import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/delivery_option.dart';

/// A cart delivery group — one set of shipping [options] for a group of lines,
/// with the currently [selectedOptionHandle] (if Shopify or the shopper has
/// picked one). Populated only after a delivery address is applied to the cart.
class DeliveryGroup {
  const DeliveryGroup({
    required this.id,
    required this.options,
    this.selectedOptionHandle,
  });

  /// Builds from a Storefront `CartDeliveryGroup` node.
  factory DeliveryGroup.fromJson(Map<String, dynamic> json) {
    final selected = parseMap(json, 'selectedDeliveryOption', model: _model);
    return DeliveryGroup(
      id: parseString(json, 'id', model: _model),
      selectedOptionHandle: selected.isEmpty
          ? null
          : parseStringOrNull(selected, 'handle', model: _model),
      options: parseList<DeliveryOption>(
        json,
        'deliveryOptions',
        model: _model,
        fromItem: (item) => DeliveryOption.fromJson(
          item is Map<String, dynamic> ? item : <String, dynamic>{},
        ),
      ),
    );
  }

  static const _model = 'DeliveryGroup';

  /// Delivery-group ID, used when selecting an option.
  final String id;
  final List<DeliveryOption> options;

  /// Handle of the currently selected option, or `null` if none chosen.
  final String? selectedOptionHandle;

  /// The selected [DeliveryOption], or `null` when nothing is selected.
  DeliveryOption? get selectedOption {
    final handle = selectedOptionHandle;
    if (handle == null) return null;
    for (final option in options) {
      if (option.handle == handle) return option;
    }
    return null;
  }
}
