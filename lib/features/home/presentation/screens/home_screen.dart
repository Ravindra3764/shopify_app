import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/providers/config_providers.dart';

/// Landing screen shown after the splash sequence completes.
///
/// Temporary scaffold until feature routing is added.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
