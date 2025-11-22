import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to track deleted user accounts for admin analytics
/// Creates a record before account deletion for audit trail
class DeletedAccountsTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Log account deletion before actually deleting
  /// This creates an audit trail for admin dashboard
  Future<void> logAccountDeletion({
    required String userId,
    required String userEmail,
    required String userName,
    required String userRole,
    String? deletionReason,
    String deletedBy = 'self', // 'self' or 'admin'
  }) async {
    try {
      // Create deleted account record
      await _firestore.collection('deleted_accounts').doc(userId).set({
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'userRole': userRole,
        'deletionDate': FieldValue.serverTimestamp(),
        'deletionReason': deletionReason ?? 'User initiated account deletion',
        'deletedBy': deletedBy,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('✅ Logged account deletion for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error logging account deletion: $e');
      }
      // Don't throw error - deletion tracking is not critical
      // The actual account deletion should proceed even if logging fails
    }
  }

  /// Get all deleted accounts (for admin dashboard)
  Stream<List<DeletedAccount>> getDeletedAccounts({
    int limit = 50,
  }) {
    return _firestore
        .collection('deleted_accounts')
        .orderBy('deletionDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DeletedAccount.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get deleted accounts count (for admin analytics)
  Future<int> getDeletedAccountsCount() async {
    try {
      final snapshot =
          await _firestore.collection('deleted_accounts').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting deleted accounts count: $e');
      }
      return 0;
    }
  }

  /// Get deleted accounts by role (for admin analytics)
  Future<Map<String, int>> getDeletedAccountsByRole() async {
    try {
      final snapshot = await _firestore.collection('deleted_accounts').get();

      final Map<String, int> roleCount = {
        'shg': 0,
        'sme': 0,
        'psa': 0,
        'admin': 0,
      };

      for (var doc in snapshot.docs) {
        final role = doc.data()['userRole'] as String?;
        if (role != null && roleCount.containsKey(role)) {
          roleCount[role] = roleCount[role]! + 1;
        }
      }

      return roleCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting deleted accounts by role: $e');
      }
      return {};
    }
  }

  /// Get deleted accounts in date range (for admin reports)
  Future<List<DeletedAccount>> getDeletedAccountsInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('deleted_accounts')
          .where('deletionDate', isGreaterThanOrEqualTo: startDate)
          .where('deletionDate', isLessThanOrEqualTo: endDate)
          .orderBy('deletionDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return DeletedAccount.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting deleted accounts in date range: $e');
      }
      return [];
    }
  }
}

/// Model for deleted account record
class DeletedAccount {
  final String userId;
  final String userEmail;
  final String userName;
  final String userRole;
  final DateTime? deletionDate;
  final String deletionReason;
  final String deletedBy;
  final String timestamp;

  DeletedAccount({
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userRole,
    this.deletionDate,
    required this.deletionReason,
    required this.deletedBy,
    required this.timestamp,
  });

  factory DeletedAccount.fromFirestore(
      Map<String, dynamic> data, String docId) {
    return DeletedAccount(
      userId: data['userId'] ?? docId,
      userEmail: data['userEmail'] ?? 'Unknown',
      userName: data['userName'] ?? 'Unknown',
      userRole: data['userRole'] ?? 'unknown',
      deletionDate: (data['deletionDate'] as Timestamp?)?.toDate(),
      deletionReason: data['deletionReason'] ?? 'No reason provided',
      deletedBy: data['deletedBy'] ?? 'self',
      timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userRole': userRole,
      'deletionDate': deletionDate != null
          ? Timestamp.fromDate(deletionDate!)
          : FieldValue.serverTimestamp(),
      'deletionReason': deletionReason,
      'deletedBy': deletedBy,
      'timestamp': timestamp,
    };
  }

  String get roleDisplayName {
    switch (userRole) {
      case 'shg':
        return 'SHG (Farmer)';
      case 'sme':
        return 'SME (Buyer)';
      case 'psa':
        return 'PSA (Supplier)';
      case 'admin':
        return 'Admin';
      default:
        return 'Unknown';
    }
  }

  String get deletedByDisplayName {
    return deletedBy == 'self' ? 'User' : 'Admin';
  }
}
