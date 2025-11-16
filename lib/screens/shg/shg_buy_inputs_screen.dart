import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../models/product.dart';
import '../../models/product_with_farmer.dart';
import '../../models/product_with_rating.dart';
import '../../models/browse_filter.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../services/product_with_farmer_service.dart';
// import '../../services/rating_service.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/product_skeleton_loader.dart';
import '../../widgets/hero_carousel.dart';
import '../../widgets/image_zoom_dialog.dart';
import 'shg_input_cart_screen.dart';

enum ViewMode { grid, list }

class SHGBuyInputsScreen extends StatefulWidget {
  const SHGBuyInputsScreen({super.key});

  @override
  State<SHGBuyInputsScreen> createState() => _SHGBuyInputsScreenState();
}

class _SHGBuyInputsScreenState extends State<SHGBuyInputsScreen> {
  final ProductService _productService = ProductService();
  final ProductWithFarmerService _productWithFarmerService =
      ProductWithFarmerService();
  // final RatingService _ratingService = RatingService(); // Unused for now
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  ProductCategory? _selectedCategory;
  String _searchQuery = '';
  final bool _sortByDistance = true;
  String _sortBy =
      'distance'; // 'distance', 'rating', 'price_low', 'price_high'
  bool _isSearching = false;
  BrowseFilter _activeFilter = const BrowseFilter();
  ViewMode _viewMode = ViewMode.grid;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Sort products based on selected option
  void _sortProducts(List<ProductWithRating> products) {
    switch (_sortBy) {
      case 'rating':
        products.sort((a, b) {
          final aRating = a.averageRating ?? 0.0;
          final bRating = b.averageRating ?? 0.0;
          if (aRating == bRating) {
            final aTotal = a.totalRatings ?? 0;
            final bTotal = b.totalRatings ?? 0;
            return bTotal.compareTo(aTotal);
          }
          return bRating.compareTo(aRating);
        });
        break;
      case 'price_low':
        products.sort(
          (a, b) => a.productWithFarmer.product.price.compareTo(
            b.productWithFarmer.product.price,
          ),
        );
        break;
      case 'price_high':
        products.sort(
          (a, b) => b.productWithFarmer.product.price.compareTo(
            a.productWithFarmer.product.price,
          ),
        );
        break;
      case 'distance':
      default:
        // Already sorted by distance in ProductWithFarmerService
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.itemCount;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField()
            : const Text('Buy Farming Inputs'),
        centerTitle: !_isSearching,
        elevation: 0,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
            : null,
        actions: [
          // Sort dropdown
          if (!_isSearching)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort by',
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'distance',
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: _sortBy == 'distance'
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Distance',
                        style: TextStyle(
                          fontWeight: _sortBy == 'distance'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rating',
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 18,
                        color: _sortBy == 'rating'
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rating',
                        style: TextStyle(
                          fontWeight: _sortBy == 'rating'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'price_low',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: _sortBy == 'price_low'
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Price: Low to High',
                        style: TextStyle(
                          fontWeight: _sortBy == 'price_low'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'price_high',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color: _sortBy == 'price_high'
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Price: High to Low',
                        style: TextStyle(
                          fontWeight: _sortBy == 'price_high'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search products',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
                Future.delayed(const Duration(milliseconds: 100), () {
                  _searchFocusNode.requestFocus();
                });
              },
            ),
          if (!_isSearching)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter products',
                  onPressed: _showFilterSheet,
                ),
                if (_activeFilter.hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_activeFilter.activeFilterCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (!_isSearching)
            IconButton(
              icon: Icon(
                _viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
              ),
              tooltip: _viewMode == ViewMode.grid
                  ? 'Switch to list view'
                  : 'Switch to grid view',
              onPressed: _toggleViewMode,
            ),
          if (_isSearching && _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.requestFocus();
              },
            ),
          // Cart icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SHGInputCartScreen(),
                    ),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          _buildActiveFilterChips(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.streamPSAProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ProductSkeletonLoader(
                    isListView: _viewMode == ViewMode.list,
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading products: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                var products = snapshot.data ?? [];

                // Apply category filter
                if (_selectedCategory != null) {
                  products = products
                      .where((p) => p.category == _selectedCategory)
                      .toList();
                }

                // Apply search filter (product name, description, business name)
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  products = products
                      .where(
                        (p) =>
                            p.name.toLowerCase().contains(query) ||
                            (p.description?.toLowerCase().contains(query) ??
                                false) ||
                            (p.businessName?.toLowerCase().contains(query) ??
                                false),
                      )
                      .toList();
                }

                if (products.isEmpty &&
                    _searchQuery.isEmpty &&
                    _selectedCategory == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No PSA products available yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PSA suppliers will add products soon',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Load products with farmer details, distance, and ratings
                final authProvider = Provider.of<app_auth.AuthProvider>(
                  context,
                  listen: false,
                );
                final buyerLocation = authProvider.currentUser?.location;

                return FutureBuilder<List<ProductWithFarmer>>(
                  future: _productWithFarmerService
                      .getProductsWithFarmersAndDistance(
                        products: products,
                        buyerLocation: _sortByDistance ? buyerLocation : null,
                      ),
                  builder: (context, farmerSnapshot) {
                    if (farmerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return ProductSkeletonLoader(
                        isListView: _viewMode == ViewMode.list,
                      );
                    }

                    var productsWithFarmers = farmerSnapshot.data ?? [];

                    // Apply PSA name search filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      productsWithFarmers = productsWithFarmers.where((pwf) {
                        final farmerNameMatch = pwf.farmer.name
                            .toLowerCase()
                            .contains(query);
                        final businessNameMatch =
                            pwf.product.businessName?.toLowerCase().contains(
                              query,
                            ) ??
                            false;
                        final productNameMatch = pwf.product.name
                            .toLowerCase()
                            .contains(query);
                        final descriptionMatch =
                            pwf.product.description?.toLowerCase().contains(
                              query,
                            ) ??
                            false;

                        return farmerNameMatch ||
                            businessNameMatch ||
                            productNameMatch ||
                            descriptionMatch;
                      }).toList();
                    }

                    if (productsWithFarmers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.inventory_2_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No results found for "$_searchQuery"'
                                  : 'No products match your filters',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Try different keywords or check spelling',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  _searchFocusNode.requestFocus();
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear Search'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // Load ratings for all PSA suppliers
                    // Ratings display temporarily disabled
                    var productsWithRatings = productsWithFarmers
                        .map(
                          (pwf) => ProductWithRating(
                            productWithFarmer: pwf,
                            farmerRating: null, // Rating display disabled
                          ),
                        )
                        .toList();

                    // Apply active filters
                    productsWithRatings = _applyFilters(productsWithRatings);

                    // Sort products based on selected sort option
                    _sortProducts(productsWithRatings);

                    // Get featured products (top 5 highly rated with sufficient reviews)
                    final featuredProducts = _getFeaturedProducts(
                      productsWithRatings,
                    );

                    if (productsWithRatings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No products match your filters',
                              style: TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _activeFilter = _activeFilter.clear();
                                });
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear All Filters'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Conditional rendering based on view mode
                    return CustomScrollView(
                      slivers: [
                        // Hero Carousel
                        if (featuredProducts.isNotEmpty && _searchQuery.isEmpty)
                          SliverToBoxAdapter(
                            child: HeroCarousel(
                              featuredProducts: featuredProducts,
                            ),
                          ),

                        // Product Grid or List
                        _viewMode == ViewMode.grid
                            ? SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.60,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return _buildGridProductCard(
                                      productsWithRatings[index],
                                    );
                                  }, childCount: productsWithRatings.length),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return _buildListProductCard(
                                      productsWithRatings[index],
                                    );
                                  }, childCount: productsWithRatings.length),
                                ),
                              ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build category filter tabs
  Widget _buildCategoryFilter() {
    if (_isSearching) return const SizedBox.shrink();

    final categories = [
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Crop',
        'value': ProductCategory.crop,
      },
      {
        'icon': Icons.pets_outlined,
        'label': 'Poultry',
        'value': ProductCategory.poultry,
      },
      {
        'icon': Icons.pets_outlined,
        'label': 'Goats',
        'value': ProductCategory.goats,
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Cows',
        'value': ProductCategory.cows,
      },
    ];

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // All Products chip
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = null;
                  });
                },
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: _selectedCategory == null
                      ? Colors.white
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                checkmarkColor: Colors.white,
              ),
            ),
            ...categories.map((cat) {
              final isSelected = _selectedCategory == cat['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(
                    cat['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                  label: Text(cat['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected
                          ? cat['value'] as ProductCategory
                          : null;
                    });
                  },
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  checkmarkColor: Colors.white,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build active filter chips
  Widget _buildActiveFilterChips() {
    if (!_activeFilter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Category chips
            ..._activeFilter.selectedCategories.map((categoryName) {
              final category = ProductCategory.values.firstWhere(
                (c) => c.name == categoryName,
                orElse: () => ProductCategory.other,
              );
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(category.displayName),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      final newCategories = Set<String>.from(
                        _activeFilter.selectedCategories,
                      );
                      newCategories.remove(categoryName);
                      _activeFilter = _activeFilter.copyWith(
                        selectedCategories: newCategories,
                      );
                    });
                  },
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
              );
            }),

            // Price chip
            if (_activeFilter.minPrice != null ||
                _activeFilter.maxPrice != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    _activeFilter.minPrice != null &&
                            _activeFilter.maxPrice != null
                        ? 'UGX ${_activeFilter.minPrice!.toInt()}K-${_activeFilter.maxPrice!.toInt()}K'
                        : _activeFilter.minPrice != null
                        ? '≥ UGX ${_activeFilter.minPrice!.toInt()}K'
                        : '≤ UGX ${_activeFilter.maxPrice!.toInt()}K',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _activeFilter = _activeFilter.copyWith(
                        clearMinPrice: true,
                        clearMaxPrice: true,
                      );
                    });
                  },
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                ),
              ),

            // Distance chip
            if (_activeFilter.maxDistance != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    '≤ ${_activeFilter.maxDistance!.toInt()} km',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _activeFilter = _activeFilter.copyWith(
                        clearMaxDistance: true,
                      );
                    });
                  },
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                ),
              ),

            // Rating chip
            if (_activeFilter.minRating != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    '≥ ${_activeFilter.minRating!.toStringAsFixed(1)}★',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _activeFilter = _activeFilter.copyWith(
                        clearMinRating: true,
                      );
                    });
                  },
                  backgroundColor: Colors.amber.withValues(alpha: 0.2),
                ),
              ),

            // Stock chip
            if (_activeFilter.inStockOnly)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: const Text('In Stock', style: TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _activeFilter = _activeFilter.copyWith(
                        inStockOnly: false,
                      );
                    });
                  },
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                ),
              ),

            // Clear all button
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _activeFilter = _activeFilter.clear();
                });
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  /// Build grid product card
  Widget _buildGridProductCard(ProductWithRating productWithRating) {
    final product = productWithRating.productWithFarmer.product;
    final supplier = productWithRating.productWithFarmer.farmer;
    final distance = productWithRating.productWithFarmer.distanceKm;
    final rating = productWithRating.farmerRating;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (product.images.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) =>
                  ImageZoomDialog(imageUrls: product.images, initialIndex: 0),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  if (product.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        product.images.first,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              _getProductIcon(product.category),
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        _getProductIcon(product.category),
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),

                  // PSA Badge
                  if (supplier.role == UserRole.psa)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 12, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'PSA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Stock Badge
                  if (product.isOutOfStock)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // ✅ System ID and Subcategory
                    if (product.systemId != null || product.subcategory != null)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          if (product.systemId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.qr_code_2,
                                    size: 8,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.systemId!,
                                    style: TextStyle(
                                      fontSize: 7,
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (product.subcategory != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.green[200]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                product.subcategory!,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (product.systemId != null || product.subcategory != null)
                      const SizedBox(height: 3),

                    // Supplier Name with PSA indicator
                    Row(
                      children: [
                        Icon(
                          supplier.role == UserRole.psa
                              ? Icons.business
                              : Icons.person,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            supplier.role == UserRole.psa &&
                                    product.businessName != null
                                ? product.businessName!
                                : supplier.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: supplier.role == UserRole.psa
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating and Distance
                    Row(
                      children: [
                        if (rating != null && rating.averageRating > 0) ...[
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            rating.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' (${rating.totalRatings})',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (distance != null) ...[
                          if (rating != null && rating.averageRating > 0)
                            Text(
                              ' • ',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          Icon(
                            Icons.location_on,
                            size: 11,
                            color: Colors.grey[600],
                          ),
                          Text(
                            '${distance.toStringAsFixed(1)}km',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),

                    // Price
                    Text(
                      'UGX ${NumberFormat('#,###').format(product.price)}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per ${product.unit}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),

                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: product.isOutOfStock
                            ? null
                            : () => _addToCart(product),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: const Text('Add to Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build list product card
  Widget _buildListProductCard(ProductWithRating productWithRating) {
    final product = productWithRating.productWithFarmer.product;
    final supplier = productWithRating.productWithFarmer.farmer;
    final distance = productWithRating.productWithFarmer.distanceKm;
    final rating = productWithRating.farmerRating;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with zoom capability
            GestureDetector(
              onTap: () {
                if (product.images.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => ImageZoomDialog(
                      imageUrls: product.images,
                      initialIndex: 0,
                    ),
                  );
                }
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.images.isNotEmpty
                      ? Stack(
                          children: [
                            Image.network(
                              product.images.first,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    _getProductIcon(product.category),
                                    size: 40,
                                    color: AppTheme.textSecondary,
                                  ),
                                );
                              },
                            ),
                            // Zoom indicator
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          _getProductIcon(product.category),
                          size: 40,
                          color: AppTheme.textSecondary,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Supplier name with PSA badge
                  Row(
                    children: [
                      Icon(
                        supplier.role == UserRole.psa
                            ? Icons.business
                            : Icons.person,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          supplier.role == UserRole.psa &&
                                  product.businessName != null
                              ? product.businessName!
                              : supplier.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: supplier.role == UserRole.psa
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (supplier.role == UserRole.psa) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 10,
                                color: Colors.white,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'PSA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rating and Distance
                  Row(
                    children: [
                      if (rating != null && rating.averageRating > 0) ...[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          rating.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' (${rating.totalRatings})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (distance != null) ...[
                        Icon(
                          Icons.location_on,
                          size: 13,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description
                  if (product.description != null &&
                      product.description!.isNotEmpty)
                    Text(
                      product.description!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Price and Actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UGX ${NumberFormat('#,###').format(product.price)}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'per ${product.unit}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Stock badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.isOutOfStock
                              ? Colors.red.withValues(alpha: 0.1)
                              : AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.isOutOfStock
                                  ? Icons.cancel
                                  : Icons.check_circle,
                              size: 12,
                              color: product.isOutOfStock
                                  ? Colors.red
                                  : AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.isOutOfStock
                                  ? 'Out of Stock'
                                  : 'In Stock',
                              style: TextStyle(
                                color: product.isOutOfStock
                                    ? Colors.red
                                    : AppTheme.successColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Action buttons
                  Row(
                    children: [
                      // Call button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callSupplier(supplier.phone),
                          icon: const Icon(Icons.phone, size: 14),
                          label: const Text(
                            'Call',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add to Cart button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: product.isOutOfStock
                              ? null
                              : () => _addToCart(product),
                          icon: const Icon(Icons.shopping_cart, size: 14),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProductIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.dayOldChicks:
        return Icons.egg_outlined;
      case ProductCategory.feeds:
        return Icons.grass_outlined;
      case ProductCategory.chemicals:
        return Icons.science_outlined;
      case ProductCategory.fertilizers:
        return Icons.eco_outlined;
      case ProductCategory.hoes:
        return Icons.construction_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _callSupplier(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cannot call $phone')));
      }
    }
  }

  void _addToCart(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('${product.name} added to cart')),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SHGInputCartScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<BrowseFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(initialFilter: _activeFilter),
    );

    if (result != null) {
      setState(() {
        _activeFilter = result;
      });
    }
  }

  Future<void> _toggleViewMode() async {
    setState(() {
      _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    });
    await _saveViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final viewModeString =
        prefs.getString('shg_buy_inputs_view_mode') ?? 'grid';
    setState(() {
      _viewMode = viewModeString == 'list' ? ViewMode.list : ViewMode.grid;
    });
  }

  Future<void> _saveViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'shg_buy_inputs_view_mode',
      _viewMode == ViewMode.grid ? 'grid' : 'list',
    );
  }

  List<ProductWithRating> _applyFilters(List<ProductWithRating> products) {
    var filtered = products;

    // Category filter
    if (_activeFilter.selectedCategories.isNotEmpty) {
      filtered = filtered.where((p) {
        return _activeFilter.selectedCategories.contains(
          p.productWithFarmer.product.category.name,
        );
      }).toList();
    }

    // Price filter
    if (_activeFilter.minPrice != null) {
      filtered = filtered.where((p) {
        final priceInThousands = p.productWithFarmer.product.price / 1000;
        return priceInThousands >= _activeFilter.minPrice!;
      }).toList();
    }

    if (_activeFilter.maxPrice != null) {
      filtered = filtered.where((p) {
        final priceInThousands = p.productWithFarmer.product.price / 1000;
        return priceInThousands <= _activeFilter.maxPrice!;
      }).toList();
    }

    // Distance filter
    if (_activeFilter.maxDistance != null) {
      filtered = filtered.where((p) {
        final distance = p.productWithFarmer.distanceKm;
        return distance != null && distance <= _activeFilter.maxDistance!;
      }).toList();
    }

    // Rating filter
    if (_activeFilter.minRating != null) {
      filtered = filtered.where((p) {
        final rating = p.averageRating;
        return rating != null && rating >= _activeFilter.minRating!;
      }).toList();
    }

    // Stock filter
    if (_activeFilter.inStockOnly) {
      filtered = filtered.where((p) {
        return !p.productWithFarmer.product.isOutOfStock;
      }).toList();
    }

    return filtered;
  }

  List<ProductWithRating> _getFeaturedProducts(
    List<ProductWithRating> products,
  ) {
    final featured = products.where((p) {
      final rating = p.farmerRating;
      return rating != null &&
          rating.isHighlyRated &&
          rating.hasSufficientRatings &&
          !p.productWithFarmer.product.isOutOfStock;
    }).toList();

    featured.sort((a, b) {
      final ratingA = a.farmerRating?.averageRating ?? 0;
      final ratingB = b.farmerRating?.averageRating ?? 0;
      final countA = a.farmerRating?.totalRatings ?? 0;
      final countB = b.farmerRating?.totalRatings ?? 0;

      final ratingComparison = ratingB.compareTo(ratingA);
      if (ratingComparison != 0) return ratingComparison;

      return countB.compareTo(countA);
    });

    return featured.take(5).toList();
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: 'Search products, PSAs, or suppliers...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        _searchFocusNode.requestFocus();
      },
    );
  }
}
