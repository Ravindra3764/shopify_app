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
}
