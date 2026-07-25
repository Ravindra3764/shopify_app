/// How the cart screen lays out its line items.
///
/// Tenant-configurable via the `CART_LAYOUT` key in `.env`:
/// - `classic` — the default row with an inline "X" remove button.
/// - `modern` — a cleaner row (rounded thumbnail, accent price, stepper) where
///   items are removed by swiping right-to-left instead of an "X".
enum CartLayout {
  /// Default cart row with an inline remove button.
  classic,

  /// Restyled row with swipe-to-delete (no inline remove button).
  modern;

  /// Parses the `CART_LAYOUT` env value. Empty/null → [classic]; an
  /// unrecognized value fails fast so tenant misconfiguration surfaces at
  /// startup rather than silently defaulting.
  static CartLayout fromEnv(String? raw) {
    final value = raw?.trim().toLowerCase();
    return switch (value) {
      null || '' || 'classic' => CartLayout.classic,
      'modern' => CartLayout.modern,
      _ => throw StateError(
        'Invalid CART_LAYOUT: "$raw" (use "classic" or "modern").',
      ),
    };
  }
}
