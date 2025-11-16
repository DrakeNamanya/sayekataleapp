import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Firebase User Service
/// Provides user data retrieval functionality
class FirebaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user by ID (Firebase UID)
  /// Returns AppUser if found, null otherwise
  Future<AppUser?> getUserById(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Fetching user: $userId');
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        if (kDebugMode) {
          debugPrint('✅ User found: $userId');
        }
        return AppUser.fromFirestore(userDoc.data()!, userId);
      }

      if (kDebugMode) {
        debugPrint('⚠️ User not found: $userId');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching user: $e');
      }
      return null;
    }
  }

  /// Get multiple users by IDs (batch query)
  /// Returns a map of userId -> AppUser
  Future<Map<String, AppUser>> getUsersByIds(List<String> userIds) async {
    try {
      final Map<String, AppUser> usersMap = {};

      if (userIds.isEmpty) return usersMap;

      // Remove duplicates
      final uniqueUserIds = userIds.toSet().toList();

      if (kDebugMode) {
        debugPrint('🔍 Fetching ${uniqueUserIds.length} users...');
      }

      // Firestore 'in' query has a limit of 10 items
      // Split into batches if more than 10 users
      for (int i = 0; i < uniqueUserIds.length; i += 10) {
        final batch = uniqueUserIds.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            usersMap[doc.id] = AppUser.fromFirestore(doc.data(), doc.id);
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Fetched ${usersMap.length} users');
      }

      return usersMap;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching users: $e');
      }
      return {};
    }
  }

  /// Get user by custom user ID (e.g., "SME-123", "SHG-456")
  /// This searches by the 'id' field in the user document
  Future<AppUser?> getUserByCustomId(String customId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Fetching user by custom ID: $customId');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('id', isEqualTo: customId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        if (kDebugMode) {
          debugPrint('✅ User found: $customId');
        }
        return AppUser.fromFirestore(doc.data(), doc.id);
      }

      if (kDebugMode) {
        debugPrint('⚠️ User not found: $customId');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching user by custom ID: $e');
      }
      return null;
    }
  }

  /// Get users by role
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Fetching users with role: ${role.toString()}');
      }

      final roleString = role.toString().split('.').last.toUpperCase();

      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: roleString)
          .get();

      final users = querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Found ${users.length} users with role: $roleString');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching users by role: $e');
      }
      return [];
    }
  }

  /// Stream of user data (real-time updates)
  Stream<AppUser?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromFirestore(snapshot.data()!, userId);
      }
      return null;
    });
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking user existence: $e');
      }
      return false;
    }
  }
}
