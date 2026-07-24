import 'package:shopify_app/shopify/models/product.dart';

/// Aspect ratio (width / height) for a product's image in a masonry feed.
///
/// Uses the Storefront image's real dimensions when present, biased toward
/// portrait and clamped to a pleasant range so extreme/odd source images can't
/// blow out a masonry cell; falls back when the image omits its size.
double productMasonryAspectRatio(Product product) {
  final image = product.featuredImage;
  final w = image?.width;
  final h = image?.height;
  if (w != null && h != null && w > 0 && h > 0) {
    return (w / h).clamp(_minRatio, _maxRatio);
  }
  return _fallbackRatio;
}

const double _minRatio = 0.6;
const double _maxRatio = 1;
const double _fallbackRatio = 0.8;
