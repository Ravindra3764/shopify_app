import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// Hero banner sourced from the `home_banner` metaobject.
///
/// Drives the top carousel on the home screen. [ctaCollectionHandle] points at
/// the collection the "Shop Now" button opens.
class HomeBannerModel {
  const HomeBannerModel({
    required this.id,
    required this.handle,
    required this.eyebrow,
    required this.title,
    required this.ctaLabel,
    this.image,
    this.ctaCollectionHandle,
  });

  /// Builds from a Storefront `Metaobject` node whose reference/value fields
  /// were aliased in the query (`eyebrow`, `title`, `ctaLabel`, `image`,
  /// `ctaCollection`).
  factory HomeBannerModel.fromJson(Map<String, dynamic> json) {
    String fieldValue(String key) =>
        parseString(parseMap(json, key, model: _model), 'value', model: _model);

    final imageRef = parseMap(
      parseMap(json, 'image', model: _model),
      'reference',
      model: _model,
    );
    final collectionRef = parseMap(
      parseMap(json, 'ctaCollection', model: _model),
      'reference',
      model: _model,
    );

    return HomeBannerModel(
      id: parseString(json, 'id', model: _model),
      handle: parseString(json, 'handle', model: _model),
      eyebrow: fieldValue('eyebrow'),
      title: fieldValue('title'),
      ctaLabel: fieldValue('ctaLabel'),
      image: ShopifyImage.fromJsonOrNull(
        parseMap(imageRef, 'image', model: _model),
      ),
      ctaCollectionHandle: parseStringOrNull(
        collectionRef,
        'handle',
        model: _model,
      ),
    );
  }

  static const _model = 'HomeBannerModel';

  final String id;
  final String handle;
  final String eyebrow;
  final String title;
  final String ctaLabel;
  final ShopifyImage? image;
  final String? ctaCollectionHandle;
}
