import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';

/// Service for managing in-app notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // NOTIFICATION CREATION
  // ============================================================================

  /// Create a new notification
  Future<String> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? actionUrl,
    String? relatedId,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📢 Creating notification for user: $userId');
      }

      final now = DateTime.now().toIso8601String();
      final notification = {
        'user_id': userId,
        'type': type.toString().split('.').last,
        'title': title,
        'message': message,
        'action_url': actionUrl,
        'related_id': relatedId,
        'is_read': false,
        'created_at': now,
      };

      final docRef = await _firestore
          .collection('notifications')
          .add(notification);

      if (kDebugMode) {
        debugPrint('✅ Notification created with ID: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating notification: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // NOTIFICATION RETRIEVAL
  // ============================================================================

  /// Stream user notifications with real-time updates
  Stream<List<AppNotification>> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        // Removed .orderBy() to avoid potential composite index requirement
        .snapshots()
        .map((snapshot) {
          // Get notifications
          final notifications = snapshot.docs.map((doc) {
            final data = doc.data();
            return AppNotification.fromFirestore(data, doc.id);
          }).toList();

          // Sort in memory by created_at (most recent first)
          notifications.sort((a, b) {
            return b.createdAt.compareTo(a.createdAt);
          });

          return notifications;
        });
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      // Removed second .where() to avoid composite index requirement
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .get();

      // Filter unread in memory
      final unreadCount = querySnapshot.docs
          .where((doc) => doc.data()['is_read'] == false)
          .length;

      return unreadCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Stream unread count with real-time updates
  Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        // Removed second .where() to avoid composite index requirement
        .snapshots()
        .map((snapshot) {
          // Filter unread in memory
          return snapshot.docs
              .where((doc) => doc.data()['is_read'] == false)
              .length;
        });
  }

  // ============================================================================
  // NOTIFICATION UPDATES
  // ============================================================================

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'is_read': true,
      });

      if (kDebugMode) {
        debugPrint('✅ Notification $notificationId marked as read');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error marking notification as read: $e');
      }
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      // Removed second .where() to avoid composite index requirement
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .get();

      // Filter unread in memory
      final unreadDocs = querySnapshot.docs
          .where((doc) => doc.data()['is_read'] == false)
          .toList();

      final batch = _firestore.batch();
      for (var doc in unreadDocs) {
        batch.update(doc.reference, {'is_read': true});
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ Marked ${unreadDocs.length} notifications as read');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error marking all as read: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // NOTIFICATION DELETION
  // ============================================================================

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      if (kDebugMode) {
        debugPrint('✅ Notification $notificationId deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting notification: $e');
      }
      rethrow;
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ Deleted ${querySnapshot.docs.length} notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting all notifications: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // HELPER METHODS FOR ORDER NOTIFICATIONS
  // ============================================================================

  /// Send notification when new order is placed
  Future<void> sendNewOrderNotification({
    required String sellerId,
    required String buyerName,
    required String orderId,
    required double totalAmount,
  }) async {
    try {
      await createNotification(
        userId: sellerId,
        type: NotificationType.order,
        title: '🛒 New Order Received!',
        message:
            'You have a new order from $buyerName worth UGX ${totalAmount.toStringAsFixed(0)}',
        actionUrl: '/orders/$orderId',
        relatedId: orderId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending new order notification: $e');
      }
    }
  }

  /// Send notification when order is confirmed by seller
  Future<void> sendOrderConfirmationNotification({
    required String buyerId,
    required String orderId,
    required String sellerName,
  }) async {
    try {
      await createNotification(
        userId: buyerId,
        type: NotificationType.order,
        title: '✅ Order Confirmed!',
        message:
            '$sellerName has confirmed your order and will start preparing it',
        actionUrl: '/orders/$orderId',
        relatedId: orderId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending order confirmation notification: $e');
      }
    }
  }

  /// Send notification when order status is updated
  Future<void> sendOrderStatusNotification({
    required String buyerId,
    required String orderId,
    required String status,
    required String sellerName,
  }) async {
    try {
      String message;
      String title;

      switch (status) {
        case 'confirmed':
          title = '✅ Order Confirmed';
          message = '$sellerName has confirmed your order';
          break;
        case 'preparing':
          title = '📦 Order Being Prepared';
          message = '$sellerName is preparing your order';
          break;
        case 'ready':
          title = '✅ Order Ready';
          message = 'Your order from $sellerName is ready for pickup/delivery';
          break;
        case 'in_transit':
          title = '🚚 Order In Transit';
          message = 'Your order from $sellerName is on the way!';
          break;
        case 'delivered':
          title = '📦 Order Delivered';
          message =
              'Your order from $sellerName has been delivered. Please confirm receipt.';
          break;
        case 'completed':
          title = '🎉 Order Completed';
          message = 'Thank you! Your order from $sellerName is complete.';
          break;
        case 'cancelled':
          title = '❌ Order Cancelled';
          message = 'Your order from $sellerName has been cancelled';
          break;
        default:
          title = '📋 Order Updated';
          message = 'Your order from $sellerName has been updated';
      }

      await createNotification(
        userId: buyerId,
        type: NotificationType.order,
        title: title,
        message: message,
        actionUrl: '/orders/$orderId',
        relatedId: orderId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending order status notification: $e');
      }
    }
  }

  /// Send notification for new message
  Future<void> sendNewMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String conversationId,
  }) async {
    try {
      await createNotification(
        userId: recipientId,
        type: NotificationType.message,
        title: '💬 New Message from $senderName',
        message: messagePreview.length > 100
            ? '${messagePreview.substring(0, 100)}...'
            : messagePreview,
        actionUrl: '/messages/$conversationId',
        relatedId: conversationId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending message notification: $e');
      }
    }
  }

  /// Send notification for low stock alert (for PSA/farmers)
  Future<void> sendLowStockNotification({
    required String userId,
    required String productName,
    required int currentStock,
    required String productId,
  }) async {
    try {
      await createNotification(
        userId: userId,
        type: NotificationType.alert,
        title: '⚠️ Low Stock Alert',
        message:
            'Your product "$productName" is running low (only $currentStock left)',
        actionUrl: '/products/$productId',
        relatedId: productId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending low stock notification: $e');
      }
    }
  }

  /// Send promotional notification (for all users or specific roles)
  Future<void> sendPromotionalNotification({
    required List<String> userIds,
    required String title,
    required String message,
    String? actionUrl,
  }) async {
    try {
      for (final userId in userIds) {
        await createNotification(
          userId: userId,
          type: NotificationType.promotion,
          title: title,
          message: message,
          actionUrl: actionUrl,
        );
      }

      if (kDebugMode) {
        debugPrint(
          '✅ Sent promotional notification to ${userIds.length} users',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending promotional notification: $e');
      }
    }
  }

  // ============================================================================
  // ADMIN BROADCAST METHODS
  // ============================================================================

  /// Send notification to all users (admin broadcast)
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String message,
    NotificationType? notificationType,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      // Create batch for better performance
      final batch = _firestore.batch();
      int batchCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        final now = DateTime.now().toIso8601String();
        batch.set(notificationRef, {
          'user_id': userDoc.id,
          'title': title,
          'message': message,
          'type': notificationType != null
              ? notificationType.toString().split('.').last
              : 'message',
          'image_url': imageUrl,
          'data': data,
          'is_read': false,
          'created_at': now,
        });

        batchCount++;

        // Firestore batch limit is 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }

      // Commit remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }

      if (kDebugMode) {
        debugPrint(
          '✅ Notification sent to ${usersSnapshot.docs.length} users',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending notifications to all users: $e');
        debugPrint('   Error type: ${e.runtimeType}');
        debugPrint('   Error details: ${e.toString()}');
        
        // Check for specific permission errors
        if (e.toString().contains('permission') || 
            e.toString().contains('PERMISSION_DENIED')) {
          debugPrint('');
          debugPrint('🚨 FIREBASE PERMISSION DENIED!');
          debugPrint('   This means Firebase Security Rules are blocking notification creation.');
          debugPrint('');
          debugPrint('📋 QUICK FIXES:');
          debugPrint('   1. Check isAdmin() function in Firebase Rules');
          debugPrint('   2. Verify your user role is "admin" in Firestore');
          debugPrint('   3. Ensure notifications create rule includes: if isAdmin() ||');
          debugPrint('');
        }
      }
      rethrow;
    }
  }

  /// Send notification to users by role (admin targeted broadcast)
  Future<void> sendNotificationByRole({
    required String role, // 'SHG', 'SME', 'PSA', 'ADMIN'
    required String title,
    required String message,
    NotificationType? notificationType,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get users with specific role
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      // Create batch for better performance
      final batch = _firestore.batch();
      int batchCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        final now = DateTime.now().toIso8601String();
        batch.set(notificationRef, {
          'user_id': userDoc.id,
          'title': title,
          'message': message,
          'type': notificationType != null
              ? notificationType.toString().split('.').last
              : 'message',
          'image_url': imageUrl,
          'data': data,
          'is_read': false,
          'created_at': now,
        });

        batchCount++;

        // Firestore batch limit is 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }

      // Commit remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }

      if (kDebugMode) {
        debugPrint(
          '✅ Notification sent to ${usersSnapshot.docs.length} $role users',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending notifications by role: $e');
        debugPrint('   Error type: ${e.runtimeType}');
        if (e.toString().contains('permission')) {
          debugPrint('🚨 FIREBASE PERMISSION DENIED - Check Security Rules!');
        }
      }
      rethrow;
    }
  }

  /// Send notification to a single user (admin direct message)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    NotificationType? notificationType,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _firestore.collection('notifications').add({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': notificationType != null
            ? notificationType.toString().split('.').last
            : 'message',
        'image_url': imageUrl,
        'data': data,
        'is_read': false,
        'created_at': now,
      });

      if (kDebugMode) {
        debugPrint('✅ Notification sent to user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending notification: $e');
      }
      rethrow;
    }
  }
}
