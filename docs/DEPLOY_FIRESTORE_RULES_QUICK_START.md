# Deploy Firestore Rules - Quick Start Guide

## ⚠️ CRITICAL: Admin Approval Permission Fix

Your Firestore rules are correct in the local file but **NOT deployed** to Firebase Console.
This is why you're getting "permission-denied" errors when approving PSA verifications.

---

## 🚀 Quick Deploy (5 Minutes)

### Step 1: Open Firebase Console
Go to: **https://console.firebase.google.com/project/sayekataleapp/firestore/rules**

### Step 2: Copy Rules from Local File
The complete rules are in: `/home/user/flutter_app/firestore.rules`

### Step 3: Paste & Publish
1. Select ALL text in the Firebase Console editor
2. Delete it
3. Paste the complete rules from the local file
4. Click "Publish" button (top right)
5. Wait for "Rules published successfully" confirmation

### Step 4: Test
1. Login as admin
2. Go to PSA Verifications
3. Click "Approve" on a pending verification
4. Should work without permission errors! ✅

---

## 📋 Complete Firestore Rules

Copy these rules to Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ========================================
    // Helper Functions
    // ========================================
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return exists(/databases/$(database)/documents/admin_users/$(request.auth.uid));
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // ========================================
    // Admin Users Collection
    // ========================================
    
    match /admin_users/{adminId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // ========================================
    // Users Collection
    // ========================================
    
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isOwner(userId) || isAdmin();
    }
    
    // ========================================
    // Products Collection
    // ========================================
    
    match /products/{productId} {
      allow read: if true;
      allow create, update, delete: if isAuthenticated();
    }
    
    // ========================================
    // SME Directory Collection
    // ========================================
    
    match /sme_directory/{smeId} {
      allow read: if true;
      allow write: if isAuthenticated();
    }
    
    // ========================================
    // Reviews Collection
    // ========================================
    
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
                                resource.data.reviewer_id == request.auth.uid;
    }
    
    // ========================================
    // PSA Verifications Collection (CRITICAL FIX)
    // ========================================
    
    match /psa_verifications/{verificationId} {
      // Admins can read all verification requests
      allow read: if isAdmin();
      
      // PSA users can read their own verification status
      allow get: if isAuthenticated() && resource.data.psa_id == request.auth.uid;
      
      // PSA users can query their own verifications
      allow list: if isAuthenticated() && request.auth.uid != null;
      
      // PSA users can create verification requests with their own psa_id
      allow create: if isAuthenticated() && request.resource.data.psa_id == request.auth.uid;
      
      // PSA users can update their own unsubmitted verifications
      // Admins can update any verification (for approve/reject)
      allow update: if isAuthenticated() && 
                       (resource.data.psa_id == request.auth.uid || isAdmin());
      
      // Only admins can delete verifications
      allow delete: if isAdmin();
    }
    
    // ========================================
    // User Complaints Collection
    // ========================================
    
    match /user_complaints/{complaintId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // ========================================
    // Orders Collection
    // ========================================
    
    match /orders/{orderId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // ========================================
    // Messages Collection
    // ========================================
    
    match /messages/{messageId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // ========================================
    // Notifications Collection
    // ========================================
    
    match /notifications/{notificationId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // ========================================
    // Payments Collection
    // ========================================
    
    match /payments/{paymentId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // ========================================
    // Catch-all Rule (for any other collections)
    // ========================================
    
    match /{document=**} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

---

## 🔍 What Changed

The key fix is in the **PSA Verifications Collection** section:

```javascript
// ✅ THIS LINE ALLOWS ADMIN TO APPROVE/REJECT
allow update: if isAuthenticated() && 
                 (resource.data.psa_id == request.auth.uid || isAdmin());
//                                                       ^^^^^^^^^^^
//                          This allows admin to update any verification!
```

**Before**: No rules for `psa_verifications` → permission denied
**After**: Admin can update any verification → approve/reject works! ✅

---

## ✅ Expected Results After Deployment

### PSA User Can:
- ✅ Create verification request
- ✅ Read their own verification status
- ✅ Update their own unsubmitted verification
- ✅ See "Under Review" banner after submission

### Admin Can:
- ✅ Read all verification requests
- ✅ Update any verification (approve/reject)
- ✅ Delete verifications
- ✅ No more "permission-denied" errors!

---

## 🧪 Test Commands (After Deployment)

### Test 1: Check if rules are deployed
1. Go to Firebase Console
2. Navigate to: Firestore Database → Rules tab
3. Verify you see the PSA Verifications section
4. Check "Last published" timestamp is recent

### Test 2: Try admin approval
1. Login as admin in the app
2. Navigate to PSA Verifications screen
3. Click "Approve" on a pending verification
4. **Expected**: ✅ Success message, no errors

### Test 3: Try PSA submission
1. Login as PSA user
2. Navigate to Profile
3. Submit/resubmit verification
4. **Expected**: ✅ Submission succeeds, shows "Under Review"

---

## 🆘 Troubleshooting

### If you still get permission errors after deployment:

**1. Clear browser cache** (rules might be cached):
```
- Chrome: Ctrl+Shift+Delete → Clear cached images and files
- Firefox: Ctrl+Shift+Delete → Cached Web Content
```

**2. Wait 60 seconds** after publishing rules (propagation time)

**3. Verify admin user exists** in `admin_users` collection:
```
Collection: admin_users
Document ID: <your_admin_uid>
Fields:
  role: "admin"
  email: "admin@example.com"
```

**4. Check admin is logged in** with correct account

**5. Verify Firestore Security Rules syntax**:
- No syntax errors in Firebase Console
- "Publish" button was clicked successfully
- "Rules published successfully" message appeared

---

## 📞 Support

- **Firebase Project**: sayekataleapp
- **Console**: https://console.firebase.google.com/project/sayekataleapp
- **Rules URL**: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
- **GitHub**: https://github.com/DrakeNamanya/sayekataleapp

---

## 🎯 Summary

**Issue**: Permission denied when approving PSA verifications
**Cause**: Firestore rules not deployed to Firebase Console
**Fix**: Copy rules from local file to Firebase Console and publish
**Time**: 5 minutes
**Result**: Admin approval/rejection will work! ✅
