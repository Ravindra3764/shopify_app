import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/config/app_config.dart';
import 'package:shopify_app/config/feature_flags.dart';
import 'package:shopify_app/config/product_card_style.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden in bootstrap()',
  ),
);

/// Convenience accessor for tenant feature flags.
final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => ref.watch(appConfigProvider).features,
);

/// Fixed main-axis extent a product card needs for the active card style —
/// the floating card is taller than the classic one. Used by every
/// fixed-height card row/grid so cards never overflow when a tenant switches
/// `PRODUCT_CARD_STYLE`.
final productCardExtentProvider = Provider<double>((ref) {
  final style = ref.watch(appConfigProvider.select((c) => c.productCardStyle));
  return switch (style) {
    ProductCardStyle.classic => AppDimensions.productCardHeight,
    ProductCardStyle.floating => AppDimensions.productCardHeightFloating,
  };
});
