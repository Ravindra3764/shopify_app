/// Per-tenant feature toggles. Branch feature logic on these flags only,
/// never on tenant name.
class FeatureFlags {
  const FeatureFlags({
    this.wishlistEnabled = true,
    this.reviewsEnabled = false,
    this.searchEnabled = true,
    this.guestCheckoutEnabled = false,
    this.addressBookEnabled = true,
    this.promoCodesEnabled = false,
    this.promoOffersEnabled = false,
    this.inAppWebviewCheckout = true,
    this.phoneRequired = false,
    this.wishlistDoubleTapHintEnabled = true,
    this.wishlistHintAlways = false,
    this.productDetailSheetEnabled = false,
    this.reviewSubmissionEnabled = false,
    this.reviewOnlyPurchased = false,
    this.cardImageTintEnabled = true,
  });

  /// Reads flags from `.env` string values (`"true"` / `"false"`).
  factory FeatureFlags.fromEnv(Map<String, String> env) {
    bool flag(String key, {required bool fallback}) =>
        switch (env[key]?.trim().toLowerCase()) {
          'true' => true,
          'false' => false,
          null || '' => fallback,
          final invalid => throw StateError(
            'Invalid boolean for "$key" in .env: "$invalid" '
            '(expected "true" or "false").',
          ),
        };
    return FeatureFlags(
      wishlistEnabled: flag('WISHLIST_ENABLED', fallback: true),
      reviewsEnabled: flag('REVIEWS_ENABLED', fallback: false),
      searchEnabled: flag('SEARCH_ENABLED', fallback: true),
      guestCheckoutEnabled: flag('GUEST_CHECKOUT_ENABLED', fallback: false),
      addressBookEnabled: flag('CHECKOUT_ADDRESS_BOOK_ENABLED', fallback: true),
      promoCodesEnabled: flag('CHECKOUT_PROMO_CODES_ENABLED', fallback: false),
      promoOffersEnabled: flag(
        'CHECKOUT_PROMO_OFFERS_ENABLED',
        fallback: false,
      ),
      inAppWebviewCheckout: flag(
        'CHECKOUT_IN_APP_WEBVIEW_ENABLED',
        fallback: true,
      ),
      phoneRequired: flag('CHECKOUT_PHONE_REQUIRED', fallback: false),
      wishlistDoubleTapHintEnabled: flag(
        'WISHLIST_DOUBLE_TAP_HINT_ENABLED',
        fallback: true,
      ),
      wishlistHintAlways: flag('WISHLIST_HINT_ALWAYS', fallback: false),
      productDetailSheetEnabled: flag(
        'PRODUCT_DETAIL_SHEET_ENABLED',
        fallback: false,
      ),
      reviewSubmissionEnabled: flag(
        'REVIEW_SUBMISSION_ENABLED',
        fallback: false,
      ),
      reviewOnlyPurchased: flag('REVIEW_ONLY_PURCHASED', fallback: false),
      cardImageTintEnabled: flag('PRODUCT_CARD_TINT_ENABLED', fallback: true),
    );
  }

  final bool wishlistEnabled;
  final bool reviewsEnabled;
  final bool searchEnabled;

  /// Whether a shopper can check out without signing in. When `false`, the
  /// checkout flow is gated behind sign-in.
  final bool guestCheckoutEnabled;

  /// Whether shoppers can save and reuse multiple delivery addresses locally.
  final bool addressBookEnabled;

  /// Whether a promo-code entry is offered during checkout.
  final bool promoCodesEnabled;

  /// Whether tenant-advertised promo codes (`AppConfig.promoOffers`) are
  /// surfaced at checkout as a one-tap-to-apply banner. Independent of
  /// [promoCodesEnabled] (the manual entry field).
  final bool promoOffersEnabled;

  /// Whether the hosted Shopify payment page opens in an in-app WebView
  /// (`true`) or the device's external browser (`false`).
  final bool inAppWebviewCheckout;

  /// Whether a phone number is required on the delivery address form.
  final bool phoneRequired;

  /// Whether to show the "double-tap to wishlist" onboarding hint. Only shown
  /// when [wishlistEnabled] is also `true`.
  final bool wishlistDoubleTapHintEnabled;

  /// When `true`, the hint shows on every app launch (useful for demos/QA);
  /// when `false` (default), it shows once and never again.
  final bool wishlistHintAlways;

  /// When `true`, tapping a product opens the Blinkit-style draggable sheet
  /// (partial preview that expands to full, horizontal-swipe between the
  /// siblings you came from); `false` uses the classic full-page detail.
  final bool productDetailSheetEnabled;

  /// Whether shoppers can submit a review from the app. Requires a write-
  /// capable review provider (the Storefront API is read-only); defaults to
  /// `false` until a tenant wires one in.
  final bool reviewSubmissionEnabled;

  /// When `true`, only customers who purchased a product (it appears in one of
  /// their orders) may review it; when `false`, any signed-in shopper can
  /// review any product. Only meaningful when [reviewSubmissionEnabled].
  final bool reviewOnlyPurchased;

  /// When `true`, product cards tint their panel with a color sampled from the
  /// product image (Pinterest-style) and `contain` the photo on it. When
  /// `false`, cards use the flat surface fill (masonry cards go full-bleed
  /// `cover`, standard cards `contain` on surface).
  final bool cardImageTintEnabled;
}
