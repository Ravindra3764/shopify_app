import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/product_listing/presentation/providers/collection_providers.dart';
import 'package:shopify_app/shopify/models/collection_summary.dart';

/// All storefront collections (handle + title) for the browse chip bar.
final collectionsListProvider =
    AsyncNotifierProvider<CollectionsListNotifier, List<CollectionSummary>>(
      CollectionsListNotifier.new,
    );

/// Loads the collection list via the collection repository; rethrows `Failure`
/// for `AsyncValue.error`.
class CollectionsListNotifier extends AsyncNotifier<List<CollectionSummary>> {
  @override
  Future<List<CollectionSummary>> build() async {
    final repo = ref.watch(collectionRepositoryProvider);
    final result = await repo.getCollections();
    return result.fold(
      (collections) => collections,
      (failure) => throw failure,
    );
  }
}

/// The collection handle currently selected in the browse chip bar. `null`
/// until the user taps a chip, at which point the screen defaults to the first
/// collection.
final selectedCollectionProvider =
    NotifierProvider<SelectedCollectionNotifier, String?>(
      SelectedCollectionNotifier.new,
    );

/// Holds the selected browse collection handle.
class SelectedCollectionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Selects [handle] as the active browse collection.
  void select(String handle) {
    if (state != handle) state = handle;
  }
}
