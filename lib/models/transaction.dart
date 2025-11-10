import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction model for all monetary transactions in the app
class Transaction {
  final String id;
  final TransactionType type;
  final String? orderId;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final double amount;
  final double serviceFee;
  final double sellerReceives;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final String? disbursementReference;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? receiptUrl;
  final String? failureReason;
  final Map<String, dynamic> metadata;

  Transaction({
    required this.id,
    required this.type,
    this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    required this.serviceFee,
    required this.sellerReceives,
    required this.status,
    required this.paymentMethod,
    this.paymentReference,
    this.disbursementReference,
    required this.createdAt,
    this.completedAt,
    this.receiptUrl,
    this.failureReason,
    this.metadata = const {},
  });

  /// Create from Firestore document
  factory Transaction.fromFirestore(Map<String, dynamic> data, String id) {
    return Transaction(
      id: id,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.shgToPsaInputPurchase,
      ),
      orderId: data['orderId'],
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0).toDouble(),
      sellerReceives: (data['sellerReceives'] ?? 0).toDouble(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${data['status']}',
        orElse: () => TransactionStatus.initiated,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${data['paymentMethod']}',
        orElse: () => PaymentMethod.mtnMobileMoney,
      ),
      paymentReference: data['paymentReference'],
      disbursementReference: data['disbursementReference'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      receiptUrl: data['receiptUrl'],
      failureReason: data['failureReason'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'amount': amount,
      'serviceFee': serviceFee,
      'sellerReceives': sellerReceives,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentReference': paymentReference,
      'disbursementReference': disbursementReference,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'receiptUrl': receiptUrl,
      'failureReason': failureReason,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  Transaction copyWith({
    TransactionStatus? status,
    String? paymentReference,
    String? disbursementReference,
    DateTime? completedAt,
    String? receiptUrl,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id,
      type: type,
      orderId: orderId,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: sellerId,
      sellerName: sellerName,
      amount: amount,
      serviceFee: serviceFee,
      sellerReceives: sellerReceives,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      disbursementReference: disbursementReference ?? this.disbursementReference,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Types of transactions in the system
enum TransactionType {
  shgToPsaInputPurchase,    // SHG buying inputs from PSA (UGX 7,000 fee)
  smeToShgProductPurchase,  // SME buying products from SHG (FREE)
  shgPremiumSubscription,   // SHG subscribing to premium (UGX 50,000)
  psaAnnualSubscription,    // PSA annual subscription (UGX 120,000)
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.shgToPsaInputPurchase:
        return 'Input Purchase';
      case TransactionType.smeToShgProductPurchase:
        return 'Product Purchase';
      case TransactionType.shgPremiumSubscription:
        return 'Premium Subscription';
      case TransactionType.psaAnnualSubscription:
        return 'PSA Subscription';
    }
  }

  String get description {
    switch (this) {
      case TransactionType.shgToPsaInputPurchase:
        return 'Purchase farming inputs from PSA supplier';
      case TransactionType.smeToShgProductPurchase:
        return 'Purchase products from SHG farmer';
      case TransactionType.shgPremiumSubscription:
        return 'Access to SME buyer contacts';
      case TransactionType.psaAnnualSubscription:
        return 'Annual subscription for PSA suppliers';
    }
  }
}

/// Transaction status lifecycle
enum TransactionStatus {
  initiated,                        // Transaction created
  paymentPending,                   // Waiting for payment
  paymentHeld,                      // Payment collected, held in escrow
  deliveryPending,                  // Waiting for delivery
  deliveredPendingConfirmation,     // Delivered, waiting for buyer confirmation
  confirmed,                        // Buyer confirmed receipt
  disbursementPending,              // Waiting for disbursement to seller
  completed,                        // Transaction completed successfully
  failed,                           // Transaction failed
  refunded,                         // Payment refunded to buyer
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.initiated:
        return 'Initiated';
      case TransactionStatus.paymentPending:
        return 'Payment Pending';
      case TransactionStatus.paymentHeld:
        return 'Payment Secured';
      case TransactionStatus.deliveryPending:
        return 'Awaiting Delivery';
      case TransactionStatus.deliveredPendingConfirmation:
        return 'Delivered';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.disbursementPending:
        return 'Processing Payment';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }

  String get description {
    switch (this) {
      case TransactionStatus.initiated:
        return 'Transaction has been created';
      case TransactionStatus.paymentPending:
        return 'Waiting for payment from buyer';
      case TransactionStatus.paymentHeld:
        return 'Payment is secured in escrow';
      case TransactionStatus.deliveryPending:
        return 'Waiting for seller to deliver items';
      case TransactionStatus.deliveredPendingConfirmation:
        return 'Items delivered, waiting for buyer confirmation';
      case TransactionStatus.confirmed:
        return 'Buyer has confirmed receipt of items';
      case TransactionStatus.disbursementPending:
        return 'Processing payment to seller';
      case TransactionStatus.completed:
        return 'Transaction completed successfully';
      case TransactionStatus.failed:
        return 'Transaction failed';
      case TransactionStatus.refunded:
        return 'Payment has been refunded';
    }
  }

  bool get isInProgress {
    return this != TransactionStatus.completed &&
           this != TransactionStatus.failed &&
           this != TransactionStatus.refunded;
  }

  bool get canRefund {
    return this == TransactionStatus.paymentHeld ||
           this == TransactionStatus.deliveryPending;
  }
}

/// Payment methods supported
enum PaymentMethod {
  mtnMobileMoney,
  airtelMoney,
  cashOnDelivery,
}


