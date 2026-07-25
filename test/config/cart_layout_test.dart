import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/config/cart_layout.dart';

void main() {
  group('CartLayout.fromEnv', () {
    test('defaults to classic for null/empty/classic', () {
      expect(CartLayout.fromEnv(null), CartLayout.classic);
      expect(CartLayout.fromEnv(''), CartLayout.classic);
      expect(CartLayout.fromEnv('classic'), CartLayout.classic);
    });

    test('parses modern (case/space-insensitive)', () {
      expect(CartLayout.fromEnv('modern'), CartLayout.modern);
      expect(CartLayout.fromEnv('  MODERN '), CartLayout.modern);
    });

    test('fails fast on an unrecognized value', () {
      expect(() => CartLayout.fromEnv('grid'), throwsA(isA<StateError>()));
    });
  });
}
