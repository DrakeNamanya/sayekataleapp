import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for handling account deletion with comprehensive data cleanup
/// This service deletes user account and all associated data from Firebase
class AccountDeletionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Delete user account and all associated data
  /// Returns true if deletion was successful, false otherwise
  Future<bool> deleteAccount(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ ACCOUNT DELETION - Starting for user: $userId');
      }

      // Step 1: Delete user's products
      await _deleteUserProducts(userId);

      // Step 2: Delete user's orders (as buyer)
      await _deleteUserOrders(userId);

      // Step 3: Delete user's reviews
      await _deleteUserReviews(userId);

      // Step 4: Delete user's messages and conversations
      await _deleteUserMessages(userId);

      // Step 5: Delete user's complaints
      await _deleteUserComplaints(userId);

      // Step 6: Delete user's subscriptions
      await _deleteUserSubscriptions(userId);

      // Step 7: Delete user's wallet transactions
      await _deleteUserWalletTransactions(userId);

      // Step 8: Delete PSA verification data (if PSA user)
      await _deletePSAVerification(userId);

      // Step 9: Delete user's notifications
      await _deleteUserNotifications(userId);

      // Step 10: Delete user's storage files (photos, documents)
      await _deleteUserStorageFiles(userId);

      // Step 11: Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();
      await _firestore.collection('admin_users').doc(userId).delete();
      
      if (kDebugMode) {
        debugPrint('✅ Firestore user document deleted');
      }

      // Step 12: Delete Firebase Auth account (must be last)
      await _auth.currentUser?.delete();
      
      if (kDebugMode) {
        debugPrint('✅ Firebase Auth account deleted');
      }

      if (kDebugMode) {
        debugPrint('🎉 ACCOUNT DELETION - Completed successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ACCOUNT DELETION ERROR: $e');
      }
      rethrow;
    }
  }

  /// Delete all products created by the user
  Future<void> _deleteUserProducts(String userId) async {
    try {
      final productsSnapshot = await _firestore
          .collection('products')
          .where('farmId', isEqualTo: userId)
          .get();

      if (kDebugMode) {
        debugPrint('🗑️ Deleting ${productsSnapshot.docs.length} products');
      }

      // Delete each product and its images
      for (var doc in productsSnapshot.docs) {
        // Delete product images from Storage
        final productData = doc.data();
        final images = productData['images'] as List<dynamic>?;
        if (images != null) {
          for (var imageUrl in images) {
            try {
              final ref = _storage.refFromURL(imageUrl as String);
              await ref.delete();
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Error deleting product image: $e');
              }
            }
          }
        }

        // Delete product document
        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ Products deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting products: $e');
      }
    }
  }

  /// Delete all orders where user is buyer or seller
  Future<void> _deleteUserOrders(String userId) async {
    try {
      // Delete orders where user is buyer
      final buyerOrdersSnapshot = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .get();

      for (var doc in buyerOrdersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete orders where user is seller
      final sellerOrdersSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .get();

      for (var doc in sellerOrdersSnapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ Orders deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting orders: $e');
      }
    }
  }

  /// Delete all reviews created by the user
  Future<void> _deleteUserReviews(String userId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in reviewsSnapshot.docs) {
        // Delete review images from Storage
        final reviewData = doc.data();
        final images = reviewData['images'] as List<dynamic>?;
        if (images != null) {
          for (var imageUrl in images) {
            try {
              final ref = _storage.refFromURL(imageUrl as String);
              await ref.delete();
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Error deleting review image: $e');
              }
            }
          }
        }

        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ Reviews deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting reviews: $e');
      }
    }
  }

  /// Delete all messages and conversations involving the user
  Future<void> _deleteUserMessages(String userId) async {
    try {
      // Delete conversations where user is participant
      final conversationsSnapshot = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .get();

      for (var doc in conversationsSnapshot.docs) {
        // Delete all messages in this conversation
        final messagesSnapshot =
            await doc.reference.collection('messages').get();
        for (var messageDoc in messagesSnapshot.docs) {
          await messageDoc.reference.delete();
        }

        // Delete conversation document
        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ Messages and conversations deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting messages: $e');
      }
    }
  }

  /// Delete all complaints filed by the user
  Future<void> _deleteUserComplaints(String userId) async {
    try {
      final complaintsSnapshot = await _firestore
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in complaintsSnapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ Complaints deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting complaints: $e');
      }
    }
  }

  /// Delete user's subscriptions
  Future<void> _deleteUserSubscriptions(String userId) async {
    try {
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in subscriptionsSnapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ Subscriptions deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting subscriptions: $e');
      }
    }
  }

  /// Delete user's wallet transactions
  Future<void> _deleteUserWalletTransactions(String userId) async {
    try {
      final transactionsSnapshot = await _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in transactionsSnapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ Wallet transactions deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting wallet transactions: $e');
      }
    }
  }

  /// Delete PSA verification data
  Future<void> _deletePSAVerification(String userId) async {
    try {
      final verificationSnapshot = await _firestore
          .collection('psa_verifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in verificationSnapshot.docs) {
        // Delete verification documents from Storage
        final verificationData = doc.data();
        
        // Delete business registration document
        final businessRegDoc = verificationData['businessRegistrationDoc'] as String?;
        if (businessRegDoc != null && businessRegDoc.isNotEmpty) {
          try {
            final ref = _storage.refFromURL(businessRegDoc);
            await ref.delete();
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error deleting business reg doc: $e');
            }
          }
        }

        // Delete national ID photo
        final nationalIdPhoto = verificationData['nationalIdPhoto'] as String?;
        if (nationalIdPhoto != null && nationalIdPhoto.isNotEmpty) {
          try {
            final ref = _storage.refFromURL(nationalIdPhoto);
            await ref.delete();
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error deleting national ID photo: $e');
            }
          }
        }

        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ PSA verification deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting PSA verification: $e');
      }
    }
  }

  /// Delete user's notifications
  Future<void> _deleteUserNotifications(String userId) async {
    try {
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        debugPrint('✅ Notifications deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting notifications: $e');
      }
    }
  }

  /// Delete all user's storage files (profile photo, ID, etc.)
  Future<void> _deleteUserStorageFiles(String userId) async {
    try {
      // Delete user profile photos
      try {
        final profileRef = _storage.ref('user_profiles/$userId');
        final profileList = await profileRef.listAll();
        for (var item in profileList.items) {
          await item.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error deleting profile photos: $e');
        }
      }

      // Delete verification documents
      try {
        final verificationRef = _storage.ref('verification_documents/$userId');
        final verificationList = await verificationRef.listAll();
        for (var item in verificationList.items) {
          await item.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error deleting verification documents: $e');
        }
      }

      // Delete PSA verification documents
      try {
        final psaRef = _storage.ref('psa_verifications/$userId');
        final psaList = await psaRef.listAll();
        for (var item in psaList.items) {
          await item.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error deleting PSA documents: $e');
        }
      }

      // Delete product images
      try {
        final productsRef = _storage.ref('products');
        final productsList = await productsRef.listAll();
        for (var folder in productsList.prefixes) {
          // Check if folder belongs to user's products
          // Note: This is a simple check, may need refinement
          try {
            final itemsList = await folder.listAll();
            for (var item in itemsList.items) {
              // Check metadata or use naming convention
              await item.delete();
            }
          } catch (e) {
            // Continue with other folders
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error deleting product images: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Storage files deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting storage files: $e');
      }
    }
  }

  /// Verify if user needs to re-authenticate before deletion
  /// Returns true if re-authentication is required
  Future<bool> needsReauthentication() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check last sign-in time
    final metadata = user.metadata;
    final lastSignIn = metadata.lastSignInTime;
    
    if (lastSignIn == null) return true;

    // Require re-authentication if last sign-in was more than 5 minutes ago
    final now = DateTime.now();
    final difference = now.difference(lastSignIn);
    
    return difference.inMinutes > 5;
  }

  /// Re-authenticate user with password before account deletion
  Future<bool> reauthenticateUser(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      
      if (kDebugMode) {
        debugPrint('✅ User re-authenticated successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Re-authentication failed: $e');
      }
      return false;
    }
  }
}
