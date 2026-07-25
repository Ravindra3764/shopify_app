import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/config/cart_added_style.dart';

void main() {
  group('CartAddedStyle.fromEnv', () {
    test('defaults to toast for null/empty/toast', () {
      expect(CartAddedStyle.fromEnv(null), CartAddedStyle.toast);
      expect(CartAddedStyle.fromEnv(''), CartAddedStyle.toast);
      expect(CartAddedStyle.fromEnv('toast'), CartAddedStyle.toast);
    });

    test('parses overlay (case/space-insensitive)', () {
      expect(CartAddedStyle.fromEnv('overlay'), CartAddedStyle.overlay);
      expect(CartAddedStyle.fromEnv('  OVERLAY '), CartAddedStyle.overlay);
    });

    test('fails fast on an unrecognized value', () {
      expect(
        () => CartAddedStyle.fromEnv('popup'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
