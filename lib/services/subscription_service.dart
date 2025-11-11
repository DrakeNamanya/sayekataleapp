import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

/// Service for managing premium subscriptions
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Subscription pricing
  static const double YEARLY_SME_DIRECTORY_PRICE = 50000.0; // UGX 50,000

  /// Check if user has active SME directory subscription
  Future<bool> hasActiveSMEDirectorySubscription(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: 'smeDirectory')
          .where('status', isEqualTo: 'active')
          .get();

      if (querySnapshot.docs.isEmpty) return false;

      // Check if subscription is not expired
      for (final doc in querySnapshot.docs) {
        final subscription = Subscription.fromFirestore(doc.data(), doc.id);
        if (subscription.isActive) {
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking subscription: $e');
      }
      return false;
    }
  }

  /// Get user's current active subscription
  Future<Subscription?> getActiveSubscription(String userId, SubscriptionType type) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('status', isEqualTo: 'active')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final subscription = Subscription.fromFirestore(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );

      return subscription.isActive ? subscription : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting subscription: $e');
      }
      return null;
    }
  }

  /// Create new subscription (after payment confirmation)
  Future<String> createSubscription({
    required String userId,
    required SubscriptionType type,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    try {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 365)); // 1 year

      final subscription = Subscription(
        id: '', // Will be set by Firestore
        userId: userId,
        type: type,
        status: SubscriptionStatus.active,
        startDate: startDate,
        endDate: endDate,
        amount: YEARLY_SME_DIRECTORY_PRICE,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toFirestore());

      if (kDebugMode) {
        debugPrint('✅ Subscription created: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating subscription: $e');
      }
      throw Exception('Failed to create subscription: $e');
    }
  }

  /// Create pending subscription (before payment)
  Future<String> createPendingSubscription({
    required String userId,
    required SubscriptionType type,
    required String paymentMethod,
  }) async {
    try {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 365));

      final subscription = Subscription(
        id: '',
        userId: userId,
        type: type,
        status: SubscriptionStatus.pending,
        startDate: startDate,
        endDate: endDate,
        amount: YEARLY_SME_DIRECTORY_PRICE,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toFirestore());

      if (kDebugMode) {
        debugPrint('✅ Pending subscription created: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating pending subscription: $e');
      }
      throw Exception('Failed to create pending subscription: $e');
    }
  }

  /// Activate pending subscription (after payment confirmation)
  Future<void> activateSubscription(String subscriptionId, String paymentReference) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'active',
        'payment_reference': paymentReference,
      });

      if (kDebugMode) {
        debugPrint('✅ Subscription activated: $subscriptionId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error activating subscription: $e');
      }
      throw Exception('Failed to activate subscription: $e');
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'cancelled',
        'cancelled_at': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('✅ Subscription cancelled: $subscriptionId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cancelling subscription: $e');
      }
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Get all SME contacts (for premium users)
  Future<List<SMEContact>> getAllSMEContacts() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('user_type', isEqualTo: 'sme')
          .orderBy('name')
          .get();

      final contacts = querySnapshot.docs
          .map((doc) => SMEContact.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Fetched ${contacts.length} SME contacts');
      }

      return contacts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching SME contacts: $e');
      }
      throw Exception('Failed to fetch SME contacts: $e');
    }
  }

  /// Search SME contacts with filters
  Future<List<SMEContact>> searchSMEContacts({
    String? searchQuery,
    String? district,
    String? product,
    bool? verifiedOnly,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('user_type', isEqualTo: 'sme');

      // Apply district filter
      if (district != null && district.isNotEmpty && district != 'All') {
        query = query.where('district', isEqualTo: district);
      }

      // Apply verified filter
      if (verifiedOnly == true) {
        query = query.where('is_verified', isEqualTo: true);
      }

      final querySnapshot = await query.get();

      var contacts = querySnapshot.docs
          .map((doc) => SMEContact.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply search query filter (in-memory)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        contacts = contacts.where((contact) {
          final query = searchQuery.toLowerCase();
          return contact.name.toLowerCase().contains(query) ||
                 contact.phone.contains(query) ||
                 contact.email.toLowerCase().contains(query) ||
                 contact.district.toLowerCase().contains(query);
        }).toList();
      }

      // Apply product filter (in-memory)
      if (product != null && product.isNotEmpty && product != 'All') {
        contacts = contacts.where((contact) {
          return contact.products.any((p) => p.toLowerCase().contains(product.toLowerCase()));
        }).toList();
      }

      if (kDebugMode) {
        debugPrint('✅ Filtered ${contacts.length} SME contacts');
      }

      return contacts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching SME contacts: $e');
      }
      throw Exception('Failed to search SME contacts: $e');
    }
  }

  /// Get subscription history for user
  Stream<List<Subscription>> streamUserSubscriptions(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Subscription.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Check and update expired subscriptions
  Future<void> updateExpiredSubscriptions() async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .where('end_date', isLessThan: now)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({'status': 'expired'});
      }

      if (kDebugMode) {
        debugPrint('✅ Updated ${querySnapshot.docs.length} expired subscriptions');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating expired subscriptions: $e');
      }
    }
  }
}
