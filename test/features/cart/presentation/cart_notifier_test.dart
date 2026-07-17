import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/storage/cart_storage.dart';
import 'package:shopify_app/features/cart/domain/cart_repository.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/providers/storage_providers.dart';
import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/models/cart_discount_code.dart';
import 'package:shopify_app/shopify/models/cart_line.dart';
import 'package:shopify_app/shopify/models/money.dart';

Money _usd(double amount) => Money(amount: amount, currencyCode: 'USD');

const _cartId = 'gid://shopify/Cart/abc123';

final _line = CartLine(
  id: 'gid://shopify/CartLine/l1',
  variantId: 'gid://shopify/ProductVariant/v1',
  productTitle: 'Cotton Tee',
  variantTitle: 'M',
  quantity: 1,
  unitPrice: _usd(80),
  lineTotal: _usd(80),
  selectedOptions: const {'Size': 'M'},
);

Cart _cart({List<CartDiscountCode> codes = const []}) {
  final applicable = codes.where((c) => c.applicable).toList();
  return Cart(
    id: _cartId,
    checkoutUrl: 'https://acme.myshopify.com/cart/c/abc123',
    totalQuantity: 1,
    subtotal: _usd(80),
    total: _usd(applicable.isEmpty ? 80 : 72),
    lines: [_line],
    discount: applicable.isEmpty ? null : _usd(8),
    discountCodes: codes,
  );
}

/// Fake cart repo: `applicable` codes (upper-cased) reduce the cart; any other
/// submitted code echoes back non-applicable, mirroring Shopify.
class _FakeCartRepository implements CartRepository {
  _FakeCartRepository({this.applicable = const {}});

  final Set<String> applicable;
  List<String>? lastDiscountCodes;

  @override
  Future<Result<Cart, Failure>> getCart(String cartId) async =>
      Success(_cart());

  @override
  Future<Result<Cart, Failure>> updateDiscountCodes(
    String cartId,
    List<String> codes,
  ) async {
    lastDiscountCodes = codes;
    return Success(
      _cart(
        codes: [
          for (final c in codes)
            CartDiscountCode(
              code: c,
              applicable: applicable.contains(c.toUpperCase()),
            ),
        ],
      ),
    );
  }

  @override
  Future<Result<Cart, Failure>> createCart(String variantId, int quantity) =>
      throw UnimplementedError();
  @override
  Future<Result<Cart, Failure>> addLine(
    String cartId,
    String variantId,
    int quantity,
  ) => throw UnimplementedError();
  @override
  Future<Result<Cart, Failure>> updateLine(
    String cartId,
    String lineId,
    int quantity,
  ) => throw UnimplementedError();
  @override
  Future<Result<Cart, Failure>> removeLine(String cartId, String lineId) =>
      throw UnimplementedError();
}

/// Fake that fails only the discount mutation, for the error path.
class _FailingDiscountRepository extends _FakeCartRepository {
  @override
  Future<Result<Cart, Failure>> updateDiscountCodes(
    String cartId,
    List<String> codes,
  ) async => const Failed(ShopifyFailure('boom'));
}

class _FakeCartStorage implements CartStorage {
  @override
  String? readCartId() => _cartId;
  @override
  Future<void> writeCartId(String cartId) async {}
  @override
  Future<void> clearCartId() async {}
}

ProviderContainer _container(CartRepository repo) {
  final container = ProviderContainer(
    overrides: [
      cartRepositoryProvider.overrideWithValue(repo),
      cartStorageProvider.overrideWithValue(_FakeCartStorage()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('CartNotifier.applyPromoCode', () {
    test('applies a valid code and reflects the discount', () async {
      final repo = _FakeCartRepository(applicable: {'SAVE10'});
      final container = _container(repo);
      await container.read(cartProvider.future);

      final outcome = await container
          .read(cartProvider.notifier)
          .applyPromoCode('save10');

      expect(outcome, PromoOutcome.applied);
      final cart = container.read(cartProvider).value!;
      expect(cart.appliedDiscountCodes.map((c) => c.code), ['save10']);
      expect(cart.discount, isNotNull);
    });

    test('reports a non-applicable code and strips it back out', () async {
      final repo = _FakeCartRepository();
      final container = _container(repo);
      await container.read(cartProvider.future);

      final outcome = await container
          .read(cartProvider.notifier)
          .applyPromoCode('BOGUS');

      expect(outcome, PromoOutcome.notApplicable);
      // Last call clears the bad code so it doesn't linger on the cart.
      expect(repo.lastDiscountCodes, isEmpty);
      expect(container.read(cartProvider).value!.appliedDiscountCodes, isEmpty);
    });

    test('reports an error when the mutation fails', () async {
      final container = _container(_FailingDiscountRepository());
      await container.read(cartProvider.future);

      final outcome = await container
          .read(cartProvider.notifier)
          .applyPromoCode('SAVE10');

      expect(outcome, PromoOutcome.error);
    });

    test('removePromoCode re-sends the remaining codes', () async {
      final repo = _FakeCartRepository(applicable: {'SAVE10', 'FREESHIP'});
      final container = _container(repo);
      final notifier = container.read(cartProvider.notifier);
      await container.read(cartProvider.future);

      await notifier.applyPromoCode('SAVE10');
      await notifier.applyPromoCode('FREESHIP');
      await notifier.removePromoCode('SAVE10');

      expect(repo.lastDiscountCodes, ['FREESHIP']);
    });
  });
}
