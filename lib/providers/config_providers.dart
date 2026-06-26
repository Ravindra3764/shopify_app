import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/config/app_config.dart';
import 'package:shopify_app/config/feature_flags.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden in bootstrap()',
  ),
);

/// Convenience accessor for tenant feature flags.
final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => ref.watch(appConfigProvider).features,
);
