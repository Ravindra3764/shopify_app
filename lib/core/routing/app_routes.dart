/// Centralized route paths and names.
///
/// One source of truth for navigation targets and deep links. Build collection
/// links with [collectionPath] so the encoding stays consistent.
abstract final class AppRoutes {
  /// Splash / launch route.
  static const String splash = '/';

  /// Home route.
  static const String home = '/home';

  /// Cart tab route.
  static const String cart = '/cart';

  /// Profile tab route.
  static const String profile = '/profile';

  /// Sign-in route (pushed full-screen).
  static const String login = '/login';

  /// Registration route (pushed full-screen).
  static const String register = '/register';

  /// Password-recovery route (pushed full-screen).
  static const String forgotPassword = '/forgot-password';

  /// Wishlist route (pushed full-screen; gated by the wishlist feature flag).
  static const String wishlist = '/wishlist';

  /// Search route (pushed full-screen; gated by the search feature flag).
  static const String search = '/search';

  /// Checkout wizard (address → shipping → review).
  static const String checkout = '/checkout';

  /// Hosted payment page (in-app WebView or external browser).
  static const String checkoutPay = '/checkout/pay';

  /// Order confirmation shown after successful payment.
  static const String orderConfirmed = '/checkout/confirmed';

  /// Collection product grid; deep-link pattern `/collection/:handle`.
  static const String collection = '/collection/:handle';

  /// Route name used for `goNamed` / `pushNamed`.
  static const String collectionName = 'collection';

  /// Builds a concrete collection location, e.g. `/collection/men`.
  ///
  /// The display title is passed separately via the route's `extra`, not the
  /// URL — see `CollectionScreen`.
  static String collectionPath(String handle) =>
      '/collection/${Uri.encodeComponent(handle)}';

  /// Product detail; deep-link pattern `/product/:handle`.
  static const String productDetail = '/product/:handle';

  /// Route name used for `goNamed` / `pushNamed`.
  static const String productDetailName = 'productDetail';

  /// Builds a concrete product-detail location, e.g. `/product/noir-trench`.
  static String productDetailPath(String handle) =>
      '/product/${Uri.encodeComponent(handle)}';
}
