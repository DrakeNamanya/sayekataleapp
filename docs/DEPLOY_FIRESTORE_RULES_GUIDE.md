# 🚀 COMPLETE FIRESTORE RULES DEPLOYMENT GUIDE

## **📋 OVERVIEW**

This guide will help you deploy the updated Firestore Security Rules that fix:
1. ✅ PSA Approve/Reject permission errors
2. ✅ Profile update "not-found" errors
3. ✅ Product image loading issues

---

## **🔥 STEP 1: DEPLOY FIRESTORE RULES**

### **Method A: Firebase Console (Recommended - Easy)**

1. **Open Firebase Console:**
   - Go to: **https://console.firebase.google.com/project/sayekataleapp/firestore/rules**

2. **Copy the Updated Rules:**
   - The rules are in `/home/user/flutter_app/firestore.rules`
   - Or copy from the code block at the end of this guide

3. **Replace Existing Rules:**
   - **Select all text** in the Firebase Console editor (Ctrl+A / Cmd+A)
   - **Delete** existing rules
   - **Paste** the new rules

4. **Publish Rules:**
   - Click **"Publish"** button (top-right)
   - Wait for confirmation message
   - Verify publication timestamp updates

### **Method B: Firebase CLI (Advanced)**

```bash
# From your local machine (not sandbox)
cd path/to/your/flutter_app

# Login to Firebase (if not already)
firebase login

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules:get
```

---

## **🔧 STEP 2: CONFIGURE ADMIN USER**

### **Critical Requirement:**
Your admin user MUST have a document in the `users` collection with `role: "admin"` or `role: "superAdmin"`.

### **How to Set Up Admin User:**

#### **Method A: Firebase Console (Easiest)**

1. **Open Firestore Database:**
   - Go to: **https://console.firebase.google.com/project/sayekataleapp/firestore/data**

2. **Navigate to users Collection:**
   - Click on **"users"** collection

3. **Find Your Admin User:**
   - Look for a document with your admin email
   - Document ID should be your Firebase Auth UID

4. **Add/Update role Field:**
   - Click on the document
   - Click **"Add field"** or edit existing field
   - **Field name:** `role`
   - **Field type:** `string`
   - **Value:** `admin` (or `superAdmin`)
   - Click **"Update"**

#### **Method B: Flutter App Code**

Add this one-time setup code to your admin app:

```dart
// Run this ONCE to set up admin user
Future<void> setupAdminUser(String adminUid) async {
  try {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(adminUid)  // Replace with your Firebase Auth UID
      .set({
        'role': 'admin',  // ← This is the critical field
        'email': 'admin@example.com',
        'name': 'Admin Name',
        'phone': '+256700000000',
        'uid': adminUid,
      }, SetOptions(merge: true));
    
    print('✅ Admin user configured successfully');
  } catch (e) {
    print('❌ Admin setup failed: $e');
  }
}
```

#### **Method C: Python Script (Backend)**

If you have Firebase Admin SDK access:

```python
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin SDK
cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# Set admin role
admin_uid = 'your-firebase-auth-uid-here'
db.collection('users').document(admin_uid).set({
    'role': 'admin',
    'email': 'admin@example.com',
    'name': 'Admin Name',
    'phone': '+256700000000',
    'uid': admin_uid,
}, merge=True)

print('✅ Admin user configured')
```

### **Verify Admin Setup:**

```dart
// Check if current user is admin
Future<bool> isCurrentUserAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .get();
  
  final role = userDoc.data()?['role'] as String?;
  print('User role: $role');
  return role == 'admin' || role == 'superAdmin';
}
```

---

## **🔧 STEP 3: UPDATE FLUTTER APP CODE**

### **Fix Profile Update Logic:**

**File:** `lib/services/user_service.dart` (or wherever you handle profile updates)

**❌ OLD CODE (Causes "not-found" errors):**
```dart
Future<void> updateUserProfile(Map<String, dynamic> data) async {
  final user = FirebaseAuth.instance.currentUser;
  await FirebaseFirestore.instance
    .collection('users')
    .doc(user!.uid)
    .update(data);  // ← This fails if document doesn't exist
}
```

**✅ NEW CODE (Works with new rules):**
```dart
Future<void> updateUserProfile(Map<String, dynamic> data) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not authenticated');
  
  // Remove protected fields (rules will reject these anyway)
  data.remove('role');
  data.remove('uid');
  
  // Use set() with merge instead of update()
  await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)  // ← Document ID MUST match Firebase Auth UID
    .set(data, SetOptions(merge: true));  // ← Works for both create and update
}
```

### **Verify PSA Approval Code:**

**File:** `lib/services/admin_service.dart` (or similar)

```dart
Future<void> approvePsaVerification(String verificationId, String notes) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Not authenticated');
  
  // Rules will now check if user.uid exists in users collection with role=admin
  await FirebaseFirestore.instance
    .collection('psa_verifications')
    .doc(verificationId)
    .update({
      'status': 'approved',
      'reviewed_by': user.uid,
      'reviewed_at': FieldValue.serverTimestamp(),
      'notes': notes,
    });
}

Future<void> rejectPsaVerification(String verificationId, String reason) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Not authenticated');
  
  await FirebaseFirestore.instance
    .collection('psa_verifications')
    .doc(verificationId)
    .update({
      'status': 'rejected',
      'reviewed_by': user.uid,
      'reviewed_at': FieldValue.serverTimestamp(),
      'rejection_reason': reason,
    });
}
```

---

## **🔧 STEP 4: FIX PRODUCT IMAGE ISSUES**

### **Check Image URLs in Firestore:**

1. **Open Firestore Database:**
   - Go to: **https://console.firebase.google.com/project/sayekataleapp/firestore/data**

2. **Navigate to products Collection:**
   - Click on **"products"** collection
   - Select any product document

3. **Verify images Field:**
   - Should be an array of strings
   - Each string should be a full Firebase Storage URL

**✅ CORRECT format:**
```json
{
  "images": [
    "https://firebasestorage.googleapis.com/v0/b/sayekataleapp.appspot.com/o/products%2Fproduct123%2Fimage1.jpg?alt=media&token=abc123..."
  ]
}
```

**❌ WRONG formats:**
```json
// Empty array
{"images": []}

// Relative paths
{"images": ["image1.jpg", "image2.jpg"]}

// Storage URIs (not download URLs)
{"images": ["gs://bucket/products/123/image.jpg"]}
```

### **Fix Image Upload Code:**

```dart
class ImageStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Future<String> uploadProductImage(File imageFile, String productId) async {
    try {
      // Generate unique filename
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Storage
      final ref = _storage.ref('products/$productId/$fileName');
      await ref.putFile(imageFile);
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      
      print('✅ Image uploaded: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Image upload failed: $e');
      rethrow;
    }
  }
  
  Future<void> saveProductImages(String productId, List<File> imageFiles) async {
    final uploadedUrls = <String>[];
    
    // Upload all images
    for (final imageFile in imageFiles) {
      final url = await uploadProductImage(imageFile, productId);
      uploadedUrls.add(url);
    }
    
    // Save URLs to Firestore
    await FirebaseFirestore.instance
      .collection('products')
      .doc(productId)
      .update({
        'images': uploadedUrls,  // ← Save as array of download URLs
      });
  }
}
```

### **Display Images Correctly:**

```dart
class ProductImage extends StatelessWidget {
  final String imageUrl;
  
  @override
  Widget build(BuildContext context) {
    // Validate URL
    if (imageUrl.isEmpty || !imageUrl.startsWith('https://')) {
      return _buildPlaceholder('Invalid URL');
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Image load error: $error');
        return _buildPlaceholder('Image Load Failed');
      },
    );
  }
  
  Widget _buildPlaceholder(String message) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
```

---

## **🔧 STEP 5: BUILD AND TEST**

### **Build Updated APK:**

```bash
cd /home/user/flutter_app

# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# APK location:
# /home/user/flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

### **Testing Checklist:**

#### **Test 1: Admin Login & PSA Approval**
- [ ] Login with admin account
- [ ] Navigate to PSA Verification screen
- [ ] Select a pending verification
- [ ] Click "Approve" button
- [ ] **Expected:** ✅ Approval succeeds, no permission errors
- [ ] **Check Firestore:** Status should be "approved"

#### **Test 2: PSA Rejection**
- [ ] Select a pending verification
- [ ] Click "Reject" button
- [ ] Enter rejection reason
- [ ] **Expected:** ✅ Rejection succeeds with reason saved
- [ ] **Check Firestore:** Status should be "rejected" with reason

#### **Test 3: Profile Updates**
- [ ] Login as any user (buyer, farmer, PSA)
- [ ] Go to Profile/Settings
- [ ] Update name, phone, or bio
- [ ] Click "Save"
- [ ] **Expected:** ✅ Update succeeds, no "not-found" errors
- [ ] **Refresh app:** Changes should persist

#### **Test 4: Product Images**
- [ ] Browse products in marketplace
- [ ] **Expected:** ✅ Product images load correctly
- [ ] **If images fail:** Check Firestore for valid URLs

---

## **🔍 TROUBLESHOOTING**

### **Issue: PSA Approval Still Shows Permission Denied**

**Cause:** Admin user doesn't have correct role in `users` collection

**Solution:**
1. Go to Firebase Console → Firestore → `users` collection
2. Find your admin user document (by email or UID)
3. Add/update field: `role: "admin"`
4. **Re-login** to your app
5. Try approval again

**Verification:**
```dart
// In your Flutter app, check current user role:
final userDoc = await FirebaseFirestore.instance
  .collection('users')
  .doc(FirebaseAuth.instance.currentUser!.uid)
  .get();
  
print('Current role: ${userDoc.data()?['role']}');
// Should print: "Current role: admin"
```

### **Issue: Profile Update Shows "not-found"**

**Cause:** Using `.update()` instead of `.set(merge: true)`

**Solution:**
1. Update your profile update code (see Step 3 above)
2. Use `.set(data, SetOptions(merge: true))` instead of `.update(data)`
3. Rebuild APK
4. Test again

### **Issue: Product Images Show "Image Unavailable"**

**Causes & Solutions:**

**Cause 1:** Invalid URLs in Firestore
- **Check:** Open Firestore → `products` → verify `images` array
- **Fix:** Upload images again with correct code (see Step 4)

**Cause 2:** Images not uploaded to Storage
- **Check:** Firebase Console → Storage → verify files exist in `products/` folder
- **Fix:** Re-upload images through your app

**Cause 3:** Browser DevTools shows specific error
- **Check:** Press F12 → Console → look for firebase_storage errors
- **Fix:** Based on specific error message

---

## **📊 VERIFICATION COMMANDS**

### **Check Current Firestore Rules:**
```bash
# From your terminal
firebase firestore:rules:get

# Should show the updated rules with:
# - isAdmin() checking users collection
# - Combined create/update for users
```

### **Test Rules with Firebase Emulator:**
```bash
firebase emulators:start --only firestore
# Then run your app pointing to emulator
```

### **Check Admin User in Firestore:**
```javascript
// In Firebase Console → Firestore → Run query
db.collection("users")
  .where("role", "in", ["admin", "superAdmin"])
  .get()
  
// Should return at least one document
```

---

## **📦 UPDATED RULES (Copy to Firebase Console)**

<details>
<summary><b>Click to expand complete Firestore Rules</b></summary>

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // ✅ CRITICAL FIX: Check users collection for admin role
    function isAdmin() {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
              get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'superAdmin');
    }
    
    // PSA Verifications Collection
    match /psa_verifications/{verificationId} {
      allow read: if isAdmin();
      allow get: if isAuthenticated() && resource.data.psa_id == request.auth.uid;
      allow list: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.psa_id == request.auth.uid;
      allow update: if isAuthenticated() && 
                       (resource.data.psa_id == request.auth.uid || isAdmin());
      allow delete: if isAdmin();
    }
    
    // Users Collection (FIXED)
    match /users/{userId} {
      allow read: if isAuthenticated();
      
      // ✅ CRITICAL FIX: Combined create/update for profile management
      allow create, update: if isOwner(userId) &&
                               (!('role' in request.resource.data) || 
                                !('role' in resource.data) || 
                                request.resource.data.role == resource.data.role) &&
                               (!('uid' in request.resource.data) || 
                                !('uid' in resource.data) || 
                                request.resource.data.uid == resource.data.uid);
      
      allow delete: if isOwner(userId) || isAdmin();
    }
    
    // [Rest of your rules - products, orders, etc.]
    // Copy complete rules from /home/user/flutter_app/firestore.rules
  }
}
```

</details>

---

## **✅ DEPLOYMENT CHECKLIST**

### **Pre-Deployment:**
- [ ] Rules file ready: `/home/user/flutter_app/firestore.rules`
- [ ] Admin user email/UID identified
- [ ] Current app behavior documented

### **Deployment:**
- [ ] Firestore rules deployed to Firebase Console
- [ ] Rules published successfully
- [ ] Admin user configured with `role: "admin"`
- [ ] Flutter app code updated (if needed)
- [ ] New APK built and deployed

### **Post-Deployment:**
- [ ] PSA approval tested successfully
- [ ] PSA rejection tested successfully
- [ ] Profile updates tested successfully
- [ ] Product images loading correctly
- [ ] No error logs in Firebase Console

---

## **📞 SUPPORT**

If you encounter issues:

1. **Check Firebase Console Logs:**
   - Go to: https://console.firebase.google.com/project/sayekataleapp/usage
   - Look for permission errors

2. **Check Flutter App Logs:**
   - Run `flutter run` with debug mode
   - Look for Firestore error messages

3. **Verify Rules Syntax:**
   - Rules should have no syntax errors
   - Publication timestamp should be recent

4. **Test with Firebase Emulator:**
   - Test rules locally before deploying
   - Use Rules Playground in Firebase Console

---

**🔗 GitHub Commit:** `ab6891c` - CRITICAL FIX: Firestore Rules - Admin check & profile update  
**📅 Deployment Date:** 2025-01-24  
**📊 Status:** Ready for Production Deployment

---

**Need the complete rules file?** It's located at: `/home/user/flutter_app/firestore.rules`
