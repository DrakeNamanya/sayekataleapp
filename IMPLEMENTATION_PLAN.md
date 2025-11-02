# 📋 SayeKatale - Notifications & Messaging Implementation Plan

## 🎯 Objective
Implement complete notifications and messaging system to make SayeKatale production-ready for farmers, buyers, and suppliers.

---

## 📊 Current Status Analysis

### ✅ **What We Have:**
1. **Models Defined:**
   - `Message` model with conversation support
   - `Conversation` model for chat management
   - `AppNotification` model with 7 notification types
   - Enum types and extensions

2. **Placeholder Screens:**
   - SHG Messages Screen
   - SME Messages Screen
   - PSA Messages Screen
   - SHG Notifications Screen
   - SME Notifications Screen
   - PSA Notifications Screen

3. **Firebase Package:**
   - `firebase_messaging: 15.1.3` installed
   - Ready for FCM integration

### ❌ **What's Missing:**
1. **Services:**
   - MessageService (for chat functionality)
   - NotificationService (for in-app notifications)
   - FCM Service (for push notifications)

2. **Functionality:**
   - Real-time chat
   - Conversation management
   - Notification delivery
   - Push notifications
   - Unread counters

---

## 🔧 Implementation Components

### **Component 1: Firebase Cloud Messaging (FCM) Setup**

**Files to Create/Modify:**
1. `lib/services/fcm_service.dart` - FCM initialization and handlers
2. `lib/main.dart` - Initialize FCM on app start
3. Update Firebase configuration for cloud messaging

**Key Features:**
- Device token registration
- Foreground notification handling
- Background notification handling
- Notification click actions
- Topic subscriptions (for broadcast notifications)

**Firebase Console Setup:**
- Enable Cloud Messaging API
- Configure notification settings
- Set up server key for backend

---

### **Component 2: Notification System**

**Files to Create:**
1. `lib/services/notification_service.dart` - Notification CRUD operations
2. `lib/providers/notification_provider.dart` - State management
3. Update notification screens (SHG, SME, PSA)
4. `lib/widgets/notification_card.dart` - Reusable notification card

**Firestore Collections:**
```
notifications/
  {notification_id}/
    user_id: string
    type: string (order|payment|message|delivery|promotion|alert|general)
    title: string
    message: string
    action_url: string (optional)
    related_id: string (optional - order_id, message_id, etc.)
    is_read: boolean
    created_at: timestamp
```

**Notification Triggers:**
- New order placed → Notify seller
- Order status updated → Notify buyer
- Order delivered → Notify buyer
- Payment received → Notify seller
- New message → Notify recipient
- Low stock alert → Notify seller (PSA)

---

### **Component 3: In-App Messaging System**

**Files to Create:**
1. `lib/services/message_service.dart` - Message CRUD and streaming
2. `lib/providers/message_provider.dart` - State management
3. Update message screens:
   - `lib/screens/common/conversation_list_screen.dart` - Conversation list
   - `lib/screens/common/chat_screen.dart` - Individual chat
4. `lib/widgets/message_bubble.dart` - Chat message widget
5. `lib/widgets/conversation_tile.dart` - Conversation list tile

**Firestore Collections:**
```
conversations/
  {conversation_id}/
    participant_ids: array[string]
    participant_names: map{user_id: name}
    last_message: string
    last_message_time: timestamp
    unread_count: map{user_id: count}
    created_at: timestamp
    updated_at: timestamp

messages/
  {message_id}/
    conversation_id: string
    sender_id: string
    sender_name: string
    content: string
    type: string (text|image|file|location)
    attachment_url: string (optional)
    is_read: boolean
    created_at: timestamp
```

**Message Features:**
- Real-time message streaming
- Conversation creation (auto-create on first message)
- Unread message counters
- Message read status
- Typing indicators (future enhancement)
- File attachments (future enhancement)

---

## 📝 Detailed Implementation Steps

### **Phase 1: Push Notifications (Priority: CRITICAL)**

#### **Step 1.1: Configure Firebase Cloud Messaging**

**1. Update `android/app/build.gradle` (if needed):**
```gradle
// Already configured with firebase packages
```

**2. Create FCM Service:**
```dart
// lib/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  
  Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission();
    
    // Get FCM token
    _fcmToken = await _messaging.getToken();
    
    // Save token to Firestore user document
    // Configure handlers
  }
  
  // Foreground message handler
  // Background message handler
  // Notification click handler
}
```

**3. Update `main.dart`:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize FCM
  await FCMService().initialize();
  
  runApp(const MyApp());
}
```

#### **Step 1.2: Implement Notification Triggers**

**Trigger Points:**
1. **New Order Created:**
   - After `OrderService.placeOrdersFromCart()`
   - Send notification to seller

2. **Order Status Updated:**
   - After `OrderService.updateOrderStatus()`
   - Send notification to buyer

3. **New Message Received:**
   - After `MessageService.sendMessage()`
   - Send notification to recipient

**Implementation:**
```dart
// In OrderService
Future<void> _sendOrderNotification(Order order, String type) async {
  final notification = AppNotification(
    id: Uuid().v4(),
    userId: type == 'new_order' ? order.farmerId : order.buyerId,
    type: NotificationType.order,
    title: type == 'new_order' ? 'New Order Received' : 'Order Updated',
    message: '...',
    relatedId: order.id,
    isRead: false,
    createdAt: DateTime.now(),
  );
  
  await NotificationService().createNotification(notification);
}
```

---

### **Phase 2: Notification Service & UI (Priority: CRITICAL)**

#### **Step 2.1: Create NotificationService**

**File: `lib/services/notification_service.dart`**

**Key Methods:**
```dart
class NotificationService {
  // Create notification
  Future<String> createNotification(AppNotification notification);
  
  // Stream user notifications
  Stream<List<AppNotification>> streamUserNotifications(String userId);
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId);
  
  // Mark all as read
  Future<void> markAllAsRead(String userId);
  
  // Delete notification
  Future<void> deleteNotification(String notificationId);
  
  // Get unread count
  Future<int> getUnreadCount(String userId);
}
```

#### **Step 2.2: Update Notification Screens**

**Convert placeholder screens to functional:**
1. Show list of notifications (StreamBuilder)
2. Display notification icon based on type
3. Mark as read on tap
4. Navigate to related content (orders, messages, etc.)
5. Pull-to-refresh
6. Empty state when no notifications

**UI Components:**
- Notification card with icon, title, message, timestamp
- Unread indicator (blue dot)
- Swipe to delete
- Filter by type (optional)

---

### **Phase 3: Messaging System (Priority: CRITICAL)**

#### **Step 3.1: Create MessageService**

**File: `lib/services/message_service.dart`**

**Key Methods:**
```dart
class MessageService {
  // Create or get conversation between two users
  Future<Conversation> getOrCreateConversation(
    String user1Id, String user1Name,
    String user2Id, String user2Name
  );
  
  // Stream conversations for user
  Stream<List<Conversation>> streamUserConversations(String userId);
  
  // Send message
  Future<String> sendMessage(Message message);
  
  // Stream messages in conversation
  Stream<List<Message>> streamConversationMessages(String conversationId);
  
  // Mark messages as read
  Future<void> markMessagesAsRead(
    String conversationId, String userId
  );
  
  // Get unread count
  Future<int> getUnreadCount(String userId);
}
```

#### **Step 3.2: Build Chat Screens**

**A. Conversation List Screen:**
```dart
// lib/screens/common/conversation_list_screen.dart

- Show all user conversations
- Display last message and timestamp
- Show unread count badge
- Real-time updates (StreamBuilder)
- Search conversations
- Pull-to-refresh
- Empty state
```

**B. Chat Screen:**
```dart
// lib/screens/common/chat_screen.dart

- Display conversation messages
- Message bubbles (sent/received styling)
- Text input with send button
- Real-time message streaming
- Auto-scroll to latest
- Show read status
- Typing indicator (optional)
- Attachment button (future)
```

#### **Step 3.3: Integration Points**

**Where Users Can Start Conversations:**
1. **From Order Details:**
   - "Contact Seller" button → Opens chat with seller
   - "Contact Buyer" button → Opens chat with buyer

2. **From Product Details:**
   - "Message Seller" button → Opens chat with product seller

3. **From Messages Tab:**
   - "New Message" button → Select user and start chat

---

## 🔄 Data Flow Diagrams

### **Notification Flow:**
```
Event Occurs (New Order)
    ↓
OrderService creates notification
    ↓
Save to Firestore (notifications collection)
    ↓
FCM sends push notification to device
    ↓
User sees notification banner
    ↓
User taps → Navigate to order details
```

### **Messaging Flow:**
```
User A wants to message User B
    ↓
Check if conversation exists
    ↓
If not, create conversation
    ↓
User A types message
    ↓
MessageService.sendMessage()
    ↓
Save to Firestore (messages collection)
    ↓
Update conversation (last_message, unread_count)
    ↓
FCM sends push notification to User B
    ↓
User B sees message in real-time (StreamBuilder)
```

---

## 🧪 Testing Plan

### **Notification Testing:**
1. ✅ Create order → Check seller receives notification
2. ✅ Update order status → Check buyer receives notification
3. ✅ Tap notification → Verify navigation to order details
4. ✅ Mark as read → Verify unread count decreases
5. ✅ Test foreground notifications
6. ✅ Test background notifications
7. ✅ Test notification when app is closed

### **Messaging Testing:**
1. ✅ Send message between SHG and SME
2. ✅ Send message between SHG and PSA
3. ✅ Verify real-time message delivery
4. ✅ Check unread counter updates
5. ✅ Test mark as read functionality
6. ✅ Test conversation list updates
7. ✅ Test message from order details button

---

## ⏱️ Time Estimates

### **Phase 1: Push Notifications**
- FCM Configuration: 2 hours
- Service Implementation: 3 hours
- Testing: 2 hours
- **Total: 7 hours (1 day)**

### **Phase 2: Notification System**
- NotificationService: 3 hours
- UI Screens: 4 hours
- Integration: 2 hours
- Testing: 2 hours
- **Total: 11 hours (1.5 days)**

### **Phase 3: Messaging System**
- MessageService: 4 hours
- Conversation List: 4 hours
- Chat Screen: 6 hours
- Integration Points: 3 hours
- Testing: 3 hours
- **Total: 20 hours (2.5 days)**

### **Grand Total: 38 hours (5 days)**

---

## 📦 Dependencies

### **Additional Packages Needed:**
```yaml
dependencies:
  # Already installed
  firebase_messaging: 15.1.3
  
  # Need to add
  flutter_local_notifications: ^17.0.0  # For foreground notifications
  uuid: ^4.0.0  # For generating IDs
```

---

## 🚀 Deployment Checklist

### **Before Production:**
- [ ] Test notifications on physical devices (iOS/Android)
- [ ] Verify FCM token registration
- [ ] Test background notification handling
- [ ] Ensure notification permissions requested properly
- [ ] Test message delivery and real-time updates
- [ ] Verify unread counters accuracy
- [ ] Test notification click actions
- [ ] Performance test with multiple conversations
- [ ] Security rules for notifications and messages collections
- [ ] Error handling for failed notifications

---

## 🎯 Success Criteria

### **Notifications:**
- ✅ Users receive push notifications for all critical events
- ✅ Notifications appear in notification center
- ✅ Tapping notification navigates to relevant screen
- ✅ Unread count displays correctly on dashboard
- ✅ Mark as read functionality works
- ✅ Notifications persist across app restarts

### **Messaging:**
- ✅ Users can send/receive messages in real-time
- ✅ Conversation list updates automatically
- ✅ Unread message count is accurate
- ✅ Messages marked as read when viewed
- ✅ Users can start conversations from orders/products
- ✅ Chat history persists
- ✅ Messages display with correct styling (sent/received)

---

## 📞 Support & Resources

### **Firebase Documentation:**
- [Firebase Cloud Messaging for Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Firestore Real-time Updates](https://firebase.google.com/docs/firestore/query-data/listen)
- [Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)

### **Best Practices:**
- Keep notifications concise and actionable
- Use appropriate notification icons and colors
- Handle notification permissions gracefully
- Implement notification channels (Android 8+)
- Test on different Android versions
- Respect user notification preferences

---

## ✅ Next Steps

**Immediate:**
1. Start with Phase 1 (Push Notifications) - Most critical
2. Then Phase 2 (Notification System) - Core functionality
3. Finally Phase 3 (Messaging System) - User engagement

**After Implementation:**
4. Comprehensive testing
5. Bug fixes
6. Performance optimization
7. Production deployment

---

**🔔 Ready to implement notifications and messaging for SayeKatale! 🔔**
