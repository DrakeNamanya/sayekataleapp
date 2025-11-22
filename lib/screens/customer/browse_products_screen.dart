import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
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
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedDistrict = 'All';
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> _featuredProducts = [];
  final Map<String, String> _farmerNames = {};
  bool _isLoading = true;
  bool _showFilters = false;

  final List<String> _categories = ['All', 'Crops', 'Vegetables', 'Onions'];
  List<String> _districts = ['All'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all products
      final products = await _productService.getAllAvailableProducts();

      // Load farmer names and extract districts
      final farmerIds = products.map((p) => p.farmId).toSet().toList();
      final Set<String> districtSet = {};
      
      for (final farmId in farmerIds) {
        final result = await _getFarmerNameAndDistrict(farmId);
        _farmerNames[farmId] = result['name']!;
        if (result['district'] != null && result['district']!.isNotEmpty) {
          districtSet.add(result['district']!);
        }
      }

      final districtList = districtSet.toList()..sort();

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _featuredProducts = products.where((p) => p.isFeatured).toList();
        _districts = ['All', ...districtList];
        _isLoading = false;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, String?>> _getFarmerNameAndDistrict(String farmId) async {
    try {
      // Try SHG profiles first
      var doc = await _firestore.collection('shg_profiles').doc(farmId).get();
      if (doc.exists) {
        final data = doc.data();
        return {
          'name': data?['shg_name'] ?? 'Unknown Farmer',
          'district': data?['district'] ?? data?['location']?['district'],
        };
      }

      // Try farmer_profiles next
      doc = await _firestore.collection('farmer_profiles').doc(farmId).get();
      if (doc.exists) {
        final data = doc.data();
        return {
          'name': data?['name'] ?? 'Unknown Farmer',
          'district': data?['district'] ?? data?['location']?['district'],
        };
      }

      // Try users collection
      doc = await _firestore.collection('users').doc(farmId).get();
      if (doc.exists) {
        final data = doc.data();
        return {
          'name': data?['name'] ?? 'Unknown Farmer',
          'district': data?['location']?['district'],
        };
      }

      return {'name': 'Unknown Farmer', 'district': null};
    } catch (e) {
      return {'name': 'Unknown Farmer', 'district': null};
    }
  }

  void _applyFilters() {
    var filtered = List<Product>.from(_allProducts);

    // Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((product) {
        if (_selectedCategory == 'Crops') {
          return product.category == ProductCategory.crop;
        } else if (_selectedCategory == 'Vegetables') {
          return product.category == ProductCategory.tomatoes ||
              product.category == ProductCategory.onions;
        } else if (_selectedCategory == 'Onions') {
          return product.category == ProductCategory.onions;
        }
        return true;
      }).toList();
    }

    // District filter (filter by farmer's district)
    if (_selectedDistrict != 'All') {
      filtered = filtered.where((product) {
        // This is a simplified check - you might need to enhance this
        // based on how district info is stored with products/farmers
        return true; // Keep all for now, enhance based on your data structure
      }).toList();
    }

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((product) {
        final farmerName = (_farmerNames[product.farmId] ?? '').toLowerCase();
        final description = (product.description ?? '').toLowerCase();
        return product.name.toLowerCase().contains(query) ||
            description.contains(query) ||
            farmerName.contains(query) ||
            product.category.toString().toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedDistrict = 'All';
      _searchController.clear();
      _filteredProducts = _allProducts;
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
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products, farmers, districts...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                ),

                // Advanced Filters (collapsible)
                if (_showFilters)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // District Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedDistrict,
                            decoration: InputDecoration(
                              labelText: 'District',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: _districts.map((district) {
                              return DropdownMenuItem(
                                value: district,
                                child: Text(district),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDistrict = value!;
                              });
                              _applyFilters();
                            },
                          ),
                          const SizedBox(height: 12),
                          // Clear Filters Button
                          OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Filters'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

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
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _applyFilters();
                            },
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
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
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
                    }, childCount: _filteredProducts.length),
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
