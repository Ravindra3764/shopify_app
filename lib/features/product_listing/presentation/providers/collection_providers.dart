import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/product_listing/data/collection_repository_impl.dart';
import 'package:shopify_app/features/product_listing/domain/collection_repository.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/collection.dart';

/// Collection repository, wired to the Storefront `ApiClient`.
final collectionRepositoryProvider = Provider<CollectionRepository>(
  (ref) => CollectionRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Loads a [Collection] (with products) by handle, keyed per handle.
final collectionProvider =
    AsyncNotifierProvider.family<CollectionNotifier, Collection, String>(
      CollectionNotifier.new,
    );

/// Fetches one collection via [CollectionRepository]; rethrows `Failure` for
/// `AsyncValue.error`.
class CollectionNotifier extends FamilyAsyncNotifier<Collection, String> {
  @override
  Future<Collection> build(String handle) async {
    final repo = ref.watch(collectionRepositoryProvider);
    final result = await repo.getCollection(handle);
    return result.fold((collection) => collection, (failure) => throw failure);
  }
}
