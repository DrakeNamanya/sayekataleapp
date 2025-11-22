#!/usr/bin/env python3
"""
Delete Test Users Script
Removes specified test accounts and all their associated data
"""

import os
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, auth
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 Installing firebase-admin...")
    os.system("pip install firebase-admin==7.1.0")
    import firebase_admin
    from firebase_admin import credentials, firestore, auth

# Initialize Firebase Admin SDK
firebase_admin_sdk_path = "/opt/flutter/firebase-admin-sdk.json"

if not os.path.exists(firebase_admin_sdk_path):
    print(f"❌ Firebase Admin SDK file not found at: {firebase_admin_sdk_path}")
    print("📋 Please ensure the file exists at this location")
    sys.exit(1)

# Initialize Firebase
try:
    cred = credentials.Certificate(firebase_admin_sdk_path)
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized")
except Exception as e:
    print(f"❌ Error initializing Firebase: {e}")
    sys.exit(1)

# Get Firestore client
db = firestore.client()

# Users to delete
USERS_TO_DELETE = [
    "test_20251116223809@sayekatale.test",
    "kiconcodebrah@gmail.com"
]

def get_user_by_email(email):
    """Get user from Firebase Auth by email"""
    try:
        user = auth.get_user_by_email(email)
        return user
    except auth.UserNotFoundError:
        print(f"⚠️  User not found in Firebase Auth: {email}")
        return None
    except Exception as e:
        print(f"❌ Error getting user {email}: {e}")
        return None

def delete_user_products(user_id):
    """Delete all products created by the user"""
    try:
        # Query products by farmer_id (snake_case as per your code)
        products_ref = db.collection('products')
        
        # Try both field names
        queries = [
            products_ref.where('farmer_id', '==', user_id).get(),
            products_ref.where('farmerId', '==', user_id).get(),
            products_ref.where('farm_id', '==', user_id).get(),
        ]
        
        deleted_count = 0
        for query in queries:
            docs = query
            for doc in docs:
                doc.reference.delete()
                deleted_count += 1
                print(f"  🗑️  Deleted product: {doc.id}")
        
        if deleted_count > 0:
            print(f"✅ Deleted {deleted_count} products")
        else:
            print("ℹ️  No products found for this user")
            
    except Exception as e:
        print(f"❌ Error deleting products: {e}")

def delete_user_orders(user_id):
    """Delete all orders (as buyer or seller)"""
    try:
        orders_ref = db.collection('orders')
        
        # Query as buyer
        buyer_orders = orders_ref.where('buyer_id', '==', user_id).get()
        # Query as seller
        seller_orders = orders_ref.where('farmerId', '==', user_id).get()
        
        deleted_count = 0
        for doc in list(buyer_orders) + list(seller_orders):
            doc.reference.delete()
            deleted_count += 1
            print(f"  🗑️  Deleted order: {doc.id}")
        
        if deleted_count > 0:
            print(f"✅ Deleted {deleted_count} orders")
        else:
            print("ℹ️  No orders found for this user")
            
    except Exception as e:
        print(f"❌ Error deleting orders: {e}")

def delete_user_data(user_id):
    """Delete all user-related data from Firestore"""
    try:
        # Delete user document
        user_doc_ref = db.collection('users').document(user_id)
        if user_doc_ref.get().exists:
            user_doc_ref.delete()
            print("  ✅ Deleted user document")
        
        # Delete products
        delete_user_products(user_id)
        
        # Delete orders
        delete_user_orders(user_id)
        
        # Delete reviews
        reviews = db.collection('reviews').where('reviewerId', '==', user_id).get()
        for doc in reviews:
            doc.reference.delete()
            print(f"  🗑️  Deleted review: {doc.id}")
        
        # Delete messages
        messages = db.collection('messages').where('sender_id', '==', user_id).get()
        for doc in messages:
            doc.reference.delete()
            print(f"  🗑️  Deleted message: {doc.id}")
        
        # Delete conversations
        conversations = db.collection('conversations').where('participant_ids', 'array_contains', user_id).get()
        for doc in conversations:
            doc.reference.delete()
            print(f"  🗑️  Deleted conversation: {doc.id}")
        
        # Delete complaints
        complaints = db.collection('complaints').where('userId', '==', user_id).get()
        for doc in complaints:
            doc.reference.delete()
            print(f"  🗑️  Deleted complaint: {doc.id}")
        
        # Delete notifications
        notifications = db.collection('notifications').where('user_id', '==', user_id).get()
        for doc in notifications:
            doc.reference.delete()
            print(f"  🗑️  Deleted notification: {doc.id}")
            
        print("✅ All Firestore data deleted")
        
    except Exception as e:
        print(f"❌ Error deleting user data: {e}")

def delete_user_from_auth(user_id):
    """Delete user from Firebase Authentication"""
    try:
        auth.delete_user(user_id)
        print("✅ User deleted from Firebase Auth")
    except Exception as e:
        print(f"❌ Error deleting user from Auth: {e}")

def main():
    print("=" * 60)
    print("🗑️  DELETING TEST USERS")
    print("=" * 60)
    print(f"\nUsers to delete: {len(USERS_TO_DELETE)}")
    for email in USERS_TO_DELETE:
        print(f"  • {email}")
    
    print("\n" + "=" * 60)
    confirm = input("\n⚠️  Are you sure you want to delete these users? (yes/no): ")
    
    if confirm.lower() != 'yes':
        print("❌ Deletion cancelled")
        return
    
    print("\n" + "=" * 60)
    print("🚀 Starting deletion process...")
    print("=" * 60 + "\n")
    
    for email in USERS_TO_DELETE:
        print(f"\n📧 Processing: {email}")
        print("-" * 60)
        
        # Get user from Firebase Auth
        user = get_user_by_email(email)
        
        if user:
            print(f"✅ Found user: {user.uid}")
            
            # Delete all Firestore data
            print("\n🗑️  Deleting Firestore data...")
            delete_user_data(user.uid)
            
            # Delete from Firebase Auth
            print("\n🗑️  Deleting from Firebase Auth...")
            delete_user_from_auth(user.uid)
            
            print(f"\n✅ Successfully deleted user: {email}")
        else:
            print(f"⚠️  User {email} not found - skipping")
        
        print("-" * 60)
    
    print("\n" + "=" * 60)
    print("🎉 DELETION COMPLETE")
    print("=" * 60)
    print("\n📊 Summary:")
    print(f"  • Attempted to delete: {len(USERS_TO_DELETE)} users")
    print("\n✅ All operations completed")

if __name__ == "__main__":
    main()
