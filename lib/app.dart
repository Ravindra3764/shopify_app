import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_theme.dart';
import 'package:shopify_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:shopify_app/providers/config_providers.dart';

/// Root widget. Builds the themed [MaterialApp] from tenant config.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return MaterialApp(
      title: config.appName,
      theme: AppTheme.light(config),
      home: const SplashScreen(),
    );
  }
}
