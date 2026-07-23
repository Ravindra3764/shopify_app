import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/config/promo_offer.dart';

void main() {
  group('PromoOffer.parse', () {
    test('returns empty for null or blank', () {
      expect(PromoOffer.parse(null), isEmpty);
      expect(PromoOffer.parse(''), isEmpty);
      expect(PromoOffer.parse('   '), isEmpty);
    });

    test('parses pipe-separated CODE:Label entries', () {
      final offers = PromoOffer.parse('SAVE10:10% off|FREESHIP:Free shipping');
      expect(offers, hasLength(2));
      expect(offers[0].code, 'SAVE10');
      expect(offers[0].label, '10% off');
      expect(offers[0].minSubtotal, isNull);
      expect(offers[1].code, 'FREESHIP');
      expect(offers[1].label, 'Free shipping');
    });

    test('reads a trailing numeric field as minSubtotal', () {
      final offers = PromoOffer.parse('SAVE10:10% off orders over 999:999');
      expect(offers.single.code, 'SAVE10');
      expect(offers.single.label, '10% off orders over 999');
      expect(offers.single.minSubtotal, 999);
    });

    test('minSubtotal null gates isEligible open; threshold gates it', () {
      const gated = PromoOffer(code: 'SAVE10', label: 'x', minSubtotal: 999);
      const open = PromoOffer(code: 'FREESHIP', label: 'y');
      expect(open.isEligible(0), isTrue);
      expect(gated.isEligible(998), isFalse);
      expect(gated.isEligible(999), isTrue);
      expect(gated.isEligible(1500), isTrue);
    });

    test('uppercases the code and trims whitespace', () {
      final offers = PromoOffer.parse('  save10 : 10% off  ');
      expect(offers.single.code, 'SAVE10');
      expect(offers.single.label, '10% off');
    });

    test('falls back to code as label when no colon', () {
      final offers = PromoOffer.parse('WELCOME');
      expect(offers.single.code, 'WELCOME');
      expect(offers.single.label, 'WELCOME');
    });

    test('keeps colons that appear inside the label', () {
      final offers = PromoOffer.parse('DEAL:Buy 1: get 1 free');
      expect(offers.single.code, 'DEAL');
      expect(offers.single.label, 'Buy 1: get 1 free');
    });

    test('skips entries with no code', () {
      final offers = PromoOffer.parse('SAVE10:ten|:orphan label|  |WELCOME');
      expect(offers.map((o) => o.code), ['SAVE10', 'WELCOME']);
    });
  });
}
