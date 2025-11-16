import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

/// Service for managing premium subscriptions
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Subscription pricing
  static const double yearlySmeDirectoryPrice = 50000.0; // UGX 50,000

  /// Check if user has active SME directory subscription
  /// Uses direct document lookup for better performance
  Future<bool> hasActiveSMEDirectorySubscription(String userId) async {
    try {
      // Direct document lookup
      final docSnapshot = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) return false;

      final subscription = Subscription.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );

      // Check if it's SME directory subscription and is active
      return subscription.type == SubscriptionType.smeDirectory && 
             subscription.isActive;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking subscription: $e');
      }
      return false;
    }
  }

  /// Get user's current active subscription
  /// Uses userId as document ID for direct lookup
  Future<Subscription?> getActiveSubscription(String userId, SubscriptionType type) async {
    try {
      // Direct document lookup using userId
      final docSnapshot = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) return null;

      final subscription = Subscription.fromFirestore(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );

      // Verify it's the correct type and is active
      if (subscription.type != type) return null;
      
      return subscription.isActive ? subscription : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting subscription: $e');
      }
      return null;
    }
  }

  /// Create new subscription (after payment confirmation)
  /// Uses userId as document ID for efficient security rules checking
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
        id: userId, // Use userId as document ID
        userId: userId,
        type: type,
        status: SubscriptionStatus.active,
        startDate: startDate,
        endDate: endDate,
        amount: yearlySmeDirectoryPrice,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        createdAt: DateTime.now(),
      );

      // Use userId as document ID for efficient exists() checks in security rules
      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .set(subscription.toFirestore(), SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('✅ Subscription created for user: $userId');
      }

      return userId;
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
        amount: yearlySmeDirectoryPrice,
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
      // Query uses 'role' field, not 'user_type'
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'sme')
          .get();

      final contacts = querySnapshot.docs
          .map((doc) => SMEContact.fromFirestore(doc.data(), doc.id))
          .toList();

      // Fetch products for each SME from their order history
      await _populateSMEProducts(contacts);

      // Sort by name in memory
      contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (kDebugMode) {
        debugPrint('✅ Fetched ${contacts.length} SME contacts with products');
      }

      return contacts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching SME contacts: $e');
      }
      throw Exception('Failed to fetch SME contacts: $e');
    }
  }

  /// Populate products for SMEs from their order history
  Future<void> _populateSMEProducts(List<SMEContact> contacts) async {
    for (var contact in contacts) {
      try {
        // Get all orders placed by this SME
        final ordersSnapshot = await _firestore
            .collection('orders')
            .where('buyer_id', isEqualTo: contact.id)
            .get();

        // Extract unique product names from order items
        final Set<String> productSet = {};
        for (var orderDoc in ordersSnapshot.docs) {
          final orderData = orderDoc.data();
          final items = orderData['items'] as List<dynamic>?;
          if (items != null) {
            for (var item in items) {
              final productName = item['product_name'] ?? item['productName'];
              if (productName != null && productName.toString().isNotEmpty) {
                productSet.add(productName.toString());
              }
            }
          }
        }

        // Update the contact's products list
        // Using reflection-like approach via creating new instance
        final index = contacts.indexOf(contact);
        contacts[index] = SMEContact(
          id: contact.id,
          name: contact.name,
          phone: contact.phone,
          email: contact.email,
          district: contact.district,
          subCounty: contact.subCounty,
          village: contact.village,
          products: productSet.toList()..sort(),
          registeredAt: contact.registeredAt,
          isVerified: contact.isVerified,
          profileImage: contact.profileImage,
        );

        if (kDebugMode) {
          debugPrint('  • ${contact.name}: ${productSet.length} unique products');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error fetching products for ${contact.name}: $e');
        }
        // Continue with empty products list if error occurs
      }
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
          .where('role', isEqualTo: 'sme');

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
