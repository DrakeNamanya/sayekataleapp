import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
import '../../models/product_category_hierarchy.dart';
import '../../services/product_service.dart';
import '../../widgets/featured_product_carousel.dart';
import '../../widgets/product_card_compact.dart';
import 'product_detail_screen.dart';

class BrowseProductsScreen extends StatefulWidget {
  const BrowseProductsScreen({super.key});

  @override
  State<BrowseProductsScreen> createState() => _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends State<BrowseProductsScreen> {
  final ProductService _productService = ProductService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _selectedCategory = 'All';
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> _featuredProducts = [];
  Map<String, String> _farmerNames = {};
  bool _isLoading = true;

  final List<String> _categories = ['All', 'Crops', 'Vegetables', 'Onions'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all products
      final products = await _productService.getAllAvailableProducts();
      
      // Load farmer names
      final farmerIds = products.map((p) => p.farmId).toSet().toList();
      for (final farmId in farmerIds) {
        final farmerName = await _getFarmerName(farmId);
        _farmerNames[farmId] = farmerName;
      }

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _featuredProducts = products.where((p) => p.isFeatured).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getFarmerName(String farmId) async {
    try {
      // Try SHG profiles first
      var doc = await _firestore.collection('shg_profiles').doc(farmId).get();
      if (doc.exists) {
        return doc.data()?['shg_name'] ?? 'Unknown Farmer';
      }

      // Try farmer_profiles next
      doc = await _firestore.collection('farmer_profiles').doc(farmId).get();
      if (doc.exists) {
        return doc.data()?['name'] ?? 'Unknown Farmer';
      }

      return 'Unknown Farmer';
    } catch (e) {
      return 'Unknown Farmer';
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          // Implement category filtering logic based on your category structure
          if (category == 'Crops') {
            return product.category == ProductCategory.crop;
          } else if (category == 'Vegetables') {
            return product.category == ProductCategory.tomatoes ||
                   product.category == ProductCategory.onions;
          } else if (category == 'Onions') {
            return product.category == ProductCategory.onions;
          }
          return true;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Browse Products',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () {
              // TODO: Implement advanced filtering
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.black87),
            onPressed: () {
              // TODO: Toggle grid/list view
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Category Tabs
                SliverToBoxAdapter(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) => _filterByCategory(category),
                            selectedColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide.none,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Featured Products Carousel
                if (_featuredProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: FeaturedProductCarousel(
                      featuredProducts: _featuredProducts,
                      onProductTap: (product) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    ),
                  ),

                // Product List
                if (_filteredProducts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _filteredProducts[index];
                        final farmerName = _farmerNames[product.farmId];
                        return ProductCardCompact(
                          product: product,
                          farmerName: farmerName,
                          distanceKm: 0.0, // TODO: Calculate actual distance
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          onAddToCart: () {
                            // TODO: Implement add to cart
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                      childCount: _filteredProducts.length,
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Browse tab
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        onTap: (index) {
          // TODO: Implement navigation
          if (index != 1) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
