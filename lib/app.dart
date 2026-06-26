import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/core/theme/app_theme.dart';
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
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary landing screen until feature routing is added.
class _PlaceholderHome extends ConsumerWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: Text(config.appName)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'White-label scaffold ready',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: () {}, child: const Text('Primary action')),
          ],
        ),
      ),
    );
  }
}
