import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/config/product_card_style.dart';

void main() {
  group('ProductCardStyle.fromEnv', () {
    test('defaults to classic for null/empty/classic', () {
      expect(ProductCardStyle.fromEnv(null), ProductCardStyle.classic);
      expect(ProductCardStyle.fromEnv(''), ProductCardStyle.classic);
      expect(ProductCardStyle.fromEnv('classic'), ProductCardStyle.classic);
    });

    test('parses floating (case/space-insensitive)', () {
      expect(ProductCardStyle.fromEnv('floating'), ProductCardStyle.floating);
      expect(
        ProductCardStyle.fromEnv('  FLOATING '),
        ProductCardStyle.floating,
      );
    });

    test('fails fast on an unrecognized value', () {
      expect(
        () => ProductCardStyle.fromEnv('fancy'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
