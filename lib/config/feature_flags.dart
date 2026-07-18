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
    this.inAppWebviewCheckout = true,
    this.phoneRequired = false,
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
      inAppWebviewCheckout: flag(
        'CHECKOUT_IN_APP_WEBVIEW_ENABLED',
        fallback: true,
      ),
      phoneRequired: flag('CHECKOUT_PHONE_REQUIRED', fallback: false),
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

  /// Whether the hosted Shopify payment page opens in an in-app WebView
  /// (`true`) or the device's external browser (`false`).
  final bool inAppWebviewCheckout;

  /// Whether a phone number is required on the delivery address form.
  final bool phoneRequired;
}
