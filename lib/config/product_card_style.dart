/// How individual product cards render across the app (home rows, collection
/// grids, wishlist, search results, related products).
///
/// Tenant-configurable via the `PRODUCT_CARD_STYLE` key in `.env`:
/// - `classic` — image panel with the title + price stacked below, wishlist
///   heart floated over the image (the default look).
/// - `floating` — an elevated white card: rounded image on top, title + price
///   below, a circular "quick add" button, and a pill-shaped wishlist heart.
enum ProductCardStyle {
  /// Flat card: image panel, title and price stacked beneath it.
  classic,

  /// Elevated white card with a circular quick-add button.
  floating;

  /// Parses the `PRODUCT_CARD_STYLE` env value. Empty/null → [classic]; an
  /// unrecognized value fails fast so tenant misconfiguration surfaces at
  /// startup rather than silently defaulting.
  static ProductCardStyle fromEnv(String? raw) {
    final value = raw?.trim().toLowerCase();
    return switch (value) {
      null || '' || 'classic' => ProductCardStyle.classic,
      'floating' => ProductCardStyle.floating,
      _ => throw StateError(
        'Invalid PRODUCT_CARD_STYLE: "$raw" (use "classic" or "floating").',
      ),
    };
  }
}
