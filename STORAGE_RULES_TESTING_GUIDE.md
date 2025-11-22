# 🔍 Firebase Storage Rules Testing & Debugging Guide

## 🚨 Issue: User `drnamanya@gmail.com` Can't Add/Delete Products

### Root Cause Analysis

Based on your screenshot, I can see you're using the **Rules Playground** to test. The key issue is in the **"path/to/resource"** field.

---

## ❌ Common Mistakes in Rules Playground

### **1. Incorrect Path Format**

**You entered:** `path/to/resource` (placeholder text)  
**This is WRONG!** ❌

Firebase Storage requires **actual file paths** that match your upload code.

---

## ✅ Correct Testing Paths

### **For Product Images:**

According to your Flutter code (`lib/screens/shg/shg_products_screen.dart`), product images are uploaded to:

```
products/{userId}/{imageFileName}
```

**Example correct paths for testing:**
```
products/ABC123XYZ/tomato_image.jpg
products/drnamanya_user_id/product_photo_1.png
products/YourFirebaseUID/image.jpg
```

### **For Profile Photos:**

```
user_profiles/ABC123XYZ/profile_photo.jpg
user_profiles/drnamanya_user_id/avatar.png
```

### **For PSA Verification Documents:**

```
psa_verifications/ABC123XYZ/business_certificate.pdf
psa_verifications/YourFirebaseUID/signpost.jpg
```

---

## 🎯 How to Use Rules Playground Correctly

### **Step 1: Set Simulation Type**

- **For Upload/Create:** Select **`write`** or **`create`**
- **For View:** Select **`read`** or **`get`**
- **For Delete:** Select **`delete`**

### **Step 2: Enter Correct Location**

**Get your Firebase Storage bucket name from Firebase Console:**
```
/b/sayekataleapp.firebasestorage.app/o
```

### **Step 3: Enter Correct Path**

Replace `path/to/resource` with an **actual file path**:

**Examples:**
```
products/userABC123/tomato_photo.jpg
user_profiles/userABC123/profile_photo.png
psa_verifications/userABC123/certificate.pdf
```

### **Step 4: Set Authentication**

**Toggle "Authenticated" to ON** ✅

This simulates a logged-in user. When OFF, it simulates anonymous access.

### **Step 5: Click "Run"**

The result will show:
- ✅ **Success** - Rules allow the operation
- ❌ **Denied** - Rules block the operation

---

## 🔧 What is the Rules Playground?

The **Rules Playground** is a **testing tool** in Firebase Console that lets you:

1. **Test rules before deploying** - Simulate operations without affecting real data
2. **Debug permission errors** - See why operations fail
3. **Verify rule logic** - Test different scenarios (authenticated vs anonymous, different paths)
4. **Save development time** - No need to test in actual app

**Think of it as a "sandbox"** where you can safely test rules without breaking your app.

---

## 🐛 Debugging Your Specific Issue

### **Why `drnamanya@gmail.com` Can't Add Products**

Let me help you debug step-by-step:

### **Test 1: Check if User is Authenticated**

**In Rules Playground:**
1. Simulation type: **`write`**
2. Location: `/b/sayekataleapp.firebasestorage.app/o`
3. Path: `products/TEST_USER_ID/test_image.jpg`
4. Authenticated: **✅ ON**
5. Click **"Run"**

**Expected Result:** ✅ **Allowed**

If it shows ❌ **Denied**, the rules are not published correctly.

---

### **Test 2: Check Product Upload Path**

**Your Flutter code uploads to:**
```dart
folder: 'products'
userId: firebaseUid
```

This creates paths like: `products/{userId}/{imageFile}`

**Test in Playground:**
1. Get your Firebase UID from Firebase Console → Authentication
2. Use path: `products/YOUR_ACTUAL_FIREBASE_UID/test.jpg`
3. Authenticated: **ON**
4. Run

---

### **Test 3: Check File Type Validation**

Your rules validate:
```javascript
function isValidImage() {
  return request.resource.contentType.matches('image/.*') &&
         (request.resource.contentType.matches('image/jpeg') ||
          request.resource.contentType.matches('image/jpg') ||
          request.resource.contentType.matches('image/png') ||
          ...);
}
```

**Potential Issue:** If your app uploads files without proper MIME types, this check will fail.

---

## 🚨 Critical Issues to Check

### **Issue 1: Firebase UID vs App User ID**

Your Flutter code uses:
```dart
final firebaseUid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
imageUrls = await imageStorageService.uploadMultipleImagesFromXFiles(
  folder: 'products',
  userId: firebaseUid,  // ✅ Correct - uses Firebase Auth UID
);
```

**Make sure** your Firebase Auth UID matches the userId in the storage path!

---

### **Issue 2: Admin User Authentication**

Your rules check for admin:
```javascript
function isAdmin() {
  return request.auth != null && 
         (request.auth.token.admin == true || 
          request.auth.token.role == 'admin' ||
          request.auth.token.role == 'superAdmin');
}
```

**But your email `drnamanya@gmail.com` may not have these custom claims!**

---

## ✅ Solution: Simplified Storage Rules (For Testing)

If you want to **temporarily bypass all restrictions** for testing, use these simplified rules:

### **⚠️ TEMPORARY TESTING RULES (NOT FOR PRODUCTION!)**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // TEMPORARY: Allow all authenticated users to do anything
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Deploy these rules to test if authentication is working.**

If uploads work with these simplified rules, then the issue is in the validation functions (file size, file type, or isOwner checks).

---

## 🔍 Debugging Checklist

### **Step 1: Verify User is Authenticated**

**Check in Flutter app:**
```dart
final user = FirebaseAuth.instance.currentUser;
print('User UID: ${user?.uid}');
print('User Email: ${user?.email}');
```

### **Step 2: Check Firebase Console Authentication**

1. Go to: **Firebase Console → Authentication → Users**
2. Find user with email: `drnamanya@gmail.com`
3. Copy the **User UID** (long string like `ABC123XYZ...`)

### **Step 3: Test with Actual UID in Playground**

Use the **actual User UID** from Step 2 in your test path:
```
products/ABC123XYZ456DEF789/test_image.jpg
```

### **Step 4: Check Flutter Upload Code**

Verify the code is using correct paths:
```dart
await imageStorageService.uploadMultipleImagesFromXFiles(
  images: selectedImages,
  folder: 'products',  // ✅ This becomes "products/{userId}/"
  userId: FirebaseAuth.instance.currentUser!.uid,  // ✅ Firebase Auth UID
  compress: true,
);
```

### **Step 5: Check Browser Console for Errors**

When testing in web preview:
1. Open browser DevTools (F12)
2. Go to **Console** tab
3. Try to upload a product
4. Look for error messages like:
   - "Permission denied"
   - "User does not have permission"
   - "Firebase Storage: User does not have permission to access"

---

## 🎯 Recommended Testing Strategy

### **Phase 1: Test with Simplified Rules**

1. **Deploy simplified rules** (allow all authenticated)
2. **Test upload in app**
3. **If it works:** Rules were too restrictive
4. **If it fails:** Authentication issue

### **Phase 2: Identify Failing Validation**

If simplified rules work, add back restrictions one by one:

**Test 1: Add file size limit**
```javascript
allow write: if request.auth != null && 
                request.resource.size <= 5 * 1024 * 1024;
```

**Test 2: Add file type validation**
```javascript
allow write: if request.auth != null && 
                request.resource.size <= 5 * 1024 * 1024 &&
                request.resource.contentType.matches('image/.*');
```

**Test 3: Add ownership check**
```javascript
allow write: if request.auth != null && 
                request.auth.uid == userId &&
                request.resource.size <= 5 * 1024 * 1024;
```

### **Phase 3: Deploy Production Rules**

Once you identify the issue, deploy the full production rules.

---

## 📋 Quick Fixes

### **Fix 1: Remove isOwner Check for Products**

Current rule:
```javascript
match /user_profiles/{userId}/{allPaths=**} {
  allow write: if isAuthenticated() && isOwner(userId) && ...;
}
```

**Problem:** User might be uploading to wrong path

**Fix:** For products, don't check ownership:
```javascript
match /products/{productId}/{allPaths=**} {
  allow write: if isAuthenticated() && isValidImage() && isValidImageSize();
  // ✅ No isOwner check - any authenticated user can upload products
}
```

### **Fix 2: Simplify File Type Validation**

Current validation is very strict. Simplify:
```javascript
function isValidImage() {
  return request.resource.contentType.matches('image/.*');
  // ✅ Accept any image type
}
```

---

## 🚀 Deployment Commands

### **Deploy Rules via Firebase CLI (Alternative to Console):**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not done)
firebase init storage

# Deploy rules
firebase deploy --only storage
```

---

## 📊 Common Error Messages & Solutions

| Error Message | Cause | Solution |
|--------------|-------|----------|
| "Permission denied" | User not authenticated | Check Firebase Auth login |
| "User does not have permission to access" | Rules too restrictive | Test with simplified rules |
| "Invalid argument: 'path/to/resource'" | Using placeholder path | Use actual storage path |
| "Function isOwner() not defined" | Rules not deployed | Re-publish rules in Console |
| "File size exceeds limit" | File too large | Check file size < 5MB |
| "Invalid content type" | Wrong file type | Ensure image MIME type |

---

## ✅ Final Recommendations

### **For Your Specific Case (`drnamanya@gmail.com`):**

1. **Get your Firebase Auth UID** from Firebase Console → Authentication
2. **Use actual UID in Rules Playground** test path
3. **Test with simplified rules first** to isolate the issue
4. **Check browser console** for detailed error messages
5. **Verify file size** < 5MB and **file type** is image

### **Production Rules Should:**
- ✅ Allow authenticated users to upload products
- ✅ Validate file size (5MB images, 10MB docs)
- ✅ Validate file types (images, PDFs)
- ✅ Allow public read for product images
- ✅ Restrict profile photos to owner only

---

## 📝 Summary

**Rules Playground Purpose:**
- Testing tool, not required for production
- Simulates operations to verify rules
- Helps debug permission errors

**Your Issue:**
- Using placeholder path `path/to/resource` ❌
- Should use actual paths like `products/{userId}/image.jpg` ✅

**Next Steps:**
1. Get your Firebase Auth UID
2. Test in Playground with actual path
3. Use simplified rules if needed
4. Deploy production rules once working

Need help with any specific step? Let me know!
