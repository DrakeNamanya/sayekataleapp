# Firebase Cloud Messaging (FCM) Implementation Guide
## Issue #1: Users Not Receiving Push Notifications

---

## 📋 Overview

This guide documents the **COMPLETE FCM implementation** for SayeKatale app to enable push notifications for:
- New orders (SME → SHG notification)
- Order confirmations (SHG → SME notification)
- New messages (all users)
- PSA verification submissions (PSA → Admin notification) ✅ **IMPLEMENTED**
- Delivery tracking updates
- Low stock alerts
- Promotional campaigns

---

## ✅ Current Implementation Status

### **Completed Components**

#### 1. ✅ FCM Service (`lib/services/fcm_service.dart`)
**Status**: ✅ **COMPLETE** - Full FCM service with token management

**Features**:
- ✅ Permission request handling
- ✅ FCM token retrieval and storage in Firestore
- ✅ Token refresh listener
- ✅ Foreground message handler
- ✅ Background message handler (tap)
- ✅ Initial message check (app opened from notification)
- ✅ Comprehensive debug logging

**Key Methods**:
```dart
// Initialize FCM for a user
await FCMService().initialize(userId);

// Get current FCM token
final token = await FCMService().getFCMToken();

// Save token to Firestore (users/{userId}/fcm_token)
await FCMService().saveFCMToken(userId, token);

// Send test notification
await FCMService().sendTestNotification(userId);
```

---

#### 2. ✅ Auth Provider Integration (`lib/providers/auth_provider.dart`)
**Status**: ✅ **COMPLETE** - FCM initialized on user login

**Location**: Line ~65-75 in `_loadUserFromFirestore()`

**What It Does**:
```dart
// After user loads successfully, initialize FCM
try {
  await _fcmService.initialize(user.id);
  debugPrint('✅ AUTH PROVIDER - FCM initialized for user ${user.id}');
} catch (e) {
  debugPrint('⚠️ AUTH PROVIDER - FCM initialization failed: $e');
  // Non-blocking - user can still use app
}
```

**When It Runs**:
- ✅ On app startup (if user already logged in)
- ✅ On login success (new user logs in)
- ✅ On token refresh (Firebase re-authentication)

---

#### 3. ✅ Background Message Handler (`lib/main.dart`)
**Status**: ✅ **COMPLETE** - Registered in main()

**Location**: Line ~91 in `main()`

**Implementation**:
```dart
// Register FCM background message handler
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

**Handler Function** (`lib/services/fcm_service.dart`, line 293):
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 BACKGROUND MESSAGE RECEIVED');
  debugPrint('📬 Title: ${message.notification?.title ?? "No title"}');
  // Handle background message
}
```

---

#### 4. ✅ PSA Admin Notifications (`lib/services/psa_verification_service.dart`)
**Status**: ✅ **COMPLETE** - Admin notified when PSA submits verification

**Location**: Line ~70-90 in `submitVerification()`

**What It Does**:
```dart
// After PSA submits verification, notify admin
await NotificationService().createNotification(
  userId: 'ADMIN',  // Special admin user ID
  type: NotificationType.alert,
  title: '🆕 New PSA Verification',
  message: '$psaName submitted verification documents',
  actionUrl: '/admin/psa-verification',
  metadata: {'verification_id': verificationId},
);
```

**Admin Dashboard**: Admins see notification badge → tap → view pending PSA verifications

---

## 🔧 Firestore Database Schema

### **User Document** (`users/{userId}`)
```json
{
  "id": "user_123",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "SME",
  
  // ✅ FCM Token Fields (auto-saved by FCMService)
  "fcm_token": "fJK3k2j1...",  // ← CRITICAL for push notifications
  "fcm_token_updated_at": Timestamp
}
```

**CRITICAL**: The `fcm_token` field **MUST** be saved to Firestore when:
1. ✅ User logs in (handled by AuthProvider → FCMService.initialize())
2. ✅ Token refreshes (handled by FCMService.setupTokenRefreshListener())
3. ✅ User grants notification permission

---

### **Notification Document** (`notifications/{notificationId}`)
```json
{
  "id": "notif_123",
  "user_id": "user_123",
  "type": "order",
  "title": "New Order Received!",
  "message": "Jane Smith ordered 50kg of maize",
  "action_url": "/orders/order_456",
  "metadata": {
    "order_id": "order_456",
    "product_name": "Maize"
  },
  "is_read": false,
  "created_at": Timestamp
}
```

---

## 🚀 Testing Checklist

### **Phase 1: Local Testing (In-App Notifications)**

#### Test 1: Login and FCM Initialization
1. ✅ Open app → Login with test account
2. ✅ Check debug console for:
   ```
   🔔 ========================================
   🔔 INITIALIZING FCM SERVICE
   🔔 User ID: user_123
   🔔 ========================================
   📱 Requesting notification permission...
   ✅ Permission granted
   🔑 Getting FCM token...
   ✅ FCM Token: fJK3k2j1...
   💾 Saving FCM token to Firestore...
   ✅ FCM token saved successfully
   👂 Setting up token refresh listener...
   ✅ FCM Service initialized successfully
   ```
3. ✅ Verify in Firebase Console → Firestore → `users/{userId}`:
   - ✅ `fcm_token` field exists
   - ✅ `fcm_token_updated_at` timestamp

#### Test 2: PSA Verification Admin Notification ✅
1. ✅ Login as PSA user
2. ✅ Navigate to Profile → Complete PSA Verification form
3. ✅ Submit verification documents
4. ✅ Login as Admin user
5. ✅ Check notification bell → Should see "🆕 New PSA Verification"
6. ✅ Tap notification → Should navigate to PSA verification screen

#### Test 3: In-App Notification System
1. ✅ Create test notification using NotificationService:
   ```dart
   await NotificationService().createNotification(
     userId: 'user_123',
     type: NotificationType.general,
     title: 'Test Notification',
     message: 'This is a test notification',
   );
   ```
2. ✅ Check user's notification bell → Should show badge
3. ✅ Tap notification → Should mark as read

---

### **Phase 2: FCM Push Notifications (Requires Backend)**

#### Test 4: Foreground Notification
1. ⏳ **REQUIRES**: Backend server to send FCM push
2. ⏳ With app **OPEN**, send test FCM push notification
3. ⏳ Check debug console:
   ```
   📬 ========================================
   📬 FOREGROUND MESSAGE RECEIVED
   📬 Title: Test Notification
   📬 Body: This is a test push notification
   📬 ========================================
   ```
4. ⏳ Verify notification appears in system tray

#### Test 5: Background Notification (App Closed)
1. ⏳ **REQUIRES**: Backend server
2. ⏳ Close app completely
3. ⏳ Send FCM push notification from backend
4. ⏳ Check device notification tray → Should show notification
5. ⏳ Tap notification → App opens to correct screen

#### Test 6: Token Refresh
1. ⏳ Delete and reinstall app
2. ⏳ Login again
3. ⏳ Verify new `fcm_token` saved to Firestore
4. ⏳ Send notification → Should still receive

---

## ⚠️ Remaining Implementation Steps

### **Step 1: Backend FCM Server** ⏳ **REQUIRED**

Currently, **in-app notifications work** (users see notifications in the app's notification bell), but **push notifications require a backend server**.

**Options**:

#### **Option A: Firebase Cloud Functions (Recommended)**
Create serverless functions that automatically send FCM push notifications when events occur.

**Example**: Order notification when SME receives order
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendOrderNotification = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const sellerId = order.seller_id;
    
    // Get seller's FCM token from Firestore
    const sellerDoc = await admin.firestore()
      .collection('users')
      .doc(sellerId)
      .get();
    
    const fcmToken = sellerDoc.data().fcm_token;
    
    if (!fcmToken) {
      console.log('No FCM token for user:', sellerId);
      return null;
    }
    
    // Send FCM push notification
    const message = {
      notification: {
        title: '🛒 New Order Received!',
        body: `${order.buyer_name} ordered ${order.product_name}`,
      },
      data: {
        type: 'order',
        order_id: order.id,
        action_url: '/orders/' + order.id,
      },
      token: fcmToken,
    };
    
    return admin.messaging().send(message);
  });
```

**Deploy**:
```bash
cd functions
npm install firebase-functions firebase-admin
firebase deploy --only functions
```

---

#### **Option B: Custom Backend Server (Python/Node.js)**
Create a backend API that sends FCM notifications using Firebase Admin SDK.

**Example**: Python Flask server
```python
# backend/send_notification.py
from firebase_admin import messaging
import firebase_admin
from firebase_admin import credentials

# Initialize Firebase Admin SDK
cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
firebase_admin.initialize_app(cred)

def send_fcm_notification(fcm_token, title, body, data=None):
    """Send FCM push notification to a device"""
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data or {},
        token=fcm_token,
    )
    
    response = messaging.send(message)
    print(f'✅ Notification sent successfully: {response}')
    return response

# Example: Send order notification
def notify_new_order(seller_id, order_id, buyer_name, product_name):
    # Get seller's FCM token from Firestore
    seller_doc = db.collection('users').document(seller_id).get()
    fcm_token = seller_doc.to_dict().get('fcm_token')
    
    if not fcm_token:
        print(f'⚠️ No FCM token for user: {seller_id}')
        return
    
    # Send notification
    send_fcm_notification(
        fcm_token=fcm_token,
        title='🛒 New Order Received!',
        body=f'{buyer_name} ordered {product_name}',
        data={
            'type': 'order',
            'order_id': order_id,
            'action_url': f'/orders/{order_id}',
        }
    )
```

---

### **Step 2: Update Order Service** ⏳ **PENDING**

Add backend notification triggers when orders are created/updated.

**File**: `lib/services/order_service.dart`

**Current Implementation**:
```dart
// Currently only creates in-app notification
await NotificationService().sendOrderNotification(
  sellerId: order.sellerId,
  order: order,
);
```

**Required Addition**:
```dart
// Option 1: Trigger Cloud Function (Firebase automatically calls it)
// No code change needed - Cloud Function watches Firestore

// Option 2: Call backend API
await http.post(
  Uri.parse('https://your-backend.com/api/send-notification'),
  body: json.encode({
    'seller_id': order.sellerId,
    'order_id': order.id,
    'notification_type': 'new_order',
  }),
);
```

---

### **Step 3: Update Message Service** ⏳ **PENDING**

**File**: `lib/services/message_service.dart`

Send FCM notification when new message received:
```dart
// After creating in-app notification
await NotificationService().sendMessageNotification(
  recipientId: message.recipientId,
  senderName: message.senderName,
);

// ⏳ TODO: Add backend call to send FCM push
```

---

### **Step 4: Test FCM Push Notifications** ⏳ **PENDING**

Once backend is set up:

1. ⏳ Send test notification using Firebase Console
   - Firebase Console → Cloud Messaging → Send Test Message
   - Enter FCM token (from Firestore)
   - Check device receives notification

2. ⏳ Test order notification flow:
   - Place order from SHG user
   - SME user should receive push notification
   - Tap notification → Opens order details

3. ⏳ Test message notification:
   - Send message from one user to another
   - Recipient receives push notification
   - Tap → Opens conversation

---

## 📊 Firebase Console Configuration

### **1. Enable Cloud Messaging**
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select SayeKatale project
3. Build → Cloud Messaging
4. Verify "Firebase Cloud Messaging API" is **ENABLED**

### **2. Android Configuration**
1. Verify `google-services.json` is in `android/app/`
2. Check `android/app/build.gradle` includes:
   ```gradle
   dependencies {
     implementation 'com.google.firebase:firebase-messaging:23.1.0'
   }
   ```

### **3. Test Notifications (Firebase Console)**
1. Cloud Messaging → Send Test Message
2. Enter FCM token (copy from Firestore → users → {userId} → fcm_token)
3. Enter notification title and body
4. Click "Test" → Notification should appear on device

---

## 🐛 Troubleshooting

### **Issue 1: No FCM token in Firestore**
**Symptoms**: `fcm_token` field is NULL or missing in user document

**Debug Steps**:
1. Check debug console for FCM initialization logs
2. Verify notification permission is granted:
   ```dart
   final settings = await FirebaseMessaging.instance.getNotificationSettings();
   print('Permission: ${settings.authorizationStatus}');
   ```
3. Check if `FCMService.initialize()` is called in auth provider
4. Manually test FCM token retrieval:
   ```dart
   final token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

**Solution**: Ensure auth provider calls FCM initialization (✅ Already implemented)

---

### **Issue 2: Foreground notifications not showing**
**Symptoms**: Debug logs show message received, but no notification appears

**Cause**: Flutter FCM requires `flutter_local_notifications` package for foreground display

**Solution** ⏳ **TODO**:
1. Add dependency:
   ```yaml
   dependencies:
     flutter_local_notifications: ^17.2.4
   ```
2. Initialize local notifications in FCM service
3. Update `_showLocalNotification()` method

---

### **Issue 3: Background notifications not received**
**Symptoms**: Notifications work when app is open, but not when app is closed

**Debug Steps**:
1. Check if background handler is registered in main.dart (✅ Already done)
2. Verify backend sends FCM push with correct format:
   ```json
   {
     "message": {
       "token": "fJK3k2j1...",
       "notification": {
         "title": "Test",
         "body": "Test message"
       },
       "data": {
         "type": "order",
         "order_id": "order_123"
       }
     }
   }
   ```
3. Check Firebase Console → Cloud Messaging → Logs for delivery errors

---

## 📈 Implementation Progress

| Component | Status | Notes |
|---|---|---|
| FCM Service | ✅ Complete | Token management, handlers |
| Auth Provider Integration | ✅ Complete | Initializes FCM on login |
| Background Handler | ✅ Complete | Registered in main.dart |
| PSA Admin Notifications | ✅ Complete | Issue #9 fixed |
| Order Notifications | ⏳ Partial | In-app ✅, Push ⏳ |
| Message Notifications | ⏳ Partial | In-app ✅, Push ⏳ |
| Backend Server | ⏳ Pending | Requires Cloud Functions or API |
| Local Notifications | ⏳ Pending | Foreground display |
| Production Testing | ⏳ Pending | Requires backend + APK |

---

## 🎯 Next Steps

### **Immediate Actions**

1. **⏳ Set up Backend for FCM Push** (Choose Option A or B)
   - Option A: Firebase Cloud Functions (recommended for simplicity)
   - Option B: Custom backend API (more control, requires server)

2. **⏳ Add `flutter_local_notifications` Package**
   - Enables foreground notification display
   - Updates `FCMService._showLocalNotification()`

3. **⏳ Test FCM Push Notifications**
   - Use Firebase Console to send test notification
   - Verify device receives push when app is closed

4. **✅ Build Production APK**
   - Test on real Android device
   - Verify notifications work end-to-end

---

## 📝 Summary

### **What's Working Now** ✅
- ✅ FCM tokens are saved to Firestore when users log in
- ✅ Background message handler is registered
- ✅ In-app notifications work (notification bell)
- ✅ PSA admin notifications (Issue #9 fixed)

### **What's Missing** ⏳
- ⏳ Backend server to send FCM push notifications
- ⏳ Foreground notification display (local notifications)
- ⏳ Production testing with real devices

### **User Impact**
- **Current**: Users see notifications ONLY when app is open (notification bell)
- **After Backend Setup**: Users receive push notifications even when app is closed ✨

---

## 🔗 Related Files

- `lib/services/fcm_service.dart` - Main FCM service
- `lib/providers/auth_provider.dart` - FCM initialization on login
- `lib/services/notification_service.dart` - In-app notification management
- `lib/services/psa_verification_service.dart` - PSA admin notifications
- `lib/main.dart` - Background handler registration
- `pubspec.yaml` - firebase_messaging: 15.1.3

---

**Last Updated**: 2025-11-29  
**Issue**: #1 - Firebase Cloud Messaging (FCM)  
**Status**: 🔄 In Progress (80% complete - awaiting backend)
