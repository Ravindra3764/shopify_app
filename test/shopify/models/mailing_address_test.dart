import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/shopify/models/mailing_address.dart';

void main() {
  group('MailingAddress', () {
    const address = MailingAddress(
      id: 'addr_1',
      firstName: 'Ada',
      lastName: 'Lovelace',
      address1: '1 Analytical Way',
      address2: 'Apt 2',
      city: 'London',
      province: 'CA',
      zip: '94016',
      country: 'US',
      phone: '5551234567',
    );

    test('toInput emits the Storefront MailingAddressInput shape', () {
      expect(address.toInput(), {
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'address1': '1 Analytical Way',
        'address2': 'Apt 2',
        'city': 'London',
        'province': 'CA',
        'zip': '94016',
        'country': 'US',
        'phone': '5551234567',
      });
    });

    test('toInput omits empty optional fields', () {
      const minimal = MailingAddress(
        id: 'addr_2',
        firstName: 'Grace',
        lastName: 'Hopper',
        address1: '2 Compiler St',
        city: 'Arlington',
        province: 'VA',
        zip: '22201',
        country: 'US',
      );
      final input = minimal.toInput();
      expect(input.containsKey('address2'), isFalse);
      expect(input.containsKey('phone'), isFalse);
    });

    test('toJson/fromJson round-trips', () {
      final restored = MailingAddress.fromJson(address.toJson());
      expect(restored.id, address.id);
      expect(restored.fullName, 'Ada Lovelace');
      expect(restored.address2, 'Apt 2');
      expect(restored.phone, '5551234567');
      expect(restored.country, 'US');
    });

    test('formatted renders a multi-line summary', () {
      expect(
        address.formatted,
        '1 Analytical Way, Apt 2\nLondon, CA 94016\nUS',
      );
    });
  });
}
