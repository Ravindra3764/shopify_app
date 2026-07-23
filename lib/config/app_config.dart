import 'package:shopify_app/config/feature_flags.dart';

class AppConfig {
  const AppConfig({
    required this.appName,
    required this.fontFamily,
    required this.shopifyDomain,
    required this.storefrontAccessToken,
    required this.storefrontApiVersion,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.accentColorHex,
    required this.logoAsset,
    required this.features,
    this.defaultCountry = 'US',
    this.wishlistHintText =
        'Double-tap any product to save it to your wishlist.',
    this.popularSearches = const [],
    this.aboutPageHandle,
    this.helpPageHandle,
    this.judgeMeShopDomain,
    this.judgeMeApiToken,
  });

  factory AppConfig.fromEnv(Map<String, String> env) {
    String required(String key) {
      final value = env[key];
      if (value == null || value.isEmpty) {
        throw StateError('Missing required config key: $key');
      }
      return value;
    }

    String? optional(String key) {
      final value = env[key]?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    return AppConfig(
      appName: required('APP_NAME'),
      fontFamily: env['FONT_FAMILY'] ?? 'Roboto',
      shopifyDomain: required('SHOPIFY_DOMAIN'),
      storefrontAccessToken: required('STOREFRONT_ACCESS_TOKEN'),
      storefrontApiVersion: required('STOREFRONT_API_VERSION'),
      primaryColorHex: required('PRIMARY_COLOR'),
      secondaryColorHex: required('SECONDARY_COLOR'),
      accentColorHex: required('ACCENT_COLOR'),
      logoAsset: required('LOGO_ASSET'),
      features: FeatureFlags.fromEnv(env),
      // Home country (ISO code) prefilled on the checkout address form.
      defaultCountry: (env['DEFAULT_COUNTRY'] ?? 'US').trim().toUpperCase(),
      // Onboarding hint copy; falls back to the default when unset/blank.
      wishlistHintText: switch (env['WISHLIST_HINT_TEXT']?.trim()) {
        final String text when text.isNotEmpty => text,
        _ => 'Double-tap any product to save it to your wishlist.',
      },
      // Popular search chips on the search screen; comma-separated per tenant.
      popularSearches: (env['POPULAR_SEARCHES'] ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      // Online Store → Pages handles for the About / Help entries under
      // Profile → More. Null when the tenant has no such page → tile hidden.
      aboutPageHandle: optional('ABOUT_PAGE_HANDLE'),
      helpPageHandle: optional('HELP_PAGE_HANDLE'),
      // Judge.me review provider. When both are set, reviews (read + submit)
      // route to Judge.me; otherwise reviews fall back to Storefront
      // `product_review` metaobjects (read-only).
      judgeMeShopDomain: optional('JUDGEME_SHOP_DOMAIN'),
      judgeMeApiToken: optional('JUDGEME_API_TOKEN'),
    );
  }

  final String appName;
  final String fontFamily;

  final String shopifyDomain;
  final String storefrontAccessToken;
  final String storefrontApiVersion;

  final String primaryColorHex;
  final String secondaryColorHex;
  final String accentColorHex;

  final String logoAsset;
  final FeatureFlags features;

  /// Tenant home country as an ISO 3166-1 alpha-2 code (e.g. `US`, `IN`).
  /// Prefilled as the country on the checkout address form.
  final String defaultCountry;

  /// Copy for the one-time wishlist onboarding hint (see
  /// `FeatureFlags.wishlistDoubleTapHintEnabled`). Configurable per tenant.
  final String wishlistHintText;

  /// Suggested search terms shown as chips on the search screen. Per-tenant.
  final List<String> popularSearches;

  /// Handle of the Online Store "About us" page (Profile → More). Null when
  /// the tenant hasn't published one — the About tile is then hidden.
  final String? aboutPageHandle;

  /// Handle of the Online Store "Help & support" page (Profile → More). Null
  /// when the tenant hasn't published one — the Help tile is then hidden.
  final String? helpPageHandle;

  /// Judge.me shop domain (e.g. `acme.myshopify.com`). Null disables the
  /// Judge.me review provider (reviews then use Storefront metaobjects).
  final String? judgeMeShopDomain;

  /// Judge.me **private** API token. WARNING: privileged (read/write to all
  /// review data) and shipped in the client by tenant choice — treat as
  /// exposed. Null disables the Judge.me review provider.
  final String? judgeMeApiToken;

  /// Whether the Judge.me review provider is fully configured.
  bool get hasJudgeMe =>
      (judgeMeShopDomain?.isNotEmpty ?? false) &&
      (judgeMeApiToken?.isNotEmpty ?? false);
}
