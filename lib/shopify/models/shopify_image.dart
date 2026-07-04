import 'package:shopify_app/core/utils/json_parse.dart';

/// Storefront `Image` — a CDN [url] plus optional alt text and dimensions.
class ShopifyImage {
  const ShopifyImage({
    required this.url,
    this.altText,
    this.width,
    this.height,
  });

  /// Builds from a Storefront `Image` node.
  factory ShopifyImage.fromJson(Map<String, dynamic> json) {
    return ShopifyImage(
      url: parseString(json, 'url', model: _model),
      altText: parseStringOrNull(json, 'altText', model: _model),
      width: parseIntOrNull(json, 'width', model: _model),
      height: parseIntOrNull(json, 'height', model: _model),
    );
  }

  /// Builds from an optional map; returns `null` when [json] is empty/missing.
  static ShopifyImage? fromJsonOrNull(Map<String, dynamic> json) {
    if (json.isEmpty) return null;
    final image = ShopifyImage.fromJson(json);
    return image.url.isEmpty ? null : image;
  }

  static const _model = 'ShopifyImage';

  final String url;
  final String? altText;
  final int? width;
  final int? height;
}
