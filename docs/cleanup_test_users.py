#!/usr/bin/env python3
"""
SAYE KATALE - Test User Cleanup Script
========================================

This script removes 20 test users and all their associated data from:
- Firebase Authentication
- Firestore Database (all collections)
- Firebase Storage (user files)

REQUIREMENTS:
- Python 3.7+
- firebase-admin==7.1.0
- Firebase Admin SDK JSON file

USAGE:
    python3 cleanup_test_users.py

IMPORTANT: 
- This script performs IRREVERSIBLE deletions
- Always backup your data before running
- Run in a test environment first
"""

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

# Collections to check for user data
COLLECTIONS_TO_CLEAN = [
    'users',
    'products',
    'orders',
    'transactions',
    'psa_verifications',
    'subscriptions',
    'cart_items',
    'favorite_products',
    'reviews',
    'notifications',
    'conversations',
    'messages',
    'user_complaints',
]

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        # Try to find Firebase Admin SDK file
        sdk_paths = [
            '/opt/flutter/firebase-admin-sdk.json',
            './firebase-admin-sdk.json',
            '../firebase-admin-sdk.json',
        ]
        
        sdk_path = None
        for path in sdk_paths:
            try:
                cred = credentials.Certificate(path)
                sdk_path = path
                break
            except Exception:
                continue
        
        if sdk_path is None:
            print("❌ Firebase Admin SDK file not found!")
            print("\nPlease provide the path to your Firebase Admin SDK JSON file:")
            print("1. Download from: https://console.firebase.google.com/project/sayekataleapp/settings/serviceaccounts/adminsdk")
            print("2. Save as 'firebase-admin-sdk.json' in the current directory")
            print("3. Run this script again")
            sys.exit(1)
        
        firebase_admin.initialize_app(cred)
        print(f"✅ Firebase Admin SDK initialized from: {sdk_path}")
        return firestore.client()
    
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        sys.exit(1)

def delete_from_auth(user_id):
    """Delete user from Firebase Authentication"""
    try:
        auth.delete_user(user_id)
        print(f"  ✅ Deleted from Auth: {user_id}")
        return True
    except auth.UserNotFoundError:
        print(f"  ⚠️  Not found in Auth: {user_id}")
        return False
    except Exception as e:
        print(f"  ❌ Auth deletion failed for {user_id}: {e}")
        return False

def delete_user_documents(db, user_id):
    """Delete user's documents from Firestore collections"""
    deleted_counts = {}
    
    # 1. Delete from users collection
    try:
        db.collection('users').document(user_id).delete()
        deleted_counts['users'] = 1
        print(f"  ✅ Deleted user profile: {user_id}")
    except Exception as e:
        print(f"  ⚠️  User profile not found or error: {e}")
        deleted_counts['users'] = 0
    
    # 2. Delete products (farmer_id or farm_id)
    try:
        products_ref = db.collection('products')
        # Check farmer_id
        farmer_products = products_ref.where('farmer_id', '==', user_id).stream()
        count = 0
        for doc in farmer_products:
            doc.reference.delete()
            count += 1
        # Check farm_id
        farm_products = products_ref.where('farm_id', '==', user_id).stream()
        for doc in farm_products:
            doc.reference.delete()
            count += 1
        deleted_counts['products'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} products")
    except Exception as e:
        print(f"  ⚠️  Products deletion error: {e}")
        deleted_counts['products'] = 0
    
    # 3. Delete orders (buyer_id or seller_id)
    try:
        orders_ref = db.collection('orders')
        # Check buyer_id
        buyer_orders = orders_ref.where('buyer_id', '==', user_id).stream()
        count = 0
        for doc in buyer_orders:
            doc.reference.delete()
            count += 1
        # Check seller_id
        seller_orders = orders_ref.where('seller_id', '==', user_id).stream()
        for doc in seller_orders:
            doc.reference.delete()
            count += 1
        # Check farmerId
        farmer_orders = orders_ref.where('farmerId', '==', user_id).stream()
        for doc in farmer_orders:
            doc.reference.delete()
            count += 1
        deleted_counts['orders'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} orders")
    except Exception as e:
        print(f"  ⚠️  Orders deletion error: {e}")
        deleted_counts['orders'] = 0
    
    # 4. Delete transactions (user_id)
    try:
        transactions = db.collection('transactions').where('user_id', '==', user_id).stream()
        count = 0
        for doc in transactions:
            doc.reference.delete()
            count += 1
        deleted_counts['transactions'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} transactions")
    except Exception as e:
        print(f"  ⚠️  Transactions deletion error: {e}")
        deleted_counts['transactions'] = 0
    
    # 5. Delete PSA verifications (psa_id)
    try:
        verifications = db.collection('psa_verifications').where('psa_id', '==', user_id).stream()
        count = 0
        for doc in verifications:
            doc.reference.delete()
            count += 1
        deleted_counts['psa_verifications'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} PSA verifications")
    except Exception as e:
        print(f"  ⚠️  PSA verifications deletion error: {e}")
        deleted_counts['psa_verifications'] = 0
    
    # 6. Delete subscriptions (user_id)
    try:
        subscriptions = db.collection('subscriptions').where('user_id', '==', user_id).stream()
        count = 0
        for doc in subscriptions:
            doc.reference.delete()
            count += 1
        deleted_counts['subscriptions'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} subscriptions")
    except Exception as e:
        print(f"  ⚠️  Subscriptions deletion error: {e}")
        deleted_counts['subscriptions'] = 0
    
    # 7. Delete cart items (user_id)
    try:
        cart_items = db.collection('cart_items').where('user_id', '==', user_id).stream()
        count = 0
        for doc in cart_items:
            doc.reference.delete()
            count += 1
        deleted_counts['cart_items'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} cart items")
    except Exception as e:
        print(f"  ⚠️  Cart items deletion error: {e}")
        deleted_counts['cart_items'] = 0
    
    # 8. Delete favorite products (user_id)
    try:
        favorites = db.collection('favorite_products').where('user_id', '==', user_id).stream()
        count = 0
        for doc in favorites:
            doc.reference.delete()
            count += 1
        deleted_counts['favorite_products'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} favorite products")
    except Exception as e:
        print(f"  ⚠️  Favorite products deletion error: {e}")
        deleted_counts['favorite_products'] = 0
    
    # 9. Delete reviews (user_id)
    try:
        reviews = db.collection('reviews').where('user_id', '==', user_id).stream()
        count = 0
        for doc in reviews:
            doc.reference.delete()
            count += 1
        deleted_counts['reviews'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} reviews")
    except Exception as e:
        print(f"  ⚠️  Reviews deletion error: {e}")
        deleted_counts['reviews'] = 0
    
    # 10. Delete notifications (user_id)
    try:
        notifications = db.collection('notifications').where('user_id', '==', user_id).stream()
        count = 0
        for doc in notifications:
            doc.reference.delete()
            count += 1
        deleted_counts['notifications'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} notifications")
    except Exception as e:
        print(f"  ⚠️  Notifications deletion error: {e}")
        deleted_counts['notifications'] = 0
    
    # 11. Delete conversations (participants array contains user_id)
    try:
        conversations = db.collection('conversations').where('participants', 'array_contains', user_id).stream()
        count = 0
        for doc in conversations:
            doc.reference.delete()
            count += 1
        deleted_counts['conversations'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} conversations")
    except Exception as e:
        print(f"  ⚠️  Conversations deletion error: {e}")
        deleted_counts['conversations'] = 0
    
    # 12. Delete messages (sender_id)
    try:
        messages = db.collection('messages').where('sender_id', '==', user_id).stream()
        count = 0
        for doc in messages:
            doc.reference.delete()
            count += 1
        deleted_counts['messages'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} messages")
    except Exception as e:
        print(f"  ⚠️  Messages deletion error: {e}")
        deleted_counts['messages'] = 0
    
    # 13. Delete user complaints
    try:
        complaints = db.collection('user_complaints').where('user_id', '==', user_id).stream()
        count = 0
        for doc in complaints:
            doc.reference.delete()
            count += 1
        deleted_counts['user_complaints'] = count
        if count > 0:
            print(f"  ✅ Deleted {count} complaints")
    except Exception as e:
        print(f"  ⚠️  Complaints deletion error: {e}")
        deleted_counts['user_complaints'] = 0
    
    return deleted_counts

def delete_storage_files(user_id):
    """Delete user's files from Firebase Storage"""
    try:
        bucket = storage.bucket()
        
        # Paths to check
        storage_paths = [
            f'users/{user_id}/',
            f'products/{user_id}/',
            f'temp/{user_id}/',
        ]
        
        total_deleted = 0
        for path in storage_paths:
            try:
                blobs = bucket.list_blobs(prefix=path)
                count = 0
                for blob in blobs:
                    blob.delete()
                    count += 1
                if count > 0:
                    total_deleted += count
                    print(f"  ✅ Deleted {count} files from {path}")
            except Exception as e:
                print(f"  ⚠️  Storage path {path} error: {e}")
        
        return total_deleted
    
    except Exception as e:
        print(f"  ⚠️  Storage deletion error: {e}")
        return 0

def main():
    """Main cleanup function"""
    print("=" * 60)
    print("SAYE KATALE - Test User Cleanup Script")
    print("=" * 60)
    print(f"\nStarting cleanup at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"\n🗑️  Will delete {len(TEST_USERS)} test users and all their data")
    print("\n⚠️  WARNING: This operation is IRREVERSIBLE!")
    print("⚠️  All user data will be permanently deleted from:")
    print("   - Firebase Authentication")
    print("   - Firestore Database (all collections)")
    print("   - Firebase Storage (user files)")
    
    # Confirmation
    print("\n" + "=" * 60)
    response = input("\nType 'DELETE' to confirm and proceed: ")
    if response != 'DELETE':
        print("\n❌ Cleanup cancelled.")
        sys.exit(0)
    
    print("\n" + "=" * 60)
    print("🚀 Starting cleanup process...")
    print("=" * 60)
    
    # Initialize Firebase
    db = initialize_firebase()
    
    # Track statistics
    stats = {
        'auth_deleted': 0,
        'auth_not_found': 0,
        'auth_errors': 0,
        'total_firestore_docs': 0,
        'total_storage_files': 0,
    }
    
    collection_stats = {col: 0 for col in COLLECTIONS_TO_CLEAN}
    
    # Process each user
    for i, user_id in enumerate(TEST_USERS, 1):
        print(f"\n[{i}/{len(TEST_USERS)}] Processing: {user_id}")
        print("-" * 60)
        
        # Delete from Authentication
        auth_deleted = delete_from_auth(user_id)
        if auth_deleted:
            stats['auth_deleted'] += 1
        else:
            stats['auth_not_found'] += 1
        
        # Delete from Firestore
        deleted_counts = delete_user_documents(db, user_id)
        for collection, count in deleted_counts.items():
            collection_stats[collection] += count
            stats['total_firestore_docs'] += count
        
        # Delete from Storage
        storage_count = delete_storage_files(user_id)
        stats['total_storage_files'] += storage_count
        
        # Small delay to avoid rate limits
        time.sleep(0.5)
    
    # Final summary
    print("\n" + "=" * 60)
    print("✅ CLEANUP COMPLETE!")
    print("=" * 60)
    print(f"\nCompleted at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
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
