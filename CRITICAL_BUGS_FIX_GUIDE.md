# 🐛 Critical Bugs Fix Guide - SayeKatale App

## 📋 Issue Summary

This document addresses 10 critical bugs identified in the SayeKatale application based on user testing and screenshots.

---

## 🔴 **Issue #1: Users Not Receiving Push Notifications**

### **Problem**:
- Users are not receiving push notifications for orders, messages, or updates
- Firebase Cloud Messaging (FCM) not working properly

### **Root Cause**:
- FCM token not being generated/stored correctly
- Background message handling not implemented
- Notification permissions not requested

### **Solution**:

1. **Update `pubspec.yaml` - Firebase Messaging**:
```yaml
dependencies:
  firebase_messaging: 15.1.3
  flutter_local_notifications: ^17.2.2  # Add this
```

2. **Create `lib/services/notification_service.dart`**:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize(String userId) async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFCMToken(userId, token);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveFCMToken(userId, newToken);
    });
    
    // Initialize local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(settings);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }
  
  Future<void> _saveFCMToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'fcmToken': token});
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
```

3. **Update `main.dart` to handle background messages**:
```dart
// Add at top level (outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}
```

4. **Initialize notification service after login**:
```dart
// In AuthProvider after successful login
await NotificationService().initialize(user.id);
```

---

## 🔴 **Issue #2: SME Purchase Receipts Not Showing**

### **Problem**:
- After delivery confirmation, receipts don't appear in "My Receipts"
- Message shows "No purchase receipts yet"
- Test user: Abbey Rukundo

### **Root Cause**:
- Receipt document not being created in Firestore after delivery confirmation
- Wrong field name or collection query

### **Solution**:

1. **Check receipt creation logic** in order service:
```bash
cd /home/user/flutter_app
grep -A 20 "confirmDelivery\|createReceipt" lib/services/order_service.dart
```

2. **Fix receipt creation** (add this method if missing):
```dart
Future<void> createPurchaseReceipt(String orderId) async {
  final order = await _firestore.collection('orders').doc(orderId).get();
  if (!order.exists) return;
  
  final orderData = order.data()!;
  
  // Create receipt
  await _firestore.collection('receipts').add({
    'orderId': orderId,
    'buyerId': orderData['buyerId'],
    'sellerId': orderData['sellerId'],
    'productName': orderData['productName'],
    'totalAmount': orderData['totalAmount'],
    'deliveryDate': FieldValue.serverTimestamp(),
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

3. **Update delivery confirmation to create receipt**:
```dart
Future<void> confirmDelivery(String orderId) async {
  await _firestore.collection('orders').doc(orderId).update({
    'status': 'delivered',
    'deliveredAt': FieldValue.serverTimestamp(),
  });
  
  // CREATE RECEIPT
  await createPurchaseReceipt(orderId);
}
```

4. **Fix receipts query** in SME receipts screen:
```dart
Stream<List<Receipt>> getUserReceipts(String userId) {
  return _firestore
      .collection('receipts')
      .where('buyerId', isEqualTo: userId)  // Correct field name
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Receipt.fromFirestore(doc.data(), doc.id))
          .toList());
}
```

---

## 🟡 **Issue #3: Distance Shows "0m away"**

### **Problem**:
- All products show "Distance: 0m away"
- Should calculate distance between SME location and SHG product location

### **Root Cause**:
- Distance calculation not implemented
- GPS coordinates not being compared

### **Solution**:

1. **Add Geolocator utility method** in `lib/utils/location_helper.dart`:
```dart
import 'dart:math';

class LocationHelper {
  /// Calculate distance between two GPS coordinates in meters
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const earthRadius = 6371000; // meters
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
        cos(_toRadians(lat2)) *
        sin(dLon / 2) *
        sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m away';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km away';
    }
  }
}
```

2. **Update product card to calculate distance**:
```dart
// Get current user location
final userLat = authProvider.currentUser?.location?.latitude ?? 0.0;
final userLon = authProvider.currentUser?.location?.longitude ?? 0.0;

// Get product location
final productLat = product.farmLocation?.latitude ?? 0.0;
final productLon = product.farmLocation?.longitude ?? 0.0;

// Calculate distance
final distance = LocationHelper.calculateDistance(
  userLat, userLon,
  productLat, productLon,
);

// Display
Text(LocationHelper.formatDistance(distance));
```

---

## 🔴 **Issue #4: Track Delivery Not Working**

### **Problem**:
- Track delivery feature doesn't work
- Users can't see delivery status or location

### **Root Cause**:
- Real-time tracking not implemented
- Order status updates not being reflected

### **Solution**:

1. **Create delivery tracking screen** with real-time updates:
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final order = snapshot.data!;
    final status = order['status'];
    
    return DeliveryTrackingWidget(
      status: status,
      estimatedDelivery: order['estimatedDelivery'],
      currentLocation: order['deliveryLocation'],
    );
  },
);
```

---

## 🔴 **Issue #5: App Not Showing Notifications When Closed**

### **Problem**:
- When app is closed, notifications don't appear on device
- Users miss orders and messages

### **Root Cause**:
- Background notification handling not configured
- Android notification channel not set up

### **Solution**:

1. **Update `android/app/src/main/AndroidManifest.xml`**:
```xml
<manifest>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  
  <application>
    <!-- Add notification metadata -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="default_channel" />
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@mipmap/ic_launcher" />
  </application>
</manifest>
```

2. **Create notification channel on app start**:
```dart
// In main.dart initState
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel',
  'Default Notifications',
  importance: Importance.high,
);

await FlutterLocalNotificationsPlugin()
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
```

---

## 🟡 **Issue #6: Web App Domain Setup**

### **Problem**:
- Need custom domain for web app access
- Currently using long generated URLs

### **Solution**:

**This is a deployment/infrastructure task:**

1. Purchase domain (e.g., `sayekatale.com`)
2. Configure DNS settings to point to hosting
3. Deploy Flutter web app to hosting (Firebase Hosting, Netlify, Vercel)
4. Set up SSL certificate
5. Update Firebase console with authorized domain

**Not a code fix - requires manual setup**

---

## 🔴 **Issue #7: Logout Shows Black Screen with Loading**

**Status**: ✅ **ALREADY FIXED**

See commit `f2a73e7` - Logout now shows "Logging out..." dialog

If still occurring:
- Clear app cache
- Rebuild app
- Check for navigation conflicts

---

## 🔴 **Issue #8: Registration Error - "Email already registered" + Black Screen**

### **Problem**:
- New user tries to register
- Gets "Email already registered, please login"
- Then shows black screen with green loading circle

### **Root Cause**:
- Error handling not redirecting properly
- Loading state not being cleared after error

### **Solution**:

**Find registration screen**:
```bash
grep -r "Email already registered" lib/screens/
```

**Fix error handling** in registration screen:
```dart
try {
  await authProvider.register(...);
} on FirebaseAuthException catch (e) {
  // IMPORTANT: Clear loading state FIRST
  setState(() {
    _isLoading = false;
  });
  
  String errorMessage;
  if (e.code == 'email-already-in-use') {
    errorMessage = 'Email already registered. Please login instead.';
    
    // Navigate to login screen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  } else {
    errorMessage = 'Registration failed: ${e.message}';
    
    // Show error dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Registration Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
```

---

## 🔴 **Issue #9: PSA Approval - Admin Not Receiving Submissions**

### **Problem**:
- PSA submits verification documents
- Admin doesn't receive notification
- Documents not appearing in admin dashboard

### **Root Cause**:
- PSA verification submission not creating admin notification
- Admin query not fetching pending PSA verifications

### **Solution**:

1. **Add admin notification when PSA submits**:
```dart
// In PSA verification submission
await FirebaseFirestore.instance.collection('psa_verifications').doc(userId).set({
  'userId': userId,
  'status': 'pending',
  'submittedAt': FieldValue.serverTimestamp(),
  ...documents
});

// CREATE ADMIN NOTIFICATION
await FirebaseFirestore.instance.collection('admin_notifications').add({
  'type': 'psa_verification',
  'userId': userId,
  'userName': userName,
  'message': 'New PSA verification submitted',
  'status': 'unread',
  'createdAt': FieldValue.serverTimestamp(),
});
```

2. **Add admin dashboard query** for pending verifications:
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('psa_verifications')
      .where('status', isEqualTo: 'pending')
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final pendingPSAs = snapshot.data!.docs;
    
    return ListView.builder(
      itemCount: pendingPSAs.length,
      itemBuilder: (context, index) {
        final psa = pendingPSAs[index];
        return PSAVerificationCard(psa: psa);
      },
    );
  },
);
```

---

## 🔴 **Issue #10: Account Deletion Error**

### **Problem**:
- Delete account shows error: "An error occurred. Please try again or contact support"
- Account is not deleted

### **Root Cause**:
- Re-authentication check may be failing
- Firebase Auth requires recent login for account deletion

### **Solution**:

**The code is correct but needs recent login. Add better error handling**:

1. **Update account deletion dialog** to handle specific errors:
```dart
// In account_deletion_dialog.dart line 115
String _getErrorMessage(String error) {
  if (error.contains('requires-recent-login')) {
    return 'For security, please logout and login again (within last 5 minutes) before deleting your account.';
  } else if (error.contains('wrong-password')) {
    return 'Incorrect password. Please try again.';
  } else if (error.contains('network')) {
    return 'Network error. Please check your connection.';
  } else if (error.contains('permission-denied')) {
    return 'Permission denied. Please ensure you have proper authentication.';
  } else {
    return 'Error: $error\n\nPlease try:\n1. Logout and login again\n2. Check your internet connection\n3. Contact support if issue persists';
  }
}
```

2. **Add re-login prompt**:
```dart
// Before delete attempt, check last sign-in time
if (_needsReauth) {
  final lastSignIn = FirebaseAuth.instance.currentUser?.metadata.lastSignInTime;
  final now = DateTime.now();
  
  if (lastSignIn != null && now.difference(lastSignIn).inMinutes > 5) {
    // Require re-login
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Re-login Required'),
        content: Text('For security, please logout and login again before deleting your account.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close deletion dialog
              // Logout
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Logout & Re-login'),
          ),
        ],
      ),
    );
    return;
  }
}
```

---

## 🎯 Implementation Priority

### **High Priority (Fix Immediately)**:
1. ✅ Issue #7: Logout black screen - ALREADY FIXED
2. 🔴 Issue #8: Registration error + black screen
3. 🔴 Issue #10: Account deletion error
4. 🔴 Issue #2: Purchase receipts not showing
5. 🔴 Issue #9: PSA admin approval workflow

### **Medium Priority (Fix Soon)**:
6. 🔴 Issue #1: Push notifications
7. 🔴 Issue #4: Track delivery
8. 🔴 Issue #5: Background notifications
9. 🟡 Issue #3: Distance calculation

### **Low Priority (Enhancement)**:
10. 🟡 Issue #6: Web domain setup (infrastructure task)

---

## 📝 Testing Checklist

After implementing fixes, test:

- [ ] Push notifications (foreground and background)
- [ ] SME receipts after delivery confirmation (Abbey Rukundo account)
- [ ] Distance calculation on browse products
- [ ] Track delivery status updates
- [ ] Background notifications when app closed
- [ ] Logout flow (no black screen)
- [ ] Registration with existing email
- [ ] PSA verification submission to admin
- [ ] Account deletion with recent login

---

## 🚀 Quick Fix Commands

```bash
# Pull latest code
cd /home/user/flutter_app
git pull origin main

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Build and test
flutter build web --release
```

---

**Last Updated**: 2025-01-28  
**Status**: Documentation Complete - Implementation Pending
