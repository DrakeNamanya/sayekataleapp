import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../models/product_category_hierarchy.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';

class PSAAddEditProductScreen extends StatefulWidget {
  final Product? product; // null for add, non-null for edit

  const PSAAddEditProductScreen({super.key, this.product});

  @override
  State<PSAAddEditProductScreen> createState() => _PSAAddEditProductScreenState();
}

class _PSAAddEditProductScreenState extends State<PSAAddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitSizeController = TextEditingController();
  final ProductService _productService = ProductService();
  
  ProductCategory _selectedCategory = ProductCategory.crop;
  String? _selectedMainCategory;
  String? _selectedSubcategory;
  String _selectedUnit = 'KGs';
  String? _productImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      // Edit mode - load existing product data
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stockQuantity.toString();
      _unitSizeController.text = widget.product!.unitSize.toString();
      _selectedCategory = widget.product!.category;
      _selectedMainCategory = widget.product!.mainCategory;
      _selectedSubcategory = widget.product!.subcategory;
      _selectedUnit = widget.product!.unit;
      // _productImagePath = widget.product!.imageUrl; // Product doesn't have imageUrl field yet
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _productImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get current PSA user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final psaUser = authProvider.currentUser;
    
    if (psaUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not logged in'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final stockQuantity = int.parse(_stockController.text.trim());
      final unitSize = _unitSizeController.text.trim().isNotEmpty 
          ? int.parse(_unitSizeController.text.trim()) 
          : 1;

      if (widget.product == null) {
        // Create new product
        await _productService.createProduct(
          farmerId: psaUser.id,
          farmerName: psaUser.name,
          name: name,
          description: description,
          category: _selectedCategory,
          mainCategory: _selectedMainCategory,
          subcategory: _selectedSubcategory,
          price: price,
          unit: _selectedUnit,
          unitSize: unitSize,
          stockQuantity: stockQuantity,
          imageUrl: _productImagePath,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Product added successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        // Update existing product
        await _productService.updateProduct(
          productId: widget.product!.id,
          name: name,
          description: description,
          category: _selectedCategory,
          mainCategory: _selectedMainCategory,
          subcategory: _selectedSubcategory,
          price: price,
          unit: _selectedUnit,
          unitSize: unitSize,
          stockQuantity: stockQuantity,
          imageUrl: _productImagePath,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Product updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving product: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Product' : 'Add New Product'),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showDeleteConfirmation();
              },
              tooltip: 'Delete Product',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Image
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _productImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _productImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 48, color: AppTheme.primaryColor),
                                  SizedBox(height: 8),
                                  Text('Tap to add photo', style: TextStyle(color: AppTheme.primaryColor)),
                                ],
                              );
                            },
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 48, color: AppTheme.primaryColor),
                            SizedBox(height: 8),
                            Text('Tap to add photo', style: TextStyle(color: AppTheme.primaryColor)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Main Category
            DropdownButtonFormField<String>(
              value: _selectedMainCategory,
              decoration: const InputDecoration(
                labelText: 'Main Category *',
                prefixIcon: Icon(Icons.category),
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
                setState(() {
                  _selectedMainCategory = value;
                  _selectedSubcategory = null; // Reset subcategory
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a main category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subcategory
            if (_selectedMainCategory != null)
              DropdownButtonFormField<String>(
                value: _selectedSubcategory,
                decoration: const InputDecoration(
                  labelText: 'Subcategory *',
                  prefixIcon: Icon(Icons.grain),
                  hintText: 'Select subcategory',
                ),
                items: ProductCategoryHierarchy.categoryMap[_selectedMainCategory]!
                    .map((subcat) {
                  return DropdownMenuItem(
                    value: subcat.value,
                    child: Text(subcat.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubcategory = value;
                  });
                },
                validator: (value) {
                  if (_selectedMainCategory != null && value == null) {
                    return 'Please select a subcategory';
                  }
                  return null;
                },
              ),
            if (_selectedMainCategory != null)
              const SizedBox(height: 16),

            // Product Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                hintText: 'e.g., Hybrid Maize Seeds',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
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
                prefixIcon: Icon(Icons.description),
                hintText: 'Describe your product',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (UGX) *',
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Price is required';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Unit and Unit Size
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    items: ProductCategoryHierarchy.unitOptions.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUnit = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _unitSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Size',
                      hintText: 'e.g., 50 (for 50kg bag)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final size = double.tryParse(value);
                        if (size == null || size <= 0) {
                          return 'Invalid size';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock Quantity
            TextFormField(
              controller: _stockController,
              decoration: InputDecoration(
                labelText: 'Stock Quantity *',
                prefixIcon: const Icon(Icons.inventory),
                hintText: '0',
                suffixText: '${_selectedUnit}s',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Stock quantity is required';
                }
                final stock = int.tryParse(value);
                if (stock == null || stock < 0) {
                  return 'Please enter a valid quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isEditMode ? 'Update Product' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${widget.product!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                await _productService.deleteProduct(widget.product!.id);
                if (mounted) {
                  Navigator.pop(context, 'deleted'); // Return to products screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Product deleted successfully'),
                      backgroundColor: AppTheme.successColor,
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
