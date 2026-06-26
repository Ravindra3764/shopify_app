import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/shopify/models/collection.dart';
import 'package:shopify_app/shopify/models/home_banner_model.dart';

/// Aggregate payload for the home screen: hero [banners] and the storefront
/// [collections] (each with its first page of products).
class HomeData {
  const HomeData({required this.banners, required this.collections});

  /// Builds from the `data` object returned by `kHomeQuery`.
  factory HomeData.fromJson(Map<String, dynamic> data) {
    return HomeData(
      banners: _edges(data, 'banners', HomeBannerModel.fromJson),
      collections: _edges(data, 'collections', Collection.fromJson),
    );
  }

  static const _model = 'HomeData';

  final List<HomeBannerModel> banners;
  final List<Collection> collections;

  /// Maps a GraphQL `{ field: { edges: [{ node }] } }` connection to a list.
  static List<T> _edges<T>(
    Map<String, dynamic> data,
    String field,
    T Function(Map<String, dynamic>) fromNode,
  ) {
    final connection = parseMap(data, field, model: _model);
    return parseList<T>(
      connection,
      'edges',
      model: _model,
      fromItem: (item) {
        final edge = item is Map<String, dynamic> ? item : <String, dynamic>{};
        return fromNode(parseMap(edge, 'node', model: _model));
      },
    );
  }
}
