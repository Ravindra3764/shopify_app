import 'package:flutter/material.dart';
import 'package:shopify_app/config/app_config.dart';

abstract final class AppColors {
  // --- Brand (tenant-driven) -------------------------------------------------

  /// Primary brand color, parsed from `PRIMARY_COLOR` in `.env`.
  static late Color primary;

  /// Sets tenant-driven colors. Must run before the theme is built.
  static void init(AppConfig config) {
    primary = fromHex(config.primaryColorHex);
    secondary = fromHex(config.secondaryColorHex);
    accent = fromHex(config.accentColorHex);
  }

  /// Secondary brand color, from `SECONDARY_COLOR`.
  static late Color secondary;

  /// Accent brand color, from `ACCENT_COLOR`.
  static late Color accent;

  // --- Neutrals (shared) -----------------------------------------------------

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF434656);
  static const Color textTertiary = Color(0xFF8A8A8E);
  static const Color hint = Color(0xFF9E9E9E);

  static const Color background = Color(0xFFF7F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDDD8D0);
  static const Color divider = Color(0xFFECECEC);
  static const Color boxFill = Color(0xFFF6EFEC);
  static const Color disabled = Color(0xFFE5E5EA);
  static const Color shimmerBase = Color(0xFFEFEFEF);
  static const Color shimmerHighlight = Color(0xFFF7F7F7);

  // --- Semantic (shared) -----------------------------------------------------

  static const Color success = Color(0xFF28B446);
  static const Color error = Color(0xFFEB543E);
  static const Color warning = Color(0xFFF7B539);
  static const Color rating = Color(0xFFF7B539);
  static const Color discount = Color(0xFFF14336);

  // --- Helpers -------------------------------------  --------------------------

  /// Parses a hex string (`#RRGGBB`, `RRGGBB`, or `#AARRGGBB`) into a [Color].
  static Color fromHex(String hex) {
    var value = hex.replaceFirst('#', '').toUpperCase();
    if (value.length == 6) value = 'FF$value'; // assume opaque
    return Color(int.parse(value, radix: 16));
  }
}
