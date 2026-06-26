/// Per-tenant feature toggles. Branch feature logic on these flags only,
/// never on tenant name.
class FeatureFlags {
  const FeatureFlags({
    this.wishlistEnabled = true,
    this.reviewsEnabled = false,
    this.searchEnabled = true,
    this.guestCheckoutEnabled = false,
  });

  /// Reads flags from `.env` string values (`"true"` / `"false"`).
  factory FeatureFlags.fromEnv(Map<String, String> env) {
    bool flag(String key, {required bool fallback}) =>
        switch (env[key]?.toLowerCase()) {
          'true' => true,
          'false' => false,
          _ => fallback,
        };
    return FeatureFlags(
      wishlistEnabled: flag('WISHLIST_ENABLED', fallback: true),
      reviewsEnabled: flag('REVIEWS_ENABLED', fallback: false),
      searchEnabled: flag('SEARCH_ENABLED', fallback: true),
      guestCheckoutEnabled: flag('GUEST_CHECKOUT_ENABLED', fallback: false),
    );
  }

  final bool wishlistEnabled;
  final bool reviewsEnabled;
  final bool searchEnabled;
  final bool guestCheckoutEnabled;
}
