import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import 'psa_add_edit_product_screen.dart';

class PSAProductsScreen extends StatefulWidget {
  const PSAProductsScreen({super.key});

  @override
  State<PSAProductsScreen> createState() => _PSAProductsScreenState();
}

class _PSAProductsScreenState extends State<PSAProductsScreen> {
  final ProductService _productService = ProductService();
  ProductCategory _selectedCategory = ProductCategory.crop;

  List<Product> _filterProductsByCategory(
    List<Product> products,
    ProductCategory category,
  ) {
    // Filter products by main category
    switch (category) {
      case ProductCategory.crop:
        return products
            .where(
              (p) =>
                  p.category == ProductCategory.fertilizers ||
                  p.category == ProductCategory.chemicals ||
                  p.category == ProductCategory.hoes ||
                  p.category == ProductCategory.crop,
            )
            .toList();
      case ProductCategory.poultry:
        return products
            .where(
              (p) =>
                  p.category == ProductCategory.dayOldChicks ||
                  p.category == ProductCategory.feeds ||
                  p.category == ProductCategory.poultry,
            )
            .toList();
      case ProductCategory.goats:
        return products
            .where(
              (p) =>
                  p.category == ProductCategory.feeds ||
                  p.category == ProductCategory.goats,
            )
            .toList();
      case ProductCategory.cows:
        return products
            .where(
              (p) =>
                  p.category == ProductCategory.feeds ||
                  p.category == ProductCategory.cows,
            )
            .toList();
      default:
        return products;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final psaId = authProvider.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to dashboard/home tab
            Navigator.of(context).pop();
          },
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productService.streamFarmerProducts(psaId),
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
          final filteredProducts = _filterProductsByCategory(
            allProducts,
            _selectedCategory,
          );

          // Count products by category for tabs
          final categoryCounts = <ProductCategory, int>{};
          for (final category in ProductCategoryExtension.mainCategories) {
            categoryCounts[category] = _filterProductsByCategory(
              allProducts,
              category,
            ).length;
          }

          return Column(
            children: [
              // Category Tabs
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  children: ProductCategoryExtension.mainCategories.map((
                    category,
                  ) {
                    final isSelected = _selectedCategory == category;
                    final count = categoryCounts[category] ?? 0;

                    return _CategoryTab(
                      category: category,
                      count: count,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // Products List
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allProducts.isEmpty
                                  ? 'No products yet'
                                  : 'No products in this category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (allProducts.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Click the + button to add your first product',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _ProductCard(
                            product: product,
                            onEdit: () =>
                                _showEditProductDialog(context, product),
                            onDelete: () =>
                                _showDeleteConfirmation(context, product),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (context) => const PSAAddEditProductScreen()),
    );

    if (result == true && mounted) {
      // Product was added successfully, refresh list
      setState(() {
        // In production, this would fetch from API/database
      });
    }
  }

  void _showEditProductDialog(BuildContext context, Product product) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => PSAAddEditProductScreen(product: product),
      ),
    );

    if (result == true && mounted) {
      // Product was updated successfully, StreamBuilder will auto-refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Product updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result == 'deleted' && mounted) {
      // Product was deleted, StreamBuilder will auto-refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _productService.deleteProduct(product.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Product deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error deleting product: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final ProductCategory category;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.category,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (category) {
      case ProductCategory.crop:
        return Icons.grass;
      case ProductCategory.poultry:
        return Icons.egg_outlined;
      case ProductCategory.goats:
        return Icons.pets_outlined;
      case ProductCategory.cows:
        return Icons.agriculture_outlined;
      default:
        return Icons.category;
    }
  }

  Color get _color {
    switch (category) {
      case ProductCategory.crop:
        return AppTheme.accentColor;
      case ProductCategory.poultry:
        return AppTheme.primaryColor;
      case ProductCategory.goats:
        return Colors.brown.shade600;
      case ProductCategory.cows:
        return Colors.blue.shade700;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              category.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : _color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : _color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _stockColor {
    if (product.stockQuantity == 0) return AppTheme.errorColor;
    if (product.stockQuantity <= product.lowStockThreshold)
      return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String get _stockStatus {
    if (product.stockQuantity == 0) return 'Out of Stock';
    if (product.stockQuantity <= product.lowStockThreshold) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: AppTheme.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _stockStatus,
                    style: TextStyle(
                      fontSize: 11,
                      color: _stockColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'UGX ${product.price.toStringAsFixed(0)}/${product.unit}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${product.stockQuantity} ${product.unit}s',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _stockColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: AppTheme.primaryColor,
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.errorColor,
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
