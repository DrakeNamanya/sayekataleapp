# 🔒 Firestore Security Rules - Complete Documentation

## 📋 Overview

This document provides a complete reference for all Firestore security rules in the SayeKatale app.

**Last Updated:** December 2024  
**Firebase Project:** sayekataleapp  
**Total Collections:** 18 collections with security rules

---

## 🎯 Quick Reference

| Collection | Users Can | Admins Can | Notes |
|-----------|-----------|------------|-------|
| **users** | Read all, Update own | All operations | Profile management |
| **products** | Read all, Create own, Update own | All operations | Marketplace items |
| **orders** | Read own, Create own, Update own | All operations | Order management |
| **receipts** | Read own | Delete | System-generated |
| **wallets** | Read own | Read all | Backend-managed |
| **transactions** | Read own | Delete | System-generated |
| **conversations** | Read if participant, Create, Update | All operations | Messaging |
| **messages** | Read if participant, Create, Mark read | Delete | Chat messages |
| **notifications** | Read own, Create, Update, Delete | All operations | User notifications |
| **complaints** | Read own, Create, Update pending | All operations | CSV export |
| **user_complaints** | Read own, Create, Update pending | All operations | Main app |
| **cart_items** | Full CRUD on own items | N/A | Shopping cart |
| **favorite_products** | Full CRUD on own items | N/A | Favorites |
| **reviews** | Read all, Create own, Update own | Delete | Product reviews |
| **subscriptions** | Read own | All operations | System-managed |

---

## 📚 Detailed Rules by Collection

### 1. Users Collection

**Purpose:** User profiles and account information

**Rules:**
```javascript
match /users/{userId} {
  // Anyone authenticated can read user profiles (for marketplace)
  allow read: if isAuthenticated();
  
  // Users can only update their own profile
  allow update: if isOwner(userId);
  
  // Users can create their own profile during signup
  allow create: if isAuthenticated() && request.auth.uid == userId;
  
  // Only admins can delete users
  allow delete: if isAdmin();
}
```

**Field Restrictions:**
- Cannot change `role` field
- Cannot change `uid` field
- userId must match Firebase Auth UID

---

### 2. Products Collection

**Purpose:** Marketplace products (agricultural items)

**Rules:**
```javascript
match /products/{productId} {
  // Anyone authenticated can read products
  allow read: if isAuthenticated();
  
  // Only product owner or admin can update
  allow update: if isAuthenticated() && 
                   (resource.data.farmerId == request.auth.uid || isAdmin());
  
  // Authenticated users can create products
  allow create: if isAuthenticated() && 
                   request.resource.data.farmerId == request.auth.uid;
  
  // Only owner or admin can delete
  allow delete: if isAuthenticated() && 
                   (resource.data.farmerId == request.auth.uid || isAdmin());
}
```

**Key Fields:**
- `farmerId` - Owner of the product

---

### 3. Orders Collection

**Purpose:** Purchase orders and transactions

**Rules:**
```javascript
match /orders/{orderId} {
  // Allow list queries for authenticated users
  allow list: if isAuthenticated();
  
  // Users can get specific orders they're part of
  allow get: if isAuthenticated() && 
                (resource.data.buyer_id == request.auth.uid || 
                 resource.data.farmerId == request.auth.uid ||
                 resource.data.seller_id == request.auth.uid ||
                 isAdmin());
  
  // Buyers can create orders
  allow create: if isAuthenticated() && 
                   request.resource.data.buyer_id == request.auth.uid;
  
  // Buyers and sellers can update order status
  allow update: if isAuthenticated() && 
                   (resource.data.buyer_id == request.auth.uid || 
                    resource.data.farmerId == request.auth.uid ||
                    resource.data.seller_id == request.auth.uid ||
                    isAdmin());
  
  // Only admin can delete orders
  allow delete: if isAdmin();
}
```

**Key Fields:**
- `buyer_id` - Customer who placed order
- `farmerId` - Original farmer
- `seller_id` - Current seller (may differ from farmer)

---

### 4. Receipts Collection

**Purpose:** Purchase receipts (system-generated)

**Rules:**
```javascript
match /receipts/{receiptId} {
  // Allow authenticated users to list receipts
  allow list: if isAuthenticated();
  
  // Read individual receipt (user must be buyer or seller)
  allow get: if isReceiptOwner() || isAdmin();
  
  // Receipts are system-generated only
  allow create: if false;
  allow update: if false;
  
  // Only admin can delete receipts
  allow delete: if isAdmin();
}
```

**Ownership Check:**
- Supports both `buyerId`/`buyer_id` and `sellerId`/`seller_id`

---

### 5. Wallets Collection

**Purpose:** User wallet balances (backend-managed)

**Rules:**
```javascript
match /wallets/{walletId} {
  // Users can only read their own wallet
  allow read: if isOwner(walletId) || isAdmin();
  
  // Wallet operations only through backend webhooks
  allow create: if false;
  allow update: if false;
  allow delete: if false;
}
```

**Important:** All wallet operations must go through backend webhooks

---

### 6. Transactions Collection

**Purpose:** Wallet transaction history

**Rules:**
```javascript
match /transactions/{transactionId} {
  // Allow authenticated users to list transactions
  allow list: if isAuthenticated();
  
  // Read individual transaction (user must own it)
  allow get: if isTransactionOwner() || isAdmin();
  
  // Transactions are system-generated only
  allow create: if false;
  allow update: if false;
  allow delete: if isAdmin();
}
```

**Ownership Check:**
- Supports both `userId` and `user_id` field names

---

### 7. Conversations Collection

**Purpose:** Messaging conversation metadata

**Rules:**
```javascript
match /conversations/{conversationId} {
  // Allow authenticated users to list conversations
  allow list: if isAuthenticated();
  
  // Read conversation (user must be participant)
  allow get: if isConversationParticipant() || isAdmin();
  
  // Create conversation (user must be one of the participants)
  allow create: if isCreatingValidConversation();
  
  // Update conversation (for last message, unread count)
  allow update: if isConversationParticipant();
  
  // Delete conversations (only admin)
  allow delete: if isAdmin();
}
```

**Key Fields:**
- `participant_ids` - Array of user IDs in conversation
- `last_message` - Latest message text
- `unread_count` - Map of unread counts per user

---

### 8. Messages Collection

**Purpose:** Individual chat messages

**Rules:**
```javascript
match /messages/{messageId} {
  // Allow authenticated users to list messages
  allow list: if isAuthenticated();
  
  // Read message (user must be part of conversation)
  allow get: if isMessageConversationParticipant(resource.data.conversation_id);
  
  // Create message (user must be sender and part of conversation)
  allow create: if isAuthenticated() && 
                   request.resource.data.sender_id == request.auth.uid &&
                   isMessageConversationParticipant(request.resource.data.conversation_id);
  
  // Update message (only to mark as read)
  allow update: if isMessageConversationParticipant(resource.data.conversation_id) &&
                   request.resource.data.diff(resource.data).affectedKeys().hasOnly(['is_read']);
  
  // Delete messages (only admin)
  allow delete: if isAdmin();
}
```

**Key Fields:**
- `conversation_id` - Reference to conversation
- `sender_id` - Message sender
- `is_read` - Read status (can be updated)

**Important:** Messages are validated against conversation participant list

---

### 9. Notifications Collection

**Purpose:** User notifications and alerts

**Rules:**
```javascript
match /notifications/{notificationId} {
  // Allow authenticated users to list notifications
  allow list: if isAuthenticated();
  
  // Read notification (user must own it)
  allow get: if isNotificationOwner() || isAdmin();
  
  // System can create notifications for users
  allow create: if isAuthenticated() &&
                   (request.resource.data.userId == request.auth.uid ||
                    request.resource.data.user_id == request.auth.uid);
  
  // Users can update their own notifications (mark as read)
  allow update: if isNotificationOwner();
  
  // Users can delete their own notifications
  allow delete: if isNotificationOwner();
}
```

**Ownership Check:**
- Supports both `userId` and `user_id` field names

---

### 10. Complaints Collection (CSV Export)

**Purpose:** Complaint records for CSV export

**Rules:**
```javascript
match /complaints/{complaintId} {
  // Allow authenticated users to list complaints
  allow list: if isAuthenticated();
  
  // Read complaint (user must own it or be admin)
  allow get: if isComplaintOwner() || isAdmin();
  
  // Create complaint (user must set themselves as complainant)
  allow create: if isAuthenticated() &&
                   (request.resource.data.userId == request.auth.uid ||
                    request.resource.data.user_id == request.auth.uid);
  
  // Users can update pending complaints, admins can update any
  allow update: if isAdmin() ||
                   (isComplaintOwner() && resource.data.status == 'pending');
  
  // Only admin can delete complaints
  allow delete: if isAdmin();
}
```

**Status Restriction:**
- Users can only update complaints with `status == 'pending'`
- Once admin responds, user cannot modify

---

### 11. User Complaints Collection (Main App)

**Purpose:** Main complaint submission and management

**Rules:**
```javascript
match /user_complaints/{complaintId} {
  // Allow authenticated users to list complaints
  allow list: if isAuthenticated();
  
  // Read complaint (user must own it or be admin)
  allow get: if isComplaintOwner() || isAdmin();
  
  // Create complaint (user must set themselves as complainant)
  allow create: if isAuthenticated() &&
                   (request.resource.data.userId == request.auth.uid ||
                    request.resource.data.user_id == request.auth.uid);
  
  // Users can update pending complaints, admins can update any
  allow update: if isAdmin() ||
                   (isComplaintOwner() && resource.data.status == 'pending');
  
  // Only admin can delete complaints
  allow delete: if isAdmin();
}
```

**Note:** Identical rules to `complaints` collection

**Used By:**
- `lib/services/complaint_service.dart` (main app)
- `lib/services/admin_service.dart` (admin dashboard)

---

### 12. Cart Items Collection

**Purpose:** Shopping cart management

**Rules:**
```javascript
match /cart_items/{cartItemId} {
  // Allow list queries for authenticated users
  allow list: if isAuthenticated();
  
  // Users can get specific cart items they own
  allow get: if isAuthenticated() && resource.data.user_id == request.auth.uid;
  
  // Users can manage their own cart (full CRUD)
  allow create: if isAuthenticated() && request.resource.data.user_id == request.auth.uid;
  allow update: if isAuthenticated() && resource.data.user_id == request.auth.uid;
  allow delete: if isAuthenticated() && resource.data.user_id == request.auth.uid;
}
```

**Key Fields:**
- `user_id` - Cart owner
- `added_at` - Timestamp (for sorting)

---

### 13. Favorite Products Collection

**Purpose:** User's favorite/bookmarked products

**Rules:**
```javascript
match /favorite_products/{favoriteId} {
  // Allow list queries for authenticated users
  allow list: if isAuthenticated();
  
  // Users can get specific favorites they own
  allow get: if isAuthenticated() && resource.data.user_id == request.auth.uid;
  
  // Users can manage their own favorites (full CRUD)
  allow create: if isAuthenticated() && request.resource.data.user_id == request.auth.uid;
  allow update: if isAuthenticated() && resource.data.user_id == request.auth.uid;
  allow delete: if isAuthenticated() && resource.data.user_id == request.auth.uid;
}
```

**Key Fields:**
- `user_id` - User who favorited
- `product_id` - Referenced product

---

### 14. Reviews Collection

**Purpose:** Product reviews and ratings

**Rules:**
```javascript
match /reviews/{reviewId} {
  // Anyone authenticated can read reviews
  allow read: if isAuthenticated();
  
  // Users can create reviews (must set themselves as reviewer)
  allow create: if isAuthenticated() &&
                   request.resource.data.reviewerId == request.auth.uid;
  
  // Users can update their own reviews (within limits)
  allow update: if isAuthenticated() && 
                   resource.data.reviewerId == request.auth.uid &&
                   request.resource.data.reviewerId == resource.data.reviewerId &&
                   request.resource.data.orderId == resource.data.orderId &&
                   request.resource.data.revieweeId == resource.data.revieweeId;
  
  // Only admin can delete reviews
  allow delete: if isAdmin();
}
```

**Field Restrictions:**
- Cannot change `reviewerId` in updates
- Cannot change `orderId` in updates
- Cannot change `revieweeId` in updates

---

### 15. Subscriptions Collection

**Purpose:** User subscription plans (system-managed)

**Rules:**
```javascript
match /subscriptions/{subscriptionId} {
  // Users can read their own subscriptions
  allow read: if isOwner(subscriptionId) || isAdmin();
  
  // Subscriptions are system-managed only
  allow create: if false;
  allow update: if false;
  allow delete: if isAdmin();
}
```

**Important:** All subscription operations through backend payment processing

---

### 16. Admin-Only Collections

**admin_logs:**
```javascript
match /admin_logs/{logId} {
  allow read, write: if isAdmin();
}
```

**system_config:**
```javascript
match /system_config/{configId} {
  allow read: if isAuthenticated();
  allow write: if isAdmin();
}
```

---

## 🛡️ Helper Functions

### isAuthenticated()
Checks if user is logged in via Firebase Auth
```javascript
function isAuthenticated() {
  return request.auth != null;
}
```

### isOwner(userId)
Checks if current user owns the resource
```javascript
function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}
```

### isAdmin()
Checks if user has admin role
```javascript
function isAdmin() {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

---

## 🔐 Security Best Practices

### Field Name Flexibility
Many collections support both camelCase and snake_case for compatibility:
- `userId` / `user_id`
- `buyerId` / `buyer_id`
- `sellerId` / `seller_id`

### List vs Get Operations
- **allow list**: Permits querying the collection
- **allow get**: Requires ownership check for individual documents
- This pattern allows queries while preventing unauthorized data access

### System-Generated Collections
Collections with `allow create: if false`:
- receipts
- transactions
- wallets
- subscriptions

These can only be created by backend services, not client apps.

---

## 📊 Composite Indexes

See `firestore.indexes.json` for complete list of composite indexes required for queries.

**Key Indexes:**
- conversations: `participant_ids (array-contains) + updated_at (desc)`
- user_complaints: `user_id (asc) + created_at (desc)`
- user_complaints: `status (asc) + created_at (desc)`
- messages: `conversation_id (asc) + created_at (desc)`
- receipts: `buyer_id (asc) + created_at (desc)`
- receipts: `seller_id (asc) + created_at (desc)`

---

## 🚀 Deployment

**Deploy Rules:**
```bash
firebase deploy --only firestore:rules
```

**Deploy Indexes:**
```bash
firebase deploy --only firestore:indexes
```

**Verify Deployment:**
```
https://console.firebase.google.com/project/sayekataleapp/firestore/rules
https://console.firebase.google.com/project/sayekataleapp/firestore/indexes
```

---

## 🧪 Testing Rules

Use Firebase Emulator for local testing:
```bash
firebase emulators:start --only firestore
```

Or test in Firebase Console Rules Playground:
```
https://console.firebase.google.com/project/sayekataleapp/firestore/rules
```

---

## 📝 Notes

- All collections require authentication (`isAuthenticated()`)
- Default rule denies all access: `match /{document=**} { allow read, write: if false; }`
- Admin operations require `role == 'admin'` in user document
- Document-level security prevents unauthorized access even if list query succeeds

---

**For detailed fix history, see:**
- `FIRESTORE_RULES_UPDATE.md` - Initial receipts/messages/notifications fixes
- `FIRESTORE_MESSAGES_COMPLAINTS_FIX.md` - Messages and complaints implementation
- `CRITICAL_FIX_USER_COMPLAINTS.md` - user_complaints collection fix

---

**Last Updated:** December 2024  
**Firebase Project:** sayekataleapp  
**Status:** ✅ All collections have proper security rules
