import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_theme.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/providers/router_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      theme: AppTheme.light(config),
      routerConfig: router,
    );
  }
}
