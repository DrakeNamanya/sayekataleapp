import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// Service for managing products in Firestore
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // PRODUCT CREATION (Farmers)
  // ============================================================================

  /// Create a new product
  Future<String> createProduct({
    required String farmerId,
    required String farmerName,
    required String name,
    required String description,
    required ProductCategory category,
    required double price,
    required String unit,
    required int stockQuantity,
    String? imageUrl,
    String? location,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📦 Creating product: $name for farmer $farmerName');
      }

      final product = {
        'farmer_id': farmerId,
        'farmer_name': farmerName,
        'name': name,
        'description': description,
        'category': category.toString().split('.').last,
        'price': price,
        'unit': unit,
        'stock_quantity': stockQuantity,
        'low_stock_threshold': 10,
        'image_url': imageUrl ?? 'https://via.placeholder.com/400x400?text=${Uri.encodeComponent(name)}',
        'location': location ?? '',
        'rating': 0.0,
        'total_reviews': 0,
        'is_available': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('products').add(product);

      if (kDebugMode) {
        debugPrint('✅ Product created with ID: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating product: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // PRODUCT UPDATES (Farmers)
  // ============================================================================

  /// Update an existing product
  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    ProductCategory? category,
    double? price,
    String? unit,
    int? stockQuantity,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📝 Updating product: $productId');
      }

      final Map<String, dynamic> updates = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category.toString().split('.').last;
      if (price != null) updates['price'] = price;
      if (unit != null) updates['unit'] = unit;
      if (stockQuantity != null) updates['stock_quantity'] = stockQuantity;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (isAvailable != null) updates['is_available'] = isAvailable;

      await _firestore.collection('products').doc(productId).update(updates);

      if (kDebugMode) {
        debugPrint('✅ Product updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating product: $e');
      }
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ Deleting product: $productId');
      }

      await _firestore.collection('products').doc(productId).delete();

      if (kDebugMode) {
        debugPrint('✅ Product deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting product: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // PRODUCT RETRIEVAL
  // ============================================================================

  /// Get all products for a farmer
  Future<List<Product>> getFarmerProducts(String farmerId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Fetching products for farmer: $farmerId');
      }

      final querySnapshot = await _firestore
          .collection('products')
          .where('farmer_id', isEqualTo: farmerId)
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Product.fromFirestore(data, doc.id);
      }).toList();

      if (kDebugMode) {
        debugPrint('📋 Found ${products.length} products');
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching farmer products: $e');
      }
      return [];
    }
  }

  /// Stream of farmer products for real-time updates
  Stream<List<Product>> streamFarmerProducts(String farmerId) {
    return _firestore
        .collection('products')
        .where('farmer_id', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Get all available products (for buyers)
  Future<List<Product>> getAllAvailableProducts() async {
    try {
      if (kDebugMode) {
        debugPrint('🛒 Fetching all available products');
      }

      final querySnapshot = await _firestore
          .collection('products')
          .where('is_available', isEqualTo: true)
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Product.fromFirestore(data, doc.id);
      }).toList();

      if (kDebugMode) {
        debugPrint('📋 Found ${products.length} available products');
      }

      // Sort by created date (newest first)
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return products;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching available products: $e');
      }
      return [];
    }
  }

  /// Stream of all available products for real-time updates (for buyers)
  Stream<List<Product>> streamAllAvailableProducts() {
    return _firestore
        .collection('products')
        .where('is_available', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return Product.fromFirestore(data, doc.id);
      }).toList();

      // Sort by created date (newest first)
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return products;
    });
  }

  /// Get a single product by ID
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();

      if (doc.exists) {
        return Product.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching product: $e');
      }
      return null;
    }
  }

  // ============================================================================
  // STOCK MANAGEMENT
  // ============================================================================

  /// Update product stock quantity
  Future<void> updateStock(String productId, int newQuantity) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'stock_quantity': newQuantity,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Stock updated for product: $productId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating stock: $e');
      }
      rethrow;
    }
  }

  /// Decrease stock after order
  Future<void> decreaseStock(String productId, int quantity) async {
    try {
      final product = await getProduct(productId);
      if (product != null) {
        final newStock = product.stockQuantity - quantity;
        await updateStock(productId, newStock >= 0 ? newStock : 0);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error decreasing stock: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // SEARCH AND FILTER
  // ============================================================================

  /// Search products by name or description
  Future<List<Product>> searchProducts(String query) async {
    try {
      final allProducts = await getAllAvailableProducts();
      final lowerQuery = query.toLowerCase();

      return allProducts.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
            (product.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching products: $e');
      }
      return [];
    }
  }

  /// Filter products by category
  Future<List<Product>> getProductsByCategory(ProductCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category.toString().split('.').last)
          .where('is_available', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error filtering by category: $e');
      }
      return [];
    }
  }
}
