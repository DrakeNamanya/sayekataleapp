# 🔓 Unlock Premium Farmer Directory for SME User

## 👤 Target User Information

- **Name**: Abby Rukundo
- **Email**: datacollectorslimited@gmail.com
- **Role**: SME (Small & Medium Enterprise)
- **Feature**: Premium Farmer Directory Access
- **Purpose**: Testing

---

## 🎯 What This Will Enable

After unlocking premium access, Abby Rukundo will have access to:

✅ **Farmer Directory** - Browse all registered farmers
✅ **Advanced Search** - Filter farmers by location, crops, ratings
✅ **Bulk Messaging** - Send messages to multiple farmers
✅ **Export Contacts** - Download farmer contact lists
✅ **Premium Support** - Priority customer support

---

## 📋 Prerequisites

To unlock premium features, you need:

1. **Firebase Admin SDK Service Account Key**
   - Download from: Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save as `firebase-admin-sdk.json`

2. **Python 3.x** with `firebase-admin` package
   ```bash
   pip install firebase-admin==7.1.0
   ```

---

## 🚀 Method 1: Using Python Script (Recommended)

### Step 1: Install Firebase Admin SDK

```bash
pip install firebase-admin==7.1.0
```

### Step 2: Get Firebase Admin SDK Key

1. Go to: https://console.firebase.google.com/project/sayekataleapp/settings/serviceaccounts/adminsdk
2. Click **"Generate new private key"**
3. Download the JSON file
4. Save it as: `/home/user/firebase-admin-sdk.json`

### Step 3: Run the Unlock Script

```bash
cd /home/user
python3 unlock_premium_farmer_directory.py
```

### Expected Output:

```
============================================================
🔓 PREMIUM FARMER DIRECTORY UNLOCK
============================================================

👤 Target User:
   Name: Abby Rukundo
   Email: datacollectorslimited@gmail.com
   Purpose: Testing Premium Farmer Directory

✅ firebase-admin imported successfully
📂 Using Firebase Admin SDK: /home/user/firebase-admin-sdk.json
✅ Firebase Admin initialized successfully
✅ Firestore client initialized

🔍 Searching for user with email: datacollectorslimited@gmail.com
✅ Found user: Abby Rukundo
   Role: sme
   User ID: <user_id>

🔓 Unlocking Premium Farmer Directory for: Abby Rukundo
✅ Premium Farmer Directory UNLOCKED!

📋 Subscription Details:
   Plan: Premium Test
   Status: Active
   Expiry: 2026-01-29 (1 year)

🎉 Features Enabled:
   ✅ Farmer Directory Access
   ✅ Advanced Search
   ✅ Bulk Messaging
   ✅ Export Contacts

📝 Activity log created

============================================================
✅ SUCCESS: Premium Farmer Directory Unlocked!
============================================================
```

---

## 🔧 Method 2: Using Firebase Console (Manual)

If you prefer to do this manually through Firebase Console:

### Step 1: Open Firestore Database

1. Go to: https://console.firebase.google.com/project/sayekataleapp/firestore
2. Navigate to **Firestore Database**

### Step 2: Find User Document

1. Go to `users` collection
2. Search for user with email: `datacollectorslimited@gmail.com`
3. Click on the user document

### Step 3: Add Premium Fields

Add/Update these fields in the user document:

```json
{
  "has_premium_access": true,
  "premium_features": {
    "farmer_directory": true,
    "advanced_search": true,
    "bulk_messaging": true,
    "export_contacts": true
  },
  "subscription_plan": "premium_test",
  "subscription_status": "active",
  "subscription_start": "2025-01-29T00:00:00Z",
  "subscription_expiry": "2026-01-29T00:00:00Z",
  "updated_at": "<current_timestamp>"
}
```

### Step 4: Save Changes

Click **"Update"** to save the changes.

---

## 🧪 Testing the Premium Feature

### Step 1: Login to the App

**Web Preview**: https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai

**Credentials**:
- Email: `datacollectorslimited@gmail.com`
- Password: <user's password>

### Step 2: Navigate to Farmer Directory

1. After login, you'll see the **SME Dashboard**
2. Look for **"Farmer Directory"** or **"Browse Farmers"** section
3. Click to access the directory

### Step 3: Verify Premium Features

Check that these features are accessible:

✅ **View All Farmers**
- Should see a complete list of registered farmers
- No "Upgrade to Premium" prompts

✅ **Advanced Search**
- Filter by location (district, sub-county, parish)
- Filter by crops grown
- Filter by ratings
- Sort options

✅ **Bulk Messaging**
- Select multiple farmers
- Send group messages
- Message templates

✅ **Export Contacts**
- Download farmer data as CSV/Excel
- Export filtered results
- Include contact information

### Expected Behavior:

✅ **Premium Badge**: User profile shows "Premium Member" badge
✅ **No Payment Prompts**: No requests to upgrade or pay
✅ **Full Access**: All farmer directory features are unlocked
✅ **Export Functionality**: Can download farmer contact lists

---

## 🔍 Verification Steps

### Check User Document in Firestore:

1. Go to Firestore Console
2. Navigate to `users` collection
3. Find user: `datacollectorslimited@gmail.com`
4. Verify fields exist:
   - `has_premium_access: true`
   - `premium_features.farmer_directory: true`
   - `subscription_status: 'active'`

### Check in App:

1. Login as the user
2. Check for premium indicators in UI
3. Try accessing farmer directory
4. Test export functionality

---

## 📱 App Code Changes (If Needed)

If the app doesn't automatically recognize premium status, you may need to add premium checks:

### Check Premium Status in Code:

```dart
// In SME Dashboard or Farmer Directory Screen
bool hasPremiumAccess() {
  final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
  return user?.hasPremiumAccess ?? false;
}

bool canAccessFarmerDirectory() {
  final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
  return user?.premiumFeatures?['farmer_directory'] ?? false;
}
```

### Show/Hide Features Based on Premium:

```dart
if (hasPremiumAccess()) {
  // Show premium features
  - Advanced search filters
  - Bulk messaging button
  - Export to CSV button
} else {
  // Show upgrade prompt
  - "Upgrade to Premium" button
  - Limited farmer list (first 10 only)
}
```

---

## 🔄 Revoking Premium Access (If Needed)

To revoke premium access later:

### Method 1: Using Firebase Console

Update user document fields:
```json
{
  "has_premium_access": false,
  "subscription_status": "expired"
}
```

### Method 2: Using Script

Create a revoke script similar to the unlock script, but set:
```python
subscription_data = {
    'has_premium_access': False,
    'subscription_status': 'expired',
    'subscription_end': firestore.SERVER_TIMESTAMP,
}
```

---

## 📊 Current Status

- **Script Created**: ✅ `/home/user/unlock_premium_farmer_directory.py`
- **Firebase Admin SDK**: ⚠️ Needs to be provided
- **Target User**: datacollectorslimited@gmail.com (Abby Rukundo)
- **Feature**: Premium Farmer Directory
- **Duration**: 1 year (testing)

---

## 🚨 Troubleshooting

### Issue: User not found

**Solution**:
1. Verify email is correct: `datacollectorslimited@gmail.com`
2. Check if user has registered in the app
3. Look in Firestore `users` collection manually

### Issue: Firebase Admin SDK error

**Solution**:
1. Ensure you have the correct service account JSON file
2. Verify file path is correct
3. Check Firebase project ID matches: `sayekataleapp`

### Issue: Premium features not showing in app

**Solution**:
1. Force logout and login again
2. Clear app cache
3. Check if app code has premium feature gates
4. Verify user document in Firestore was updated

---

## 📞 Next Steps

1. **Get Firebase Admin SDK Key** from Firebase Console
2. **Run the unlock script** to grant premium access
3. **Test in the app** to verify features work
4. **Provide feedback** on any issues

---

## ✅ Success Criteria

After unlocking, verify:

✅ User can login successfully
✅ SME Dashboard shows "Premium Member" badge
✅ Farmer Directory is fully accessible
✅ Advanced search filters are available
✅ Bulk messaging works
✅ Export to CSV functionality works
✅ No "Upgrade to Premium" prompts appear

---

**Created**: 2025-01-29  
**Target User**: datacollectorslimited@gmail.com (Abby Rukundo)  
**Feature**: Premium Farmer Directory  
**Status**: Ready to Execute (Requires Firebase Admin SDK Key)
