import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_router.dart';
import 'package:shopify_app/providers/config_providers.dart';

/// App-wide [GoRouter]. Built once and reused for the app's lifetime.
final routerProvider = Provider<GoRouter>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return createRouter(
    sheetProductDetail: flags.productDetailSheetEnabled,
    searchEnabled: flags.searchEnabled,
  );
});
