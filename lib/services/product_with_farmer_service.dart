import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/product_with_farmer.dart';
import '../models/user.dart';

/// Service for loading products with farmer details and distance calculation
class ProductWithFarmerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load products with farmer details and calculate distances
  /// Returns products sorted by distance (nearest first)
  Future<List<ProductWithFarmer>> getProductsWithFarmersAndDistance({
    required List<Product> products,
    Location? buyerLocation,
  }) async {
    try {
      if (products.isEmpty) return [];

      // Get unique farmer IDs
      final farmerIds = products.map((p) => p.farmId).toSet().toList();

      // Load all farmers in one query
      final farmerDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: farmerIds)
          .get();

      // Create farmer map for quick lookup
      final farmerMap = <String, AppUser>{};
      for (final doc in farmerDocs.docs) {
        farmerMap[doc.id] = AppUser.fromFirestore(doc.data(), doc.id);
      }

      // Create ProductWithFarmer list
      final productsWithFarmers = <ProductWithFarmer>[];
      
      for (final product in products) {
        final farmer = farmerMap[product.farmId];
        
        if (farmer != null) {
          // Calculate distance if both locations available
          double? distance;
          if (buyerLocation != null && farmer.location != null) {
            distance = buyerLocation.distanceTo(farmer.location!);
          }

          productsWithFarmers.add(ProductWithFarmer(
            product: product,
            farmer: farmer,
            distanceKm: distance,
          ));
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Farmer not found for product: ${product.name} (${product.farmId})');
          }
        }
      }

      // Sort by distance (nearest first)
      if (buyerLocation != null) {
        productsWithFarmers.sort((a, b) {
          // Products without distance go to end
          if (a.distanceKm == null) return 1;
          if (b.distanceKm == null) return -1;
          return a.distanceKm!.compareTo(b.distanceKm!);
        });

        if (kDebugMode) {
          debugPrint('📍 Sorted ${productsWithFarmers.length} products by distance');
          if (productsWithFarmers.isNotEmpty) {
            debugPrint('   Nearest: ${productsWithFarmers.first.product.name} (${productsWithFarmers.first.distanceText})');
          }
        }
      }

      return productsWithFarmers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading products with farmers: $e');
      }
      return [];
    }
  }

  /// Get farmer details for a single product
  Future<AppUser?> getFarmerForProduct(String farmerId) async {
    try {
      final doc = await _firestore.collection('users').doc(farmerId).get();
      
      if (doc.exists) {
        return AppUser.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading farmer: $e');
      }
      return null;
    }
  }
}
