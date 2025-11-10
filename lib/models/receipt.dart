import 'package:cloud_firestore/cloud_firestore.dart';

/// Receipt model for documenting completed transactions
class Receipt {
  final String id;
  final String transactionId;
  final String orderId;
  final ReceiptType type;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final double amount;
  final double serviceFee;
  final double buyerPaid;
  final double sellerReceived;
  final String paymentMethod;
  final String? paymentReference;
  final String? disbursementReference;
  final DateTime transactionDate;
  final DateTime receiptGeneratedAt;
  final String pdfUrl;
  final String? messageSentTo;
  final DateTime? messageSentAt;
  final Map<String, dynamic> metadata;

  Receipt({
    required this.id,
    required this.transactionId,
    required this.orderId,
    required this.type,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.amount,
    required this.serviceFee,
    required this.buyerPaid,
    required this.sellerReceived,
    required this.paymentMethod,
    this.paymentReference,
    this.disbursementReference,
    required this.transactionDate,
    required this.receiptGeneratedAt,
    required this.pdfUrl,
    this.messageSentTo,
    this.messageSentAt,
    this.metadata = const {},
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'transactionId': transactionId,
      'orderId': orderId,
      'type': type.toString().split('.').last,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'amount': amount,
      'serviceFee': serviceFee,
      'buyerPaid': buyerPaid,
      'sellerReceived': sellerReceived,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'disbursementReference': disbursementReference,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'receiptGeneratedAt': Timestamp.fromDate(receiptGeneratedAt),
      'pdfUrl': pdfUrl,
      'messageSentTo': messageSentTo,
      'messageSentAt': messageSentAt != null ? Timestamp.fromDate(messageSentAt!) : null,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory Receipt.fromFirestore(Map<String, dynamic> data, String docId) {
    return Receipt(
      id: data['id'] ?? docId,
      transactionId: data['transactionId'] ?? '',
      orderId: data['orderId'] ?? '',
      type: ReceiptType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ReceiptType.productPurchase,
      ),
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      buyerPhone: data['buyerPhone'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerPhone: data['sellerPhone'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0).toDouble(),
      buyerPaid: (data['buyerPaid'] ?? 0).toDouble(),
      sellerReceived: (data['sellerReceived'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      paymentReference: data['paymentReference'],
      disbursementReference: data['disbursementReference'],
      transactionDate: (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptGeneratedAt: (data['receiptGeneratedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pdfUrl: data['pdfUrl'] ?? '',
      messageSentTo: data['messageSentTo'],
      messageSentAt: (data['messageSentAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] ?? {},
    );
  }
}

/// Type of receipt
enum ReceiptType {
  productPurchase,        // Regular product purchase
  inputPurchase,          // Input purchase with service fee
  subscription,           // Subscription payment
  refund,                 // Refund receipt
}

/// Extension methods for ReceiptType
extension ReceiptTypeExtension on ReceiptType {
  String get displayName {
    switch (this) {
      case ReceiptType.productPurchase:
        return 'Product Purchase';
      case ReceiptType.inputPurchase:
        return 'Input Purchase';
      case ReceiptType.subscription:
        return 'Subscription Payment';
      case ReceiptType.refund:
        return 'Refund';
    }
  }
}
