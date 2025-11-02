import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';

class SHGBuyInputsScreen extends StatefulWidget {
  const SHGBuyInputsScreen({super.key});

  @override
  State<SHGBuyInputsScreen> createState() => _SHGBuyInputsScreenState();
}

class _SHGBuyInputsScreenState extends State<SHGBuyInputsScreen> {
  ProductCategory _selectedCategory = ProductCategory.crop;
  
  // Mock PSA products by category
  final Map<ProductCategory, List<Product>> _psaProducts = {
    ProductCategory.crop: [
      Product(
        id: 'psa1',
        farmId: 'psa001',
        name: 'Hybrid Maize Seeds (10kg)',
        description: 'High-yield hybrid maize seeds',
        category: ProductCategory.fertilizers,
        unit: 'bag',
        unitSize: 10,
        price: 450000,
        stockQuantity: 120,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'psa2',
        farmId: 'psa001',
        name: 'NPK Fertilizer (50kg)',
        description: 'Balanced NPK 17:17:17 fertilizer',
        category: ProductCategory.fertilizers,
        unit: 'bag',
        unitSize: 50,
        price: 180000,
        stockQuantity: 85,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'psa3',
        farmId: 'psa002',
        name: 'Pesticide Spray (5L)',
        description: 'Broad spectrum insecticide',
        category: ProductCategory.chemicals,
        unit: 'bottle',
        unitSize: 5,
        price: 95000,
        stockQuantity: 45,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'psa4',
        farmId: 'psa001',
        name: 'Hand Hoe',
        description: 'Strong steel hand hoe',
        category: ProductCategory.hoes,
        unit: 'piece',
        unitSize: 1,
        price: 25000,
        stockQuantity: 200,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
    ProductCategory.poultry: [
      Product(
        id: 'psa5',
        farmId: 'psa003',
        name: 'Day-Old Chicks (Broilers)',
        description: 'Healthy broiler chicks, vaccinated',
        category: ProductCategory.dayOldChicks,
        unit: 'piece',
        unitSize: 1,
        price: 3500,
        stockQuantity: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'psa6',
        farmId: 'psa003',
        name: 'Poultry Starter Feed (50kg)',
        description: 'Complete starter feed for chicks',
        category: ProductCategory.feeds,
        unit: 'bag',
        unitSize: 50,
        price: 125000,
        stockQuantity: 75,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'psa7',
        farmId: 'psa003',
        name: 'Poultry Grower Feed (50kg)',
        description: 'Nutrient-rich grower feed',
        category: ProductCategory.feeds,
        unit: 'bag',
        unitSize: 50,
        price: 115000,
        stockQuantity: 60,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'psa8',
        farmId: 'psa002',
        name: 'Poultry Vaccines Kit',
        description: 'Complete vaccination kit',
        category: ProductCategory.chemicals,
        unit: 'kit',
        unitSize: 1,
        price: 85000,
        stockQuantity: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
    ProductCategory.goats: [
      Product(
        id: 'psa9',
        farmId: 'psa004',
        name: 'Goat Feed Concentrate (25kg)',
        description: 'Protein-rich goat feed',
        category: ProductCategory.feeds,
        unit: 'bag',
        unitSize: 25,
        price: 75000,
        stockQuantity: 40,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'psa10',
        farmId: 'psa004',
        name: 'Goat Mineral Supplements',
        description: 'Essential minerals for goats',
        category: ProductCategory.chemicals,
        unit: 'kg',
        unitSize: 1,
        price: 15000,
        stockQuantity: 80,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
    ProductCategory.cows: [
      Product(
        id: 'psa11',
        farmId: 'psa004',
        name: 'Dairy Cow Feed (50kg)',
        description: 'High-protein dairy feed',
        category: ProductCategory.feeds,
        unit: 'bag',
        unitSize: 50,
        price: 145000,
        stockQuantity: 35,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'psa12',
        farmId: 'psa004',
        name: 'Cattle Dewormer',
        description: 'Broad spectrum dewormer',
        category: ProductCategory.chemicals,
        unit: 'bottle',
        unitSize: 1,
        price: 55000,
        stockQuantity: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
  };

  List<Product> get _filteredProducts {
    return _psaProducts[_selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Farming Inputs'),
        elevation: 0,
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

          // Products List
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products available',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _ProductCard(product: product);
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
                        'UGX ${product.price.toStringAsFixed(0)}',
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
