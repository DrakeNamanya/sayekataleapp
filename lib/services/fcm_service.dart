import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import 'notification_service.dart';

/// Firebase Cloud Messaging Service
/// Handles FCM token management and push notifications
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize FCM service for a user
  Future<void> initialize(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔔 ========================================');
        debugPrint('🔔 INITIALIZING FCM SERVICE');
        debugPrint('🔔 User ID: $userId');
        debugPrint('🔔 ========================================');
      }

      // Step 1: Request permission
      final permissionGranted = await requestPermission();
      if (!permissionGranted) {
        if (kDebugMode) {
          debugPrint('⚠️ FCM Permission denied by user');
        }
        return;
      }

      // Step 2: Get FCM token
      final token = await getFCMToken();
      if (token != null) {
        // Step 3: Save token to Firestore
        await saveFCMToken(userId, token);

        // Step 4: Listen for token refresh
        setupTokenRefreshListener(userId);

        // Step 5: Setup message handlers
        setupMessageHandlers();

        if (kDebugMode) {
          debugPrint('✅ FCM Service initialized successfully');
          debugPrint('🔔 ========================================');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to get FCM token');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing FCM: $e');
        debugPrint('📍 Stack trace: $stackTrace');
      }
    }
  }

  // ============================================================================
  // PERMISSION HANDLING
  // ============================================================================

  /// Request notification permission from user
  Future<bool> requestPermission() async {
    try {
      if (kDebugMode) {
        debugPrint('📱 Requesting notification permission...');
      }

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (kDebugMode) {
        debugPrint('📱 Permission status: ${settings.authorizationStatus}');
        debugPrint(granted ? '✅ Permission granted' : '❌ Permission denied');
      }

      return granted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error requesting permission: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // TOKEN MANAGEMENT
  // ============================================================================

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      if (kDebugMode) {
        debugPrint('🔑 Getting FCM token...');
      }

      final token = await _messaging.getToken();

      if (kDebugMode) {
        if (token != null) {
          debugPrint('✅ FCM Token: ${token.substring(0, 20)}...');
        } else {
          debugPrint('⚠️ FCM Token is null');
        }
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Save FCM token to Firestore
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      if (kDebugMode) {
        debugPrint('💾 Saving FCM token to Firestore...');
        debugPrint('   User ID: $userId');
        debugPrint('   Token: ${token.substring(0, 20)}...');
      }

      await _firestore.collection('users').doc(userId).update({
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ FCM token saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving FCM token: $e');
      }
      // Don't throw - token saving failure shouldn't block app
    }
  }

  /// Setup listener for token refresh
  void setupTokenRefreshListener(String userId) {
    if (kDebugMode) {
      debugPrint('👂 Setting up token refresh listener...');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        debugPrint('🔄 FCM Token refreshed');
        debugPrint('   New token: ${newToken.substring(0, 20)}...');
      }
      saveFCMToken(userId, newToken);
    });
  }

  // ============================================================================
  // MESSAGE HANDLERS
  // ============================================================================

  /// Setup foreground and background message handlers
  void setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('📬 ========================================');
        debugPrint('📬 FOREGROUND MESSAGE RECEIVED');
        debugPrint('📬 Title: ${message.notification?.title ?? "No title"}');
        debugPrint('📬 Body: ${message.notification?.body ?? "No body"}');
        debugPrint('📬 Data: ${message.data}');
        debugPrint('📬 ========================================');
      }

      // Show local notification when app is in foreground
      _showLocalNotification(message);
    });

    // Handle background message taps (when user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('🔔 ========================================');
        debugPrint('🔔 NOTIFICATION TAPPED (Background)');
        debugPrint('🔔 Title: ${message.notification?.title ?? "No title"}');
        debugPrint('🔔 Data: ${message.data}');
        debugPrint('🔔 ========================================');
      }

      _handleNotificationTap(message);
    });

    // Check for initial message (app opened from terminated state)
    _checkInitialMessage();
  }

  /// Show local notification (for foreground messages)
  void _showLocalNotification(RemoteMessage message) {
    // This will be handled by flutter_local_notifications
    // For now, just create in-app notification
    if (message.data['user_id'] != null) {
      // Already handled by in-app notification system
      if (kDebugMode) {
        debugPrint('ℹ️ Foreground notification - check notification bell');
      }
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on notification data
    final actionUrl = message.data['action_url'] as String?;
    if (kDebugMode) {
      debugPrint('🔗 Action URL: ${actionUrl ?? "None"}');
    }

    // Navigation will be handled by the app's routing system
    // You can use a notification tap stream to handle this
  }

  /// Check for initial message (app opened from terminated state)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      if (kDebugMode) {
        debugPrint('🔔 ========================================');
        debugPrint('🔔 APP OPENED FROM NOTIFICATION (Terminated)');
        debugPrint('🔔 Title: ${initialMessage.notification?.title ?? "No title"}');
        debugPrint('🔔 Data: ${initialMessage.data}');
        debugPrint('🔔 ========================================');
      }

      _handleNotificationTap(initialMessage);
    }
  }

  // ============================================================================
  // TESTING
  // ============================================================================

  /// Test notification - sends a test push notification to current device
  Future<void> sendTestNotification(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Sending test notification to user: $userId');
      }

      // This would typically be done through your backend
      // For now, just create an in-app notification
      await _notificationService.createNotification(
        userId: userId,
        type: NotificationType.general,
        title: '🧪 Test Notification',
        message: 'This is a test notification. FCM is working!',
      );

      if (kDebugMode) {
        debugPrint('✅ Test notification created');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending test notification: $e');
      }
    }
  }
}

// ============================================================================
// BACKGROUND MESSAGE HANDLER (Top-level function)
// ============================================================================

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('📬 ========================================');
    debugPrint('📬 BACKGROUND MESSAGE RECEIVED');
    debugPrint('📬 Title: ${message.notification?.title ?? "No title"}');
    debugPrint('📬 Body: ${message.notification?.body ?? "No body"}');
    debugPrint('📬 Data: ${message.data}');
    debugPrint('📬 ========================================');
  }

  // Handle background message
  // This runs in a separate isolate, so you have limited access to app state
}
