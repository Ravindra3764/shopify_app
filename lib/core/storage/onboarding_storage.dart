import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which one-time onboarding hints the shopper has already seen, so they
/// show once and never again.
///
/// An interface so tests can inject a fake instead of touching disk.
abstract interface class OnboardingStorage {
  /// Whether the wishlist double-tap hint has been shown before.
  bool wishlistHintSeen();

  /// Marks the wishlist hint as shown.
  Future<void> markWishlistHintSeen();
}

/// [OnboardingStorage] backed by `SharedPreferences`.
class SharedPrefsOnboardingStorage implements OnboardingStorage {
  const SharedPrefsOnboardingStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _wishlistHintKey = 'onboarding_wishlist_hint_seen';

  @override
  bool wishlistHintSeen() => _prefs.getBool(_wishlistHintKey) ?? false;

  @override
  Future<void> markWishlistHintSeen() => _prefs.setBool(_wishlistHintKey, true);
}
