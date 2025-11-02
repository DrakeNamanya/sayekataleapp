import 'package:cloud_firestore/cloud_firestore.dart';

/// Cart Item Model for Shopping Cart
/// Represents a product added to buyer's cart with quantity
class CartItem {
  final String id; // Firestore document ID
  final String userId; // Buyer's user ID
  final String productId; // Product ID
  final String productName;
  final String productImage;
  final double price;
  final String unit;
  final int quantity;
  final String farmerId; // Seller's user ID
  final String farmerName;
  final DateTime addedAt;
  final DateTime updatedAt;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.farmerId,
    required this.farmerName,
    required this.addedAt,
    required this.updatedAt,
  });

  /// Calculate total price for this cart item
  double get totalPrice => price * quantity;

  /// Create CartItem from Firestore document
  factory CartItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItem(
      id: id,
      userId: data['user_id'] ?? '',
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      productImage: data['product_image'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'kg',
      quantity: data['quantity'] ?? 1,
      farmerId: data['farmer_id'] ?? '',
      farmerName: data['farmer_name'] ?? '',
      addedAt: (data['added_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert CartItem to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'added_at': Timestamp.fromDate(addedAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with updated fields
  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    String? unit,
    int? quantity,
    String? farmerId,
    String? farmerName,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
