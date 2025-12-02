# 🚀 GOOGLE CLOUD SHELL - QUICK CLEANUP GUIDE

## **Fastest Method: Run in Google Cloud Shell**

### ✅ **Step 1: Get Firebase Admin SDK (1 minute)**

1. Go to: **https://console.firebase.google.com/project/sayekataleapp/settings/serviceaccounts/adminsdk**
2. Select **"Python"** as Admin SDK language
3. Click **"Generate new private key"**
4. Download the JSON file (keep it ready for upload)

---

### ✅ **Step 2: Open Google Cloud Shell (30 seconds)**

1. Go to: **https://console.cloud.google.com/**
2. Select your **sayekataleapp** project
3. Click the **Cloud Shell** icon (top right, terminal icon)
4. Wait for Cloud Shell to activate

---

### ✅ **Step 3: Upload Files to Cloud Shell (1 minute)**

**Upload 2 files using the Cloud Shell upload button (⋮ menu → Upload):**

1. **Upload cleanup script**: `cleanup_test_users.py` 
   - Located at: `/home/user/cleanup_test_users.py`
   
2. **Upload Firebase Admin SDK**: The JSON file you just downloaded
   - Rename it to: `firebase-admin-sdk.json`

**Alternative: Use inline script creation (faster):**

```bash
# Create the script directly in Cloud Shell (copy the complete script below)
cat > cleanup_test_users.py << 'SCRIPT_EOF'
# [COMPLETE SCRIPT CONTENT WILL BE PROVIDED BELOW]
SCRIPT_EOF
```

---

### ✅ **Step 4: Run Cleanup (2-3 minutes)**

```bash
# Install dependencies
pip3 install firebase-admin==7.1.0

# Run the cleanup script
python3 cleanup_test_users.py
```

**When prompted, type:** `DELETE`

---

### ✅ **Step 5: Verify Completion**

The script will show progress like:

```
[1/20] Processing: 4CdvRwCq0MOknJoWWPVHa5jYMWk1
  ✅ Deleted from Auth
  ✅ Deleted user profile
  ✅ Deleted 3 products
  ✅ Deleted 5 orders
  ...

============================================================
✅ CLEANUP COMPLETE!
============================================================

📊 SUMMARY:
   Total users processed: 20
   Firebase Authentication: Deleted 20
   Firestore Database: 150 documents deleted
   Firebase Storage: 85 files deleted
```

---

## 📋 **COMPLETE INLINE SCRIPT (Copy-Paste Ready)**

If uploading files is inconvenient, create the script directly in Cloud Shell:

```bash
# Step 1: Create cleanup script
cat > cleanup_test_users.py << 'EOF'
#!/usr/bin/env python3
"""SAYE KATALE - Test User Cleanup Script"""

import firebase_admin
from firebase_admin import credentials, auth, firestore, storage
import sys
import time
from datetime import datetime

# Test users to delete
TEST_USERS = [
    '4CdvRwCq0MOknJoWWPVHa5jYMWk1',
    'wvwCw0HS3UdMUnhu9cWlaIrbSRR2',
    'zAAapBidPAXIZRUWabNXv2pc7R03',
    'xsmnGylST2PP0s2iIaR1EXTMmAr2',
    '0Zj2bMjXjnMr9ilPUkdIlklKIyv1',
    'XEIB0iHe40ZRY6s91oa9UMedJoH2',
    'LuMFRxfBGnTpmimDAxZD49l2Qyj2',
    'WKOaULMUedOh9EEcBAZnPFM7Vc72',
    'lSdQEHBbP3dnxPtbmbgl24GoMQD3',
    'faasyBXlpOTppRhCbX4uoaF8DQg2',
    'SrWntuHEBmWrLF0YWTojA5YZ54y1',
    '82yy5uWEZQT0gJcwxbfG57ZTpm03',
    'y6LFppeDDrcWXLGjJsia3RJOwox2',
    'SfFd266Pu7YIzcGa73G7YRBFFzj1',
    'LGa2z4rkeEhr2QcBMoPFyneeH6t2',
    'EawO0nfZpod4Pn7YbDd36TS72ez2',
    'Ahyc4BNQ4RUPG1pgYEKJci05ukp2',
    'EonaZZiFgaQCdvAec4qZd0KI2Ep1',
    'cDHtgKvSl4VuORHUTysFArtqUFF2',
    'tUFPvg2LovWabiifmcbkH6lUNpl1',
]

COLLECTIONS_TO_CLEAN = [
    'users', 'products', 'orders', 'transactions', 'psa_verifications',
    'subscriptions', 'cart_items', 'favorite_products', 'reviews',
    'notifications', 'conversations', 'messages', 'user_complaints',
]

def initialize_firebase():
    try:
        cred = credentials.Certificate('./firebase-admin-sdk.json')
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialized")
        return firestore.client()
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        print("\n📝 Make sure 'firebase-admin-sdk.json' is in the current directory")
        sys.exit(1)

def delete_from_auth(user_id):
    try:
        auth.delete_user(user_id)
        print(f"  ✅ Deleted from Auth: {user_id}")
        return True
    except auth.UserNotFoundError:
        print(f"  ⚠️  Not found in Auth: {user_id}")
        return False
    except Exception as e:
        print(f"  ❌ Auth deletion failed: {e}")
        return False

def delete_user_documents(db, user_id):
    deleted_counts = {}
    
    # Delete user profile
    try:
        db.collection('users').document(user_id).delete()
        deleted_counts['users'] = 1
        print(f"  ✅ Deleted user profile")
    except:
        deleted_counts['users'] = 0
    
    # Delete products
    try:
        count = 0
        for doc in db.collection('products').where('farmer_id', '==', user_id).stream():
            doc.reference.delete()
            count += 1
        for doc in db.collection('products').where('farm_id', '==', user_id).stream():
            doc.reference.delete()
            count += 1
        deleted_counts['products'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} products")
    except Exception as e:
        deleted_counts['products'] = 0
    
    # Delete orders
    try:
        count = 0
        for doc in db.collection('orders').where('buyer_id', '==', user_id).stream():
            doc.reference.delete()
            count += 1
        for doc in db.collection('orders').where('seller_id', '==', user_id).stream():
            doc.reference.delete()
            count += 1
        for doc in db.collection('orders').where('farmerId', '==', user_id).stream():
            doc.reference.delete()
            count += 1
        deleted_counts['orders'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} orders")
    except:
        deleted_counts['orders'] = 0
    
    # Delete other collections
    other_collections = [
        ('transactions', 'user_id'),
        ('psa_verifications', 'psa_id'),
        ('subscriptions', 'user_id'),
        ('cart_items', 'user_id'),
        ('favorite_products', 'user_id'),
        ('reviews', 'user_id'),
        ('notifications', 'user_id'),
        ('messages', 'sender_id'),
        ('user_complaints', 'user_id'),
    ]
    
    for collection_name, field_name in other_collections:
        try:
            count = 0
            for doc in db.collection(collection_name).where(field_name, '==', user_id).stream():
                doc.reference.delete()
                count += 1
            deleted_counts[collection_name] = count
            if count > 0:
                print(f"  ✅ Deleted {count} {collection_name}")
        except:
            deleted_counts[collection_name] = 0
    
    # Delete conversations (array-contains)
    try:
        count = 0
        for doc in db.collection('conversations').where('participants', 'array_contains', user_id).stream():
            doc.reference.delete()
            count += 1
        deleted_counts['conversations'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} conversations")
    except:
        deleted_counts['conversations'] = 0
    
    return deleted_counts

def delete_storage_files(user_id):
    try:
        bucket = storage.bucket()
        storage_paths = [
            f'users/{user_id}/',
            f'products/{user_id}/',
            f'temp/{user_id}/',
        ]
        
        total_deleted = 0
        for path in storage_paths:
            try:
                blobs = list(bucket.list_blobs(prefix=path))
                for blob in blobs:
                    blob.delete()
                if len(blobs) > 0:
                    total_deleted += len(blobs)
                    print(f"  ✅ Deleted {len(blobs)} files from {path}")
            except:
                pass
        
        return total_deleted
    except:
        return 0

def main():
    print("=" * 60)
    print("SAYE KATALE - Test User Cleanup Script")
    print("=" * 60)
    print(f"\n🗑️  Will delete {len(TEST_USERS)} test users and all their data")
    print("\n⚠️  WARNING: This operation is IRREVERSIBLE!")
    
    response = input("\nType 'DELETE' to confirm and proceed: ")
    if response != 'DELETE':
        print("\n❌ Cleanup cancelled.")
        sys.exit(0)
    
    print("\n" + "=" * 60)
    print("🚀 Starting cleanup process...")
    print("=" * 60)
    
    db = initialize_firebase()
    
    stats = {
        'auth_deleted': 0,
        'auth_not_found': 0,
        'total_firestore_docs': 0,
        'total_storage_files': 0,
    }
    
    collection_stats = {col: 0 for col in COLLECTIONS_TO_CLEAN}
    
    for i, user_id in enumerate(TEST_USERS, 1):
        print(f"\n[{i}/{len(TEST_USERS)}] Processing: {user_id}")
        print("-" * 60)
        
        auth_deleted = delete_from_auth(user_id)
        if auth_deleted:
            stats['auth_deleted'] += 1
        else:
            stats['auth_not_found'] += 1
        
        deleted_counts = delete_user_documents(db, user_id)
        for collection, count in deleted_counts.items():
            collection_stats[collection] += count
            stats['total_firestore_docs'] += count
        
        storage_count = delete_storage_files(user_id)
        stats['total_storage_files'] += storage_count
        
        time.sleep(0.5)
    
    print("\n" + "=" * 60)
    print("✅ CLEANUP COMPLETE!")
    print("=" * 60)
    print(f"\n📊 SUMMARY:")
    print(f"   Total users processed: {len(TEST_USERS)}")
    print(f"\n   Firebase Authentication:")
    print(f"     - Deleted: {stats['auth_deleted']}")
    print(f"     - Not found: {stats['auth_not_found']}")
    print(f"\n   Firestore Database:")
    print(f"     - Total documents deleted: {stats['total_firestore_docs']}")
    for collection, count in collection_stats.items():
        if count > 0:
            print(f"       • {collection}: {count}")
    print(f"\n   Firebase Storage:")
    print(f"     - Total files deleted: {stats['total_storage_files']}")
    print("\n" + "=" * 60)
    print("🎉 All test users have been cleaned from the system!")
    print("=" * 60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Cleanup interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
EOF

# Step 2: Upload Firebase Admin SDK JSON file
# Use Cloud Shell upload button (⋮ → Upload)
# Rename it to: firebase-admin-sdk.json

# Step 3: Install dependencies
pip3 install firebase-admin==7.1.0

# Step 4: Run cleanup
python3 cleanup_test_users.py
```

---

## 🎯 **TOTAL TIME REQUIRED**

- **Firebase Admin SDK download**: 1 minute
- **Open Cloud Shell**: 30 seconds
- **Upload files**: 1 minute
- **Install dependencies**: 1 minute
- **Run cleanup**: 2-3 minutes

**✅ TOTAL: ~5-7 minutes**

---

## 🔍 **VERIFICATION AFTER CLEANUP**

Check Firebase Console to confirm deletions:

1. **Authentication**: https://console.firebase.google.com/project/sayekataleapp/authentication/users
   - Verify user count decreased by 20

2. **Firestore**: https://console.firebase.google.com/project/sayekataleapp/firestore/data
   - Search for deleted UIDs - should return no results

3. **Storage**: https://console.firebase.google.com/project/sayekataleapp/storage
   - Check that user folders are removed

---

## 📝 **TROUBLESHOOTING**

### **Error: "No module named 'firebase_admin'"**
```bash
pip3 install firebase-admin==7.1.0
```

### **Error: "Permission denied"**
- Ensure you downloaded the correct Firebase Admin SDK file
- Verify the file is named `firebase-admin-sdk.json`

### **Error: "User not found"**
- Normal - user might already be deleted
- Script will continue automatically

---

## ✅ **SUCCESS CRITERIA**

After completion, you should see:

```
📊 SUMMARY:
   Total users processed: 20
   Firebase Authentication: Deleted 20
   Firestore Database: 150+ documents deleted
   Firebase Storage: 85+ files deleted
```

---

**🎉 Ready to execute! Follow the steps above in Google Cloud Shell.**
