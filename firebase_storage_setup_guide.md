# Firebase Storage Setup Guide - Fresh Water Fish App

## 📋 Overview
Firebase Storage needs **one-time manual configuration** in Firebase Console to enable photo uploads. This guide shows you exactly what to do.

---

## ⚠️ CRITICAL: Is Firebase Storage Already Enabled?

### Quick Check (2 minutes):
1. Go to **Firebase Console**: https://console.firebase.google.com/
2. Select your project
3. Click **"Build"** → **"Storage"** in left menu
4. Look for one of these:

#### ✅ If You See Storage Bucket:
```
gs://your-project-name.appspot.com
Files | Rules | Usage tabs
```
**→ Firebase Storage is ALREADY ENABLED! Skip to Security Rules section.**

#### ❌ If You See "Get Started" Button:
```
"Get started" button with wizard
```
**→ Firebase Storage is NOT enabled. Follow Step 1 below.**

---

## 🚀 Step 1: Enable Firebase Storage (First Time Only)

### If Storage is NOT enabled:

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. Select your project
3. Click **"Build"** → **"Storage"** in left menu
4. Click **"Get started"** button
5. A dialog appears:

#### Dialog Step 1: Security Rules
```
Start in production mode (Recommended for now)
OR
Start in test mode
```
**Choose**: "Start in **production mode**" (we'll set proper rules in Step 2)

Click **"Next"**

#### Dialog Step 2: Cloud Storage Location
```
Choose a location for Cloud Storage:
- us-central1 (Iowa)
- us-east1 (South Carolina)
- europe-west1 (Belgium)
- asia-northeast1 (Tokyo)
... etc
```
**Choose**: Select the location **closest to your users**
- Uganda users? → **europe-west1** (Belgium) or **asia-south1** (Mumbai)
- Testing in US? → **us-central1**

**⚠️ IMPORTANT**: This location **cannot be changed later**!

Click **"Done"**

6. Wait 10-30 seconds for Firebase to create the storage bucket

7. ✅ **Storage Enabled!** You'll see:
```
Files | Rules | Usage tabs
gs://your-project-name.appspot.com
```

---

## 🔐 Step 2: Configure Security Rules (Required!)

### Why Security Rules Matter:
Without proper rules, your app will get **"Permission denied"** errors when uploading photos!

### Option A: Use Firebase Console (Easiest - 2 minutes)

1. In Firebase Console → **Storage** → Click **"Rules"** tab
2. You'll see default rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if false; // Denies all access!
    }
  }
}
```

3. **Replace with these rules** (copy/paste):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Profile photos - only authenticated users can upload their own
    match /profiles/{userId}/{fileName} {
      allow read: if true; // Anyone can view profile photos
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024 // Max 5MB
                   && request.resource.contentType.matches('image/.*'); // Only images
    }
    
    // National ID photos - only authenticated users can upload their own
    match /national_ids/{userId}/{fileName} {
      allow read: if request.auth != null && request.auth.uid == userId; // Only owner can view
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024 // Max 10MB (needs clarity)
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Product photos - authenticated users can upload to their folder
    match /products/{userId}/{fileName} {
      allow read: if true; // Anyone can view product photos
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024 // Max 5MB
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Thumbnails - same as parent folders
    match /profiles/thumbnails/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /products/thumbnails/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

4. Click **"Publish"** button

5. ✅ **Security Rules Published!**

### Option B: Use Firebase CLI (Advanced)

If you prefer using command line:

1. Install Firebase CLI (if not installed):
```bash
npm install -g firebase-tools
firebase login
```

2. Initialize Firebase in your project:
```bash
cd /home/user/flutter_app
firebase init storage
```

3. Edit `storage.rules` file with the rules above

4. Deploy:
```bash
firebase deploy --only storage
```

---

## 🧪 Step 3: Test Your Setup (3 minutes)

### Test in Flutter App:

1. **Open the app**: https://5060-i25ra390rl3tp6c83ufw7-583b4d74.sandbox.novita.ai

2. **Login as any user** (SHG, SME, or PSA)

3. **Go to Edit Profile**

4. **Select a profile photo**

5. **Click "Save Profile"**

6. **Open Browser Console** (Press F12) and look for:
```
✅ Image uploaded successfully: https://firebasestorage.googleapis.com/...
```

7. **Check Firebase Console**:
   - Go to Storage → Files tab
   - You should see:
   ```
   📁 profiles/
      └── 📁 user123/
           └── 🖼️ profile_1234567890.jpg
   ```

### ✅ If Upload Succeeds:
**Storage is configured correctly!**

### ❌ If You See Errors:

#### Error: "Permission denied"
```
FirebaseError: Firebase Storage: User does not have permission
```
**Fix**: Go back to Step 2 and publish the security rules

#### Error: "Storage bucket not configured"
```
FirebaseError: Firebase Storage: No default bucket found
```
**Fix**: 
1. Check `firebase_options.dart` has `storageBucket` configured
2. Or go to Step 1 and enable Storage

#### Error: "Network error"
```
Failed to upload: NetworkError
```
**Fix**: Check your internet connection

---

## 📊 Storage Folder Structure

After setup, your Firebase Storage will look like:

```
firebase-storage/
├── 📁 profiles/
│   ├── 📁 user_id_1/
│   │   ├── profile_1234567890.jpg (Farmer's profile photo)
│   │   └── profile_1234567891.jpg (Updated photo)
│   ├── 📁 user_id_2/
│   └── 📁 thumbnails/
│       └── 📁 user_id_1/
│           └── thumb_profile_1234567890.jpg
│
├── 📁 national_ids/
│   ├── 📁 user_id_1/
│   │   └── national_id_1234567890.jpg (Private - only owner can view)
│   └── 📁 user_id_2/
│
└── 📁 products/
    ├── 📁 user_id_1/
    │   ├── product_1234567890_0.jpg (First product photo)
    │   ├── product_1234567890_1.jpg (Second product photo)
    │   └── product_1234567890_2.jpg (Third product photo)
    └── 📁 thumbnails/
        └── 📁 user_id_1/
```

---

## 💰 Pricing Information

### Firebase Storage Pricing (Pay-as-you-go):
- **Storage**: $0.026/GB per month
- **Download**: $0.12/GB
- **Upload**: Free
- **Operations**: $0.05 per 10,000 operations

### Free Tier (Spark Plan):
- **5 GB** stored
- **1 GB/day** download
- **20,000/day** uploads
- **50,000/day** downloads

### Estimated Costs (1000 Active Users):

#### Monthly Storage:
- 1000 users × 2 photos × 200KB = 400MB
- 1000 products × 3 photos × 200KB = 600MB
- **Total**: ~1GB = **$0.026/month**

#### Monthly Bandwidth:
- Profile views: 1000 users × 10 views/day × 200KB × 30 days = 60GB
- **Cost**: 60GB × $0.12 = **$7.20/month**

#### With Image Compression (Current Setup):
- Photos compressed 50-80%
- **Actual cost**: ~$3-4/month for 1000 users

---

## 🔒 Security Rules Explained

### What Each Rule Does:

#### Profile Photos:
```javascript
allow read: if true; // Anyone can view profile photos (public)
allow write: if request.auth != null && request.auth.uid == userId
```
- ✅ Anyone can VIEW profile photos (for customer browsing)
- ✅ Only the owner can UPLOAD/UPDATE their own photos
- ✅ Max 5MB file size
- ✅ Only image files allowed

#### National ID Photos:
```javascript
allow read: if request.auth != null && request.auth.uid == userId; // Private!
```
- 🔒 Only the owner can VIEW their own ID photos
- 🔒 Only the owner can UPLOAD their ID photos
- ✅ Max 10MB (ID photos need clarity, no compression)

#### Product Photos:
```javascript
allow read: if true; // Anyone can view products
allow write: if request.auth != null && request.auth.uid == userId
```
- ✅ Anyone can VIEW product photos (for customers)
- ✅ Only the farmer can UPLOAD their product photos

---

## ✅ Setup Checklist

Use this checklist to ensure everything is configured:

- [ ] Firebase Storage enabled in Firebase Console
- [ ] Storage bucket location selected (cannot change later!)
- [ ] Security rules published (copy/paste from Option A above)
- [ ] Test upload successful from Flutter app
- [ ] Browser console shows: "Image uploaded successfully"
- [ ] Firebase Console shows uploaded files in correct folders
- [ ] Profile photos display in app after upload

---

## 🆘 Troubleshooting

### "Get started" button still showing?
→ You haven't enabled Storage yet. Click it and follow Step 1.

### "Permission denied" when uploading?
→ Security rules not published. Follow Step 2.

### Files uploading but not displaying?
→ Check image URLs in Firestore match Firebase Storage URLs

### Upload takes too long?
→ Normal for first upload. Subsequent uploads are faster (CDN caching)

### Want to delete test photos?
→ Go to Firebase Console → Storage → Files → Select files → Delete

---

## 📝 Summary

### What You Need to Do (ONE TIME ONLY):

1. ✅ **Enable Firebase Storage** (1 minute)
   - Go to Firebase Console → Storage → "Get started"
   - Choose location (important!)

2. ✅ **Configure Security Rules** (2 minutes)
   - Go to Rules tab
   - Copy/paste the rules from Option A
   - Click "Publish"

3. ✅ **Test Upload** (1 minute)
   - Upload a photo in the app
   - Check browser console for success message
   - Verify file appears in Firebase Console

### That's It! 
**No coding required, no SDK updates, no app rebuilding.**

The Flutter app is already configured to use Firebase Storage. You just need to enable it and set the security rules in Firebase Console.

---

## 🎉 After Setup

Once completed, your app will:
- ✅ Upload profile photos to Firebase Storage
- ✅ Upload national ID photos (private)
- ✅ Upload product photos (up to 3 per product)
- ✅ Compress images automatically (save bandwidth)
- ✅ Store only URLs in Firestore (not the images)
- ✅ Display photos from Firebase CDN (fast loading)
- ✅ Handle errors gracefully with user-friendly messages

**Total setup time**: 5-10 minutes (one time only!)
