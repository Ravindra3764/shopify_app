import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/collection.dart';

/// Loads a single collection with its products for the listing screen.
// ignore: one_member_abstracts
abstract interface class CollectionRepository {
  /// Fetches the collection identified by [handle].
  Future<Result<Collection, Failure>> getCollection(String handle);
}
