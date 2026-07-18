import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/storage/wishlist_storage.dart';
import 'package:shopify_app/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:shopify_app/providers/storage_providers.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

Product _product(String id) => Product(
  id: id,
  title: 'Aviator $id',
  handle: 'aviator-$id',
  availableForSale: true,
  price: const Money(amount: 150, currencyCode: 'INR'),
  featuredImage: const ShopifyImage(url: 'https://cdn/img.png', width: 10),
  compareAtPrice: const Money(amount: 200, currencyCode: 'INR'),
);

/// In-memory [WishlistStorage] that records the last persisted payload.
class _FakeWishlistStorage implements WishlistStorage {
  _FakeWishlistStorage([this._seed = const []]);

  List<Map<String, dynamic>> _seed;
  List<Map<String, dynamic>>? lastWritten;

  @override
  List<Map<String, dynamic>> readProducts() => _seed;

  @override
  Future<void> writeProducts(List<Map<String, dynamic>> products) async {
    lastWritten = products;
    _seed = products;
  }

  @override
  Future<void> clear() async {
    lastWritten = const [];
    _seed = const [];
  }
}

ProviderContainer _container(_FakeWishlistStorage storage) {
  final container = ProviderContainer(
    overrides: [wishlistStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('WishlistNotifier', () {
    test('hydrates from storage on build', () {
      final storage = _FakeWishlistStorage([_product('1').toJson()]);
      final container = _container(storage);

      final items = container.read(wishlistProvider);
      expect(items, hasLength(1));
      expect(items.single.id, '1');
      expect(container.read(isInWishlistProvider('1')), isTrue);
      expect(container.read(wishlistCountProvider), 1);
    });

    test('toggle adds then removes, persisting each time', () async {
      final storage = _FakeWishlistStorage();
      final container = _container(storage);

      container.read(wishlistProvider.notifier).toggle(_product('1'));
      expect(container.read(isInWishlistProvider('1')), isTrue);
      await Future<void>.delayed(Duration.zero); // let unawaited persist run
      expect(storage.lastWritten, hasLength(1));

      container.read(wishlistProvider.notifier).toggle(_product('1'));
      expect(container.read(isInWishlistProvider('1')), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(storage.lastWritten, isEmpty);
    });

    test('add is idempotent; remove of absent id is a no-op', () {
      final container = _container(_FakeWishlistStorage());

      container.read(wishlistProvider.notifier)
        ..add(_product('1'))
        ..add(_product('1'));
      expect(container.read(wishlistProvider), hasLength(1));

      container.read(wishlistProvider.notifier).remove('does-not-exist');
      expect(container.read(wishlistProvider), hasLength(1));
    });

    test('clear empties the wishlist', () {
      final storage = _FakeWishlistStorage([_product('1').toJson()]);
      final container = _container(storage);

      container.read(wishlistProvider.notifier).clear();
      expect(container.read(wishlistProvider), isEmpty);
    });

    test('stored product round-trips through toJson/fromJson', () {
      final storage = _FakeWishlistStorage([_product('9').toJson()]);
      final container = _container(storage);

      final restored = container.read(wishlistProvider).single;
      expect(restored.title, 'Aviator 9');
      expect(restored.price.amount, 150);
      expect(restored.compareAtPrice?.amount, 200);
      expect(restored.featuredImage?.url, 'https://cdn/img.png');
    });
  });
}
