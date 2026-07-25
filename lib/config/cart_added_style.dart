/// How the app confirms a successful add-to-cart.
///
/// Tenant-configurable via the `CART_ADDED_STYLE` key in `.env`:
/// - `toast` — a bottom snack bar ("Added to cart"), the default.
/// - `overlay` — a centered, auto-dismissing card with a check mark and
///   "Product added to the cart".
enum CartAddedStyle {
  /// Bottom snack bar.
  toast,

  /// Centered confirmation overlay.
  overlay;

  /// Parses the `CART_ADDED_STYLE` env value. Empty/null → [toast]; an
  /// unrecognized value fails fast so tenant misconfiguration surfaces at
  /// startup rather than silently defaulting.
  static CartAddedStyle fromEnv(String? raw) {
    final value = raw?.trim().toLowerCase();
    return switch (value) {
      null || '' || 'toast' => CartAddedStyle.toast,
      'overlay' => CartAddedStyle.overlay,
      _ => throw StateError(
        'Invalid CART_ADDED_STYLE: "$raw" (use "toast" or "overlay").',
      ),
    };
  }
}
