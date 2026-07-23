import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/shopify/models/promo_offer.dart';

Map<String, dynamic> _node({
  String? code,
  String? label,
  String? minSubtotal,
}) => {
  'id': 'gid://shopify/Metaobject/1',
  if (code != null) 'code': {'value': code},
  if (label != null) 'label': {'value': label},
  if (minSubtotal != null) 'minSubtotal': {'value': minSubtotal},
};

void main() {
  group('PromoOffer.fromJson', () {
    test('maps aliased metaobject fields', () {
      final offer = PromoOffer.fromJson(
        _node(code: 'save10', label: '10% off', minSubtotal: '999.0'),
      );
      expect(offer.code, 'SAVE10');
      expect(offer.label, '10% off');
      expect(offer.minSubtotal, 999.0);
    });

    test('falls back to code as label when label is unset', () {
      final offer = PromoOffer.fromJson(_node(code: 'WELCOME'));
      expect(offer.code, 'WELCOME');
      expect(offer.label, 'WELCOME');
      expect(offer.minSubtotal, isNull);
    });

    test('leaves minSubtotal null when the field is absent or non-numeric', () {
      expect(PromoOffer.fromJson(_node(code: 'A')).minSubtotal, isNull);
      expect(
        PromoOffer.fromJson(_node(code: 'A', minSubtotal: 'free')).minSubtotal,
        isNull,
      );
    });

    test('yields an empty code for a malformed node (repo filters these)', () {
      expect(PromoOffer.fromJson(_node(label: 'orphan')).code, '');
    });
  });

  group('isEligible', () {
    test('no threshold is always eligible', () {
      const offer = PromoOffer(code: 'FREESHIP', label: 'x');
      expect(offer.isEligible(0), isTrue);
    });

    test('threshold gates on subtotal', () {
      const offer = PromoOffer(code: 'SAVE10', label: 'x', minSubtotal: 999);
      expect(offer.isEligible(998), isFalse);
      expect(offer.isEligible(999), isTrue);
      expect(offer.isEligible(1500), isTrue);
    });
  });
}
