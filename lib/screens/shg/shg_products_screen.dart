import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/product.dart';
import '../../models/product_category_hierarchy.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../services/product_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/image_storage_service.dart';
import '../../utils/app_theme.dart';

class SHGProductsScreen extends StatefulWidget {
  final bool openAddDialog;

  const SHGProductsScreen({super.key, this.openAddDialog = false});

  @override
  State<SHGProductsScreen> createState() => _SHGProductsScreenState();
}

class _SHGProductsScreenState extends State<SHGProductsScreen> {
  final ProductService _productService = ProductService();
  ProductCategory _selectedCategory = ProductCategory.crop;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final farmerId = authProvider.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddProductDialog(),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.streamFarmerProducts(farmerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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

                // Filter by selected category
                if (_selectedCategory != ProductCategory.crop) {
                  products = products
                      .where((p) => p.category == _selectedCategory)
                      .toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first product',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddProductDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('All', ProductCategory.crop),
          _buildCategoryChip('Crops', ProductCategory.crop),
          _buildCategoryChip('Vegetables', ProductCategory.tomatoes),
          _buildCategoryChip('Onions', ProductCategory.onions),
          _buildCategoryChip('Ground Nuts', ProductCategory.groundNuts),
          _buildCategoryChip('Poultry', ProductCategory.poultry),
          _buildCategoryChip('Eggs', ProductCategory.eggs),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, ProductCategory category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.inventory_2,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Product Info
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
                  if (product.description != null)
                    Text(
                      product.description!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'UGX ${NumberFormat('#,###').format(product.price)}/${product.unit}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.isLowStock
                              ? Colors.orange[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock: ${product.stockQuantity}',
                          style: TextStyle(
                            fontSize: 11,
                            color: product.isLowStock
                                ? Colors.orange[800]
                                : Colors.green[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditProductDialog(product),
                  tooltip: 'Edit',
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _confirmDelete(product),
                  tooltip: 'Delete',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    ProductCategory selectedCategory = ProductCategory.crop;
    String? selectedMainCategory;
    String? selectedSubcategory;
    String selectedUnit = 'KGs';
    List<XFile> selectedImages = []; // Store up to 3 images
    final imagePickerService = ImagePickerService();
    bool isSubmitting = false; // Prevent duplicate submissions

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during submission
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedMainCategory,
                  decoration: const InputDecoration(
                    labelText: 'Main Category *',
                    hintText: 'Select main category',
                  ),
                  items: ProductCategoryHierarchy.categoryMap.keys.map((key) {
                    String displayName = key;
                    if (key == 'crop') displayName = 'Crop';
                    if (key == 'oilSeeds') displayName = 'Oil Seeds';
                    if (key == 'poultry') displayName = 'Poultry';
                    if (key == 'goats') displayName = 'Goats';
                    if (key == 'cows') displayName = 'Cows';
                    return DropdownMenuItem(
                      value: key,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMainCategory = value;
                      selectedSubcategory = null; // Reset subcategory
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (selectedMainCategory != null)
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubcategory,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory *',
                      hintText: 'Select subcategory',
                    ),
                    items: ProductCategoryHierarchy
                        .categoryMap[selectedMainCategory]!
                        .map((subcat) {
                          return DropdownMenuItem(
                            value: subcat.value,
                            child: Text(subcat.displayName),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedSubcategory = value);
                    },
                  ),
                if (selectedMainCategory != null) const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g., Fresh Tomatoes',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your product',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (UGX) *',
                          hintText: '5000',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit *'),
                        items: ProductCategoryHierarchy.unitOptions
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedUnit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity *',
                    hintText: '100',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Product Photos Section
                const Text(
                  'Product Photos (At least 1 required) *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      // Display selected images
                      ...List.generate(
                        selectedImages.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<Uint8List>(
                                  future: selectedImages[index].readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Add photo button
                      if (selectedImages.length < 3)
                        InkWell(
                          onTap: () async {
                            final image = await imagePickerService
                                .showImageSourceBottomSheet(context);
                            if (image != null) {
                              setDialogState(() {
                                selectedImages.add(image);
                              });
                            }
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 32,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // Prevent duplicate submissions
                      if (isSubmitting) return;

                      if (nameController.text.trim().isEmpty ||
                          priceController.text.trim().isEmpty ||
                          stockController.text.trim().isEmpty ||
                          selectedMainCategory == null ||
                          selectedSubcategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // ✅ CRITICAL: Validate that at least one photo is selected
                      if (selectedImages.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Please add at least one product photo'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      // Set submitting state
                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        final authProvider = Provider.of<app_auth.AuthProvider>(
                          context,
                          listen: false,
                        );
                        final user = authProvider.currentUser!;

                        // Upload product images to Firebase Storage
                        List<String>? imageUrls;
                        if (selectedImages.isNotEmpty) {
                          if (kDebugMode) {
                            debugPrint(
                              '📤 Uploading ${selectedImages.length} product images...',
                            );
                          }

                          final imageStorageService = ImageStorageService();
                          final firebaseUid = firebase_auth
                              .FirebaseAuth.instance.currentUser!.uid;
                          imageUrls = await imageStorageService
                              .uploadMultipleImagesFromXFiles(
                                images: selectedImages,
                                folder: 'products',
                                userId:
                                    firebaseUid, // Use Firebase Auth UID, not user.id
                                compress: true,
                              )
                              .timeout(
                                const Duration(seconds: 60),
                                onTimeout: () {
                                  throw Exception(
                                    'Image upload timeout - please check your internet connection',
                                  );
                                },
                              );

                          if (kDebugMode) {
                            debugPrint(
                              '✅ Uploaded ${imageUrls.length} product images',
                            );
                          }
                        }

                        // Create product with all uploaded images
                        await _productService.createProduct(
                          farmerId: user.id,
                          farmerName: user.name,
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                          category: selectedCategory,
                          mainCategory: selectedMainCategory,
                          subcategory: selectedSubcategory,
                          price: double.parse(priceController.text.trim()),
                          unit: selectedUnit,
                          stockQuantity: int.parse(stockController.text.trim()),
                          imageUrls: imageUrls, // Pass all images
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Product added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          debugPrint('❌ Error adding product: $e');
                        }
                        // Reset submitting state on error
                        if (mounted) {
                          setDialogState(() {
                            isSubmitting = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final descController = TextEditingController(
      text: product.description ?? '',
    );
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final stockController = TextEditingController(
      text: product.stockQuantity.toString(),
    );
    ProductCategory selectedCategory = product.category;
    String? selectedMainCategory = product.mainCategory;
    String? selectedSubcategory = product.subcategory;
    String selectedUnit = product.unit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedMainCategory,
                  decoration: const InputDecoration(
                    labelText: 'Main Category *',
                    hintText: 'Select main category',
                  ),
                  items: ProductCategoryHierarchy.categoryMap.keys.map((key) {
                    String displayName = key;
                    if (key == 'crop') displayName = 'Crop';
                    if (key == 'oilSeeds') displayName = 'Oil Seeds';
                    if (key == 'poultry') displayName = 'Poultry';
                    if (key == 'goats') displayName = 'Goats';
                    if (key == 'cows') displayName = 'Cows';
                    return DropdownMenuItem(
                      value: key,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMainCategory = value;
                      selectedSubcategory =
                          null; // Reset subcategory when main category changes
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (selectedMainCategory != null)
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubcategory,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory *',
                      hintText: 'Select subcategory',
                    ),
                    items: ProductCategoryHierarchy
                        .categoryMap[selectedMainCategory]!
                        .map((subcat) {
                          return DropdownMenuItem(
                            value: subcat.value,
                            child: Text(subcat.displayName),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedSubcategory = value);
                    },
                  ),
                if (selectedMainCategory != null) const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (UGX)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit *'),
                        items: ProductCategoryHierarchy.unitOptions
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedUnit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _productService.updateProduct(
                    productId: product.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    category: selectedCategory,
                    mainCategory: selectedMainCategory,
                    subcategory: selectedSubcategory,
                    price: double.parse(priceController.text.trim()),
                    unit: selectedUnit,
                    stockQuantity: int.parse(stockController.text.trim()),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Product updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _productService.deleteProduct(product.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Product deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
