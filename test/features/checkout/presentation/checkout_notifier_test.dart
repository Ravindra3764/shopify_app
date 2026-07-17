import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/storage/address_storage.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/features/checkout/domain/checkout_repository.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_state.dart';
import 'package:shopify_app/providers/storage_providers.dart';
import 'package:shopify_app/shopify/models/cart.dart';
import 'package:shopify_app/shopify/models/cart_line.dart';
import 'package:shopify_app/shopify/models/delivery_group.dart';
import 'package:shopify_app/shopify/models/delivery_option.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';
import 'package:shopify_app/shopify/models/money.dart';

Money _usd(double amount) => Money(amount: amount, currencyCode: 'USD');

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

Cart _cart({
  double total = 80,
  List<DeliveryGroup> deliveryGroups = const [],
}) => Cart(
  id: 'gid://shopify/Cart/abc123',
  checkoutUrl: 'https://acme.myshopify.com/cart/c/abc123',
  totalQuantity: 1,
  subtotal: _usd(80),
  total: _usd(total),
  tax: _usd(5),
  lines: [_line],
  deliveryGroups: deliveryGroups,
);

final _optionStandard = DeliveryOption(
  handle: 'standard',
  title: 'Standard',
  price: _usd(5),
);
final _optionExpress = DeliveryOption(
  handle: 'express',
  title: 'Express',
  price: _usd(15),
);

final _seedCart = _cart();
final _addressAppliedCart = _cart(
  total: 90.40,
  deliveryGroups: [
    DeliveryGroup(id: 'g1', options: [_optionStandard, _optionExpress]),
  ],
);
final _selectedCart = _cart(
  total: 90.40,
  deliveryGroups: [
    DeliveryGroup(
      id: 'g1',
      options: [_optionStandard, _optionExpress],
      selectedOptionHandle: 'standard',
    ),
  ],
);

const _address = MailingAddress(
  id: 'addr_1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  address1: '1 Analytical Way',
  city: 'London',
  province: 'CA',
  zip: '94016',
  country: 'US',
);

class _FakeCartNotifier extends CartNotifier {
  _FakeCartNotifier(this._value);
  final Cart? _value;
  @override
  Future<Cart?> build() async => _value;
}

class _FakeAddressStorage implements AddressStorage {
  @override
  List<MailingAddress> readAddresses() => const [];
  @override
  Future<void> writeAddresses(List<MailingAddress> addresses) async {}
  @override
  String? readEmail() => null;
  @override
  Future<void> writeEmail(String email) async {}
}

class _FakeCheckoutRepository implements CheckoutRepository {
  _FakeCheckoutRepository({this.addressResult});
  final Result<Cart, Failure>? addressResult;

  @override
  Future<Result<Cart, Failure>> updateBuyerAddress(
    String cartId, {
    required String email,
    required MailingAddress address,
  }) async => addressResult ?? Success(_addressAppliedCart);

  @override
  Future<Result<Cart, Failure>> selectDeliveryOption(
    String cartId, {
    required String deliveryGroupId,
    required String optionHandle,
  }) async => Success(_selectedCart);
}

ProviderContainer _container({Cart? cart, CheckoutRepository? repo}) {
  final container = ProviderContainer(
    overrides: [
      cartProvider.overrideWith(() => _FakeCartNotifier(cart ?? _seedCart)),
      addressStorageProvider.overrideWithValue(_FakeAddressStorage()),
      checkoutRepositoryProvider.overrideWithValue(
        repo ?? _FakeCheckoutRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('CheckoutNotifier', () {
    test('seeds from the active cart on the address step', () async {
      final container = _container();
      await container.read(cartProvider.future);

      final state = await container.read(checkoutProvider.future);
      expect(state.step, CheckoutStep.address);
      expect(state.cart.id, _seedCart.id);
    });

    test('throws when the cart is empty', () async {
      final empty = Cart(
        id: 'x',
        checkoutUrl: 'x',
        totalQuantity: 0,
        subtotal: _usd(0),
        total: _usd(0),
        lines: const [],
      );
      final c = _container(cart: empty);
      await c.read(cartProvider.future);

      await expectLater(
        c.read(checkoutProvider.future),
        throwsA(isA<Failure>()),
      );
    });

    test('applyAddress advances to the shipping step', () async {
      final container = _container();
      await container.read(cartProvider.future);
      await container.read(checkoutProvider.future);

      await container
          .read(checkoutProvider.notifier)
          .applyAddress(email: 'a@b.com', address: _address);

      final state = container.read(checkoutProvider).value!;
      expect(state.step, CheckoutStep.delivery);
      expect(state.email, 'a@b.com');
      expect(state.cart.hasDeliveryOptions, isTrue);
      expect(state.cart.needsDeliverySelection, isTrue);
    });

    test('selectDelivery then proceedToReview advances to review', () async {
      final container = _container();
      await container.read(cartProvider.future);
      await container.read(checkoutProvider.future);

      final notifier = container.read(checkoutProvider.notifier);
      await notifier.applyAddress(email: 'a@b.com', address: _address);
      await notifier.selectDelivery(
        deliveryGroupId: 'g1',
        optionHandle: 'standard',
      );

      var state = container.read(checkoutProvider).value!;
      expect(state.step, CheckoutStep.delivery);
      expect(state.cart.selectedShipping?.amount, 5.0);
      expect(state.cart.needsDeliverySelection, isFalse);

      notifier.proceedToReview();
      state = container.read(checkoutProvider).value!;
      expect(state.step, CheckoutStep.review);
    });

    test('applyAddress flags an unserviceable (zeroed) address', () async {
      final zeroed = Cart(
        id: 'gid://shopify/Cart/abc123',
        checkoutUrl: 'x',
        totalQuantity: 0,
        subtotal: _usd(0),
        total: _usd(0),
        lines: const [],
      );
      final container = _container(
        repo: _FakeCheckoutRepository(addressResult: Success(zeroed)),
      );
      await container.read(cartProvider.future);
      await container.read(checkoutProvider.future);

      await container
          .read(checkoutProvider.notifier)
          .applyAddress(email: 'a@b.com', address: _address);

      final state = container.read(checkoutProvider).value!;
      expect(state.step, CheckoutStep.address);
      expect(state.error, isNotNull);
    });

    test('applyAddress surfaces failure as error state', () async {
      final container = _container(
        repo: _FakeCheckoutRepository(
          addressResult: const Failed(ShopifyFailure('bad address')),
        ),
      );
      await container.read(cartProvider.future);
      await container.read(checkoutProvider.future);

      await container
          .read(checkoutProvider.notifier)
          .applyAddress(email: 'a@b.com', address: _address);

      expect(container.read(checkoutProvider).hasError, isTrue);
    });
  });
}
