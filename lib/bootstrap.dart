import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/app.dart';
import 'package:shopify_app/config/config_repository.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/providers/config_providers.dart';

/// App entry point. Loads tenant config from `.env` before `runApp`, then
/// injects it into the provider graph via an override.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await const ConfigRepository().load();
  AppColors.init(config); // tenant brand colors → palette
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const App(),
    ),
  );
}
