/// How search results are ordered. Maps to Shopify `ProductSortKeys` + reverse.
enum SearchSort {
  relevance('Relevance'),
  priceLowToHigh('Price: low to high'),
  priceHighToLow('Price: high to low'),
  titleAToZ('Name: A to Z'),
  bestSelling('Best selling');

  const SearchSort(this.label);

  /// Human-readable label for the filter sheet.
  final String label;

  /// The Storefront `ProductSortKeys` value for this sort.
  String get sortKey => switch (this) {
    SearchSort.relevance => 'RELEVANCE',
    SearchSort.priceLowToHigh || SearchSort.priceHighToLow => 'PRICE',
    SearchSort.titleAToZ => 'TITLE',
    SearchSort.bestSelling => 'BEST_SELLING',
  };

  /// Whether Shopify should reverse the sort (descending).
  bool get reverse => this == SearchSort.priceHighToLow;
}

/// Refinements applied on top of the raw search term. Immutable; copy to
/// change.
class SearchFilters {
  const SearchFilters({
    this.sort = SearchSort.relevance,
    this.inStockOnly = false,
    this.minPrice,
    this.maxPrice,
  });

  final SearchSort sort;
  final bool inStockOnly;
  final double? minPrice;
  final double? maxPrice;

  /// Whether any refinement is active (drives the "filter on" indicator).
  bool get isActive =>
      sort != SearchSort.relevance ||
      inStockOnly ||
      minPrice != null ||
      maxPrice != null;

  /// Shopify query tokens for the non-sort refinements, appended to the term
  /// (e.g. `available_for_sale:true variants.price:>=10 variants.price:<=50`).
  String get queryTokens {
    final tokens = <String>[
      if (inStockOnly) 'available_for_sale:true',
      if (minPrice != null) 'variants.price:>=${_fmt(minPrice!)}',
      if (maxPrice != null) 'variants.price:<=${_fmt(maxPrice!)}',
    ];
    return tokens.join(' ');
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  SearchFilters copyWith({
    SearchSort? sort,
    bool? inStockOnly,
    double? Function()? minPrice,
    double? Function()? maxPrice,
  }) {
    return SearchFilters(
      sort: sort ?? this.sort,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    );
  }
}
