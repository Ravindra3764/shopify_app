import 'package:shopify_app/core/utils/json_parse.dart';

/// Lightweight storefront collection reference (no products) — used for the
/// browse-screen chip bar where only [handle] and [title] are needed.
class CollectionSummary {
  const CollectionSummary({required this.handle, required this.title});

  /// Builds from a Storefront `Collection` node.
  factory CollectionSummary.fromJson(Map<String, dynamic> json) {
    return CollectionSummary(
      handle: parseString(json, 'handle', model: _model),
      title: parseString(json, 'title', model: _model),
    );
  }

  static const _model = 'CollectionSummary';

  final String handle;
  final String title;
}
