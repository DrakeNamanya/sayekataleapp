import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/user.dart' as app_user;
import 'mtn_momo_service.dart';

/// Subscription service for managing premium subscriptions
/// Handles SHG Premium (UGX 50,000/year) and PSA Annual (UGX 120,000/year)
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MtnMomoService _momoService = MtnMomoService(useSandbox: true);

  // ============================================================================
  // SUBSCRIPTION MANAGEMENT
  // ============================================================================

  /// Check if user has active subscription
  /// 
  /// [userId] - User ID
  /// [type] - Subscription type to check
  Future<bool> hasActiveSubscription(String userId, SubscriptionType type) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final subscription = Subscription.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      return subscription.isActive;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking subscription: $e');
      }
      return false;
    }
  }

  /// Get user's current subscription
  /// 
  /// [userId] - User ID
  /// [type] - Subscription type
  Future<Subscription?> getUserSubscription(String userId, SubscriptionType type) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Subscription.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching subscription: $e');
      }
      return null;
    }
  }

  /// Stream user's subscription status
  Stream<Subscription?> streamUserSubscription(String userId, SubscriptionType type) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Subscription.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  // ============================================================================
  // SUBSCRIPTION PURCHASE
  // ============================================================================

  /// Purchase subscription
  /// 
  /// [user] - User purchasing subscription
  /// [type] - Subscription type
  /// [phoneNumber] - Payment phone number
  /// 
  /// Returns subscription ID
  Future<String> purchaseSubscription({
    required app_user.AppUser user,
    required SubscriptionType type,
    required String phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('💳 Purchasing subscription: ${type.displayName} for ${user.name}');
      }

      // Check if user already has active subscription
      final hasActive = await hasActiveSubscription(user.id, type);
      if (hasActive) {
        throw Exception('User already has an active ${type.displayName} subscription');
      }

      // Create transaction
      final transaction = app_transaction.Transaction(
        id: 'TXN-SUB-${DateTime.now().millisecondsSinceEpoch}',
        type: type == SubscriptionType.shgPremium
            ? app_transaction.TransactionType.shgPremiumSubscription
            : app_transaction.TransactionType.psaAnnualSubscription,
        buyerId: user.id,
        buyerName: user.name,
        sellerId: 'APP',
        sellerName: 'Poultry Link',
        amount: type.amount,
        serviceFee: 0,
        sellerReceives: type.amount,
        status: app_transaction.TransactionStatus.initiated,
        paymentMethod: app_transaction.PaymentMethod.mtnMobileMoney,
        createdAt: DateTime.now(),
        metadata: {
          'subscriptionType': type.toString(),
          'userRole': user.role.toString(),
        },
      );

      // Save transaction
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());

      // Request payment
      try {
        final paymentRef = await _momoService.requestPayment(
          amount: type.amount,
          phoneNumber: phoneNumber,
          payerMessage: 'Subscription: ${type.displayName}',
          payeeNote: 'Poultry Link ${type.displayName}',
        );

        // Update transaction with payment reference
        await _firestore.collection('transactions').doc(transaction.id).update({
          'paymentReference': paymentRef,
          'status': app_transaction.TransactionStatus.paymentPending.toString().split('.').last,
        });

        if (kDebugMode) {
          debugPrint('✅ Payment requested: $paymentRef');
        }

        return transaction.id;
      } catch (e) {
        // Payment request failed
        await _firestore.collection('transactions').doc(transaction.id).update({
          'status': app_transaction.TransactionStatus.failed.toString().split('.').last,
          'failureReason': e.toString(),
        });
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error purchasing subscription: $e');
      }
      rethrow;
    }
  }

  /// Confirm subscription payment and activate
  /// 
  /// [transactionId] - app_transaction.Transaction ID
  Future<String?> confirmSubscriptionPayment(String transactionId) async {
    try {
      final doc = await _firestore.collection('transactions').doc(transactionId).get();
      
      if (!doc.exists) {
        throw Exception('app_transaction.Transaction not found');
      }

      final transaction = app_transaction.Transaction.fromFirestore(doc.data()!, doc.id);

      if (transaction.paymentReference == null) {
        throw Exception('Payment reference not found');
      }

      // Check payment status
      final status = await _momoService.checkPaymentStatus(transaction.paymentReference!);

      if (status.isSuccessful) {
        // Create subscription
        final subscription = Subscription(
          id: 'SUB-${DateTime.now().millisecondsSinceEpoch}',
          userId: transaction.buyerId,
          userName: transaction.buyerName,
          type: transaction.type == app_transaction.TransactionType.shgPremiumSubscription
              ? SubscriptionType.shgPremium
              : SubscriptionType.psaAnnual,
          status: SubscriptionStatus.active,
          amount: transaction.amount,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          transactionId: transactionId,
          autoRenew: false,
          createdAt: DateTime.now(),
        );

        // Save subscription
        await _firestore
            .collection('subscriptions')
            .doc(subscription.id)
            .set(subscription.toFirestore());

        // Update transaction
        await _firestore.collection('transactions').doc(transactionId).update({
          'status': app_transaction.TransactionStatus.completed.toString().split('.').last,
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Update revenue tracking
        await _updateRevenueTracking(transaction);

        if (kDebugMode) {
          debugPrint('✅ Subscription activated: ${subscription.id}');
        }

        return subscription.id;
      } else if (status.isFailed) {
        await _firestore.collection('transactions').doc(transactionId).update({
          'status': app_transaction.TransactionStatus.failed.toString().split('.').last,
          'failureReason': status.reason ?? 'Payment failed',
        });

        return null;
      }

      // Still pending
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error confirming subscription payment: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // SUBSCRIPTION RENEWAL
  // ============================================================================

  /// Check for expiring subscriptions and send reminders
  Future<void> checkExpiringSubscriptions() async {
    try {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      // Find subscriptions expiring within 30 days
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow))
          .get();

      for (final doc in snapshot.docs) {
        final subscription = Subscription.fromFirestore(doc.data(), doc.id);

        if (!subscription.isExpiringSoon) continue;

        final daysUntilExpiry = subscription.expiryDate.difference(now).inDays;

        // Send 30-day reminder
        if (daysUntilExpiry <= 30 && daysUntilExpiry > 7) {
          await _sendRenewalReminder(subscription, daysUntilExpiry);
        }
        // Send 7-day reminder
        else if (daysUntilExpiry <= 7 && daysUntilExpiry > 0) {
          await _sendRenewalReminder(subscription, daysUntilExpiry);
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Checked expiring subscriptions');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking expiring subscriptions: $e');
      }
    }
  }

  /// Send renewal reminder
  Future<void> _sendRenewalReminder(Subscription subscription, int daysUntilExpiry) async {
    try {
      // Update last reminder sent
      await _firestore.collection('subscriptions').doc(subscription.id).update({
        'lastReminderSent': FieldValue.serverTimestamp(),
      });

      // TODO: Send in-app message/notification
      if (kDebugMode) {
        debugPrint('📧 Renewal reminder sent to ${subscription.userName}: $daysUntilExpiry days remaining');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending reminder: $e');
      }
    }
  }

  /// Renew subscription
  /// 
  /// [subscriptionId] - Current subscription ID
  /// [phoneNumber] - Payment phone number
  Future<String> renewSubscription({
    required String subscriptionId,
    required String phoneNumber,
  }) async {
    try {
      final doc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
      
      if (!doc.exists) {
        throw Exception('Subscription not found');
      }

      final subscription = Subscription.fromFirestore(doc.data()!, doc.id);

      // Fetch user details
      final userDoc = await _firestore.collection('users').doc(subscription.userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final user = app_user.AppUser.fromFirestore(userDoc.data()!, userDoc.id);

      // Create new subscription transaction
      final transactionId = await purchaseSubscription(
        user: user,
        type: subscription.type,
        phoneNumber: phoneNumber,
      );

      if (kDebugMode) {
        debugPrint('✅ Subscription renewal initiated: $transactionId');
      }

      return transactionId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error renewing subscription: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // SUBSCRIPTION ENFORCEMENT
  // ============================================================================

  /// Enforce PSA subscription - hide products if subscription expired
  Future<void> enforcePsaSubscription(String psaId) async {
    try {
      final hasActive = await hasActiveSubscription(psaId, SubscriptionType.psaAnnual);

      if (!hasActive) {
        // Hide all PSA products
        final products = await _firestore
            .collection('products')
            .where('supplierId', isEqualTo: psaId)
            .get();

        final batch = _firestore.batch();
        for (final doc in products.docs) {
          batch.update(doc.reference, {
            'isVisible': false,
            'hiddenReason': 'Subscription expired',
          });
        }
        await batch.commit();

        if (kDebugMode) {
          debugPrint('🚫 PSA products hidden due to expired subscription: $psaId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error enforcing PSA subscription: $e');
      }
    }
  }

  /// Check expired subscriptions and update status
  Future<void> updateExpiredSubscriptions() async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .where('expiryDate', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': SubscriptionStatus.expired.toString().split('.').last,
        });
      }
      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ Updated ${snapshot.docs.length} expired subscriptions');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating expired subscriptions: $e');
      }
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Update revenue tracking
  Future<void> _updateRevenueTracking(app_transaction.Transaction transaction) async {
    final month = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM
    
    await _firestore.collection('revenue_tracking').doc(month).set({
      'month': month,
      'subscriptionRevenue': FieldValue.increment(transaction.amount),
      'totalSubscriptions': FieldValue.increment(1),
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
