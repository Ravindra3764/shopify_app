import 'package:shopify_app/core/utils/json_parse.dart';
import 'package:shopify_app/core/utils/text_utils.dart';

/// A block of static store content shown under Profile → More.
///
/// Backs two Storefront sources with one shape:
/// - **Store policies** (`privacyPolicy`, `termsOfService`) from Settings →
///   Policies, which expose `{ title, body, url }`.
/// - **Content pages** (`page(handle:)`) from Online Store → Pages, which
///   expose `{ title, body, onlineStoreUrl }`.
///
/// [body] is the HTML source flattened to readable plain text. An empty
/// [body] means the merchant hasn't configured that policy/page yet — the
/// screen renders an empty state in that case.
class ShopContentPage {
  const ShopContentPage({required this.title, required this.body, this.url});

  /// Builds from a Storefront `ShopPolicy` or `Page` node. Tolerates either
  /// `url` (policy) or `onlineStoreUrl` (page) for the canonical web link.
  factory ShopContentPage.fromJson(Map<String, dynamic> json) {
    final rawBody = parseStringOrNull(json, 'body', model: _model);
    return ShopContentPage(
      title: parseString(json, 'title', model: _model),
      body: rawBody == null ? '' : htmlToPlainText(rawBody),
      url:
          parseStringOrNull(json, 'url', model: _model) ??
          parseStringOrNull(json, 'onlineStoreUrl', model: _model),
    );
  }

  static const _model = 'ShopContentPage';

  final String title;
  final String body;
  final String? url;

  /// Whether the merchant has configured any copy for this content.
  bool get hasContent => body.isNotEmpty;
}
