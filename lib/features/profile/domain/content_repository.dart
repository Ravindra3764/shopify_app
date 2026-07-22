import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/shopify/models/shop_content_page.dart';

/// Reads static store content (policies + content pages) shown under
/// Profile → More. Backed by the Storefront API in `data/`.
///
/// A merchant may not have configured a given policy/page yet; that surfaces
/// as a [ShopContentPage] with an empty body (not a [Failure]).
abstract interface class ContentRepository {
  /// Store privacy policy (Settings → Policies).
  Future<Result<ShopContentPage, Failure>> getPrivacyPolicy();

  /// Store terms of service (Settings → Policies).
  Future<Result<ShopContentPage, Failure>> getTermsOfService();

  /// A content page by [handle] (Online Store → Pages).
  Future<Result<ShopContentPage, Failure>> getPage(String handle);
}
