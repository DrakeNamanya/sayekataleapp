import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../../models/product.dart';

class SHGProductsScreen extends StatefulWidget {
  final bool openAddDialog;

  const SHGProductsScreen({super.key, this.openAddDialog = false});

  @override
  State<SHGProductsScreen> createState() => _SHGProductsScreenState();
}

class _SHGProductsScreenState extends State<SHGProductsScreen> {
  ProductCategory _selectedCategory = ProductCategory.crop;

  // Mock products data organized by category
  final Map<ProductCategory, List<Product>> _productsByCategory = {
    ProductCategory.crop: [
      Product(
        id: 'crop1',
        farmId: 'farm1',
        name: 'Fresh Onions',
        description: 'Red onions, 1kg pack',
        category: ProductCategory.onions,
        unit: 'kg',
        unitSize: 1,
        price: 3000,
        stockQuantity: 150,
        lowStockThreshold: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'crop2',
        farmId: 'farm1',
        name: 'Watermelon',
        description: 'Sweet red watermelon',
        category: ProductCategory.watermelon,
        unit: 'piece',
        unitSize: 1,
        price: 15000,
        stockQuantity: 25,
        lowStockThreshold: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'crop3',
        farmId: 'farm1',
        name: 'Fresh Tomatoes',
        description: 'Ripe tomatoes, 1kg',
        category: ProductCategory.tomatoes,
        unit: 'kg',
        unitSize: 1,
        price: 4000,
        stockQuantity: 80,
        lowStockThreshold: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'crop4',
        farmId: 'farm1',
        name: 'Ground Nuts',
        description: 'Roasted ground nuts',
        category: ProductCategory.groundNuts,
        unit: 'kg',
        unitSize: 1,
        price: 8000,
        stockQuantity: 45,
        lowStockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'crop5',
        farmId: 'farm1',
        name: 'Soya Beans',
        description: 'Organic soya beans',
        category: ProductCategory.soya,
        unit: 'kg',
        unitSize: 1,
        price: 6000,
        stockQuantity: 60,
        lowStockThreshold: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'crop6',
        farmId: 'farm1',
        name: 'Passion Fruits',
        description: 'Fresh passion fruits',
        category: ProductCategory.passionFruits,
        unit: 'kg',
        unitSize: 1,
        price: 5000,
        stockQuantity: 8,
        lowStockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
    ProductCategory.poultry: [
      Product(
        id: 'poultry1',
        farmId: 'farm1',
        name: 'Broiler Chicken',
        description: 'Ready for cooking, 2-2.5kg',
        category: ProductCategory.broilers,
        unit: 'bird',
        unitSize: 1,
        price: 18000,
        stockQuantity: 25,
        lowStockThreshold: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'poultry2',
        farmId: 'farm1',
        name: 'Sasso Chicken',
        description: 'Free-range sasso chicken',
        category: ProductCategory.sasso,
        unit: 'bird',
        unitSize: 1,
        price: 22000,
        stockQuantity: 15,
        lowStockThreshold: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'poultry3',
        farmId: 'farm1',
        name: 'Fresh Chicken Eggs',
        description: 'Brown eggs, tray of 30',
        category: ProductCategory.eggs,
        unit: 'tray',
        unitSize: 30,
        price: 12000,
        stockQuantity: 50,
        lowStockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'poultry4',
        farmId: 'farm1',
        name: 'Local Eggs',
        description: 'Free-range local eggs',
        category: ProductCategory.localEggs,
        unit: 'tray',
        unitSize: 30,
        price: 15000,
        stockQuantity: 20,
        lowStockThreshold: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'poultry5',
        farmId: 'farm1',
        name: 'Local Chicken',
        description: 'Village chicken',
        category: ProductCategory.localChicken,
        unit: 'bird',
        unitSize: 1,
        price: 25000,
        stockQuantity: 10,
        lowStockThreshold: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'poultry6',
        farmId: 'farm1',
        name: 'Incubation Service',
        description: 'Egg incubation per 100 eggs',
        category: ProductCategory.incubationServices,
        unit: 'service',
        unitSize: 100,
        price: 50000,
        stockQuantity: 5,
        lowStockThreshold: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'poultry7',
        farmId: 'farm1',
        name: 'Organic Chicken Manure',
        description: 'Poultry manure, 50kg bag',
        category: ProductCategory.organicManure,
        unit: 'bag',
        unitSize: 50,
        price: 20000,
        stockQuantity: 100,
        lowStockThreshold: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'poultry8',
        farmId: 'farm1',
        name: 'Off-Layer Hens',
        description: 'Laying hens for meat',
        category: ProductCategory.offLayers,
        unit: 'bird',
        unitSize: 1,
        price: 15000,
        stockQuantity: 0,
        lowStockThreshold: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
    ProductCategory.goats: [
      Product(
        id: 'goat1',
        farmId: 'farm1',
        name: 'Male Goats',
        description: 'Healthy male goats for breeding',
        category: ProductCategory.maleGoats,
        unit: 'piece',
        unitSize: 1,
        price: 350000,
        stockQuantity: 5,
        lowStockThreshold: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'goat2',
        farmId: 'farm1',
        name: 'Female Goats',
        description: 'Healthy female goats',
        category: ProductCategory.femaleGoats,
        unit: 'piece',
        unitSize: 1,
        price: 300000,
        stockQuantity: 8,
        lowStockThreshold: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'goat3',
        farmId: 'farm1',
        name: 'Goat Manure',
        description: 'Organic goat manure, 50kg',
        category: ProductCategory.goatManure,
        unit: 'bag',
        unitSize: 50,
        price: 15000,
        stockQuantity: 40,
        lowStockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
    ProductCategory.cows: [
      Product(
        id: 'cow1',
        farmId: 'farm1',
        name: 'Fresh Cow Milk',
        description: 'Fresh milk, 1 liter',
        category: ProductCategory.milk,
        unit: 'liter',
        unitSize: 1,
        price: 2500,
        stockQuantity: 100,
        lowStockThreshold: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'cow2',
        farmId: 'farm1',
        name: 'Bulls',
        description: 'Strong bulls for breeding',
        category: ProductCategory.bulls,
        unit: 'piece',
        unitSize: 1,
        price: 2500000,
        stockQuantity: 2,
        lowStockThreshold: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'cow3',
        farmId: 'farm1',
        name: 'Dairy Cows',
        description: 'High milk production cows',
        category: ProductCategory.cowsFemale,
        unit: 'piece',
        unitSize: 1,
        price: 2000000,
        stockQuantity: 3,
        lowStockThreshold: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'cow4',
        farmId: 'farm1',
        name: 'Cow Manure',
        description: 'Organic cow manure, 50kg',
        category: ProductCategory.cowManure,
        unit: 'bag',
        unitSize: 50,
        price: 18000,
        stockQuantity: 60,
        lowStockThreshold: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddProductDialog();
      });
    }
  }

  List<Product> get _filteredProducts {
    return _productsByCategory[_selectedCategory] ?? [];
  }

  void _showAddProductDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddProductForm(
        onProductAdded: (product) {
          setState(() {
            final category = product.category.parentCategory;
            if (_productsByCategory.containsKey(category)) {
              _productsByCategory[category]!.add(product);
            } else {
              _productsByCategory[category] = [product];
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Tabs
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
                    count: _productsByCategory[ProductCategory.crop]?.length ?? 0,
                    isSelected: _selectedCategory == ProductCategory.crop,
                    color: Colors.green.shade700,
                    onTap: () => setState(() => _selectedCategory = ProductCategory.crop),
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    icon: Icons.pets_outlined,
                    label: 'Poultry',
                    count: _productsByCategory[ProductCategory.poultry]?.length ?? 0,
                    isSelected: _selectedCategory == ProductCategory.poultry,
                    color: AppTheme.primaryColor,
                    onTap: () => setState(() => _selectedCategory = ProductCategory.poultry),
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    icon: Icons.pets_outlined,
                    label: 'Goats',
                    count: _productsByCategory[ProductCategory.goats]?.length ?? 0,
                    isSelected: _selectedCategory == ProductCategory.goats,
                    color: Colors.brown.shade600,
                    onTap: () => setState(() => _selectedCategory = ProductCategory.goats),
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    icon: Icons.agriculture_outlined,
                    label: 'Cows',
                    count: _productsByCategory[ProductCategory.cows]?.length ?? 0,
                    isSelected: _selectedCategory == ProductCategory.cows,
                    color: Colors.blue.shade700,
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
                          'No products in this category',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddProductDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _ProductCard(
                        product: product,
                        onEdit: () {
                          // TODO: Edit product
                        },
                        onDelete: () {
                          setState(() {
                            _productsByCategory[_selectedCategory]?.remove(product);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product deleted'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
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
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
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
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    Color stockColor;
    String stockText;

    if (product.isOutOfStock) {
      stockColor = AppTheme.errorColor;
      stockText = 'Out of Stock';
    } else if (product.isLowStock) {
      stockColor = AppTheme.warningColor;
      stockText = 'Low Stock';
    } else {
      stockColor = AppTheme.successColor;
      stockText = 'In Stock';
    }

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stockColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stockText,
                          style: TextStyle(
                            color: stockColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.displayName,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${product.stockQuantity} ${product.unit}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UGX ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: onEdit,
                            color: AppTheme.primaryColor,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Product'),
                                  content: const Text('Are you sure you want to delete this product?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        onDelete();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            color: AppTheme.errorColor,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
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
      case ProductCategory.eggs:
      case ProductCategory.localEggs:
        return Icons.egg_outlined;
      case ProductCategory.broilers:
      case ProductCategory.sasso:
      case ProductCategory.localChicken:
      case ProductCategory.offLayers:
        return Icons.restaurant_outlined;
      case ProductCategory.onions:
      case ProductCategory.watermelon:
      case ProductCategory.tomatoes:
      case ProductCategory.groundNuts:
      case ProductCategory.soya:
      case ProductCategory.passionFruits:
        return Icons.agriculture_outlined;
      case ProductCategory.maleGoats:
      case ProductCategory.femaleGoats:
        return Icons.pets_outlined;
      case ProductCategory.milk:
      case ProductCategory.bulls:
      case ProductCategory.cowsFemale:
        return Icons.agriculture_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _AddProductForm extends StatefulWidget {
  final Function(Product) onProductAdded;

  const _AddProductForm({required this.onProductAdded});

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  ProductCategory _selectedMainCategory = ProductCategory.crop;
  ProductCategory? _selectedSubCategory;
  String? _productImagePath;

  List<ProductCategory> get _subCategories {
    return ProductCategoryExtension.getSubcategories(_selectedMainCategory);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _productImagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Product',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Product Image
                const Text(
                  'Product Image',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _productImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _productImagePath!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload product image',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Category
                DropdownButtonFormField<ProductCategory>(
                  value: _selectedMainCategory,
                  decoration: const InputDecoration(
                    labelText: 'Main Category *',
                  ),
                  items: ProductCategoryExtension.mainCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMainCategory = value!;
                      _selectedSubCategory = null; // Reset subcategory
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Sub Category
                DropdownButtonFormField<ProductCategory>(
                  value: _selectedSubCategory,
                  decoration: const InputDecoration(
                    labelText: 'Product Type *',
                  ),
                  items: _subCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select product type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Product Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g., Fresh Tomatoes',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Product description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Price and Stock
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (UGX) *',
                          hintText: '0',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity *',
                          hintText: '0',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter stock';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newProduct = Product(
                          id: 'p${DateTime.now().millisecondsSinceEpoch}',
                          farmId: 'farm1',
                          name: _nameController.text.trim(),
                          description: _descriptionController.text.trim(),
                          category: _selectedSubCategory!,
                          unit: 'kg',
                          unitSize: 1,
                          price: double.parse(_priceController.text.trim()),
                          stockQuantity: int.parse(_stockController.text.trim()),
                          images: _productImagePath != null ? [_productImagePath!] : [],
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        
                        widget.onProductAdded(newProduct);
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product added successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    },
                    child: const Text('Add Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
