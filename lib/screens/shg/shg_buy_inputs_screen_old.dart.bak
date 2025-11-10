import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import 'shg_input_cart_screen.dart';

class SHGBuyInputsScreen extends StatefulWidget {
  const SHGBuyInputsScreen({super.key});

  @override
  State<SHGBuyInputsScreen> createState() => _SHGBuyInputsScreenState();
}

class _SHGBuyInputsScreenState extends State<SHGBuyInputsScreen> {
  final ProductService _productService = ProductService();
  ProductCategory _selectedCategory = ProductCategory.crop;
  
  List<Product> _filterProductsByCategory(List<Product> products) {
    // Filter by selected category - match category groups
    switch (_selectedCategory) {
      case ProductCategory.crop:
        return products.where((p) =>
            p.category == ProductCategory.fertilizers ||
            p.category == ProductCategory.chemicals ||
            p.category == ProductCategory.hoes ||
            p.category == ProductCategory.crop
        ).toList();
      case ProductCategory.poultry:
        return products.where((p) =>
            p.category == ProductCategory.dayOldChicks ||
            p.category == ProductCategory.feeds ||
            p.category == ProductCategory.poultry
        ).toList();
      case ProductCategory.goats:
        return products.where((p) =>
            p.category == ProductCategory.feeds ||
            p.category == ProductCategory.goats
        ).toList();
      case ProductCategory.cows:
        return products.where((p) =>
            p.category == ProductCategory.feeds ||
            p.category == ProductCategory.cows
        ).toList();
      default:
        return products;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.itemCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Farming Inputs'),
        elevation: 0,
        actions: [
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
          // Category Tabs
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _CategoryTab(
                    icon: Icons.agriculture_outlined,
                    label: 'Crop',
                    isSelected: _selectedCategory == ProductCategory.crop,
                    onTap: () => setState(() => _selectedCategory = ProductCategory.crop),
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    icon: Icons.pets_outlined,
                    label: 'Poultry',
                    isSelected: _selectedCategory == ProductCategory.poultry,
                    onTap: () => setState(() => _selectedCategory = ProductCategory.poultry),
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    icon: Icons.pets_outlined,
                    label: 'Goats',
                    isSelected: _selectedCategory == ProductCategory.goats,
                    onTap: () => setState(() => _selectedCategory = ProductCategory.goats),
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    icon: Icons.agriculture_outlined,
                    label: 'Cows',
                    isSelected: _selectedCategory == ProductCategory.cows,
                    onTap: () => setState(() => _selectedCategory = ProductCategory.cows),
                  ),
                ],
              ),
            ),
          ),

          // Products List - Stream PSA products
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
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allProducts.isEmpty
                              ? 'No PSA products available yet'
                              : 'No products in this category',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        if (allProducts.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'PSA suppliers will add products soon',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
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
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
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
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getProductIcon(product.category),
                size: 40,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'In Stock',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'UGX ${NumberFormat('#,###').format(product.price)}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
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
                                // Navigate to cart screen
                                DefaultTabController.of(context).animateTo(2); // Cart tab
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
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
}
