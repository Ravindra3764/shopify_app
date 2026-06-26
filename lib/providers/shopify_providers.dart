import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/providers/config_providers.dart';

/// Storefront API transport, built from the active tenant `AppConfig`.
///
/// Repositories depend on this; widgets and notifiers never read it directly.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(config: ref.watch(appConfigProvider)),
);
