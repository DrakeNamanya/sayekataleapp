class Order {
  final String id;
  final String customerId;
  final String farmId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final List<OrderStatusTimeline> statusTimeline;
  final String? estimatedDelivery;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.customerId,
    required this.farmId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.statusTimeline,
    this.estimatedDelivery,
    this.riderId,
    this.riderName,
    this.riderPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  OrderStatus get currentStatus =>
      statusTimeline.isNotEmpty ? statusTimeline.last.status : OrderStatus.placed;

  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      customerId: data['customer_id'] ?? '',
      farmId: data['farm_id'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (data['delivery_fee'] ?? 0.0).toDouble(),
      serviceFee: (data['service_fee'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${data['payment_method']}',
        orElse: () => PaymentMethod.cash,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${data['payment_status']}',
        orElse: () => PaymentStatus.pending,
      ),
      statusTimeline: (data['status_timeline'] as List<dynamic>?)
              ?.map((item) => OrderStatusTimeline.fromMap(item))
              .toList() ??
          [],
      estimatedDelivery: data['estimated_delivery'],
      riderId: data['rider_id'],
      riderName: data['rider_name'],
      riderPhone: data['rider_phone'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'farm_id': farmId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'service_fee': serviceFee,
      'total': total,
      'payment_method': paymentMethod.toString().split('.').last,
      'payment_status': paymentStatus.toString().split('.').last,
      'status_timeline': statusTimeline.map((item) => item.toMap()).toList(),
      'estimated_delivery': estimatedDelivery,
      'rider_id': riderId,
      'rider_name': riderName,
      'rider_phone': riderPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      quantity: data['quantity'] ?? 0,
      unitPrice: (data['unit_price'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
    };
  }
}

class OrderStatusTimeline {
  final OrderStatus status;
  final DateTime timestamp;

  OrderStatusTimeline({
    required this.status,
    required this.timestamp,
  });

  factory OrderStatusTimeline.fromMap(Map<String, dynamic> data) {
    return OrderStatusTimeline(
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${data['status']}',
        orElse: () => OrderStatus.placed,
      ),
      timestamp: DateTime.parse(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum OrderStatus {
  placed,
  accepted,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

enum PaymentMethod {
  mtnMomo,
  airtelMoney,
  cash,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Farmer Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Order Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.mtnMomo:
        return 'MTN Mobile Money';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.cash:
        return 'Cash on Delivery';
    }
  }
}
