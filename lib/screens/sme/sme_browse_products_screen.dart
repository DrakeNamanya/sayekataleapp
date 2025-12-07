import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import '../../models/product_with_farmer.dart';
import '../../models/product_with_rating.dart';
import '../../models/browse_filter.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../services/product_with_farmer_service.dart';
import '../../services/favorite_service.dart';
// import '../../services/rating_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/product_skeleton_loader.dart';
import '../../widgets/hero_carousel.dart';
import '../customer/product_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode { grid, list }

class SMEBrowseProductsScreen extends StatefulWidget {
  const SMEBrowseProductsScreen({super.key});

  @override
  State<SMEBrowseProductsScreen> createState() =>
      _SMEBrowseProductsScreenState();
}

class _SMEBrowseProductsScreenState extends State<SMEBrowseProductsScreen> {
  final ProductService _productService = ProductService();
  final ProductWithFarmerService _productWithFarmerService =
      ProductWithFarmerService();
  final FavoriteService _favoriteService = FavoriteService();
  // final RatingService _ratingService = RatingService(); // Unused for now
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  ProductCategory? _selectedCategory;
  String _searchQuery = '';
  final bool _sortByDistance = true; // Default to sorting by distance
  String _sortBy =
      'distance'; // 'distance', 'rating', 'price_low', 'price_high'
  Set<String> _favoriteProductIds = {}; // Track favorite products
  bool _isSearching = false; // Track if search bar is active
  BrowseFilter _activeFilter = const BrowseFilter(); // Active filters
  ViewMode _viewMode = ViewMode.grid; // Current view mode

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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

  /// Load user's favorite products
  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      final favoriteIds = await _favoriteService.getUserFavoriteProductIds(
        userId,
      );
      setState(() {
        _favoriteProductIds = favoriteIds.toSet();
      });
    }
  }

  /// Sort products based on selected option
  void _sortProducts(List<ProductWithRating> products) {
    switch (_sortBy) {
      case 'rating':
        products.sort((a, b) {
          final aRating = a.averageRating ?? 0.0;
          final bRating = b.averageRating ?? 0.0;
          if (aRating == bRating) {
            // Secondary sort by total ratings
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
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField()
            : const Text('Browse Products'),
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
                // Focus the search field after the UI updates
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
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          _buildActiveFilterChips(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.streamAllAvailableProducts(),
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

                // Apply search filter (product name, description)
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  products = products
                      .where(
                        (p) =>
                            p.name.toLowerCase().contains(query) ||
                            (p.description?.toLowerCase().contains(query) ??
                                false),
                      )
                      .toList();
                }

                if (products.isEmpty) {
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
                          _searchQuery.isNotEmpty
                              ? 'No products match your search'
                              : 'No products available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new products',
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
                final authProvider = Provider.of<AuthProvider>(
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

                    // Apply farmer name search filter (if search is active)
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      productsWithFarmers = productsWithFarmers.where((pwf) {
                        // Check farmer name
                        final farmerNameMatch = pwf.farmer.name
                            .toLowerCase()
                            .contains(query);
                        // Check product name (already filtered above, but double-check)
                        final productNameMatch = pwf.product.name
                            .toLowerCase()
                            .contains(query);
                        // Check description
                        final descriptionMatch =
                            pwf.product.description?.toLowerCase().contains(
                              query,
                            ) ??
                            false;

                        return farmerNameMatch ||
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
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No results found for "$_searchQuery"'
                                  : 'Unable to load product details',
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

                    // Load ratings for all farmers
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

                    // Conditional rendering based on view mode
                    return CustomScrollView(
                      slivers: [
                        // Hero Carousel
                        if (featuredProducts.isNotEmpty)
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
                                    return _buildEnhancedProductCard(
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
                                    return _buildListViewCard(
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

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', null),
          _buildFilterChip('Crops', ProductCategory.crop),
          _buildFilterChip('Vegetables', ProductCategory.tomatoes),
          _buildFilterChip('Onions', ProductCategory.onions),
          _buildFilterChip('Poultry', ProductCategory.poultry),
          _buildFilterChip('Eggs', ProductCategory.eggs),
          _buildFilterChip('Goats', ProductCategory.goats),
          _buildFilterChip('Cows', ProductCategory.cows),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ProductCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  //   Widget _buildProductCard(Product product) {
  //     final cartProvider = Provider.of<CartProvider>(context, listen: false);
  // 
  //     return Card(
  //       elevation: 2,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Product Image
  //           Expanded(
  //             flex: 3,
  //             child: ClipRRect(
  //               borderRadius: const BorderRadius.vertical(
  //                 top: Radius.circular(12),
  //               ),
  //               child: Stack(
  //                 children: [
  //                   // ✅ Only load images from Firebase (no placeholders)
  //                   product.images.isNotEmpty
  //                       ? Image.network(
  //                           product.images.first,
  //                           width: double.infinity,
  //                           height: double.infinity,
  //                           fit: BoxFit.cover,
  //                           errorBuilder: (context, error, stackTrace) {
  //                             return Container(
  //                               color: Colors.grey[200],
  //                               child: Column(
  //                                 mainAxisAlignment: MainAxisAlignment.center,
  //                                 children: [
  //                                   Icon(
  //                                     Icons.image_not_supported,
  //                                     size: 48,
  //                                     color: Colors.grey[400],
  //                                   ),
  //                                   const SizedBox(height: 8),
  //                                   Text(
  //                                     'Image unavailable',
  //                                     textAlign: TextAlign.center,
  //                                     style: TextStyle(
  //                                       fontSize: 10,
  //                                       color: Colors.grey[600],
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             );
  //                           },
  //                         )
  //                       : Container(
  //                           color: Colors.grey[200],
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               Icon(
  //                                 Icons.inventory_2,
  //                                 size: 48,
  //                                 color: Colors.grey[400],
  //                               ),
  //                               const SizedBox(height: 8),
  //                               Text(
  //                                 product.name,
  //                                 textAlign: TextAlign.center,
  //                                 style: TextStyle(
  //                                   fontSize: 11,
  //                                   color: Colors.grey[700],
  //                                   fontWeight: FontWeight.w500,
  //                                 ),
  //                                 maxLines: 2,
  //                                 overflow: TextOverflow.ellipsis,
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                   if (product.isOutOfStock)
  //                     Container(
  //                       color: Colors.black54,
  //                       child: const Center(
  //                         child: Text(
  //                           'OUT OF STOCK',
  //                           style: TextStyle(
  //                             color: Colors.white,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ),
  //           ),
  // 
  //           // Product Info
  //           Expanded(
  //             flex: 2,
  //             child: Padding(
  //               padding: const EdgeInsets.all(8),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         product.name,
  //                         style: const TextStyle(
  //                           fontSize: 14,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       const SizedBox(height: 2),
  //                       // Farmer name - get from farmId (this is the user ID)
  //                       Text(
  //                         'Farmer', // We don't have farmer name in Product model
  //                         style: TextStyle(fontSize: 11, color: Colors.grey[600]),
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         'UGX ${NumberFormat('#,###').format(product.price)}/${product.unit}',
  //                         style: TextStyle(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.w600,
  //                           color: AppTheme.primaryColor,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  // 
  //                   // Add to Cart Button
  //                   SizedBox(
  //                     width: double.infinity,
  //                     height: 32,
  //                     child: ElevatedButton(
  //                       onPressed: product.isOutOfStock
  //                           ? null
  //                           : () => _addToCart(product, cartProvider),
  //                       style: ElevatedButton.styleFrom(
  //                         padding: const EdgeInsets.symmetric(horizontal: 8),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                       ),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           const Icon(Icons.add_shopping_cart, size: 16),
  //                           const SizedBox(width: 4),
  //                           Text(
  //                             product.isOutOfStock ? 'Out of Stock' : 'Add',
  //                             style: const TextStyle(fontSize: 12),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  /// Enhanced product card with farmer details, distance, and ratings
  Widget _buildEnhancedProductCard(ProductWithRating productWithRating) {
    final productWithFarmer = productWithRating.productWithFarmer;
    final product = productWithFarmer.product;
    final farmer = productWithFarmer.farmer;
    final rating = productWithRating.farmerRating;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return InkWell(
      onTap: () {
        // Navigate to product detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Distance Badge
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    // ✅ Only load images from Firebase (no placeholders)
                    product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              if (kDebugMode) {
                                debugPrint('🖼️ Loading image: ${product.images.first}');
                              }
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              if (kDebugMode) {
                                debugPrint('❌ Failed to load image: ${product.images.first}');
                                debugPrint('Error: $error');
                              }
                              return Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image unavailable',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                    // PSA Badge (top left)
                    if (farmer.role == UserRole.psa)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
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
                    // Distance Badge
                    if (productWithFarmer.distanceKm != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: productWithFarmer.isLocal
                                ? Colors.green
                                : productWithFarmer.isNearby
                                ? Colors.orange
                                : Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                productWithFarmer.distanceText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Favorite Heart Button (adjust position if PSA)
                    Positioned(
                      top: farmer.role == UserRole.psa ? 44 : 8,
                      left: 8,
                      child: _buildFavoriteButton(product),
                    ),
                    // Out of Stock Overlay
                    if (product.isOutOfStock)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Product and Farmer Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // System ID and Subcategory badges
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
                      const SizedBox(height: 2),

                    // Farmer/Supplier Name (show business name for PSA)
                    Row(
                      children: [
                        Icon(
                          farmer.role == UserRole.psa
                              ? Icons.business
                              : Icons.person,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            farmer.role == UserRole.psa &&
                                    product.businessName != null
                                ? product.businessName!
                                : farmer.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: farmer.role == UserRole.psa
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Rating Display
                    if (rating != null && rating.totalRatings > 0)
                      Row(
                        children: [
                          _buildStarRating(rating.averageRating),
                          const SizedBox(width: 4),
                          Text(
                            '(${rating.totalRatings})',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Highly Rated Badge
                          if (rating.isHighlyRated &&
                              rating.hasSufficientRatings)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.amber[700]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 10,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Top',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    if (rating != null && rating.totalRatings > 0)
                      const SizedBox(height: 2),

                    // District
                    Row(
                      children: [
                        const Icon(
                          Icons.location_city,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            productWithFarmer.farmerDistrict,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Stock Info
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 12,
                          color: product.isLowStock
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: ${product.stockQuantity} ${product.unit}',
                          style: TextStyle(
                            fontSize: 10,
                            color: product.isLowStock
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price
                    Text(
                      'UGX ${NumberFormat('#,###').format(product.price)}/${product.unit}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Call Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _callFarmer(farmer.phone),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Icon(Icons.phone, size: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add to Cart Button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: product.isOutOfStock
                                ? null
                                : () => _addToCart(product, cartProvider),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_shopping_cart, size: 14),
                                SizedBox(width: 4),
                                Text('Add', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  /// Build list view card with horizontal layout
  Widget _buildListViewCard(ProductWithRating productWithRating) {
    final productWithFarmer = productWithRating.productWithFarmer;
    final product = productWithFarmer.product;
    final farmer = productWithFarmer.farmer;
    final rating = productWithRating.farmerRating;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images[0],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          if (kDebugMode) {
                            debugPrint('🖼️ [ListView] Loading image: ${product.images[0]}');
                          }
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) {
                            debugPrint('❌ [ListView] Failed to load image: ${product.images[0]}');
                            debugPrint('Error: $error');
                          }
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Product ID and Subcategory
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (product.systemId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
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
                                  size: 10,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  product.systemId!,
                                  style: TextStyle(
                                    fontSize: 9,
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
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green[200]!,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              product.subcategory!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Farmer/Supplier Name with PSA badge
                    Row(
                      children: [
                        Icon(
                          farmer.role == UserRole.psa
                              ? Icons.business
                              : Icons.person,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            farmer.role == UserRole.psa &&
                                    product.businessName != null
                                ? product.businessName!
                                : farmer.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: farmer.role == UserRole.psa
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (farmer.role == UserRole.psa) ...[
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
                            child: const Text(
                              'PSA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating
                    if (rating != null && rating.totalRatings > 0)
                      Row(
                        children: [
                          _buildStarRating(rating.averageRating, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '(${rating.totalRatings})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (rating.isHighlyRated &&
                              rating.hasSufficientRatings) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.amber[700]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Top',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.amber[900],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 4),

                    // Distance
                    if (productWithFarmer.distanceKm != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${productWithFarmer.distanceKm!.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),

                    // Price and Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UGX ${NumberFormat('#,###').format(product.price)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
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

                        // Add to Cart Button
                        ElevatedButton.icon(
                          onPressed: product.isOutOfStock
                              ? null
                              : () => _addToCart(product, cartProvider),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: Text(
                            product.isOutOfStock ? 'Out of Stock' : 'Add',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
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
      ),
    );
  }

  /// Build star rating display widget
  Widget _buildStarRating(double rating, {double size = 12}) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, size: size, color: Colors.amber[700]);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, size: size, color: Colors.amber[700]);
        } else {
          return Icon(Icons.star_border, size: size, color: Colors.grey[400]);
        }
      }),
    );
  }

  /// Build favorite button (heart icon)
  Widget _buildFavoriteButton(Product product) {
    final isFavorite = _favoriteProductIds.contains(product.id);

    return GestureDetector(
      onTap: () => _toggleFavorite(product),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: isFavorite ? Colors.red : Colors.grey[600],
        ),
      ),
    );
  }

  /// Toggle favorite status
  Future<void> _toggleFavorite(Product product) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save favorites')),
      );
      return;
    }

    try {
      final nowFavorite = await _favoriteService.toggleFavorite(
        userId: userId,
        productId: product.id,
        farmerId: product.farmId,
      );

      setState(() {
        if (nowFavorite) {
          _favoriteProductIds.add(product.id);
        } else {
          _favoriteProductIds.remove(product.id);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowFavorite ? '❤️ Added to favorites' : 'Removed from favorites',
            ),
            backgroundColor: nowFavorite ? Colors.green : Colors.grey[700],
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Call farmer
  void _callFarmer(String phone) async {
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

  void _addToCart(Product product, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => _AddToCartDialog(product: product),
    ).then((quantity) {
      if (quantity != null && quantity > 0) {
        cartProvider.addItem(
          product,
          quantity: quantity,
          farmerId: product.farmId,
          farmerName:
              'Farmer', // We'll need to fetch this from users collection
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${product.name} added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  //   void _showSearchDialog() {
  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         String query = _searchQuery;
  //         return AlertDialog(
  //           title: const Text('Search Products'),
  //           content: TextField(
  //             autofocus: true,
  //             decoration: const InputDecoration(
  //               hintText: 'Enter product name...',
  //               prefixIcon: Icon(Icons.search),
  //             ),
  //             onChanged: (value) => query = value,
  //             onSubmitted: (value) {
  //               setState(() => _searchQuery = value);
  //               Navigator.pop(context);
  //             },
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 setState(() => _searchQuery = '');
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('Clear'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 setState(() => _searchQuery = query);
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('Search'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }

  /// Show filter bottom sheet
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

  /// Toggle between grid and list view
  Future<void> _toggleViewMode() async {
    setState(() {
      _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    });
    await _saveViewPreference();
  }

  /// Load view preference from storage
  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final viewModeString = prefs.getString('browse_view_mode') ?? 'grid';
    setState(() {
      _viewMode = viewModeString == 'list' ? ViewMode.list : ViewMode.grid;
    });
  }

  /// Save view preference to storage
  Future<void> _saveViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'browse_view_mode',
      _viewMode == ViewMode.grid ? 'grid' : 'list',
    );
  }

  /// Apply filters to products
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

    // District filter
    if (_activeFilter.selectedDistricts.isNotEmpty) {
      filtered = filtered.where((p) {
        final farmerDistrict = p.productWithFarmer.farmer.location?.district;
        return farmerDistrict != null &&
            _activeFilter.selectedDistricts.contains(farmerDistrict);
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

  /// Get featured products (highly rated with sufficient reviews)
  List<ProductWithRating> _getFeaturedProducts(
    List<ProductWithRating> products,
  ) {
    // Filter products that are highly rated and have sufficient reviews
    final featured = products.where((p) {
      final rating = p.farmerRating;
      return rating != null &&
          rating.isHighlyRated &&
          rating.hasSufficientRatings &&
          !p.productWithFarmer.product.isOutOfStock;
    }).toList();

    // Sort by rating and review count
    featured.sort((a, b) {
      final ratingA = a.farmerRating?.averageRating ?? 0;
      final ratingB = b.farmerRating?.averageRating ?? 0;
      final countA = a.farmerRating?.totalRatings ?? 0;
      final countB = b.farmerRating?.totalRatings ?? 0;

      // First compare by rating
      final ratingComparison = ratingB.compareTo(ratingA);
      if (ratingComparison != 0) return ratingComparison;

      // If ratings are equal, compare by review count
      return countB.compareTo(countA);
    });

    // Return top 5 featured products
    return featured.take(5).toList();
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

  /// Build search text field for AppBar
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: 'Search products or farmers...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        // Keep focus on the search field
        _searchFocusNode.requestFocus();
      },
    );
  }
}

class _AddToCartDialog extends StatefulWidget {
  final Product product;

  const _AddToCartDialog({required this.product});

  @override
  State<_AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<_AddToCartDialog> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'UGX ${NumberFormat('#,###').format(widget.product.price)} per ${widget.product.unit}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_quantity ${widget.product.unit}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _quantity < widget.product.stockQuantity
                    ? () => setState(() => _quantity++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total: UGX ${NumberFormat('#,###').format(widget.product.price * _quantity)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stock: ${widget.product.stockQuantity} ${widget.product.unit} available',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _quantity),
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}
