import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shopify_app/config/app_config.dart';

/// Loads tenant configuration from the active `.env` file.
///
/// Swap the bundled `.env` per tenant/flavor at build time; feature logic
/// reads the resulting [AppConfig] and never touches `dotenv` directly.
class ConfigRepository {
  const ConfigRepository();

  /// Loads and parses config. Call once in `bootstrap()` before `runApp`.
  Future<AppConfig> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
    return AppConfig.fromEnv(dotenv.env);
  }
}
