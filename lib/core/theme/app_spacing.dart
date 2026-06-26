/// Centralized spacing scale. Use these instead of magic numbers in widgets.
///
/// ```dart
/// Padding(padding: EdgeInsets.all(AppSpacing.md), child: ...)
/// SizedBox(height: AppSpacing.sm)
/// ```
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Centralized radii / sizes. Extend as needed; never hardcode in widgets.
abstract final class AppDimensions {
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;

  static const double cardRadius = 8;

  static const double buttonHeight = 52;
  static const double iconSm = 16;
  static const double iconMd = 24;

  static const double retryButtonWidth = 160;

  /// Heights for home content blocks.
  static const double bannerHeight = 460;
  static const double productCardWidth = 200;
  static const double productCardHeight = 260;
  static const double productImageHeight = 200;
  static const double categoryTileHeight = 150;
}
