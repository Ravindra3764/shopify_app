import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopify_app/app.dart';
import 'package:shopify_app/config/config_repository.dart';
import 'package:shopify_app/core/storage/address_storage.dart';
import 'package:shopify_app/core/storage/cart_storage.dart';
import 'package:shopify_app/core/storage/onboarding_storage.dart';
import 'package:shopify_app/core/storage/search_history_storage.dart';
import 'package:shopify_app/core/storage/wishlist_storage.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/providers/storage_providers.dart';

/// App entry point. Loads tenant config from `.env` and persistent storage
/// before `runApp`, then injects both into the provider graph via overrides.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await const ConfigRepository().load();
  final prefs = await SharedPreferences.getInstance();
  AppColors.init(config); // tenant brand colors → palette
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        cartStorageProvider.overrideWithValue(SharedPrefsCartStorage(prefs)),
        addressStorageProvider.overrideWithValue(
          SharedPrefsAddressStorage(prefs),
        ),
        wishlistStorageProvider.overrideWithValue(
          SharedPrefsWishlistStorage(prefs),
        ),
        onboardingStorageProvider.overrideWithValue(
          SharedPrefsOnboardingStorage(prefs),
        ),
        searchHistoryStorageProvider.overrideWithValue(
          SharedPrefsSearchHistoryStorage(prefs),
        ),
      ],
      child: const App(),
    ),
  );
}
