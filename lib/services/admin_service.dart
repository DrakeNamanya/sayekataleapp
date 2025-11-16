import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';
import '../models/psa_verification.dart';
import '../models/product.dart';
import '../models/user.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Admin User Management ====================

  /// Get admin user by ID
  Future<AdminUser?> getAdminUser(String adminId) async {
    try {
      final doc = await _firestore.collection('admin_users').doc(adminId).get();
      if (!doc.exists) return null;
      return AdminUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get admin user: $e');
    }
  }

  /// Update admin last login time
  Future<void> updateAdminLastLogin(String adminId) async {
    await _firestore.collection('admin_users').doc(adminId).update({
      'last_login_at': DateTime.now().toIso8601String(),
    });
  }

  // ==================== PSA Verification Management ====================

  /// Get all PSA verification requests
  Future<List<PsaVerification>> getAllPsaVerifications({
    PsaVerificationStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('psa_verifications');

      if (status != null) {
        query = query.where(
          'status',
          isEqualTo: status.toString().split('.').last,
        );
      }

      final snapshot = await query.limit(limit).get();
      final verifications = snapshot.docs
          .map(
            (doc) => PsaVerification.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // Sort by created date (newest first)
      verifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return verifications;
    } catch (e) {
      throw Exception('Failed to get PSA verifications: $e');
    }
  }

  /// Get pending PSA verifications count
  Future<int> getPendingPsaCount() async {
    final snapshot = await _firestore
        .collection('psa_verifications')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  /// Approve PSA verification
  Future<void> approvePsaVerification(
    String verificationId,
    String adminId, {
    String? reviewNotes,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update verification record
      final verificationRef = _firestore
          .collection('psa_verifications')
          .doc(verificationId);
      batch.update(verificationRef, {
        'status': 'approved',
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'review_notes': reviewNotes,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Get verification details to update user
      final verificationDoc = await verificationRef.get();
      final verification = PsaVerification.fromFirestore(
        verificationDoc.data()!,
        verificationDoc.id,
      );

      // Update PSA user status
      final userRef = _firestore.collection('users').doc(verification.psaId);
      batch.update(userRef, {
        'is_verified': true,
        'verification_status': 'approved',
        'verified_at': DateTime.now().toIso8601String(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to approve PSA: $e');
    }
  }

  /// Reject PSA verification
  Future<void> rejectPsaVerification(
    String verificationId,
    String adminId,
    String rejectionReason, {
    String? reviewNotes,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update verification record
      final verificationRef = _firestore
          .collection('psa_verifications')
          .doc(verificationId);
      batch.update(verificationRef, {
        'status': 'rejected',
        'rejection_reason': rejectionReason,
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'review_notes': reviewNotes,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Get verification details to update user
      final verificationDoc = await verificationRef.get();
      final verification = PsaVerification.fromFirestore(
        verificationDoc.data()!,
        verificationDoc.id,
      );

      // Update PSA user status
      final userRef = _firestore.collection('users').doc(verification.psaId);
      batch.update(userRef, {
        'is_verified': false,
        'verification_status': 'rejected',
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reject PSA: $e');
    }
  }

  /// Request more information from PSA
  Future<void> requestMoreInfo(
    String verificationId,
    String adminId,
    String message,
  ) async {
    await _firestore
        .collection('psa_verifications')
        .doc(verificationId)
        .update({
          'status': 'moreInfoRequired',
          'review_notes': message,
          'reviewed_by': adminId,
          'reviewed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  // ==================== User Management ====================

  /// Get all users with filtering
  Future<List<Map<String, dynamic>>> getAllUsers({
    UserRole? role,
    bool? isVerified,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('users');

      if (role != null) {
        query = query.where('role', isEqualTo: role.toString().split('.').last);
      }

      if (isVerified != null) {
        query = query.where('is_verified', isEqualTo: isVerified);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Suspend user account
  Future<void> suspendUser(String userId, String adminId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'is_suspended': true,
      'suspended_at': DateTime.now().toIso8601String(),
      'suspension_reason': reason,
      'suspended_by': adminId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Unsuspend (reactivate) user account
  Future<void> unsuspendUser(String userId, String adminId) async {
    await _firestore.collection('users').doc(userId).update({
      'is_suspended': false,
      'suspended_at': null,
      'suspension_reason': null,
      'suspended_by': null,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get suspended users count
  Future<int> getSuspendedUsersCount() async {
    final snapshot = await _firestore
        .collection('users')
        .where('is_suspended', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  // ==================== Product Moderation ====================

  /// Get products requiring moderation
  Future<List<Product>> getProductsForModeration({int limit = 50}) async {
    try {
      // Get recently added products or flagged products
      final snapshot = await _firestore
          .collection('products')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products for moderation: $e');
    }
  }

  /// Flag product as inappropriate
  Future<void> flagProduct(
    String productId,
    String adminId,
    String reason,
  ) async {
    await _firestore.collection('products').doc(productId).update({
      'is_flagged': true,
      'flag_reason': reason,
      'flagged_by': adminId,
      'flagged_at': DateTime.now().toIso8601String(),
    });
  }

  /// Approve product
  Future<void> approveProduct(String productId, String adminId) async {
    await _firestore.collection('products').doc(productId).update({
      'is_approved': true,
      'approved_by': adminId,
      'approved_at': DateTime.now().toIso8601String(),
      'is_flagged': false,
    });
  }

  /// Remove product
  Future<void> removeProduct(String productId, String reason) async {
    await _firestore.collection('products').doc(productId).update({
      'is_active': false,
      'removed_reason': reason,
      'removed_at': DateTime.now().toIso8601String(),
    });
  }

  // ==================== Analytics ====================

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final stats = <String, dynamic>{};

      // Total users by role
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs;
      stats['total_users'] = users.length;
      stats['shg_count'] = users.where((u) => u.data()['role'] == 'shg').length;
      stats['psa_count'] = users.where((u) => u.data()['role'] == 'psa').length;
      stats['customer_count'] = users
          .where((u) => u.data()['role'] == 'customer')
          .length;

      // Verified users
      stats['verified_users'] = users
          .where((u) => u.data()['is_verified'] == true)
          .length;

      // Active users (not suspended)
      stats['active_users'] = users
          .where((u) => u.data()['is_active'] != false)
          .length;

      // Pending verifications
      final pendingPsa = await _firestore
          .collection('psa_verifications')
          .where('status', isEqualTo: 'pending')
          .get();
      stats['pending_psa'] = pendingPsa.docs.length;

      // Total products
      final productsSnapshot = await _firestore.collection('products').get();
      stats['total_products'] = productsSnapshot.docs.length;

      // Active products
      stats['active_products'] = productsSnapshot.docs
          .where((p) => p.data()['is_active'] != false)
          .length;

      // Flagged products
      stats['flagged_products'] = productsSnapshot.docs
          .where((p) => p.data()['is_flagged'] == true)
          .length;

      // Low stock products (quantity < 10)
      stats['low_stock_products'] = productsSnapshot.docs
          .where(
            (p) =>
                (p.data()['quantity'] ?? 0) < 10 &&
                p.data()['is_active'] != false,
          )
          .length;

      // Total orders
      final ordersSnapshot = await _firestore.collection('orders').get();
      stats['total_orders'] = ordersSnapshot.docs.length;

      // Pending orders
      stats['pending_orders'] = ordersSnapshot.docs
          .where((o) => o.data()['status'] == 'pending')
          .length;

      // Processing orders
      stats['processing_orders'] = ordersSnapshot.docs
          .where((o) => o.data()['status'] == 'processing')
          .length;

      // Completed orders
      stats['completed_orders'] = ordersSnapshot.docs
          .where((o) => o.data()['status'] == 'delivered')
          .length;

      // Revenue (sum of completed orders)
      double totalRevenue = 0;
      double pendingRevenue = 0;
      for (final order in ordersSnapshot.docs) {
        final amount = (order.data()['total_amount'] ?? 0.0).toDouble();
        if (order.data()['status'] == 'delivered') {
          totalRevenue += amount;
        } else if (order.data()['status'] == 'pending' ||
            order.data()['status'] == 'processing') {
          pendingRevenue += amount;
        }
      }
      stats['total_revenue'] = totalRevenue;
      stats['pending_revenue'] = pendingRevenue;

      // Today's stats
      final today = DateTime.now();
      final todayStart = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();

      stats['today_orders'] = ordersSnapshot.docs
          .where(
            (o) => (o.data()['created_at'] ?? '').toString().startsWith(
              todayStart.substring(0, 10),
            ),
          )
          .length;

      stats['today_revenue'] = ordersSnapshot.docs
          .where(
            (o) =>
                (o.data()['created_at'] ?? '').toString().startsWith(
                  todayStart.substring(0, 10),
                ) &&
                o.data()['status'] == 'delivered',
          )
          .fold(
            0.0,
            (acc, o) => acc + ((o.data()['total_amount'] ?? 0.0).toDouble()),
          );

      // Complaints stats
      final complaintsSnapshot = await _firestore
          .collection('user_complaints')
          .get();
      stats['total_complaints'] = complaintsSnapshot.docs.length;
      stats['pending_complaints'] = complaintsSnapshot.docs
          .where((c) => c.data()['status'] == 'pending')
          .length;

      return stats;
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  /// Get recent activities
  Future<List<Map<String, dynamic>>> getRecentActivities({
    int limit = 20,
  }) async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Get recent orders
      final orders = await _firestore
          .collection('orders')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      for (final order in orders.docs) {
        activities.add({
          'type': 'order',
          'action': 'New order placed',
          'orderId': order.id,
          'timestamp': order.data()['created_at'],
        });
      }

      // Get recent products
      final products = await _firestore
          .collection('products')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      for (final product in products.docs) {
        activities.add({
          'type': 'product',
          'action': 'New product listed',
          'productId': product.id,
          'productName': product.data()['name'],
          'timestamp': product.data()['created_at'],
        });
      }

      // Sort by timestamp
      activities.sort((a, b) {
        final aTime = a['timestamp'].toString();
        final bTime = b['timestamp'].toString();
        return bTime.compareTo(aTime);
      });

      return activities.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get recent activities: $e');
    }
  }

  // ==================== Complaints Management ====================

  /// Get all complaints with optional filtering
  Future<List<Map<String, dynamic>>> getAllComplaints({
    String? status,
    String? category,
    String? priority,
    String? assignedTo,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('user_complaints');

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      if (priority != null && priority != 'all') {
        query = query.where('priority', isEqualTo: priority);
      }

      if (assignedTo != null && assignedTo.isNotEmpty) {
        query = query.where('assigned_to', isEqualTo: assignedTo);
      }

      final snapshot = await query
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to get complaints: $e');
    }
  }

  /// Get complaint by ID
  Future<Map<String, dynamic>?> getComplaint(String complaintId) async {
    try {
      final doc = await _firestore
          .collection('user_complaints')
          .doc(complaintId)
          .get();

      if (!doc.exists) return null;

      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    } catch (e) {
      throw Exception('Failed to get complaint: $e');
    }
  }

  /// Update complaint status
  Future<void> updateComplaintStatus(
    String complaintId,
    String status,
    String adminId,
  ) async {
    await _firestore.collection('user_complaints').doc(complaintId).update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': adminId,
    });
  }

  /// Assign complaint to staff
  Future<void> assignComplaint(
    String complaintId,
    String adminId,
    String assignedBy,
  ) async {
    await _firestore.collection('user_complaints').doc(complaintId).update({
      'assigned_to': adminId,
      'assigned_at': DateTime.now().toIso8601String(),
      'assigned_by': assignedBy,
      'status': 'inProgress',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Add response to complaint
  Future<void> addComplaintResponse(
    String complaintId,
    String adminId,
    String response,
  ) async {
    await _firestore.collection('user_complaints').doc(complaintId).update({
      'response': response,
      'responded_by': adminId,
      'responded_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Close complaint
  Future<void> closeComplaint(
    String complaintId,
    String adminId,
    String resolution,
  ) async {
    await _firestore.collection('user_complaints').doc(complaintId).update({
      'status': 'closed',
      'resolution': resolution,
      'closed_by': adminId,
      'closed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get complaints statistics
  Future<Map<String, int>> getComplaintsStats() async {
    try {
      final snapshot = await _firestore.collection('user_complaints').get();
      final complaints = snapshot.docs;

      return {
        'total': complaints.length,
        'pending': complaints
            .where((c) => c.data()['status'] == 'pending')
            .length,
        'in_progress': complaints
            .where((c) => c.data()['status'] == 'inProgress')
            .length,
        'resolved': complaints
            .where((c) => c.data()['status'] == 'resolved')
            .length,
        'closed': complaints
            .where((c) => c.data()['status'] == 'closed')
            .length,
        'urgent': complaints
            .where((c) => c.data()['priority'] == 'urgent')
            .length,
        'high': complaints.where((c) => c.data()['priority'] == 'high').length,
      };
    } catch (e) {
      throw Exception('Failed to get complaints stats: $e');
    }
  }

  /// Get pending complaints count
  Future<int> getPendingComplaintsCount() async {
    final snapshot = await _firestore
        .collection('user_complaints')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }
}
