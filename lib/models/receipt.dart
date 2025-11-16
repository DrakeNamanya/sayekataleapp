import 'package:cloud_firestore/cloud_firestore.dart';

/// Receipt Model for Order Deliveries
/// Generated when SME/SHG confirms receipt of delivered products
class Receipt {
  final String id; // Receipt ID (e.g., "RCP-00001")
  final String orderId; // Associated order ID
  final String buyerId; // SME/SHG buyer ID
  final String buyerName;
  final String sellerId; // SHG/PSA seller ID
  final String sellerName;
  final List<ReceiptItem> items; // Products received
  final double totalAmount; // Total amount paid
  final String paymentMethod; // How payment was made
  final DateTime confirmedAt; // When buyer confirmed receipt
  final DateTime createdAt; // Receipt generation time
  final String? notes; // Additional notes from buyer
  final String? deliveryPhoto; // Photo of delivered products
  final int? rating; // Buyer's rating (1-5 stars)
  final String? feedback; // Buyer's feedback/comment

  Receipt({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.confirmedAt,
    required this.createdAt,
    this.notes,
    this.deliveryPhoto,
    this.rating,
    this.feedback,
  });

  factory Receipt.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }

    return Receipt(
      id: data['id'] ?? id,
      orderId: data['order_id'] ?? '',
      buyerId: data['buyer_id'] ?? '',
      buyerName: data['buyer_name'] ?? '',
      sellerId: data['seller_id'] ?? '',
      sellerName: data['seller_name'] ?? '',
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => ReceiptItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
      paymentMethod: data['payment_method'] ?? '',
      confirmedAt: parseDateTime(data['confirmed_at']) ?? DateTime.now(),
      createdAt: parseDateTime(data['created_at']) ?? DateTime.now(),
      notes: data['notes'],
      deliveryPhoto: data['delivery_photo'],
      rating: data['rating'],
      feedback: data['feedback'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'order_id': orderId,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'confirmed_at': Timestamp.fromDate(confirmedAt),
      'created_at': Timestamp.fromDate(createdAt),
      'notes': notes,
      'delivery_photo': deliveryPhoto,
      'rating': rating,
      'feedback': feedback,
    };
  }

  /// Generate receipt number from count
  static String generateReceiptId(int count) {
    return 'RCP-${(count + 1).toString().padLeft(5, '0')}';
  }
}

/// Receipt Item - Product received in delivery
class ReceiptItem {
  final String productId;
  final String productName;
  final int quantity;
  final String unit;
  final double pricePerUnit;
  final double totalPrice;

  ReceiptItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalPrice,
  });

  factory ReceiptItem.fromMap(Map<String, dynamic> data) {
    return ReceiptItem(
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? 'kg',
      pricePerUnit: (data['price_per_unit'] ?? 0).toDouble(),
      totalPrice: (data['total_price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
    };
  }
}
