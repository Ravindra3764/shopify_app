import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/core/utils/text_utils.dart';

/// Shop-wide `shippingPolicy` / `refundPolicy` bodies from Settings →
/// Policies in Shopify admin. Either may be `null` if the merchant hasn't
/// configured that policy.
class ShopPolicies {
  const ShopPolicies({this.shippingPolicyBody, this.refundPolicyBody});

  /// Builds from a Storefront `Shop` node.
  factory ShopPolicies.fromJson(Map<String, dynamic> json) {
    final shippingBody = parseStringOrNull(
      parseMap(json, 'shippingPolicy', model: _model),
      'body',
      model: _model,
    );
    final refundBody = parseStringOrNull(
      parseMap(json, 'refundPolicy', model: _model),
      'body',
      model: _model,
    );
    return ShopPolicies(
      shippingPolicyBody: shippingBody == null
          ? null
          : stripHtmlTags(shippingBody),
      refundPolicyBody: refundBody == null ? null : stripHtmlTags(refundBody),
    );
  }

  static const _model = 'ShopPolicies';

  final String? shippingPolicyBody;
  final String? refundPolicyBody;

  /// Combined "Shipping & Return" tab copy, joining whichever policies the
  /// merchant has configured. Empty if neither is set.
  String get combinedCopy {
    final parts = [
      shippingPolicyBody,
      refundPolicyBody,
    ].whereType<String>().where((body) => body.isNotEmpty);
    return parts.join('\n\n');
  }
}
