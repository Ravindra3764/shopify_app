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

  /// Thin 1px border / divider stroke.
  static const double hairline = 1;

  static const double cardRadius = 8;

  static const double buttonHeight = 52;
  static const double iconSm = 16;
  static const double iconMd = 24;

  static const double retryButtonWidth = 160;

  /// Grab-handle for the Blinkit-style product sheet.
  static const double sheetHandleWidth = 40;
  static const double sheetHandleHeight = 4;

  /// Sizes for the animated double-tap wishlist onboarding hint.
  static const double hintMaxWidth = 360;
  static const double hintStageSize = 140;
  static const double hintRippleSize = 120;
  static const double hintHeartSize = 56;
  static const double hintFingerSize = 44;

  /// Heights for home content blocks.
  static const double bannerHeight = 460;
  static const double productCardWidth = 200;
  static const double productCardHeight = 260;
  static const double productImageHeight = 200;
  static const double categoryTileHeight = 150;

  /// Sizes for the product-detail screen.
  static const double productGalleryHeight = 460;
  static const double circleIconButtonSize = 36;
  static const double galleryDotSize = 6;
  static const double galleryDotActiveWidth = 18;
  static const double swatchSize = 46;
  static const double swatchRingWidth = 2;
  static const double optionChipHeight = 44;
  static const double quantityStepperWidth = 120;
  static const double shimmerTitleWidth = 220;
  static const double shimmerShortWidth = 120;

  /// Sizes for the floating bottom navigation bar.
  static const double floatingNavHeight = 64;
  static const double floatingNavRadius = 32;
  static const double floatingNavItemRadius = 24;
  static const double floatingNavIconSize = 24;
  static const double floatingNavShadowBlur = 20;
  static const double floatingNavShadowOffsetY = 8;

  /// Bottom padding scrollable tab content needs so its last item clears
  /// the floating nav bar instead of sitting behind it.
  static const double floatingNavClearance = floatingNavHeight + AppSpacing.xl;

  /// Sizes for the cart screen.
  static const double cartThumbSize = 96;
  static const double cartSummaryShimmerHeight = 180;

  /// Line-item thumbnail on the order confirmation screen.
  static const double orderThumbSize = 56;

  /// Diameter of the animated success badge on the confirmation screen.
  static const double successBadgeSize = 96;

  /// Diameter of the count badge overlaid on a cart icon.
  static const double cartBadgeSize = 18;
}
