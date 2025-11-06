import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

/// Service for managing user's favorite products
class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a product to user's favorites
  Future<void> addFavorite({
    required String userId,
    required String productId,
    required String farmerId,
  }) async {
    try {
      final favoriteId = '${userId}_$productId';
      await _firestore.collection('favorite_products').doc(favoriteId).set({
        'user_id': userId,
        'product_id': productId,
        'farmer_id': farmerId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  /// Remove a product from user's favorites
  Future<void> removeFavorite({
    required String userId,
    required String productId,
  }) async {
    try {
      final favoriteId = '${userId}_$productId';
      await _firestore.collection('favorite_products').doc(favoriteId).delete();
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  /// Toggle favorite status (add if not exists, remove if exists)
  Future<bool> toggleFavorite({
    required String userId,
    required String productId,
    required String farmerId,
  }) async {
    try {
      final isFavorite = await isFavorited(userId: userId, productId: productId);
      
      if (isFavorite) {
        await removeFavorite(userId: userId, productId: productId);
        return false; // Now unfavorited
      } else {
        await addFavorite(userId: userId, productId: productId, farmerId: farmerId);
        return true; // Now favorited
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Check if a product is favorited by user
  Future<bool> isFavorited({
    required String userId,
    required String productId,
  }) async {
    try {
      final favoriteId = '${userId}_$productId';
      final doc = await _firestore.collection('favorite_products').doc(favoriteId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get all favorite product IDs for a user
  Future<List<String>> getUserFavoriteProductIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorite_products')
          .where('user_id', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => doc.data()['product_id'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get favorite product IDs: $e');
    }
  }

  /// Get all favorite products for a user (returns Product objects)
  Future<List<Product>> getUserFavoriteProducts(String userId) async {
    try {
      // Get favorite product IDs
      final favoriteProductIds = await getUserFavoriteProductIds(userId);

      if (favoriteProductIds.isEmpty) {
        return [];
      }

      // Firestore 'in' query has a limit of 10 items
      // Split into batches if more than 10 favorites
      final List<Product> allFavoriteProducts = [];
      
      for (int i = 0; i < favoriteProductIds.length; i += 10) {
        final batch = favoriteProductIds.skip(i).take(10).toList();
        
        final productsSnapshot = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final products = productsSnapshot.docs
            .map((doc) => Product.fromFirestore(doc.data(), doc.id))
            .where((product) => !product.isOutOfStock) // Filter out of stock
            .toList();

        allFavoriteProducts.addAll(products);
      }

      return allFavoriteProducts;
    } catch (e) {
      throw Exception('Failed to get favorite products: $e');
    }
  }

  /// Stream all favorite product IDs for a user (real-time updates)
  Stream<List<String>> streamUserFavoriteProductIds(String userId) {
    return _firestore
        .collection('favorite_products')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()['product_id'] as String).toList();
    });
  }

  /// Get count of favorite products for a user
  Future<int> getUserFavoritesCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorite_products')
          .where('user_id', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all favorite farmer IDs for a user (unique farmers from favorites)
  Future<List<String>> getUserFavoriteFarmerIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorite_products')
          .where('user_id', isEqualTo: userId)
          .get();

      // Get unique farmer IDs
      final farmerIds = snapshot.docs
          .map((doc) => doc.data()['farmer_id'] as String)
          .toSet()
          .toList();

      return farmerIds;
    } catch (e) {
      throw Exception('Failed to get favorite farmer IDs: $e');
    }
  }

  /// Remove all favorites for a user (useful for account deletion)
  Future<void> clearUserFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorite_products')
          .where('user_id', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear favorites: $e');
    }
  }

  /// Get products by farmer ID that are in user's favorites
  Future<List<Product>> getFavoriteProductsByFarmer({
    required String userId,
    required String farmerId,
  }) async {
    try {
      // Get all user's favorite product IDs for this farmer
      final snapshot = await _firestore
          .collection('favorite_products')
          .where('user_id', isEqualTo: userId)
          .where('farmer_id', isEqualTo: farmerId)
          .get();

      final productIds = snapshot.docs
          .map((doc) => doc.data()['product_id'] as String)
          .toList();

      if (productIds.isEmpty) {
        return [];
      }

      // Get the actual products
      final productsSnapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();

      return productsSnapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get favorite products by farmer: $e');
    }
  }
}
