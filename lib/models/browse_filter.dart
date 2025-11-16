/// Browse Filter Model
/// Manages filter state for product browsing
class BrowseFilter {
  final Set<String> selectedCategories;
  final double? minPrice;
  final double? maxPrice;
  final double? maxDistance; // in kilometers
  final double? minRating; // minimum rating filter (e.g., 4.0 for 4+ stars)
  final bool inStockOnly;

  const BrowseFilter({
    this.selectedCategories = const {},
    this.minPrice,
    this.maxPrice,
    this.maxDistance,
    this.minRating,
    this.inStockOnly = false,
  });

  /// Check if any filters are active
  bool get hasActiveFilters {
    return selectedCategories.isNotEmpty ||
        minPrice != null ||
        maxPrice != null ||
        maxDistance != null ||
        minRating != null ||
        inStockOnly;
  }

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (selectedCategories.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (maxDistance != null) count++;
    if (minRating != null) count++;
    if (inStockOnly) count++;
    return count;
  }

  /// Create a copy with updated values
  BrowseFilter copyWith({
    Set<String>? selectedCategories,
    double? minPrice,
    double? maxPrice,
    double? maxDistance,
    double? minRating,
    bool? inStockOnly,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMaxDistance = false,
    bool clearMinRating = false,
  }) {
    return BrowseFilter(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      maxDistance: clearMaxDistance ? null : (maxDistance ?? this.maxDistance),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }

  /// Clear all filters
  BrowseFilter clear() {
    return const BrowseFilter();
  }

  /// Get filter description for display
  String getDescription() {
    final List<String> descriptions = [];

    if (selectedCategories.isNotEmpty) {
      descriptions.add('${selectedCategories.length} categories');
    }

    if (minPrice != null || maxPrice != null) {
      if (minPrice != null && maxPrice != null) {
        descriptions.add('UGX ${minPrice!.toInt()}K-${maxPrice!.toInt()}K');
      } else if (minPrice != null) {
        descriptions.add('≥ UGX ${minPrice!.toInt()}K');
      } else {
        descriptions.add('≤ UGX ${maxPrice!.toInt()}K');
      }
    }

    if (maxDistance != null) {
      descriptions.add('≤ ${maxDistance!.toInt()} km');
    }

    if (minRating != null) {
      descriptions.add('≥ ${minRating!.toStringAsFixed(1)}★');
    }

    if (inStockOnly) {
      descriptions.add('In stock');
    }

    return descriptions.join(' • ');
  }

  @override
  String toString() {
    return 'BrowseFilter(categories: $selectedCategories, price: $minPrice-$maxPrice, '
        'distance: $maxDistance, rating: $minRating, inStock: $inStockOnly)';
  }
}
