/// Passed as a product route's `extra` when opening from a list, so the
/// Blinkit-style sheet can swipe horizontally through the same siblings.
class ProductPeekArgs {
  const ProductPeekArgs({required this.handles, required this.initialIndex});

  /// Product handles of the source list, in display order.
  final List<String> handles;

  /// Index of the tapped product within [handles].
  final int initialIndex;
}
