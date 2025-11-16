import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/order.dart' as app_order;
import 'mtn_momo_service.dart';

/// Escrow service for managing payment holding and release
/// Ensures secure transactions by holding funds until delivery confirmation
class EscrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MtnMomoService _momoService = MtnMomoService(useSandbox: true);

  // ============================================================================
  // STEP 1: INITIATE ESCROW PAYMENT
  // ============================================================================

  /// Initiate escrow payment for an order
  ///
  /// [order] - app_order.Order details
  /// [payerPhone] - Payer's phone number for MTN MoMo
  ///
  /// Returns transaction ID
  Future<String> initiateEscrowPayment({
    required app_order.Order order,
    required String payerPhone,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔒 Initiating escrow payment for order: ${order.id}');
      }

      // Create transaction record
      final transaction = app_transaction.Transaction(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        type: order.type == app_order.OrderType.shgToPsaInputPurchase
            ? app_transaction.TransactionType.shgToPsaInputPurchase
            : app_transaction.TransactionType.smeToShgProductPurchase,
        orderId: order.id,
        buyerId: order.buyerId,
        buyerName: order.buyerName,
        sellerId: order.sellerId,
        sellerName: order.sellerName,
        amount: order.subtotal,
        serviceFee: order.serviceFee,
        sellerReceives: order.subtotal - order.type.sellerFee,
        status: app_transaction.TransactionStatus.initiated,
        paymentMethod:
            order.paymentMethod == app_order.PaymentMethod.mtnMobileMoney
            ? app_transaction.PaymentMethod.mtnMobileMoney
            : order.paymentMethod == app_order.PaymentMethod.airtelMoney
            ? app_transaction.PaymentMethod.airtelMoney
            : app_transaction.PaymentMethod.cashOnDelivery,
        createdAt: DateTime.now(),
        metadata: {
          'orderType': order.type.toString(),
          'buyerFee': order.type.buyerFee,
          'sellerFee': order.type.sellerFee,
        },
      );

      // Save transaction to Firestore
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());

      // Update order with transaction ID
      await _firestore.collection('orders').doc(order.id).update({
        'transactionId': transaction.id,
      });

      if (kDebugMode) {
        debugPrint('✅ app_transaction.Transaction created: ${transaction.id}');
      }

      // If COD, skip payment collection
      if (order.paymentMethod == app_order.PaymentMethod.cashOnDelivery) {
        await _updateTransactionStatus(
          transaction.id,
          app_transaction.TransactionStatus.confirmed,
        );

        await _firestore.collection('orders').doc(order.id).update({
          'status': app_order.OrderStatus.deliveryPending
              .toString()
              .split('.')
              .last,
        });

        return transaction.id;
      }

      // Request payment via MTN MoMo
      try {
        final paymentRef = await _momoService.requestPayment(
          amount: order.totalAmount,
          phoneNumber: payerPhone,
          payerMessage: 'Payment for ${order.type.displayName} - ${order.id}',
          payeeNote: 'Poultry Link order payment',
        );

        // Update transaction with payment reference
        await _firestore.collection('transactions').doc(transaction.id).update({
          'paymentReference': paymentRef,
          'status': app_transaction.TransactionStatus.paymentPending
              .toString()
              .split('.')
              .last,
        });

        if (kDebugMode) {
          debugPrint('✅ Payment requested: $paymentRef');
        }

        return transaction.id;
      } catch (e) {
        // Payment request failed
        await _updateTransactionStatus(
          transaction.id,
          app_transaction.TransactionStatus.failed,
          failureReason: e.toString(),
        );
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initiating escrow payment: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // STEP 2: CONFIRM PAYMENT COLLECTION
  // ============================================================================

  /// Check and confirm payment collection
  ///
  /// [transactionId] - app_transaction.Transaction ID
  ///
  /// Returns true if payment confirmed
  Future<bool> confirmPaymentCollection(String transactionId) async {
    try {
      final doc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!doc.exists) {
        throw Exception('Transaction not found');
      }

      final transaction = app_transaction.Transaction.fromFirestore(
        doc.data()!,
        doc.id,
      );

      // Skip if COD
      if (transaction.paymentMethod == app_order.PaymentMethod.cashOnDelivery) {
        return true;
      }

      // Check payment status with MTN MoMo
      if (transaction.paymentReference == null) {
        throw Exception('Payment reference not found');
      }

      final status = await _momoService.checkPaymentStatus(
        transaction.paymentReference!,
      );

      if (status.isSuccessful) {
        // Update transaction to payment held
        await _updateTransactionStatus(
          transactionId,
          app_transaction.TransactionStatus.paymentHeld,
        );

        // Update order status
        if (transaction.orderId != null) {
          await _firestore
              .collection('orders')
              .doc(transaction.orderId)
              .update({
                'status': app_order.OrderStatus.deliveryPending
                    .toString()
                    .split('.')
                    .last,
              });
        }

        if (kDebugMode) {
          debugPrint('✅ Payment held in escrow: $transactionId');
        }

        return true;
      } else if (status.isFailed) {
        await _updateTransactionStatus(
          transactionId,
          app_transaction.TransactionStatus.failed,
          failureReason: status.reason ?? 'Payment failed',
        );

        return false;
      }

      // Still pending
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error confirming payment: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // STEP 3: MARK DELIVERY COMPLETED
  // ============================================================================

  /// Mark order as delivered (by seller)
  ///
  /// [orderId] - app_order.Order ID
  Future<void> markDelivered(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = app_order.Order.fromFirestore(
        orderDoc.data()!,
        orderDoc.id,
      );

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.deliveredPendingConfirmation
            .toString()
            .split('.')
            .last,
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      // Update transaction status
      if (order.transactionId != null) {
        await _updateTransactionStatus(
          order.transactionId!,
          app_transaction.TransactionStatus.deliveredPendingConfirmation,
        );
      }

      if (kDebugMode) {
        debugPrint('✅ app_order.Order marked as delivered: $orderId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error marking delivery: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // STEP 4: CONFIRM DELIVERY & RELEASE PAYMENT
  // ============================================================================

  /// Confirm delivery and release payment to seller
  ///
  /// [orderId] - app_order.Order ID
  /// [sellerPhone] - Seller's phone number for disbursement
  Future<void> confirmDeliveryAndRelease({
    required String orderId,
    required String sellerPhone,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎉 Confirming delivery and releasing payment: $orderId');
      }

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = app_order.Order.fromFirestore(
        orderDoc.data()!,
        orderDoc.id,
      );

      if (order.transactionId == null) {
        throw Exception('app_transaction.Transaction ID not found');
      }

      final txnDoc = await _firestore
          .collection('transactions')
          .doc(order.transactionId)
          .get();

      if (!txnDoc.exists) {
        throw Exception('Transaction not found');
      }

      final transaction = app_transaction.Transaction.fromFirestore(
        txnDoc.data()!,
        txnDoc.id,
      );

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.confirmed.toString().split('.').last,
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      // Update transaction status
      await _updateTransactionStatus(
        order.transactionId!,
        app_transaction.TransactionStatus.confirmed,
      );

      // If COD, no disbursement needed
      if (transaction.paymentMethod == app_order.PaymentMethod.cashOnDelivery) {
        await _completeTransaction(order.transactionId!);
        return;
      }

      // Release payment to seller via disbursement
      try {
        final disbursementRef = await _momoService.sendPayment(
          amount: transaction.sellerReceives,
          phoneNumber: sellerPhone,
          payeeNote: 'Payment for order ${order.id}',
          payerMessage: 'Poultry Link order payment release',
        );

        // Update transaction with disbursement reference
        await _firestore
            .collection('transactions')
            .doc(order.transactionId)
            .update({
              'disbursementReference': disbursementRef,
              'status': app_transaction.TransactionStatus.disbursementPending
                  .toString()
                  .split('.')
                  .last,
            });

        if (kDebugMode) {
          debugPrint('✅ Disbursement initiated: $disbursementRef');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Disbursement failed: $e');
        }
        // Mark transaction as failed but order as completed
        await _updateTransactionStatus(
          order.transactionId!,
          app_transaction.TransactionStatus.failed,
          failureReason: 'Disbursement failed: $e',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error confirming delivery: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // STEP 5: COMPLETE TRANSACTION
  // ============================================================================

  /// Check disbursement status and complete transaction
  ///
  /// [transactionId] - app_transaction.Transaction ID
  Future<bool> completeDisbursement(String transactionId) async {
    try {
      final doc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!doc.exists) {
        throw Exception('Transaction not found');
      }

      final transaction = app_transaction.Transaction.fromFirestore(
        doc.data()!,
        doc.id,
      );

      if (transaction.disbursementReference == null) {
        throw Exception('Disbursement reference not found');
      }

      // Check disbursement status
      final status = await _momoService.checkDisbursementStatus(
        transaction.disbursementReference!,
      );

      if (status.isSuccessful) {
        await _completeTransaction(transactionId);

        if (kDebugMode) {
          debugPrint('✅ app_transaction.Transaction completed: $transactionId');
        }

        return true;
      } else if (status.isFailed) {
        await _updateTransactionStatus(
          transactionId,
          app_transaction.TransactionStatus.failed,
          failureReason: status.reason ?? 'Disbursement failed',
        );

        return false;
      }

      // Still pending
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error completing disbursement: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Update transaction status
  Future<void> _updateTransactionStatus(
    String transactionId,
    app_transaction.TransactionStatus status, {
    String? failureReason,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': status.toString().split('.').last,
    };

    if (failureReason != null) {
      updateData['failureReason'] = failureReason;
    }

    if (status == app_transaction.TransactionStatus.completed) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore
        .collection('transactions')
        .doc(transactionId)
        .update(updateData);
  }

  /// Complete transaction
  Future<void> _completeTransaction(String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': app_transaction.TransactionStatus.completed
          .toString()
          .split('.')
          .last,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Update associated order
    final txnDoc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();
    final transaction = app_transaction.Transaction.fromFirestore(
      txnDoc.data()!,
      txnDoc.id,
    );

    if (transaction.orderId != null) {
      await _firestore.collection('orders').doc(transaction.orderId).update({
        'status': app_order.OrderStatus.completed.toString().split('.').last,
      });
    }

    // Update revenue tracking
    await _updateRevenueTracking(transaction);
  }

  /// Update revenue tracking
  Future<void> _updateRevenueTracking(
    app_transaction.Transaction transaction,
  ) async {
    final month = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM

    await _firestore.collection('revenue_tracking').doc(month).set({
      'month': month,
      'totalRevenue': FieldValue.increment(transaction.serviceFee),
      'totalTransactions': FieldValue.increment(1),
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============================================================================
  // REFUND HANDLING
  // ============================================================================

  /// Cancel order and initiate refund
  ///
  /// [orderId] - Order ID
  /// [reason] - Cancellation reason
  Future<void> cancelOrderAndRefund({
    required String orderId,
    required String reason,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔙 Cancelling order and initiating refund: $orderId');
      }

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = app_order.Order.fromFirestore(
        orderDoc.data()!,
        orderDoc.id,
      );

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': app_order.OrderStatus.cancelled.toString().split('.').last,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
      });

      // Update transaction status
      if (order.transactionId != null) {
        await _updateTransactionStatus(
          order.transactionId!,
          app_transaction.TransactionStatus.refunded,
          failureReason: reason,
        );
      }

      // TODO: Implement actual refund logic via MTN MoMo
      // For now, mark as refunded in database

      if (kDebugMode) {
        debugPrint(
          '✅ app_order.Order cancelled and refund initiated: $orderId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cancelling order: $e');
      }
      rethrow;
    }
  }
}
