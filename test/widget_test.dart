import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/app.dart';
import 'package:shopify_app/config/app_config.dart';
import 'package:shopify_app/config/feature_flags.dart';
import 'package:shopify_app/providers/config_providers.dart';

const _testConfig = AppConfig(
  appName: 'Test Store',
  fontFamily: 'Roboto',
  shopifyDomain: 'test.myshopify.com',
  storefrontAccessToken: 'token',
  storefrontApiVersion: '2025-01',
  primaryColorHex: '#086C4C',
  secondaryColorHex: '#625B71',
  accentColorHex: '#7D5260',
  logoAsset: 'assets/images/logo.png',
  features: FeatureFlags(),
);

void main() {
  testWidgets('App renders tenant name from config', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(_testConfig)],
        child: const App(),
      ),
    );

    expect(find.text('Test Store'), findsWidgets);
    expect(find.text('Primary action'), findsOneWidget);
  });
}
