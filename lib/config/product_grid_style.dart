/// How product grids render across the app (collection screens, the browse
/// feed, and any square-card grid).
///
/// Tenant-configurable via the `PRODUCT_GRID_STYLE` key in `.env`:
/// - `standard` — fixed-height 2-column grid (the default look).
/// - `masonry` — Pinterest-style staggered feed where each card's height
///   follows its image aspect ratio.
enum ProductGridStyle {
  /// Uniform 2-column grid of equal-height cards.
  standard,

  /// Staggered, variable-height "waterfall" feed.
  masonry;

  /// Parses the `PRODUCT_GRID_STYLE` env value. Empty/null → [standard];
  /// an unrecognized value fails fast so tenant misconfiguration surfaces at
  /// startup rather than silently defaulting.
  static ProductGridStyle fromEnv(String? raw) {
    final value = raw?.trim().toLowerCase();
    return switch (value) {
      null || '' || 'standard' => ProductGridStyle.standard,
      'masonry' => ProductGridStyle.masonry,
      _ => throw StateError(
        'Invalid PRODUCT_GRID_STYLE: "$raw" (use "standard" or "masonry").',
      ),
    };
  }
}
