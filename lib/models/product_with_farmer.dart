import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';
import 'user.dart';

/// Enhanced Product model that includes farmer details and distance
class ProductWithFarmer {
  final Product product;
  final AppUser farmer;
  final double? distanceKm;  // Distance from buyer to farmer in kilometers

  ProductWithFarmer({
    required this.product,
    required this.farmer,
    this.distanceKm,
  });

  /// Get formatted distance string
  String get distanceText {
    if (distanceKm == null) return 'Distance unknown';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)}m away';
    } else {
      return '${distanceKm!.toStringAsFixed(1)}km away';
    }
  }

  /// Check if this is a nearby product (within 50km)
  bool get isNearby => distanceKm != null && distanceKm! <= 50;

  /// Check if this is a local product (within 10km)
  bool get isLocal => distanceKm != null && distanceKm! <= 10;

  /// Get farmer contact phone
  String get farmerPhone => farmer.phone;

  /// Get farmer district
  String get farmerDistrict => farmer.location?.district ?? 'Unknown district';

  /// Get farmer address
  String get farmerAddress => farmer.location?.fullAddress ?? 'Address not available';

  /// Get product stock quantity
  int get stockQuantity => product.stockQuantity;

  /// Get farmer name
  String get farmerName => farmer.name;
}
