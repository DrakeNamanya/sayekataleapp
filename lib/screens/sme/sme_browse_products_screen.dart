import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import '../../models/product_with_farmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../services/product_with_farmer_service.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';

class SMEBrowseProductsScreen extends StatefulWidget {
  const SMEBrowseProductsScreen({super.key});

  @override
  State<SMEBrowseProductsScreen> createState() => _SMEBrowseProductsScreenState();
}

class _SMEBrowseProductsScreenState extends State<SMEBrowseProductsScreen> {
  final ProductService _productService = ProductService();
  final ProductWithFarmerService _productWithFarmerService = ProductWithFarmerService();
  ProductCategory? _selectedCategory;
  String _searchQuery = '';
  bool _sortByDistance = true;  // Default to sorting by distance
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Products'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.streamAllAvailableProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                  products = products.where((p) => p.category == _selectedCategory).toList();
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  products = products.where((p) =>
                      p.name.toLowerCase().contains(query) ||
                      (p.description?.toLowerCase().contains(query) ?? false)
                  ).toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No products match your search'
                              : 'No products available',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new products',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Load products with farmer details and distance
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final buyerLocation = authProvider.currentUser?.location;

                return FutureBuilder<List<ProductWithFarmer>>(
                  future: _productWithFarmerService.getProductsWithFarmersAndDistance(
                    products: products,
                    buyerLocation: _sortByDistance ? buyerLocation : null,
                  ),
                  builder: (context, farmerSnapshot) {
                    if (farmerSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading farmer details...'),
                          ],
                        ),
                      );
                    }

                    final productsWithFarmers = farmerSnapshot.data ?? [];

                    if (productsWithFarmers.isEmpty) {
                      return const Center(
                        child: Text('Unable to load product details'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,  // Adjusted for more content
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: productsWithFarmers.length,
                      itemBuilder: (context, index) {
                        return _buildEnhancedProductCard(productsWithFarmers[index]);
                      },
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

  Widget _buildProductCard(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.network(
                    product.images.isNotEmpty
                        ? product.images.first
                        : 'https://via.placeholder.com/400x400?text=${Uri.encodeComponent(product.name)}',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              product.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
          
          // Product Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Farmer name - get from farmId (this is the user ID)
                      Text(
                        'Farmer', // We don't have farmer name in Product model
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UGX ${NumberFormat('#,###').format(product.price)}/${product.unit}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: product.isOutOfStock
                          ? null
                          : () => _addToCart(product, cartProvider),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            product.isOutOfStock ? 'Out of Stock' : 'Add',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced product card with farmer details and distance
  Widget _buildEnhancedProductCard(ProductWithFarmer productWithFarmer) {
    final product = productWithFarmer.product;
    final farmer = productWithFarmer.farmer;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with Distance Badge
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.network(
                    product.images.isNotEmpty
                        ? product.images.first
                        : 'https://via.placeholder.com/400x400?text=${Uri.encodeComponent(product.name)}',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              product.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Distance Badge
                  if (productWithFarmer.distanceKm != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            const Icon(Icons.location_on, size: 12, color: Colors.white),
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
                  
                  // Farmer Name
                  Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          farmer.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  
                  // District
                  Row(
                    children: [
                      const Icon(Icons.location_city, size: 12, color: Colors.grey),
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
                        color: product.isLowStock ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${product.stockQuantity} ${product.unit}',
                        style: TextStyle(
                          fontSize: 10,
                          color: product.isLowStock ? Colors.orange : Colors.green,
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
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    );
  }

  /// Call farmer
  void _callFarmer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phone')),
        );
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
          farmerName: 'Farmer', // We'll need to fetch this from users collection
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = _searchQuery;
        return AlertDialog(
          title: const Text('Search Products'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter product name...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => query = value,
            onSubmitted: (value) {
              setState(() => _searchQuery = value);
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _searchQuery = query);
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
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
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_quantity ${widget.product.unit}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
