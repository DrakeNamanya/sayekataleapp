import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/farmer.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';

class SMEFarmerDetailScreen extends StatefulWidget {
  final Farmer farmer;

  const SMEFarmerDetailScreen({super.key, required this.farmer});

  @override
  State<SMEFarmerDetailScreen> createState() => _SMEFarmerDetailScreenState();
}

class _SMEFarmerDetailScreenState extends State<SMEFarmerDetailScreen> {
  bool _isFavorite = false; // Would come from favorites provider
  ProductCategory? _selectedCategory;

  List<Product> get _filteredProducts {
    if (_selectedCategory == null) {
      return widget.farmer.products;
    }
    return widget.farmer.getProductsByCategory(_selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final smeLocation = authProvider.currentUser?.location;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farmer.name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              if (kDebugMode) {
                debugPrint(
                  'Farmer ${_isFavorite ? 'added to' : 'removed from'} favorites',
                );
              }
            },
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: Column(
        children: [
          // Farmer Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.store,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.farmer.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.farmer.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Verified Farmer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatBadge(
                      icon: Icons.star,
                      label: widget.farmer.rating.toStringAsFixed(1),
                      sublabel: '${widget.farmer.totalReviews} reviews',
                    ),
                    const SizedBox(width: 16),
                    _StatBadge(
                      icon: Icons.receipt_long,
                      label: '${widget.farmer.totalOrders}',
                      sublabel: 'orders',
                    ),
                    if (smeLocation != null &&
                        widget.farmer.location != null) ...[
                      const SizedBox(width: 16),
                      _StatBadge(
                        icon: Icons.location_on,
                        label: widget.farmer.getDistanceText(smeLocation),
                        sublabel: 'away',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Category Filter
          if (widget.farmer.products.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'All',
                    count: widget.farmer.products.length,
                    isSelected: _selectedCategory == null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                  ),
                  ...ProductCategoryExtension.mainCategories.map((category) {
                    final productsInCategory = widget.farmer
                        .getProductsByCategory(category);
                    if (productsInCategory.isEmpty)
                      return const SizedBox.shrink();

                    return _CategoryChip(
                      label: category.displayName,
                      count: productsInCategory.length,
                      isSelected: _selectedCategory == category,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),

          // Products List
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('No products in this category'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _ProductCard(
                        product: product,
                        farmerId: widget.farmer.id,
                        farmerName: widget.farmer.name,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade200,
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String farmerId;
  final String farmerName;

  const _ProductCard({
    required this.product,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final quantityInCart = cartProvider.getItemQuantity(product.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'UGX ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '/${product.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${product.stockQuantity} ${product.unit}s',
                    style: TextStyle(
                      fontSize: 11,
                      color: product.stockQuantity > 10
                          ? AppTheme.successColor
                          : product.stockQuantity > 0
                          ? AppTheme.warningColor
                          : AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Add to Cart Button
            Column(
              children: [
                if (quantityInCart > 0)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            try {
                              await cartProvider.addItem(
                                product,
                                farmerId: farmerId,
                                farmerName: farmerName,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added 1 more ${product.name}',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Icon(
                            Icons.add,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        Text(
                          '$quantityInCart',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            try {
                              final currentQty = cartProvider.getItemQuantity(
                                product.id,
                              );
                              if (currentQty > 1) {
                                // Find cart item ID
                                final cartItem = cartProvider.cartItems
                                    .firstWhere(
                                      (item) => item.productId == product.id,
                                    );
                                await cartProvider.updateQuantity(
                                  cartItem.id,
                                  currentQty - 1,
                                );
                              } else {
                                // Remove item completely
                                final cartItem = cartProvider.cartItems
                                    .firstWhere(
                                      (item) => item.productId == product.id,
                                    );
                                await cartProvider.removeItem(cartItem.id);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Icon(
                            Icons.remove,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed:
                        product.stockQuantity > 0 && product.stockQuantity > 0
                        ? () async {
                            try {
                              await cartProvider.addItem(
                                product,
                                farmerId: farmerId,
                                farmerName: farmerName,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} added to cart',
                                    ),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Add'),
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
    );
  }
}
