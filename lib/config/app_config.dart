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
  });

  factory AppConfig.fromEnv(Map<String, String> env) {
    String required(String key) {
      final value = env[key];
      if (value == null || value.isEmpty) {
        throw StateError('Missing required config key: $key');
      }
      return value;
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
}
