# 🗑️ TEST USER CLEANUP - COMPLETE GUIDE

## 📋 Overview

This guide provides instructions for cleaning 20 test users from the SAYE KATALE system using both:
1. **Automated Python Script** (Recommended - fastest)
2. **Manual Firebase Console** (Fallback method)

---

## ✅ METHOD 1: AUTOMATED CLEANUP (RECOMMENDED)

### **Prerequisites**

1. **Python 3.7+** installed
2. **firebase-admin** package: `pip install firebase-admin==7.1.0`
3. **Firebase Admin SDK JSON file**

### **Step 1: Get Firebase Admin SDK File**

1. Go to **Firebase Console**: https://console.firebase.google.com/project/sayekataleapp/settings/serviceaccounts/adminsdk
2. Select **"Python"** as Admin SDK configuration language
3. Click **"Generate new private key"**
4. Save the downloaded JSON file as `firebase-admin-sdk.json`

### **Step 2: Run Cleanup Script**

#### **Option A: Local Machine**

```bash
# 1. Copy the script
cp /home/user/cleanup_test_users.py ~/cleanup_test_users.py

# 2. Copy your Firebase Admin SDK file to same directory
cp /path/to/your/firebase-admin-sdk.json ~/firebase-admin-sdk.json

# 3. Install dependencies
pip install firebase-admin==7.1.0

# 4. Run the script
cd ~
python3 cleanup_test_users.py
```

#### **Option B: Google Cloud Shell**

```bash
# 1. Upload the script to Cloud Shell
# (Use the upload button in Cloud Shell UI)

# 2. Upload Firebase Admin SDK JSON file
# (Upload to Cloud Shell and rename to firebase-admin-sdk.json)

# 3. Install dependencies
pip install firebase-admin==7.1.0

# 4. Run the script
python3 cleanup_test_users.py
```

### **Step 3: Confirm and Execute**

The script will:
1. Show a summary of what will be deleted
2. Ask for confirmation (type `DELETE` to proceed)
3. Delete all 20 users from:
   - Firebase Authentication
   - Firestore Database (all collections)
   - Firebase Storage (user files)
4. Display detailed progress and final summary

### **Expected Output**

```
============================================================
SAYE KATALE - Test User Cleanup Script
============================================================

🗑️  Will delete 20 test users and all their data

⚠️  WARNING: This operation is IRREVERSIBLE!

============================================================

Type 'DELETE' to confirm and proceed: DELETE

============================================================
🚀 Starting cleanup process...
============================================================

[1/20] Processing: 4CdvRwCq0MOknJoWWPVHa5jYMWk1
------------------------------------------------------------
  ✅ Deleted from Auth: 4CdvRwCq0MOknJoWWPVHa5jYMWk1
  ✅ Deleted user profile: 4CdvRwCq0MOknJoWWPVHa5jYMWk1
  ✅ Deleted 3 products
  ✅ Deleted 5 orders
  ✅ Deleted 2 cart items
  ✅ Deleted 10 files from users/4CdvRwCq0MOknJoWWPVHa5jYMWk1/

[2/20] Processing: wvwCw0HS3UdMUnhu9cWlaIrbSRR2
------------------------------------------------------------
...

============================================================
✅ CLEANUP COMPLETE!
============================================================

📊 SUMMARY:
   Total users processed: 20

   Firebase Authentication:
     - Deleted: 20
     - Not found: 0

   Firestore Database:
     - Total documents deleted: 150
       • users: 20
       • products: 45
       • orders: 32
       • cart_items: 15
       • transactions: 10
       • reviews: 8
       • notifications: 20

   Firebase Storage:
     - Total files deleted: 85

============================================================
🎉 All test users have been cleaned from the system!
============================================================
```

### **Estimated Time**: 2-3 minutes for all 20 users

---

## ⚙️ METHOD 2: MANUAL CLEANUP (FALLBACK)

If you cannot run the Python script, follow these manual steps.

### **Step 1: Delete from Firebase Authentication**

1. Go to: https://console.firebase.google.com/project/sayekataleapp/authentication/users
2. Search for each UID and click **Delete User**:

```
4CdvRwCq0MOknJoWWPVHa5jYMWk1
wvwCw0HS3UdMUnhu9cWlaIrbSRR2
zAAapBidPAXIZRUWabNXv2pc7R03
xsmnGylST2PP0s2iIaR1EXTMmAr2
0Zj2bMjXjnMr9ilPUkdIlklKIyv1
XEIB0iHe40ZRY6s91oa9UMedJoH2
LuMFRxfBGnTpmimDAxZD49l2Qyj2
WKOaULMUedOh9EEcBAZnPFM7Vc72
lSdQEHBbP3dnxPtbmbgl24GoMQD3
faasyBXlpOTppRhCbX4uoaF8DQg2
SrWntuHEBmWrLF0YWTojA5YZ54y1
82yy5uWEZQT0gJcwxbfG57ZTpm03
y6LFppeDDrcWXLGjJsia3RJOwox2
SfFd266Pu7YIzcGa73G7YRBFFzj1
LGa2z4rkeEhr2QcBMoPFyneeH6t2
EawO0nfZpod4Pn7YbDd36TS72ez2
Ahyc4BNQ4RUPG1pgYEKJci05ukp2
EonaZZiFgaQCdvAec4qZd0KI2Ep1
cDHtgKvSl4VuORHUTysFArtqUFF2
tUFPvg2LovWabiifmcbkH6lUNpl1
```

### **Step 2: Delete from Firestore Database**

Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/data

For **EACH** of the 20 users above, delete documents from these collections:

#### **A. User Profile**
- Collection: `/users/{userId}`
- Action: Delete the document with ID matching the user UID

#### **B. Products**
- Collection: `/products`
- Query: `farmer_id == {userId}` OR `farm_id == {userId}`
- Action: Delete all matching documents

#### **C. Orders**
- Collection: `/orders`
- Query: `buyer_id == {userId}` OR `seller_id == {userId}` OR `farmerId == {userId}`
- Action: Delete all matching documents

#### **D. Transactions**
- Collection: `/transactions`
- Query: `user_id == {userId}`
- Action: Delete all matching documents

#### **E. PSA Verifications**
- Collection: `/psa_verifications`
- Query: `psa_id == {userId}`
- Action: Delete all matching documents

#### **F. Subscriptions**
- Collection: `/subscriptions`
- Query: `user_id == {userId}`
- Action: Delete all matching documents

#### **G. Cart Items**
- Collection: `/cart_items`
- Query: `user_id == {userId}`
- Action: Delete all matching documents

#### **H. Favorite Products**
- Collection: `/favorite_products`
- Query: `user_id == {userId}`
- Action: Delete all matching documents

#### **I. Reviews**
- Collection: `/reviews`
- Query: `user_id == {userId}`
- Action: Delete all matching documents

#### **J. Notifications**
- Collection: `/notifications`
- Query: `user_id == {userId}`
- Action: Delete all matching documents

#### **K. Conversations**
- Collection: `/conversations`
- Query: `participants array-contains {userId}`
- Action: Delete all matching documents

#### **L. Messages**
- Collection: `/messages`
- Query: `sender_id == {userId}`
- Action: Delete all matching documents

#### **M. User Complaints**
- Collection: `/user_complaints`
- Query: `user_id == {userId}`
- Action: Delete all matching documents

### **Step 3: Delete from Firebase Storage**

Go to: https://console.firebase.google.com/project/sayekataleapp/storage

For **EACH** of the 20 users, delete these folders:

```
/users/{userId}/          - Profile images
/products/{userId}/       - Product images (if user is farmer/PSA)
/temp/{userId}/          - Temporary files
```

### **Estimated Time**: 30-45 minutes for all 20 users

---

## 📊 CLEANUP VERIFICATION

After cleanup, verify all data has been removed:

### **1. Firebase Authentication**
```bash
# Check user count decreased
# Before: Total users
# After: Total users - 20
```

### **2. Firestore Database**
Run queries to confirm no documents remain:
- `/users` - No documents with test user IDs
- `/products` - No products with test user farmer_id
- `/orders` - No orders with test user buyer_id/seller_id

### **3. Firebase Storage**
- Check that user folders have been deleted
- Verify storage usage decreased

---

## 🚨 TROUBLESHOOTING

### **Error: "User not found in Authentication"**
- **Cause**: User already deleted or never existed
- **Action**: Continue to next user (safe to ignore)

### **Error: "Permission denied"**
- **Cause**: Insufficient Firebase Admin permissions
- **Action**: Verify Firebase Admin SDK file has correct permissions

### **Error: "Document not found"**
- **Cause**: Document already deleted
- **Action**: Continue (safe to ignore)

### **Script hangs or times out**
- **Cause**: Network issues or rate limiting
- **Action**: 
  - Wait a moment and restart script
  - Script will skip already-deleted users
  - Or switch to manual cleanup method

---

## 📝 BACKUP RECOMMENDATION

Before running cleanup, consider creating a backup:

1. **Firestore Backup**:
   ```bash
   gcloud firestore export gs://sayekataleapp-backup/$(date +%Y%m%d)
   ```

2. **Authentication Backup**:
   - Export users from Firebase Console
   - Authentication → Users → Export Users

3. **Storage Backup**:
   - Use `gsutil` to copy storage bucket
   ```bash
   gsutil -m cp -r gs://sayekataleapp.appspot.com gs://backup-bucket
   ```

---

## ✅ COMPLETION CHECKLIST

After cleanup, verify:

- [ ] All 20 users deleted from Firebase Authentication
- [ ] User profile documents deleted from `/users` collection
- [ ] All user-associated documents deleted from other collections
- [ ] User folders deleted from Firebase Storage
- [ ] No orphaned data remains in database
- [ ] App functionality tested with remaining users
- [ ] Storage usage decreased appropriately

---

## 🎯 NEXT STEPS AFTER CLEANUP

1. **Monitor App Performance**:
   - Check for any errors related to missing users
   - Verify app functions normally

2. **Review Remaining Users**:
   - Confirm only legitimate users remain
   - Check for any other test accounts

3. **Update Security Rules** (if needed):
   - Ensure rules don't reference deleted users
   - Verify admin access still works

4. **Production Deployment**:
   - Deploy latest code with bug fixes
   - Test critical flows (PSA, products, orders)

---

## 📞 SUPPORT

**Script Location**: `/home/user/cleanup_test_users.py`

**Documentation**:
- This guide: `/home/user/CLEANUP_INSTRUCTIONS.md`
- Complete TODO solutions: `/home/user/flutter_app/docs/COMPLETE_TODO_SOLUTIONS.md`

**Firebase Console Links**:
- Auth: https://console.firebase.google.com/project/sayekataleapp/authentication/users
- Firestore: https://console.firebase.google.com/project/sayekataleapp/firestore/data
- Storage: https://console.firebase.google.com/project/sayekataleapp/storage

---

**STATUS**: ✅ Cleanup script ready for execution!
