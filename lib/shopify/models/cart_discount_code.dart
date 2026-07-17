import 'package:shopify_app/core/utils/json_parse.dart';

/// A discount code attached to a Storefront cart.
///
/// Shopify echoes every submitted code back with [applicable] — `false` when
/// the code is invalid, or valid but not usable on this cart (unmet minimum,
/// wrong products, expired). Only [applicable] codes actually reduce the total.
class CartDiscountCode {
  const CartDiscountCode({required this.code, required this.applicable});

  /// Builds from a Storefront `CartDiscountCode` node (`{code, applicable}`).
  factory CartDiscountCode.fromJson(Map<String, dynamic> json) =>
      CartDiscountCode(
        code: parseString(json, 'code', model: _model),
        applicable: parseBool(json, 'applicable', model: _model),
      );

  static const _model = 'CartDiscountCode';

  final String code;
  final bool applicable;
}
