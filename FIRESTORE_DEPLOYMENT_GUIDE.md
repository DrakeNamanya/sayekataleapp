# 🔥 Firestore Configuration Deployment Guide

## 📋 Overview

This guide will help you deploy the updated Firestore security rules and composite indexes to fix the three critical issues:

1. ✅ **Receipts Collection** - Fixed security rules and added composite indexes for `buyer_id + created_at` and `seller_id + created_at`
2. ✅ **Messages Collection** - Fixed security rules to enforce query filtering by `conversation_id` and added composite index
3. ✅ **Notifications Collection** - Fixed security rules and added composite index for `user_id + created_at`

## 🛠️ Prerequisites

- Firebase CLI installed on your Windows machine
- Firebase project access (sayekataleapp)
- Command Prompt or PowerShell

### Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

### Login to Firebase

```bash
firebase login
```

## 📁 Files Updated

1. **firestore.rules** - Security rules with query filtering enforcement
2. **firestore.indexes.json** - 12 composite indexes for all collections

## 🚀 Deployment Steps

### Step 1: Navigate to Flutter Project Directory

```bash
cd C:\path\to\your\flutter_app
```

Or wherever you have the Flutter project on your Windows machine.

### Step 2: Initialize Firebase (if not already done)

```bash
firebase init
```

- Select **Firestore** when prompted
- Choose **Use an existing project**
- Select **sayekataleapp**
- Use **firestore.rules** as the rules file
- Use **firestore.indexes.json** as the indexes file

**IMPORTANT**: If Firebase is already initialized, skip this step.

### Step 3: Deploy Security Rules

Deploy only the security rules first:

```bash
firebase deploy --only firestore:rules
```

Expected output:
```
✔ Deploy complete!

Project Console: https://console.firebase.google.com/project/sayekataleapp/overview
```

### Step 4: Deploy Composite Indexes

Deploy the composite indexes:

```bash
firebase deploy --only firestore:indexes
```

Expected output:
```
✔ Deploy complete!

Indexes will be created in the background. Check status:
https://console.firebase.google.com/project/sayekataleapp/firestore/indexes
```

### Step 5: Monitor Index Building Progress

Indexes take **2-15 minutes** to build. Monitor progress at:

https://console.firebase.google.com/project/sayekataleapp/firestore/indexes

**Index States**:
- 🟡 **Building** - Index is being created (wait)
- 🟢 **Enabled** - Index is ready to use
- 🔴 **Error** - Index creation failed (check logs)

## 📊 Deployed Indexes Summary

### Receipts Collection (2 indexes)
- `buyer_id + created_at` (ASCENDING + DESCENDING)
- `seller_id + created_at` (ASCENDING + DESCENDING)

### Notifications Collection (1 index)
- `user_id + created_at` (ASCENDING + DESCENDING)

### Messages Collection (1 index)
- `conversation_id + created_at` (ASCENDING + DESCENDING)

### Orders Collection (4 indexes)
- `buyer_id + created_at` (ASCENDING + DESCENDING)
- `farmerId + created_at` (ASCENDING + DESCENDING)
- `seller_id + created_at` (ASCENDING + DESCENDING)
- `status + created_at` (ASCENDING + DESCENDING)

### Transactions Collection (1 index)
- `user_id + created_at` (ASCENDING + DESCENDING)

### Cart Items Collection (1 index)
- `user_id + added_at` (ASCENDING + DESCENDING)

### Favorite Products Collection (1 index)
- `user_id + created_at` (ASCENDING + DESCENDING)

### Products Collection (1 index)
- `category + created_at` (ASCENDING + DESCENDING)

**Total: 12 composite indexes**

## 🔒 Security Rules Changes

### 1. Messages Collection - Conversation-Based Access

**✅ NEW (Enforced Conversation Filtering)**:
```javascript
match /messages/{messageId} {
  // Query MUST filter by conversation_id
  allow list: if isAuthenticated() &&
                 request.query.where.conversation_id != null;
  
  // Individual message access checks conversation membership
  allow get: if isAuthenticated() &&
                isConversationMember(resource.data.conversation_id);
}
```

**Key Changes**:
- ✅ Enforces `conversation_id` filtering on list queries
- ✅ Verifies user is a conversation participant before allowing access
- ✅ More secure than previous senderId/receiverId approach

### 2. Receipts Collection - Buyer/Seller Filtering

**✅ NEW (Enforced Ownership Filtering)**:
```javascript
match /receipts/{receiptId} {
  // Query MUST filter by buyer_id OR seller_id
  allow list: if isAuthenticated() &&
                 (request.query.where.buyer_id == request.auth.uid ||
                  request.query.where.seller_id == request.auth.uid);
  
  // Individual receipt access checks ownership
  allow get: if isAuthenticated() &&
                (resource.data.buyer_id == request.auth.uid ||
                 resource.data.seller_id == request.auth.uid);
}
```

**Key Changes**:
- ✅ Uses snake_case field names (`buyer_id`, `seller_id`)
- ✅ Enforces query filtering by buyer or seller
- ✅ Prevents unauthorized access to other users' receipts

### 3. Notifications Collection - User Filtering

**✅ NEW (Enforced User Filtering)**:
```javascript
match /notifications/{notificationId} {
  // Query MUST filter by user_id
  allow list: if isAuthenticated() &&
                 request.query.where.user_id == request.auth.uid;
  
  // Individual notification access checks ownership
  allow get: if isAuthenticated() &&
                resource.data.user_id == request.auth.uid;
}
```

**Key Changes**:
- ✅ Uses snake_case field name (`user_id`)
- ✅ Enforces query filtering by current user
- ✅ Prevents users from viewing others' notifications

### 4. Transactions Collection - User Filtering

**✅ NEW (Enforced User Filtering)**:
```javascript
match /transactions/{transactionId} {
  // Query MUST filter by user_id
  allow list: if isAuthenticated() &&
                 request.query.where.user_id == request.auth.uid;
}
```

## ✅ Verification Steps

### 1. Verify Security Rules Deployed

Visit Firebase Console → Firestore Database → Rules tab:
https://console.firebase.google.com/project/sayekataleapp/firestore/rules

Check that rules show the latest changes with query filtering enforcement.

### 2. Verify Indexes Created

Visit Firebase Console → Firestore Database → Indexes tab:
https://console.firebase.google.com/project/sayekataleapp/firestore/indexes

All 12 indexes should show **Status: Enabled** (green checkmark).

### 3. Test in App

1. **Receipts**: Open receipts screen - should load without errors
2. **Messages**: Open messages screen - should load conversations
3. **Notifications**: Open notifications - should display notifications

## ⚠️ Important Notes

### Query Filtering Requirement

After deploying these security rules, **ALL Firestore queries must include proper where clauses**:

**Receipts Queries**:
```dart
// ✅ CORRECT - Filters by buyer_id
FirebaseFirestore.instance
  .collection('receipts')
  .where('buyer_id', isEqualTo: userId)
  .orderBy('created_at', descending: true)
  .get();

// ✅ CORRECT - Filters by seller_id
FirebaseFirestore.instance
  .collection('receipts')
  .where('seller_id', isEqualTo: userId)
  .orderBy('created_at', descending: true)
  .get();
```

**Messages Queries**:
```dart
// ✅ CORRECT - Filters by conversation_id
FirebaseFirestore.instance
  .collection('messages')
  .where('conversation_id', isEqualTo: conversationId)
  .orderBy('created_at', descending: true)
  .get();
```

**Notifications Queries**:
```dart
// ✅ CORRECT - Filters by user_id
FirebaseFirestore.instance
  .collection('notifications')
  .where('user_id', isEqualTo: userId)
  .orderBy('created_at', descending: true)
  .get();
```

### Index Building Timeline

- **Simple collections** (< 1000 docs): 2-5 minutes
- **Medium collections** (1000-10000 docs): 5-10 minutes
- **Large collections** (> 10000 docs): 10-15 minutes

### Troubleshooting

**Error: "Firebase project not found"**
```bash
firebase use --add
# Select: sayekataleapp
```

**Error: "Insufficient permissions"**
```bash
firebase login --reauth
```

**Error: "Index creation failed"**
- Check Firebase Console for error details
- Verify field names match your Firestore data exactly
- Ensure field types are consistent (string, timestamp, etc.)

## 🎯 Next Steps After Deployment

1. **Wait for indexes to build** (2-15 minutes)
2. **Test the app thoroughly**:
   - Open receipts screen
   - Send/receive messages
   - Check notifications
3. **Monitor Firebase Console** for any new errors
4. **Verify all queries are working** with proper filtering

## 📞 Support

If you encounter any issues during deployment:

1. Check Firebase Console logs
2. Verify Firebase CLI version: `firebase --version`
3. Review error messages carefully
4. Check Firestore usage quotas

---

**Deployment Date**: Ready to deploy
**Project**: SayeKatale App (sayekataleapp)
**Collections Affected**: receipts, notifications, messages, orders, transactions, cart_items, favorite_products, products
**Total Indexes**: 12 composite indexes
