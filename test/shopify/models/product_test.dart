import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/shopify/models/product.dart';

Map<String, dynamic> _node({List<Map<String, dynamic>>? variantNodes}) => {
  'id': 'gid://shopify/Product/1',
  'title': 'Chair',
  'handle': 'chair',
  'availableForSale': true,
  'priceRange': {
    'minVariantPrice': {'amount': '250.00', 'currencyCode': 'USD'},
  },
  'compareAtPriceRange': {
    'minVariantPrice': {'amount': '0.0', 'currencyCode': 'USD'},
  },
  if (variantNodes != null) 'variants': {'nodes': variantNodes},
};

void main() {
  group('Product.firstVariantId', () {
    test('parses the first variant id from variants.nodes', () {
      final product = Product.fromJson(
        _node(
          variantNodes: [
            {'id': 'gid://shopify/ProductVariant/10'},
            {'id': 'gid://shopify/ProductVariant/11'},
          ],
        ),
      );
      expect(product.firstVariantId, 'gid://shopify/ProductVariant/10');
    });

    test('is null when the summary omits variants', () {
      expect(Product.fromJson(_node()).firstVariantId, isNull);
    });

    test('round-trips through toJson', () {
      final product = Product.fromJson(
        _node(
          variantNodes: [
            {'id': 'gid://shopify/ProductVariant/10'},
          ],
        ),
      );
      final restored = Product.fromJson(product.toJson());
      expect(restored.firstVariantId, 'gid://shopify/ProductVariant/10');
    });
  });
}
