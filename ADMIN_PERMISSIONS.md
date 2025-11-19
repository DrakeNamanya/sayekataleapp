# 👑 Admin Permissions & Security Rules

## 🎯 Quick Answer

**YES, admins are already configured in the security rules!**

Admins have **elevated permissions** across all collections through the `isAdmin()` helper function. They **do NOT need separate security rules** - the existing rules already grant them special access.

---

## 🔐 How Admin Permissions Work

### The isAdmin() Function

**Location:** `firestore.rules` (lines 20-23)

```javascript
function isAdmin() {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

**How It Works:**
1. ✅ Checks if user is authenticated (logged in)
2. ✅ Reads the user's document from `users` collection
3. ✅ Checks if `role` field equals `'admin'`
4. ✅ Returns `true` if admin, `false` otherwise

**Important:** The user document must have `role: 'admin'` field set!

---

## 📊 Admin Permissions by Collection

### Collections Where Admins Have FULL ACCESS:

| Collection | Admin Can Do | Rule Reference |
|-----------|-------------|----------------|
| **users** | Delete users | `allow delete: if isAdmin()` |
| **products** | Update any product, Delete any product | `allow update/delete: if ... || isAdmin()` |
| **orders** | Read all orders, Update any order, Delete orders | `allow get/update: if ... || isAdmin()` |
| **receipts** | Read all receipts, Delete receipts | `allow get/delete: if ... || isAdmin()` |
| **wallets** | Read all wallets | `allow read: if ... || isAdmin()` |
| **transactions** | Read all transactions, Delete transactions | `allow get/delete: if ... || isAdmin()` |
| **conversations** | Read all conversations, Delete conversations | `allow get/delete: if ... || isAdmin()` |
| **messages** | Read all messages, Delete messages | `allow get/delete: if ... || isAdmin()` |
| **notifications** | Read all notifications | `allow get: if ... || isAdmin()` |
| **complaints** | Read all, Update all, Delete all | `allow get/update/delete: if ... || isAdmin()` |
| **user_complaints** | Read all, Update all, Delete all | `allow get/update/delete: if ... || isAdmin()` |
| **reviews** | Delete reviews | `allow delete: if isAdmin()` |
| **subscriptions** | Read all, Delete subscriptions | `allow read/delete: if ... || isAdmin()` |
| **admin_logs** | Full CRUD | `allow read, write: if isAdmin()` |
| **system_config** | Full write access | `allow write: if isAdmin()` |

---

## 🔑 Setting Up an Admin User

### Step 1: Create User Account

User must first sign up normally through the app or Firebase Auth.

### Step 2: Set Admin Role in Firestore

**Option 1: Firebase Console (Easiest)**

1. Go to Firebase Console: https://console.firebase.google.com/project/sayekataleapp/firestore
2. Navigate to `users` collection
3. Find the user document (document ID = user's UID)
4. Add/Update field:
   - Field: `role`
   - Value: `admin`
5. Save the document

**Option 2: Using Firestore Admin SDK (Python/Node.js)**

```python
from firebase_admin import firestore

db = firestore.client()

# Set user as admin
user_id = "USER_UID_HERE"
db.collection('users').document(user_id).update({
    'role': 'admin'
})
```

**Option 3: Using Firebase CLI**

```bash
# First, get the user's UID from Firebase Authentication
# Then update their Firestore document

firebase firestore:update users/USER_UID_HERE role=admin
```

---

## 🧪 Testing Admin Permissions

### Verify Admin Status

```dart
// In your Flutter app
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> isCurrentUserAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  
  return userDoc.data()?['role'] == 'admin';
}
```

### Test Admin Operations

After setting role to 'admin', test these operations:

**1. View All Users:**
```dart
// Should work for admin
final allUsers = await FirebaseFirestore.instance
    .collection('users')
    .get();
```

**2. View All Complaints:**
```dart
// Should work for admin
final allComplaints = await FirebaseFirestore.instance
    .collection('user_complaints')
    .get();
```

**3. Update Any Complaint:**
```dart
// Should work for admin (even if status is not 'pending')
await FirebaseFirestore.instance
    .collection('user_complaints')
    .doc(complaintId)
    .update({
      'status': 'resolved',
      'response': 'Issue has been fixed',
      'responded_by': currentUserId,
    });
```

**4. Delete Any Order:**
```dart
// Should work for admin only
await FirebaseFirestore.instance
    .collection('orders')
    .doc(orderId)
    .delete();
```

---

## ⚠️ Important Notes

### 1. Admin Role Field is Critical

The admin check reads from the user's document:
```javascript
get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
```

**Requirements:**
- ✅ User document must exist in `users` collection
- ✅ Document ID must match Firebase Auth UID
- ✅ Must have `role` field set to `'admin'` (exact match, lowercase)

**Common Mistakes:**
- ❌ Setting role to `'Admin'` (capital A) - Won't work!
- ❌ User document doesn't exist - Admin check fails
- ❌ Document ID doesn't match UID - Admin check fails

---

### 2. Admin Check Requires Network Call

Every time a rule checks `isAdmin()`, it makes a Firestore read to the user's document:
```javascript
get(/databases/$(database)/documents/users/$(request.auth.uid))
```

**Performance Impact:**
- Each admin operation costs 1 extra read (to check role)
- Not a problem for occasional admin operations
- For high-frequency operations, consider caching

---

### 3. Creating User Documents During Signup

**Current Rule (Line 54):**
```javascript
allow create: if isAuthenticated() && request.auth.uid == userId;
```

**What This Means:**
- Users can create their own document during signup
- Document ID must match their Auth UID
- They can set their own `role` field

**⚠️ Security Risk:**
Users could potentially set themselves as admin during signup!

**Recommended Fix:**
```javascript
allow create: if isAuthenticated() && 
                 request.auth.uid == userId &&
                 (!request.resource.data.keys().hasAny(['role']) ||
                  request.resource.data.role == 'user');
```

This prevents users from setting role during creation, or forces it to 'user'.

---

## 🛠️ Recommended Admin Setup Process

### Complete Setup Steps:

**1. Create Admin User in Firebase Auth**
```bash
# Using Firebase CLI
firebase auth:create admin@sayekatale.com --password SecurePass123
```

**2. Get User UID**
```bash
# From Firebase Console → Authentication → Users
# Copy the UID of the newly created user
```

**3. Create User Document with Admin Role**
```bash
# Using Firebase Console → Firestore
# Create document in 'users' collection
# Document ID: [USER_UID_FROM_STEP_2]
# Fields:
{
  "uid": "[USER_UID]",
  "email": "admin@sayekatale.com",
  "name": "Admin User",
  "role": "admin",  ← CRITICAL FIELD
  "created_at": "[TIMESTAMP]"
}
```

**4. Test Admin Access**
- Login to app with admin credentials
- Try viewing all complaints
- Try updating any complaint
- Verify admin dashboard access

---

## 📋 Admin Permissions Checklist

Use this checklist to verify admin setup:

**Setup:**
- [ ] User account created in Firebase Auth
- [ ] User document exists in `users` collection
- [ ] Document ID matches Firebase Auth UID
- [ ] `role` field set to `'admin'` (lowercase)
- [ ] User can login to the app

**Permissions Test:**
- [ ] Can view all users
- [ ] Can view all complaints
- [ ] Can update any complaint (even resolved ones)
- [ ] Can delete orders
- [ ] Can read all transactions
- [ ] Can access admin_logs collection
- [ ] Can update system_config

**Security Test:**
- [ ] Regular users cannot set role to admin
- [ ] Regular users cannot view other users' data
- [ ] Admin status checked on every operation

---

## 🔒 Admin Security Best Practices

### 1. Limit Number of Admins
- Only create admin accounts for trusted staff
- Use principle of least privilege
- Regularly audit admin accounts

### 2. Use Strong Authentication
```dart
// Enable multi-factor authentication for admin accounts
// In Firebase Console → Authentication → Sign-in method
// Enable: Email/Password + Phone
```

### 3. Log Admin Actions
```dart
// Create audit log for admin operations
Future<void> logAdminAction(String action, String targetId) async {
  await FirebaseFirestore.instance.collection('admin_logs').add({
    'admin_id': FirebaseAuth.instance.currentUser!.uid,
    'action': action,
    'target_id': targetId,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
```

### 4. Implement Role Hierarchy (Optional)
```javascript
// In firestore.rules helper functions
function isSuperAdmin() {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
}

function isModeratorOrHigher() {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['moderator', 'admin', 'super_admin'];
}
```

---

## 🚫 What Admins CANNOT Do

Even admins have some restrictions:

| Operation | Why It's Blocked |
|-----------|------------------|
| **Create wallets** | System-managed only (`allow create: if false`) |
| **Update wallets** | System-managed only (`allow update: if false`) |
| **Create transactions** | System-managed only (`allow create: if false`) |
| **Create receipts** | System-generated only (`allow create: if false`) |
| **Update receipts** | System-generated only (`allow update: if false`) |
| **Create subscriptions** | Payment system only (`allow create: if false`) |

These operations must go through backend services/webhooks for security and data integrity.

---

## 📊 Admin vs Regular User Comparison

| Operation | Regular User | Admin |
|-----------|-------------|-------|
| **View own data** | ✅ Yes | ✅ Yes |
| **View others' data** | ❌ No | ✅ Yes |
| **Update own profile** | ✅ Yes | ✅ Yes |
| **Delete users** | ❌ No | ✅ Yes |
| **View all complaints** | ❌ No | ✅ Yes |
| **Update resolved complaints** | ❌ No | ✅ Yes |
| **Delete orders** | ❌ No | ✅ Yes |
| **Access admin_logs** | ❌ No | ✅ Yes |
| **Modify system_config** | ❌ No | ✅ Yes |

---

## 🎯 Summary

### Do Admins Need Special Rules?

**NO!** The current `firestore.rules` already includes admin permissions through the `isAdmin()` function.

### Do Admins Need Special Indexes?

**NO!** Admins use the same composite indexes as regular users. No special indexes needed.

### What DO Admins Need?

**ONLY ONE THING:** A user document with `role: 'admin'` field set in Firestore!

### Quick Setup:
1. Create user account (Firebase Auth)
2. Add user document (Firestore `users` collection)
3. Set `role: 'admin'` field
4. Done! ✅

---

## 📞 Troubleshooting

### Problem: Admin permissions not working

**Check:**
1. User is logged in (`isAuthenticated()`)
2. User document exists in `users` collection
3. Document ID matches Firebase Auth UID
4. `role` field equals `'admin'` (exact match, lowercase)
5. Security rules have been deployed
6. Firebase has synced the changes (wait 30 seconds)

### Problem: Getting "permission denied" as admin

**Solution:**
```bash
# Re-deploy security rules
firebase deploy --only firestore:rules

# Wait 30 seconds for propagation

# Clear app cache and re-login
```

---

**For more information, see:**
- `firestore.rules` - Complete security rules
- `FIRESTORE_RULES.md` - Detailed rules documentation

---

**Last Updated:** December 2024  
**Status:** ✅ Admin permissions fully configured
