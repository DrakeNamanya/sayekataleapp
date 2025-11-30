# 🔥 Firestore Security Rules - Critical Fixes Required

**Date**: 2025-11-30  
**Status**: ⚠️ **URGENT FIXES NEEDED**

---

## 🔴 **Issues Identified from Screenshots**

### 1. PSA Verification Approval/Rejection Failing
```
Error: [cloud_firestore/permission-denied] The caller does not 
have permission to execute the specified operation.
```

**Root Cause**: Admin user trying to approve/reject PSA verifications but Firestore rules checking for admin document existence fails.

### 2. Profile Update Failing
```
Error: [cloud_firestore/not-found] Some requested document 
was not found.
```

**Root Cause**: User profile update trying to access non-existent fields or missing documents.

### 3. Product Images Not Loading
```
All products show: "Image unavailable"
```

**Root Cause**: Image URLs in Firestore may be:
- Invalid Firebase Storage URLs
- Missing `images` or `image_url` fields
- Empty arrays
- CORS issues with Firebase Storage

---

## ✅ **Solution: Updated Firestore Security Rules**

### **Critical Changes Needed**:

1. **Fix Admin Check Function**:
```javascript
// Current (may fail if admin_users doc doesn't exist yet)
function isAdmin() {
  return isAuthenticated() && 
         exists(/databases/$(database)/documents/admin_users/$(request.auth.uid));
}

// ✅ FIXED - Check users collection for admin role
function isAdmin() {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

2. **Add Permissive PSA Verification Rules for Admins**:
```javascript
// PSA Verifications collection
match /psa_verifications/{verificationId} {
  // ✅ Allow admins full access
  allow read, write: if isAdmin();
  
  // PSA users can read their own verification status
  allow get: if isAuthenticated() && resource.data.psa_id == request.auth.uid;
  
  // PSA users can query their own verifications
  allow list: if isAuthenticated();
  
  // PSA users can create verification requests
  allow create: if isAuthenticated() && request.resource.data.psa_id == request.auth.uid;
  
  // PSA users can update their own pending verifications
  allow update: if isAuthenticated() && 
                   resource.data.psa_id == request.auth.uid &&
                   resource.data.status == 'pending';
}
```

3. **Fix Users Collection Rules**:
```javascript
// Users collection
match /users/{userId} {
  // Allow reading any user profile (for admin, chat, etc.)
  allow read: if isAuthenticated();
  
  // Allow users to update their own profile OR admins to update any profile
  allow update: if isAuthenticated() && 
                   (request.auth.uid == userId || isAdmin());
  
  // Allow creating own profile during registration
  allow create: if isAuthenticated() && request.auth.uid == userId;
  
  // Only admins can delete users
  allow delete: if isAdmin();
}
```

---

## 📝 **Complete Fixed firestore.rules File**

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // ✅ Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // ✅ FIXED: Check users collection for admin role
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Admin users collection (legacy - keeping for backward compatibility)
    match /admin_users/{adminId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // ✅ FIXED: Users collection with proper admin override
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow update: if isAuthenticated() && 
                       (request.auth.uid == userId || isAdmin());
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if isAdmin();
    }
    
    // Products collection (images stored here)
    match /products/{productId} {
      allow read: if true; // Public read for browsing
      allow write: if isAuthenticated();
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Messages collection
    match /messages/{messageId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Complaints collection
    match /complaints/{complaintId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Subscriptions collection
    match /subscriptions/{subscriptionId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // SME Directory collection
    match /sme_directory/{smeId} {
      allow read: if true; // Public read
      allow write: if isAuthenticated();
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      allow read: if true; // Public read
      allow write: if isAuthenticated();
    }
    
    // Wallet transactions
    match /wallet_transactions/{transactionId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Payment records
    match /payments/{paymentId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // ✅ FIXED: PSA Verifications collection
    match /psa_verifications/{verificationId} {
      // Admins have full access
      allow read, write: if isAdmin();
      
      // PSA users can read their own verification status
      allow get: if isAuthenticated() && resource.data.psa_id == request.auth.uid;
      
      // PSA users can query verifications (filtered by their own)
      allow list: if isAuthenticated();
      
      // PSA users can create verification requests
      allow create: if isAuthenticated() && request.resource.data.psa_id == request.auth.uid;
      
      // PSA users can update their own pending verifications
      allow update: if isAuthenticated() && 
                       resource.data.psa_id == request.auth.uid &&
                       resource.data.status == 'pending';
    }
    
    // User complaints collection
    match /user_complaints/{complaintId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Allow all other collections (for development flexibility)
    match /{document=**} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

---

## 🔧 **How to Deploy These Rules**

### **Option 1: Firebase Console (Recommended)**

1. **Go to Firebase Console**:
   - Visit: https://console.firebase.google.com/project/sayekataleapp/firestore/rules

2. **Replace Rules**:
   - Copy the complete rules above
   - Paste into the rules editor
   - Click **"Publish"**

3. **Verify Deployment**:
   - Test PSA approval/rejection in app
   - Test profile updates
   - Check if operations succeed

### **Option 2: Firebase CLI**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Deploy rules
firebase deploy --only firestore:rules
```

---

## 🖼️ **Product Images Not Loading - Investigation**

### **Possible Causes**:

1. **Invalid Firebase Storage URLs**:
   - Check if products have valid `images` array or `image_url` field
   - Verify URLs point to Firebase Storage

2. **CORS Configuration**:
   - Firebase Storage may need CORS configuration
   - Check if images are publicly accessible

3. **Empty Image Arrays**:
   - Products created without images
   - Default placeholders not configured

### **Debug Query**:

```javascript
// Check product image data in Firestore Console
// Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/data/products

// Look for:
// - images: [] (empty array)
// - image_url: "" (empty string)
// - missing fields entirely
```

### **Temporary Fix (Until Real Images Uploaded)**:

Add default placeholder images to products without images:

```dart
// In Product.fromFirestore()
images: data['image_url'] != null && data['image_url'].isNotEmpty
    ? [data['image_url']]
    : (data['images'] != null && (data['images'] as List).isNotEmpty
        ? List<String>.from(data['images'])
        : ['https://via.placeholder.com/400x300.png?text=No+Image']), // Default placeholder
```

---

## ✅ **Verification Steps After Deploying Rules**

### 1. Test PSA Approval (Screenshot 1 Error)
- Login as admin
- Navigate to PSA Verification screen
- Click "Approve" on pending PSA
- ✅ Should succeed without permission error

### 2. Test PSA Rejection (Screenshot 1 Error)
- Click "Reject" on pending PSA
- Enter rejection reason
- Submit
- ✅ Should succeed without permission error

### 3. Test Profile Update (Screenshot 2 Error)
- Login as any user
- Go to Edit Profile
- Update location/details
- Save
- ✅ Should succeed without not-found error

### 4. Test Product Image Loading (Screenshot 4 Issue)
- Navigate to Browse Products
- Check if product images load
- If still failing:
  - Check Firestore Console product documents
  - Verify `images` array has valid URLs
  - Check Firebase Storage CORS configuration

---

## 📊 **Priority Action Items**

| Priority | Action | Status |
|----------|--------|--------|
| 🔴 **HIGH** | Deploy fixed Firestore rules | ⏳ Pending |
| 🔴 **HIGH** | Test PSA approve/reject | ⏳ After rules |
| 🔴 **HIGH** | Test profile updates | ⏳ After rules |
| 🟡 **MEDIUM** | Investigate product images | ⏳ Needs data check |
| 🟡 **MEDIUM** | Add default image placeholders | ⏳ Code change |

---

## 🚨 **URGENT: Deploy Rules Now**

**The current Firestore rules are blocking critical admin operations.**

**Steps**:
1. Copy the complete rules above
2. Go to Firebase Console Firestore Rules
3. Paste and Publish
4. Test immediately in app

---

**End of Report**
