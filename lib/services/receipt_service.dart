import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/receipt.dart';
import '../models/order.dart' as app_order;

/// Receipt Service
/// Handles receipt generation and retrieval for confirmed deliveries
class ReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate receipt when SME/SHG confirms delivery
  Future<Receipt> generateReceipt({
    required app_order.Order order,
    String? notes,
    String? deliveryPhoto,
    int? rating,
    String? feedback,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📝 Generating receipt for order: ${order.id}');
      }

      // Get receipt count for ID generation
      final receiptsSnapshot = await _firestore.collection('receipts').get();
      final receiptId = Receipt.generateReceiptId(receiptsSnapshot.docs.length);

      // Convert order items to receipt items
      final receiptItems = order.items.map((item) {
        return ReceiptItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unit: item.unit,
          pricePerUnit: item.price,
          totalPrice: item.price * item.quantity,
        );
      }).toList();

      // Create receipt
      final receipt = Receipt(
        id: receiptId,
        orderId: order.id,
        buyerId: order.buyerId,
        buyerName: order.buyerName,
        sellerId: order.sellerId,
        sellerName: order.sellerName,
        items: receiptItems,
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod.toString().split('.').last,
        confirmedAt: DateTime.now(),
        createdAt: DateTime.now(),
        notes: notes,
        deliveryPhoto: deliveryPhoto,
        rating: rating,
        feedback: feedback,
      );

      // Save to Firestore
      await _firestore
          .collection('receipts')
          .doc(receiptId)
          .set(receipt.toFirestore());

      // Update order with receipt ID
      await _firestore.collection('orders').doc(order.id).update({
        'receipt_id': receiptId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Receipt generated: $receiptId');
      }

      return receipt;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating receipt: $e');
      }
      rethrow;
    }
  }

  /// Get receipt by ID
  Future<Receipt?> getReceipt(String receiptId) async {
    try {
      final doc = await _firestore.collection('receipts').doc(receiptId).get();

      if (doc.exists && doc.data() != null) {
        return Receipt.fromFirestore(doc.data()!, doc.id);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching receipt: $e');
      }
      return null;
    }
  }

  /// Get receipt by order ID
  Future<Receipt?> getReceiptByOrderId(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('receipts')
          .where('order_id', isEqualTo: orderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Receipt.fromFirestore(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching receipt by order ID: $e');
      }
      return null;
    }
  }

  /// Get all receipts for a buyer (SME/SHG)
  Future<List<Receipt>> getBuyerReceipts(String buyerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('receipts')
          .where('buyer_id', isEqualTo: buyerId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Receipt.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching buyer receipts: $e');
      }
      return [];
    }
  }

  /// Get all receipts for a seller (SHG/PSA)
  Future<List<Receipt>> getSellerReceipts(String sellerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('receipts')
          .where('seller_id', isEqualTo: sellerId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Receipt.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching seller receipts: $e');
      }
      return [];
    }
  }

  /// Stream receipts for a buyer
  Stream<List<Receipt>> streamBuyerReceipts(String buyerId) {
    return _firestore
        .collection('receipts')
        .where('buyer_id', isEqualTo: buyerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Receipt.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Stream receipts for a seller
  Stream<List<Receipt>> streamSellerReceipts(String sellerId) {
    return _firestore
        .collection('receipts')
        .where('seller_id', isEqualTo: sellerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Receipt.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}
