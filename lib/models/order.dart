import 'package:cloud_firestore/cloud_firestore.dart';

/// Order model for tracking purchases between users
class Order {
  final String id;
  final OrderType type;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double serviceFee;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final String deliveryAddress;
  final String? deliveryNotes;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final bool codRequiresBothConfirmation;
  final DateTime? buyerConfirmedAt;
  final DateTime? sellerConfirmedAt;
  final int codRemindersSent;
  final Map<String, dynamic> metadata;
  
  // Review and rating fields (legacy order system)
  final double? rating;          // Customer rating (1-5 stars)
  final String? rejectionReason; // Reason for order rejection
  final bool? isFavoriteSeller;  // Whether seller is marked as favorite
  
  // Backward compatibility fields (legacy order system)
  final String? farmerId;       // Alias for sellerId
  final String? farmerName;     // Alias for sellerName
  final String? farmerPhone;    // Alias for sellerPhone
  final DateTime? receivedAt;   // Alias for confirmedAt
  final bool? isReceivedByBuyer; // Alias for confirmed status
  final String? orderNumber;    // Optional order number

  Order({
    required this.id,
    required this.type,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    required this.deliveryAddress,
    this.deliveryNotes,
    // Review and rating fields
    this.rating,
    this.rejectionReason,
    this.isFavoriteSeller,
    // Backward compatibility fields
    String? farmerId,
    String? farmerName,
    String? farmerPhone,
    DateTime? receivedAt,
    bool? isReceivedByBuyer,
    this.orderNumber,
    required this.createdAt,
    this.deliveredAt,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.codRequiresBothConfirmation = false,
    this.buyerConfirmedAt,
    this.sellerConfirmedAt,
    this.codRemindersSent = 0,
    this.metadata = const {},
  }) :  // Initialize backward compatibility fields
        farmerId = farmerId ?? sellerId,
        farmerName = farmerName ?? sellerName,
        farmerPhone = farmerPhone ?? sellerPhone,
        receivedAt = receivedAt ?? confirmedAt,
        isReceivedByBuyer = isReceivedByBuyer ?? (confirmedAt != null);

  // Check if COD confirmation deadline is approaching (within 48 hours)
  bool get isCodDeadlineApproaching {
    if (paymentMethod != PaymentMethod.cashOnDelivery) return false;
    if (status != OrderStatus.deliveredPendingConfirmation) return false;
    
    final hoursElapsed = DateTime.now().difference(deliveredAt!).inHours;
    return hoursElapsed >= 24 && hoursElapsed < 48;
  }

  // Check if COD confirmation deadline has passed
  bool get isCodDeadlinePassed {
    if (paymentMethod != PaymentMethod.cashOnDelivery) return false;
    if (status != OrderStatus.deliveredPendingConfirmation) return false;
    
    final hoursElapsed = DateTime.now().difference(deliveredAt!).inHours;
    return hoursElapsed >= 48;
  }

  // Check if both parties have confirmed COD
  bool get isCodFullyConfirmed {
    return buyerConfirmedAt != null && sellerConfirmedAt != null;
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      // Don't store 'id' in document - use Firestore document ID instead
      // This prevents bugs where stored 'id' conflicts with actual docId
      'type': type.toString().split('.').last,
      // CRITICAL: Save in BOTH camelCase and snake_case for compatibility
      'buyerId': buyerId,
      'buyer_id': buyerId, // ✅ Snake case for queries
      'buyerName': buyerName,
      'buyer_name': buyerName, // ✅ Snake case for queries
      'buyerPhone': buyerPhone,
      'buyer_phone': buyerPhone, // ✅ Snake case for queries
      'sellerId': sellerId,
      'seller_id': sellerId, // ✅ Snake case for queries
      'sellerName': sellerName,
      'seller_name': sellerName, // ✅ Snake case for queries
      'sellerPhone': sellerPhone,
      'seller_phone': sellerPhone, // ✅ Snake case for queries
      'items': items.map((item) => item.toFirestore()).toList(),
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'service_fee': serviceFee, // ✅ Snake case for queries
      'totalAmount': totalAmount,
      'total_amount': totalAmount, // ✅ Snake case for queries
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'payment_method': paymentMethod.toString().split('.').last, // ✅ Snake case
      'transactionId': transactionId,
      'transaction_id': transactionId, // ✅ Snake case
      'deliveryAddress': deliveryAddress,
      'delivery_address': deliveryAddress, // ✅ Snake case
      'deliveryNotes': deliveryNotes,
      'delivery_notes': deliveryNotes, // ✅ Snake case
      'createdAt': Timestamp.fromDate(createdAt),
      'created_at': Timestamp.fromDate(createdAt), // ✅ Snake case
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'delivered_at': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null, // ✅ Snake case
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'confirmed_at': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null, // ✅ Snake case
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelled_at': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null, // ✅ Snake case
      'cancellationReason': cancellationReason,
      'cancellation_reason': cancellationReason, // ✅ Snake case
      'codRequiresBothConfirmation': codRequiresBothConfirmation,
      'cod_requires_both_confirmation': codRequiresBothConfirmation, // ✅ Snake case
      'buyerConfirmedAt': buyerConfirmedAt != null ? Timestamp.fromDate(buyerConfirmedAt!) : null,
      'buyer_confirmed_at': buyerConfirmedAt != null ? Timestamp.fromDate(buyerConfirmedAt!) : null, // ✅ Snake case
      'sellerConfirmedAt': sellerConfirmedAt != null ? Timestamp.fromDate(sellerConfirmedAt!) : null,
      'seller_confirmed_at': sellerConfirmedAt != null ? Timestamp.fromDate(sellerConfirmedAt!) : null, // ✅ Snake case
      'codRemindersSent': codRemindersSent,
      'cod_reminders_sent': codRemindersSent, // ✅ Snake case
      'metadata': metadata,
      
      // Review and rating fields (both formats)
      'rating': rating,
      'rejectionReason': rejectionReason,
      'rejection_reason': rejectionReason, // ✅ Snake case
      'isFavoriteSeller': isFavoriteSeller,
      'is_favorite_seller': isFavoriteSeller, // ✅ Snake case
      
      // Backward compatibility fields (both formats)
      'farmerId': farmerId,
      'farmer_id': farmerId, // ✅ CRITICAL: Required for getFarmerOrders query
      'farmerName': farmerName,
      'farmer_name': farmerName, // ✅ Snake case
      'farmerPhone': farmerPhone,
      'farmer_phone': farmerPhone, // ✅ Snake case
      'receivedAt': receivedAt != null ? Timestamp.fromDate(receivedAt!) : null,
      'received_at': receivedAt != null ? Timestamp.fromDate(receivedAt!) : null, // ✅ Snake case
      'isReceivedByBuyer': isReceivedByBuyer,
      'is_received_by_buyer': isReceivedByBuyer, // ✅ Snake case
      'orderNumber': orderNumber,
      'order_number': orderNumber, // ✅ Snake case
    };
  }

  // Create from Firestore document
  factory Order.fromFirestore(Map<String, dynamic> data, String docId) {
    // Smart type inference for backward compatibility
    OrderType orderType;
    final typeString = data['type'] ?? data['order_type'];
    
    if (typeString != null) {
      // Type is explicitly stored
      orderType = OrderType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
        orElse: () => OrderType.smeToShgProductPurchase, // Default
      );
    } else {
      // Infer type based on service fee (for old orders without explicit type)
      final fee = (data['serviceFee'] ?? data['service_fee'] ?? 0).toDouble();
      if (fee > 0) {
        // If there's a service fee, it's likely SHG→PSA (UGX 7,000)
        orderType = OrderType.shgToPsaInputPurchase;
      } else {
        // No fee = SME→SHG (FREE)
        orderType = OrderType.smeToShgProductPurchase;
      }
    }
    
    return Order(
      // Always use Firestore document ID, ignore any stored 'id' field
      // This prevents bugs where corrupt 'id' data causes issues
      id: docId, 
      type: orderType,
      // Read from both camelCase and snake_case
      buyerId: data['buyerId'] ?? data['buyer_id'] ?? '',
      buyerName: data['buyerName'] ?? data['buyer_name'] ?? '',
      buyerPhone: data['buyerPhone'] ?? data['buyer_phone'] ?? '',
      sellerId: data['sellerId'] ?? data['seller_id'] ?? data['farmerId'] ?? data['farmer_id'] ?? '',
      sellerName: data['sellerName'] ?? data['seller_name'] ?? data['farmerName'] ?? data['farmer_name'] ?? '',
      sellerPhone: data['sellerPhone'] ?? data['seller_phone'] ?? data['farmerPhone'] ?? data['farmer_phone'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromFirestore(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? data['sub_total'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? data['service_fee'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? data['total_amount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == (data['paymentMethod'] ?? data['payment_method']),
        orElse: () => PaymentMethod.mtnMobileMoney,
      ),
      transactionId: data['transactionId'] ?? data['transaction_id'],
      deliveryAddress: data['deliveryAddress'] ?? data['delivery_address'] ?? '',
      deliveryNotes: data['deliveryNotes'] ?? data['delivery_notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? 
                 (data['created_at'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate() ?? 
                   (data['delivered_at'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate() ?? 
                   (data['confirmed_at'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate() ?? 
                   (data['cancelled_at'] as Timestamp?)?.toDate(),
      cancellationReason: data['cancellationReason'] ?? data['cancellation_reason'],
      codRequiresBothConfirmation: data['codRequiresBothConfirmation'] ?? 
                                    data['cod_requires_both_confirmation'] ?? 
                                    false,
      buyerConfirmedAt: (data['buyerConfirmedAt'] as Timestamp?)?.toDate() ?? 
                        (data['buyer_confirmed_at'] as Timestamp?)?.toDate(),
      sellerConfirmedAt: (data['sellerConfirmedAt'] as Timestamp?)?.toDate() ?? 
                         (data['seller_confirmed_at'] as Timestamp?)?.toDate(),
      codRemindersSent: data['codRemindersSent'] ?? data['cod_reminders_sent'] ?? 0,
      metadata: data['metadata'] ?? {},
      
      // Review and rating fields (both formats)
      rating: data['rating']?.toDouble(),
      rejectionReason: data['rejectionReason'] ?? data['rejection_reason'],
      isFavoriteSeller: data['isFavoriteSeller'] ?? data['is_favorite_seller'],
      
      // Backward compatibility fields (both formats)
      farmerId: data['farmerId'] ?? data['farmer_id'],
      farmerName: data['farmerName'] ?? data['farmer_name'],
      farmerPhone: data['farmerPhone'] ?? data['farmer_phone'],
      receivedAt: (data['receivedAt'] as Timestamp?)?.toDate() ?? 
                  (data['received_at'] as Timestamp?)?.toDate(),
      isReceivedByBuyer: data['isReceivedByBuyer'] ?? data['is_received_by_buyer'],
      orderNumber: data['orderNumber'] ?? data['order_number'],
    );
  }

  // Copy with method
  Order copyWith({
    String? id,
    OrderType? type,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    List<OrderItem>? items,
    double? subtotal,
    double? serviceFee,
    double? totalAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? transactionId,
    String? deliveryAddress,
    String? deliveryNotes,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    bool? codRequiresBothConfirmation,
    DateTime? buyerConfirmedAt,
    DateTime? sellerConfirmedAt,
    int? codRemindersSent,
    Map<String, dynamic>? metadata,
    double? rating,
    String? rejectionReason,
    bool? isFavoriteSeller,
    String? farmerId,
    String? farmerName,
    String? farmerPhone,
    DateTime? receivedAt,
    bool? isReceivedByBuyer,
    String? orderNumber,
  }) {
    return Order(
      id: id ?? this.id,
      type: type ?? this.type,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      codRequiresBothConfirmation: codRequiresBothConfirmation ?? this.codRequiresBothConfirmation,
      buyerConfirmedAt: buyerConfirmedAt ?? this.buyerConfirmedAt,
      sellerConfirmedAt: sellerConfirmedAt ?? this.sellerConfirmedAt,
      codRemindersSent: codRemindersSent ?? this.codRemindersSent,
      metadata: metadata ?? this.metadata,
      
      // Review and rating fields
      rating: rating ?? this.rating,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isFavoriteSeller: isFavoriteSeller ?? this.isFavoriteSeller,
      
      // Backward compatibility fields
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      receivedAt: receivedAt ?? this.receivedAt,
      isReceivedByBuyer: isReceivedByBuyer ?? this.isReceivedByBuyer,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }
}

/// Individual item in an order
class OrderItem {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final String unit;
  final double total;
  
  // Backward compatibility: subtotal is alias for total
  double get subtotal => total;

  OrderItem({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.total,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'total': total,
      'subtotal': total, // Backward compatibility
    };
  }

  factory OrderItem.fromFirestore(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'],
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? '',
      total: (data['total'] ?? data['subtotal'] ?? 0).toDouble(), // Support both fields
    );
  }
}

/// Type of order
enum OrderType {
  shgToPsaInputPurchase,  // SHG buying inputs from PSA
  smeToShgProductPurchase, // SME buying products from SHG
}

/// Order status
enum OrderStatus {
  pending,                          // Order created, awaiting payment
  paymentPending,                   // Payment initiated but not confirmed
  paymentHeld,                      // Payment held in escrow
  deliveryPending,                  // Payment secured, awaiting delivery
  deliveredPendingConfirmation,     // Delivered, awaiting confirmation
  confirmed,                        // Delivery confirmed
  completed,                        // Order fully completed
  cancelled,                        // Order cancelled
  codPendingBothConfirmation,       // COD: Waiting for both parties
  codOverdue,                       // COD: 48-hour deadline passed
  
  // Backward compatibility statuses (legacy order system)
  preparing,                        // Preparing order (maps to deliveryPending)
  ready,                            // Ready for pickup (maps to deliveryPending)
  inTransit,                        // In transit (maps to deliveryPending)
  delivered,                        // Delivered (maps to deliveredPendingConfirmation)
  rejected,                         // Rejected (maps to cancelled)
}

/// Payment method
enum PaymentMethod {
  mtnMobileMoney,
  airtelMoney,
  cashOnDelivery,
  
  // Backward compatibility payment methods (legacy order system)
  cash,                             // Cash payment (maps to cashOnDelivery)
  mobileMoney,                      // Mobile money (maps to mtnMobileMoney)
  bankTransfer,                     // Bank transfer (deprecated)
}

/// Extension methods for OrderType
extension OrderTypeExtension on OrderType {
  String get displayName {
    switch (this) {
      case OrderType.shgToPsaInputPurchase:
        return 'Input Purchase';
      case OrderType.smeToShgProductPurchase:
        return 'Product Purchase';
    }
  }

  double get serviceFee {
    switch (this) {
      case OrderType.shgToPsaInputPurchase:
        return 7000.0; // UGX 7,000 total
      case OrderType.smeToShgProductPurchase:
        return 0.0; // FREE
    }
  }

  double get buyerFee {
    switch (this) {
      case OrderType.shgToPsaInputPurchase:
        return 2000.0; // SHG pays UGX 2,000
      case OrderType.smeToShgProductPurchase:
        return 0.0; // FREE
    }
  }

  double get sellerFee {
    switch (this) {
      case OrderType.shgToPsaInputPurchase:
        return 5000.0; // PSA pays UGX 5,000
      case OrderType.smeToShgProductPurchase:
        return 0.0; // FREE
    }
  }
}

/// Extension methods for OrderStatus
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.paymentPending:
        return 'Payment Pending';
      case OrderStatus.paymentHeld:
        return 'Payment Secured';
      case OrderStatus.deliveryPending:
        return 'Awaiting Delivery';
      case OrderStatus.deliveredPendingConfirmation:
        return 'Delivered - Confirm Receipt';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.codPendingBothConfirmation:
        return 'COD - Awaiting Both Confirmations';
      case OrderStatus.codOverdue:
        return 'COD - Overdue';
      // Legacy status names
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }
}


