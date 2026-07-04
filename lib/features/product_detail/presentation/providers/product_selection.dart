/// Mutable in-progress purchase choice on the product-detail screen: which
/// option values are picked, and how many to buy.
class ProductSelection {
  const ProductSelection({
    required this.selectedOptions,
    required this.quantity,
  });

  /// Empty selection, quantity 1 — the state before a product loads.
  const ProductSelection.initial() : selectedOptions = const {}, quantity = 1;

  /// Option name → chosen value, e.g. `{'Color': 'Black', 'Size': 'M'}`.
  final Map<String, String> selectedOptions;
  final int quantity;

  ProductSelection copyWith({
    Map<String, String>? selectedOptions,
    int? quantity,
  }) {
    return ProductSelection(
      selectedOptions: selectedOptions ?? this.selectedOptions,
      quantity: quantity ?? this.quantity,
    );
  }
}
