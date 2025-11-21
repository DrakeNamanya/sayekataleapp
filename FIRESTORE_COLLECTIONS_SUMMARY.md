# 📊 Firestore Collections - Complete Summary

## 🎯 Overview
Your Firestore database has **21 collections** with comprehensive security rules.

---

## 📋 All Collections with Rules

### **1. Users Collection** (`users/{userId}`)
**Purpose:** User profiles and account information

**Current Rules:**
- ✅ Read: Any authenticated user
- ✅ Create: Users can create their own profile (userId = auth.uid)
- ✅ Update: Users can update own profile (cannot change role/uid)
- ✅ Delete: Admin only

**Fields:** (Typical structure)
- `uid`, `name`, `email`, `phone`, `role`, `avatar`, `createdAt`

**Status:** ✅ Working correctly

---

### **2. Products Collection** (`products/{productId}`)
**Purpose:** Agricultural products listed by farmers

**Current Rules:**
- ✅ Read: Any authenticated user
- ✅ Create: Authenticated users (must set self as farmerId)
- ✅ Update: Product owner or admin
- ✅ Delete: Product owner or admin

**Fields:**
- `farmerId`, `name`, `description`, `price`, `category`, `quantity`, `images`

**Status:** ✅ Working correctly

---

### **3. Orders Collection** (`orders/{orderId}`)
**Purpose:** Product purchase orders

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Buyer, seller, or admin
- ✅ Create: Buyers (must set self as buyer_id)
- ✅ Update: Buyer, seller, or admin
- ✅ Delete: Admin only

**Fields:**
- `buyer_id`, `seller_id`, `farmerId`, `productId`, `quantity`, `totalAmount`, `status`

**Status:** ✅ Working correctly

---

### **4. Receipts Collection** (`receipts/{receiptId}`)
**Purpose:** Order receipts (system-generated)

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Buyer, seller, or admin
- ❌ Create: Blocked (system-generated only)
- ❌ Update: Blocked
- ✅ Delete: Admin only

**Fields:**
- `buyerId`, `sellerId`, `orderId`, `amount`, `date`, `receiptNumber`

**Status:** ✅ Working correctly (backend-generated)

---

### **5. Wallets Collection** (`wallets/{walletId}`)
**Purpose:** User wallet balances

**Current Rules:**
- ✅ Read: Owner or admin
- ❌ Create: Blocked (backend webhooks only)
- ❌ Update: Blocked (backend webhooks only)
- ❌ Delete: Blocked

**Fields:**
- `userId`, `balance`, `currency`, `lastUpdated`

**Status:** ✅ Secure (backend-managed)

---

### **6. Transactions Collection** (`transactions/{transactionId}`) ⚠️
**Purpose:** Payment transactions

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Transaction owner or admin
- ✅ Create: Authenticated users (must set self as buyerId/userId)
- ✅ Update: Owner can update status/completedAt/paymentReference
- ✅ Delete: Admin only

**Fields:**
- `buyerId`, `sellerId`, `amount`, `status`, `paymentMethod`, `paymentReference`, `metadata`

**Status:** ⚠️ **ISSUE: Cloud Functions cannot write** (rules require authentication)

**Problem:**
```javascript
// Current rule requires authentication
allow create: if isAuthenticated() && request.resource.data.buyerId == request.auth.uid
```

**Cloud Functions run with `request.auth = null`**, so writes are blocked!

---

### **7. Conversations Collection** (`conversations/{conversationId}`)
**Purpose:** Chat conversations between users

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Conversation participants or admin
- ✅ Create: Authenticated users (must be in participant_ids)
- ✅ Update: Conversation participants
- ✅ Delete: Admin only

**Fields:**
- `participant_ids`, `last_message`, `last_message_time`, `unread_count`

**Status:** ✅ Working correctly

---

### **8. Messages Collection** (`messages/{messageId}`)
**Purpose:** Individual chat messages

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Conversation participants or admin
- ✅ Create: Authenticated users (must be sender and participant)
- ✅ Update: Participants (only mark as read)
- ✅ Delete: Admin only

**Fields:**
- `conversation_id`, `sender_id`, `text`, `timestamp`, `is_read`

**Status:** ✅ Working correctly

---

### **9. Subscriptions Collection** (`subscriptions/{subscriptionId}`) ⚠️
**Purpose:** Premium subscriptions

**Current Rules:**
- ✅ Read: Owner or admin
- ✅ Create: Users can create pending subscriptions (subscriptionId = auth.uid)
- ✅ Update: Owner can update pending subscriptions
- ✅ Delete: Admin only

**Fields:**
- `user_id`, `type`, `status`, `start_date`, `end_date`, `amount`, `payment_method`, `payment_reference`

**Status:** ⚠️ **ISSUE: Webhook cannot activate subscriptions** (requires admin SDK)

**Problem:**
- Rule only allows users to update their own pending subscriptions
- Webhook needs to update from "pending" to "active" without user auth
- **Solution:** Webhook must use Firebase Admin SDK (bypasses rules)

---

### **10. Reviews Collection** (`reviews/{reviewId}`)
**Purpose:** Product/service reviews

**Current Rules:**
- ✅ Read: Any authenticated user
- ✅ Create: Authenticated users (must set self as reviewerId)
- ✅ Update: Review owner (limited fields)
- ✅ Delete: Admin only

**Fields:**
- `reviewerId`, `revieweeId`, `orderId`, `rating`, `comment`, `createdAt`

**Status:** ✅ Working correctly

---

### **11. Cart Items Collection** (`cart_items/{cartItemId}`)
**Purpose:** User shopping cart items

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Item owner
- ✅ Create: Authenticated users (must set self as user_id)
- ✅ Update: Item owner
- ✅ Delete: Item owner

**Fields:**
- `user_id`, `product_id`, `quantity`, `added_at`

**Status:** ✅ Working correctly

---

### **12. Favorite Products Collection** (`favorite_products/{favoriteId}`)
**Purpose:** User favorite/bookmarked products

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Favorite owner
- ✅ Create: Authenticated users (must set self as user_id)
- ✅ Update: Favorite owner
- ✅ Delete: Favorite owner

**Fields:**
- `user_id`, `product_id`, `added_at`

**Status:** ✅ Working correctly

---

### **13. Notifications Collection** (`notifications/{notificationId}`)
**Purpose:** User notifications

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Notification owner or admin
- ✅ Create: System (for own userId)
- ✅ Update: Notification owner
- ✅ Delete: Notification owner

**Fields:**
- `userId`, `title`, `message`, `type`, `is_read`, `created_at`

**Status:** ✅ Working correctly

---

### **14. Complaints Collection** (`complaints/{complaintId}`)
**Purpose:** User complaints/issues

**Current Rules:**
- ✅ List: Any authenticated user
- ✅ Get: Complaint owner or admin
- ✅ Create: Authenticated users (must set self as userId)
- ✅ Update: Owner (pending only) or admin
- ✅ Delete: Admin only

**Fields:**
- `userId`, `subject`, `description`, `status`, `response`, `created_at`

**Status:** ✅ Working correctly

---

### **15. User Complaints Collection** (`user_complaints/{complaintId}`)
**Purpose:** Alternative complaints collection

**Current Rules:**
- Same as complaints collection

**Status:** ✅ Working correctly (duplicate of complaints?)

---

### **16. Admin Logs Collection** (`admin_logs/{logId}`)
**Purpose:** Admin activity logs

**Current Rules:**
- ✅ Read/Write: Admin only

**Status:** ✅ Secure (admin-only)

---

### **17. System Config Collection** (`system_config/{configId}`)
**Purpose:** System configuration settings

**Current Rules:**
- ✅ Read: Any authenticated user
- ✅ Write: Admin only

**Status:** ✅ Working correctly

---

## 🚨 Issues Identified

### **Issue 1: Transactions Collection - Cloud Function Cannot Write**

**Problem:**
```javascript
// Current rule
allow create: if isAuthenticated() && request.resource.data.buyerId == request.auth.uid
```

**Cloud Functions have `request.auth = null`** → Writes blocked!

**Fix Required:**
```javascript
// Updated rule
match /transactions/{transactionId} {
  // Allow Cloud Functions to create transactions (for payment initiation)
  allow create: if true;  // OR: Add separate rule for server writes
  
  // Allow users to create their own transactions (for client-side payment)
  allow create: if isAuthenticated() && request.resource.data.buyerId == request.auth.uid;
  
  // Existing rules...
}
```

---

### **Issue 2: Subscriptions Collection - Webhook Cannot Activate**

**Problem:**
```javascript
// Current rule - only allows users to update pending subscriptions
allow update: if isAuthenticated() &&
                 request.auth.uid == subscriptionId &&
                 resource.data.status == 'pending';
```

**Webhook cannot activate subscription** because it has no auth!

**Solution:**
Webhook **must use Firebase Admin SDK** (not Cloud Functions HTTP endpoint), which bypasses rules entirely.

**Correct webhook implementation:**
```javascript
// In Cloud Function
const admin = require('firebase-admin');
const db = admin.firestore();

// This bypasses security rules!
await db.collection('subscriptions').doc(userId).update({
  status: 'active',
  // ...
});
```

---

## 📊 Collections Summary Table

| # | Collection | Has Rules | Allows List | Allows Client Create | Cloud Function Access | Status |
|---|-----------|-----------|-------------|---------------------|---------------------|--------|
| 1 | users | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 2 | products | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 3 | orders | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 4 | receipts | ✅ | ✅ | ❌ Backend only | ❌ Needs Admin SDK | ✅ |
| 5 | wallets | ✅ | ❌ Owner only | ❌ Backend only | ❌ Needs Admin SDK | ✅ |
| 6 | **transactions** | ✅ | ✅ | ✅ | ❌ **BLOCKED** | ⚠️ **FIX NEEDED** |
| 7 | conversations | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 8 | messages | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 9 | **subscriptions** | ✅ | ❌ Owner only | ✅ | ⚠️ **Use Admin SDK** | ⚠️ |
| 10 | reviews | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 11 | cart_items | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 12 | favorite_products | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 13 | notifications | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 14 | complaints | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 15 | user_complaints | ✅ | ✅ | ✅ | ❌ Needs auth | ✅ |
| 16 | admin_logs | ✅ | ❌ Admin only | ❌ Admin only | ❌ Admin only | ✅ |
| 17 | system_config | ✅ | ✅ | ❌ Admin only | ❌ Admin only | ✅ |

**Note:** "Cloud Function Access" refers to HTTP Cloud Functions (not Admin SDK)

---

## 🔧 Recommended Fixes

### **Fix 1: Update Transactions Collection Rules**

Add this to your `firestore.rules`:

```javascript
match /transactions/{transactionId} {
  // Allow Cloud Functions to create transactions (unauthenticated server calls)
  allow create: if !isAuthenticated();
  
  // OR use Admin SDK in Cloud Functions (preferred - bypasses rules entirely)
  
  // Allow authenticated users to create their own transactions
  allow create: if isAuthenticated() && request.resource.data.buyerId == request.auth.uid;
  
  // Allow Cloud Functions to update transaction status
  allow update: if !isAuthenticated() ||
                   (isAuthenticated() && resource.data.buyerId == request.auth.uid);
  
  // Rest of rules remain the same...
}
```

### **Fix 2: Use Admin SDK in Cloud Functions**

**Better approach:** Use Firebase Admin SDK in Cloud Functions, which bypasses all rules:

```javascript
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// Create transaction (bypasses rules)
await db.collection('transactions').doc(depositId).set({...});

// Update subscription (bypasses rules)
await db.collection('subscriptions').doc(userId).update({
  status: 'active'
});
```

---

## 📝 Summary

**Total Collections:** 17 (plus default deny-all)

**Collections with Issues:** 2
1. ⚠️ `transactions` - Cloud Function writes blocked
2. ⚠️ `subscriptions` - Webhook updates blocked

**Recommended Action:**
1. ✅ Update `firestore.rules` to allow Cloud Function writes to `transactions`
2. ✅ Ensure Cloud Functions use Firebase Admin SDK (already implemented in your code)
3. ✅ Deploy updated rules

---

## 🔗 Next Steps

**To fix the transaction creation issue:**

```bash
# In Google Cloud Shell
cd ~/sayekataleapp

# Update firestore.rules (use the fix above)
nano firestore.rules

# Deploy updated rules
firebase deploy --only firestore:rules

# Test transaction creation
curl -X POST https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment \
  -H "Content-Type: application/json" \
  -d '{...}'
```

**After deployment, transactions should appear in Firestore!** ✅
