/// Returns [url] with a Shopify CDN `width` resize parameter appended, so cards
/// fetch a right-sized thumbnail instead of the full-resolution original.
///
/// Shopify's image CDN honors a `?width=` query param and scales height
/// proportionally (aspect ratio preserved). [width] is bucketed to the nearest
/// 100px so minor layout differences don't spawn many distinct URLs (which
/// would defeat the image + palette caches). Non-http URLs are returned
/// unchanged; the param is harmless on the off chance the host isn't Shopify.
String sizedShopifyImageUrl(String url, {required int width}) {
  final trimmed = url.trim();
  if (!trimmed.startsWith('http')) return trimmed;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return trimmed;
  final bucketed = (width / _bucket).ceil() * _bucket;
  final params = Map<String, String>.from(uri.queryParameters)
    ..['width'] = '$bucketed';
  return uri.replace(queryParameters: params).toString();
}

const int _bucket = 100;
