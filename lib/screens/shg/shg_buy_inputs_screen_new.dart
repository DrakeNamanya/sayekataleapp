import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../models/product.dart';
import '../../models/product_with_farmer.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../services/product_with_farmer_service.dart';
import '../../widgets/image_zoom_dialog.dart';
import 'shg_input_cart_screen.dart';

class SHGBuyInputsScreen extends StatefulWidget {
  const SHGBuyInputsScreen({super.key});

  @override
  State<SHGBuyInputsScreen> createState() => _SHGBuyInputsScreenState();
}

class _SHGBuyInputsScreenState extends State<SHGBuyInputsScreen> {
  final ProductService _productService = ProductService();
  final ProductWithFarmerService _productWithFarmerService = ProductWithFarmerService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  ProductCategory _selectedCategory = ProductCategory.crop;
  String _searchQuery = '';
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
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

  List<Product> _filterProductsByCategory(List<Product> products) {
    // Filter by selected category - match category groups
    List<Product> filtered;
    switch (_selectedCategory) {
      case ProductCategory.crop:
        filtered = products.where((p) =>
            p.category == ProductCategory.fertilizers ||
            p.category == ProductCategory.chemicals ||
            p.category == ProductCategory.hoes ||
            p.category == ProductCategory.crop
        ).toList();
        break;
      case ProductCategory.poultry:
        filtered = products.where((p) =>
            p.category == ProductCategory.dayOldChicks ||
            p.category == ProductCategory.feeds ||
            p.category == ProductCategory.poultry
        ).toList();
        break;
      case ProductCategory.goats:
        filtered = products.where((p) =>
            p.category == ProductCategory.feeds ||
            p.category == ProductCategory.goats
        ).toList();
        break;
      case ProductCategory.cows:
        filtered = products.where((p) =>
            p.category == ProductCategory.feeds ||
            p.category == ProductCategory.cows
        ).toList();
        break;
      default:
        filtered = products;
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false) ||
          (p.businessName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.itemCount;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : const Text('Buy Farming Inputs'),
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
          if (_isSearching && _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.requestFocus();
              },
            ),
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
          // Category Tabs
          if (!_isSearching)
            Container(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _CategoryTab(
                      icon: Icons.agriculture_outlined,
                      label: 'Crop Inputs',
                      isSelected: _selectedCategory == ProductCategory.crop,
                      onTap: () => setState(() => _selectedCategory = ProductCategory.crop),
                    ),
                    const SizedBox(width: 12),
                    _CategoryTab(
                      icon: Icons.pets_outlined,
                      label: 'Poultry Inputs',
                      isSelected: _selectedCategory == ProductCategory.poultry,
                      onTap: () => setState(() => _selectedCategory = ProductCategory.poultry),
                    ),
                    const SizedBox(width: 12),
                    _CategoryTab(
                      icon: Icons.pets_outlined,
                      label: 'Goat Inputs',
                      isSelected: _selectedCategory == ProductCategory.goats,
                      onTap: () => setState(() => _selectedCategory = ProductCategory.goats),
                    ),
                    const SizedBox(width: 12),
                    _CategoryTab(
                      icon: Icons.agriculture_outlined,
                      label: 'Cow Inputs',
                      isSelected: _selectedCategory == ProductCategory.cows,
                      onTap: () => setState(() => _selectedCategory = ProductCategory.cows),
                    ),
                  ],
                ),
              ),
            ),

          // Products List - Stream PSA products with farmer details
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.streamPSAProducts(),
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
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allProducts = snapshot.data ?? [];
                final filteredProducts = _filterProductsByCategory(allProducts);

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results found for "$_searchQuery"'
                              : allProducts.isEmpty
                                  ? 'No PSA products available yet'
                                  : 'No products in this category',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isEmpty && allProducts.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'PSA suppliers will add products soon',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (_searchQuery.isNotEmpty) ...[
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

                // Load products with farmer details
                return FutureBuilder<List<ProductWithFarmer>>(
                  future: _productWithFarmerService.getProductsWithFarmersAndDistance(
                    products: filteredProducts,
                    buyerLocation: null, // No distance calculation needed for inputs
                  ),
                  builder: (context, farmerSnapshot) {
                    if (farmerSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final productsWithFarmers = farmerSnapshot.data ?? [];

                    if (productsWithFarmers.isEmpty) {
                      return const Center(
                        child: Text('Unable to load product details'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: productsWithFarmers.length,
                      itemBuilder: (context, index) {
                        final productWithFarmer = productsWithFarmers[index];
                        return _ProductCard(productWithFarmer: productWithFarmer);
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: 'Search products or suppliers...',
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

class _CategoryTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductWithFarmer productWithFarmer;

  const _ProductCard({required this.productWithFarmer});

  @override
  Widget build(BuildContext context) {
    final product = productWithFarmer.product;
    final supplier = productWithFarmer.farmer;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  color: Colors.grey.shade200,
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
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Supplier name with PSA badge
                  Row(
                    children: [
                      Icon(
                        supplier.role == UserRole.psa ? Icons.business : Icons.person,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          supplier.role == UserRole.psa && product.businessName != null
                              ? product.businessName!
                              : supplier.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: supplier.role == UserRole.psa ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (supplier.role == UserRole.psa) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 10, color: Colors.white),
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
                  
                  // Description
                  if (product.description != null && product.description!.isNotEmpty)
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
                  
                  // Price and Stock
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
                                fontSize: 18,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              product.isOutOfStock ? Icons.cancel : Icons.check_circle,
                              size: 12,
                              color: product.isOutOfStock ? Colors.red : AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.isOutOfStock ? 'Out of Stock' : 'In Stock',
                              style: TextStyle(
                                color: product.isOutOfStock ? Colors.red : AppTheme.successColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Call button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callSupplier(context, supplier.phone),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call', style: TextStyle(fontSize: 12)),
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
                              : () => _addToCart(context, product, cartProvider),
                          icon: const Icon(Icons.shopping_cart, size: 16),
                          label: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
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

  void _callSupplier(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phone')),
        );
      }
    }
  }

  void _addToCart(BuildContext context, Product product, CartProvider cartProvider) {
    cartProvider.addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${product.name} added to cart'),
            ),
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
}
