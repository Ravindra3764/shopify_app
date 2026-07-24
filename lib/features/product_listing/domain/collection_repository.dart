import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/collection.dart';
import 'package:shopify_app/shopify/models/collection_summary.dart';

/// Loads collections (and their products) for the listing / browse screens.
abstract interface class CollectionRepository {
  /// Fetches the collection identified by [handle], with its products.
  Future<Result<Collection, Failure>> getCollection(String handle);

  /// Fetches lightweight summaries of all storefront collections (for the
  /// browse-screen chip bar).
  Future<Result<List<CollectionSummary>, Failure>> getCollections({int first});
}
