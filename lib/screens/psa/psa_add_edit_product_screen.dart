import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../models/product.dart';
import '../../models/product_category_hierarchy.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/psa_approval_gate.dart';
import '../../widgets/psa_subscription_gate.dart';

class PSAAddEditProductScreen extends StatefulWidget {
  final Product? product; // null for add, non-null for edit

  const PSAAddEditProductScreen({super.key, this.product});

  @override
  State<PSAAddEditProductScreen> createState() =>
      _PSAAddEditProductScreenState();
}

class _PSAAddEditProductScreenState extends State<PSAAddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitSizeController = TextEditingController();
  final ProductService _productService = ProductService();
  final ImageStorageService _imageStorageService = ImageStorageService();

  ProductCategory _selectedCategory = ProductCategory.crop;
  String? _selectedMainCategory;
  String? _selectedSubcategory;
  String _selectedUnit = 'KGs';
  final List<XFile> _selectedImages = []; // ✅ Store up to 3 images
  List<String> _existingImageUrls =
      []; // ✅ Store existing Firebase URLs for edit mode
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
      // ✅ Load all existing Firebase URLs from images list
      _existingImageUrls = widget.product!.images.toList();
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

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    if (_selectedImages.length + _existingImageUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 photos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picker = ImagePicker();

    // Show options for camera or gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(pickedFile);
        });
      }
    }
  }

  /// Remove selected image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Remove existing image URL
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
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

      // ✅ Upload multiple images to Firebase Storage
      List<String> allImageUrls = List.from(_existingImageUrls);
      if (_selectedImages.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '📸 Uploading ${_selectedImages.length} product images to Firebase Storage...',
          );
        }
        final newImageUrls = await _imageStorageService
            .uploadMultipleImagesFromXFiles(
              images: _selectedImages,
              folder: 'products',
              userId: psaUser.id,
              compress: true,
            );
        allImageUrls.addAll(newImageUrls);
        if (kDebugMode) {
          debugPrint('✅ Uploaded ${newImageUrls.length} images successfully');
        }
      }

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
          imageUrls: allImageUrls.isNotEmpty
              ? allImageUrls
              : null, // ✅ Use all images
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
          imageUrls: allImageUrls.isNotEmpty
              ? allImageUrls
              : null, // ✅ Multiple images
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

    return PSAApprovalGate(
      blockedFeatureName: isEditMode ? 'Edit Product' : 'Add Product',
      child: PSASubscriptionGate(
        blockedFeatureName: isEditMode ? 'Edit Product' : 'Add Product',
        child: Scaffold(
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
            // ✅ Product Images (up to 3)
            const Text(
              'Product Photos (up to 3)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing Firebase images
                  ..._existingImageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(url, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
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
                    );
                  }),
                  // Newly selected images
                  ..._selectedImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final xFile = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                      future: xFile.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    )
                                  : Image.network(
                                      xFile.path,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
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
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'New',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Add photo button
                  if (_selectedImages.length + _existingImageUrls.length < 3)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 32,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Category
            DropdownButtonFormField<String>(
              initialValue: _selectedMainCategory,
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
                return DropdownMenuItem(value: key, child: Text(displayName));
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
                initialValue: _selectedSubcategory,
                decoration: const InputDecoration(
                  labelText: 'Subcategory *',
                  prefixIcon: Icon(Icons.grain),
                  hintText: 'Select subcategory',
                ),
                items: ProductCategoryHierarchy
                    .categoryMap[_selectedMainCategory]!
                    .map((subcat) {
                      return DropdownMenuItem(
                        value: subcat.value,
                        child: Text(subcat.displayName),
                      );
                    })
                    .toList(),
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
            if (_selectedMainCategory != null) const SizedBox(height: 16),

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
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    items: ProductCategoryHierarchy.unitOptions.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
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
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete ${widget.product!.name}?',
        ),
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
                  Navigator.pop(
                    context,
                    'deleted',
                  ); // Return to products screen
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
