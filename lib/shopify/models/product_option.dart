import 'package:shopify_app/core/utils/json_parse.dart';

/// Storefront product `Option` — e.g. `Color` with values `[Black, White]`.
class ProductOption {
  const ProductOption({required this.name, required this.values});

  /// Builds from a Storefront `ProductOption` node.
  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      name: parseString(json, 'name', model: _model),
      values: parseList<String>(
        json,
        'values',
        model: _model,
        fromItem: (item) => item as String,
      ),
    );
  }

  static const _model = 'ProductOption';

  final String name;
  final List<String> values;
}
