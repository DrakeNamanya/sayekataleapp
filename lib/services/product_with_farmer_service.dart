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
      if (products.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️  No products provided to load farmer details');
        }
        return [];
      }

      if (kDebugMode) {
        debugPrint('📦 Loading farmer details for ${products.length} products...');
      }

      // Get unique farmer IDs
      final farmerIds = products.map((p) => p.farmId).toSet().toList();
      
      if (kDebugMode) {
        debugPrint('👥 Unique farmer IDs to query: ${farmerIds.length}');
      }

      // Load all farmers in batches (Firestore has 10-item limit for whereIn)
      final farmerMap = <String, AppUser>{};
      
      // Process farmer IDs in batches of 10
      for (var i = 0; i < farmerIds.length; i += 10) {
        final batch = farmerIds.skip(i).take(10).toList();
        
        try {
          final farmerDocs = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          for (final doc in farmerDocs.docs) {
            farmerMap[doc.id] = AppUser.fromFirestore(doc.data(), doc.id);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️  Error loading farmer batch: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Loaded ${farmerMap.length} farmer profiles');
      }

      // Create ProductWithFarmer list
      final productsWithFarmers = <ProductWithFarmer>[];
      int missingFarmers = 0;
      
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
          missingFarmers++;
          if (kDebugMode) {
            debugPrint('⚠️  Farmer not found for product: ${product.name} | System ID: ${product.systemId ?? "N/A"} | Farmer ID: ${product.farmId}');
          }
        }
      }

      if (kDebugMode) {
        if (missingFarmers > 0) {
          debugPrint('⚠️  ${missingFarmers} products skipped due to missing farmer profiles');
        }
        debugPrint('📊 Final result: ${productsWithFarmers.length} products with farmer details');
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
        debugPrint('   Stack trace: ${StackTrace.current}');
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
