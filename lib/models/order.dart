import 'package:cloud_firestore/cloud_firestore.dart';

/// Order status enum
enum OrderStatus {
  pending,       // Order placed, waiting for farmer confirmation
  confirmed,     // Farmer accepted the order
  rejected,      // Farmer rejected the order
  preparing,     // Farmer is preparing the order
  ready,         // Order is ready for pickup/delivery
  inTransit,     // Order is being delivered
  delivered,     // Order delivered to buyer
  completed,     // Transaction completed
  cancelled,     // Order cancelled by buyer
}

/// Payment method enum
enum PaymentMethod {
  cash,          // Cash on delivery
  mobileMoney,   // Mobile Money (MTN, Airtel)
  bankTransfer,  // Bank transfer
}

/// Order model for marketplace transactions
class Order {
  final String id;                    // Firestore document ID
  final String orderNumber;           // Human-readable order number (e.g., ORD-2024-0001)
  final String buyerId;               // User ID of buyer (SME)
  final String buyerName;             // Buyer's name
  final String buyerPhone;            // Buyer's phone
  final String? buyerSystemId;        // System ID/NIN of buyer
  final String farmerId;              // User ID of farmer (SHG)
  final String farmerName;            // Farmer's name
  final String farmerPhone;           // Farmer's phone
  final String? farmerSystemId;       // System ID/NIN of farmer
  final List<OrderItem> items;        // List of products in order
  final double totalAmount;           // Total order amount
  final OrderStatus status;           // Current order status
  final PaymentMethod paymentMethod;  // Payment method
  final String? deliveryAddress;      // Delivery address
  final String? deliveryNotes;        // Special delivery instructions
  final DateTime createdAt;           // When order was placed
  final DateTime updatedAt;           // Last update time
  final DateTime? confirmedAt;        // When farmer confirmed
  final DateTime? rejectedAt;         // When farmer rejected
  final DateTime? deliveredAt;        // When order was delivered (marked by farmer)
  final DateTime? receivedAt;         // When buyer confirmed receipt
  final String? rejectionReason;      // Reason for rejection
  final bool isReceivedByBuyer;       // Buyer confirmed receipt
  final int? rating;                  // Buyer's rating (1-5 stars)
  final String? review;               // Buyer's review text
  final String? reviewPhoto;          // Photo of delivered product
  final DateTime? reviewedAt;         // When review was submitted
  final bool isFavoriteSeller;        // Is this seller marked as favorite by buyer

  Order({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerSystemId,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    this.farmerSystemId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.deliveryAddress,
    this.deliveryNotes,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.rejectedAt,
    this.deliveredAt,
    this.receivedAt,
    this.rejectionReason,
    this.isReceivedByBuyer = false,
    this.rating,
    this.review,
    this.reviewPhoto,
    this.reviewedAt,
    this.isFavoriteSeller = false,
  });

  /// Create Order from Firestore document
  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    // Helper function to parse DateTime
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }

    return Order(
      id: id,
      orderNumber: data['order_number'] ?? 'ORD-${id.substring(0, 8).toUpperCase()}',
      buyerId: data['buyer_id'] ?? '',
      buyerName: data['buyer_name'] ?? '',
      buyerPhone: data['buyer_phone'] ?? '',
      buyerSystemId: data['buyer_system_id'],
      farmerId: data['farmer_id'] ?? '',
      farmerName: data['farmer_name'] ?? '',
      farmerPhone: data['farmer_phone'] ?? '',
      farmerSystemId: data['farmer_system_id'],
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == data['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      deliveryAddress: data['delivery_address'],
      deliveryNotes: data['delivery_notes'],
      createdAt: parseDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(data['updated_at']) ?? DateTime.now(),
      confirmedAt: parseDateTime(data['confirmed_at']),
      rejectedAt: parseDateTime(data['rejected_at']),
      deliveredAt: parseDateTime(data['delivered_at']),
      receivedAt: parseDateTime(data['received_at']),
      rejectionReason: data['rejection_reason'],
      isReceivedByBuyer: data['is_received_by_buyer'] ?? false,
      rating: data['rating'],
      review: data['review'],
      reviewPhoto: data['review_photo'],
      reviewedAt: parseDateTime(data['reviewed_at']),
      isFavoriteSeller: data['is_favorite_seller'] ?? false,
    );
  }

  /// Convert Order to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'order_number': orderNumber,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_system_id': buyerSystemId,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'farmer_phone': farmerPhone,
      'farmer_system_id': farmerSystemId,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'status': status.toString().split('.').last,
      'payment_method': paymentMethod.toString().split('.').last,
      'delivery_address': deliveryAddress,
      'delivery_notes': deliveryNotes,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'confirmed_at': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'rejected_at': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'delivered_at': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'received_at': receivedAt != null ? Timestamp.fromDate(receivedAt!) : null,
      'rejection_reason': rejectionReason,
      'is_received_by_buyer': isReceivedByBuyer,
      'rating': rating,
      'review': review,
      'review_photo': reviewPhoto,
      'reviewed_at': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'is_favorite_seller': isFavoriteSeller,
    };
  }

  /// Create a copy with modified fields
  Order copyWith({
    String? id,
    String? orderNumber,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    String? buyerSystemId,
    String? farmerId,
    String? farmerName,
    String? farmerPhone,
    String? farmerSystemId,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? rejectedAt,
    DateTime? deliveredAt,
    DateTime? receivedAt,
    String? rejectionReason,
    bool? isReceivedByBuyer,
    int? rating,
    String? review,
    String? reviewPhoto,
    DateTime? reviewedAt,
    bool? isFavoriteSeller,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerSystemId: buyerSystemId ?? this.buyerSystemId,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      farmerSystemId: farmerSystemId ?? this.farmerSystemId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      receivedAt: receivedAt ?? this.receivedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isReceivedByBuyer: isReceivedByBuyer ?? this.isReceivedByBuyer,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      reviewPhoto: reviewPhoto ?? this.reviewPhoto,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      isFavoriteSeller: isFavoriteSeller ?? this.isFavoriteSeller,
    );
  }
}

/// Individual item in an order
class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final String unit;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.subtotal,
  });

  /// Create OrderItem from map
  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      productImage: data['product_image'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'kg',
      quantity: data['quantity'] ?? 1,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
    );
  }

  /// Convert OrderItem to map
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}

/// Extension for OrderStatus display
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending Confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.rejected:
        return 'Rejected';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Waiting for farmer to accept';
      case OrderStatus.confirmed:
        return 'Farmer accepted your order';
      case OrderStatus.rejected:
        return 'Farmer rejected this order';
      case OrderStatus.preparing:
        return 'Farmer is preparing your order';
      case OrderStatus.ready:
        return 'Order is ready for collection';
      case OrderStatus.inTransit:
        return 'Order is on the way';
      case OrderStatus.delivered:
        return 'Order has been delivered';
      case OrderStatus.completed:
        return 'Transaction completed';
      case OrderStatus.cancelled:
        return 'Order was cancelled';
    }
  }
}

/// Extension for PaymentMethod display
extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash on Delivery';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.cash:
        return 'Pay with cash when you receive the order';
      case PaymentMethod.mobileMoney:
        return 'Pay with MTN or Airtel Money';
      case PaymentMethod.bankTransfer:
        return 'Transfer to farmer\'s bank account';
    }
  }
}
