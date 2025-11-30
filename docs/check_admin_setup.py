#!/usr/bin/env python3
"""
Diagnostic Script: Check Admin User Setup in Firestore
This script verifies if admin users are properly configured in the users collection.
"""

import sys
import json

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 Please install: pip install firebase-admin==7.1.0")
    sys.exit(1)

# Firebase Admin SDK credential file path
FIREBASE_ADMIN_SDK_PATH = "/opt/flutter/firebase-admin-sdk.json"

def check_firebase_credentials():
    """Check if Firebase Admin SDK credentials exist"""
    import os
    if not os.path.exists(FIREBASE_ADMIN_SDK_PATH):
        print(f"❌ Firebase Admin SDK file not found at: {FIREBASE_ADMIN_SDK_PATH}")
        print("📂 Please upload your Firebase Admin SDK JSON file to the sandbox")
        return False
    print(f"✅ Firebase Admin SDK file found at: {FIREBASE_ADMIN_SDK_PATH}")
    return True

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        # Check if already initialized
        try:
            firebase_admin.get_app()
            print("✅ Firebase already initialized")
            return True
        except ValueError:
            # Not initialized, proceed
            pass
        
        cred = credentials.Certificate(FIREBASE_ADMIN_SDK_PATH)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialized successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return False

def check_admin_users():
    """Check for admin users in users collection"""
    try:
        db = firestore.client()
        
        print("\n" + "="*60)
        print("🔍 CHECKING ADMIN USERS IN 'users' COLLECTION")
        print("="*60 + "\n")
        
        # Query users with role = 'admin' or 'superAdmin'
        admin_query = db.collection('users').where('role', 'in', ['admin', 'superAdmin']).stream()
        
        admin_users = []
        for doc in admin_query:
            user_data = doc.to_dict()
            admin_users.append({
                'uid': doc.id,
                'data': user_data
            })
        
        if not admin_users:
            print("❌ NO ADMIN USERS FOUND in 'users' collection")
            print("\n📋 Required Structure:")
            print(json.dumps({
                "uid": "your-firebase-auth-uid",
                "email": "admin@example.com",
                "name": "Admin Name",
                "role": "admin",  # ← Must be "admin" or "superAdmin"
                "phone": "+256700000000"
            }, indent=2))
            print("\n🔧 FIX: In Firebase Console → Firestore → users collection")
            print("   Add/update a document with the structure above")
            return False
        
        print(f"✅ FOUND {len(admin_users)} ADMIN USER(S):\n")
        for i, user in enumerate(admin_users, 1):
            print(f"Admin {i}:")
            print(f"  UID: {user['uid']}")
            print(f"  Email: {user['data'].get('email', 'N/A')}")
            print(f"  Name: {user['data'].get('name', 'N/A')}")
            print(f"  Role: {user['data'].get('role', 'N/A')}")
            print(f"  Phone: {user['data'].get('phone', 'N/A')}")
            print()
        
        return True
        
    except Exception as e:
        print(f"❌ Error checking admin users: {e}")
        return False

def check_psa_verifications():
    """Check PSA verifications collection"""
    try:
        db = firestore.client()
        
        print("\n" + "="*60)
        print("🔍 CHECKING PSA VERIFICATIONS")
        print("="*60 + "\n")
        
        # Get pending verifications
        pending_query = db.collection('psa_verifications').where('status', '==', 'pending').limit(5).stream()
        
        pending_count = 0
        for doc in pending_query:
            pending_count += 1
            data = doc.to_dict()
            print(f"Verification ID: {doc.id}")
            print(f"  PSA ID: {data.get('psa_id', 'N/A')}")
            print(f"  Status: {data.get('status', 'N/A')}")
            print(f"  Created: {data.get('created_at', 'N/A')}")
            print()
        
        if pending_count == 0:
            print("ℹ️ No pending PSA verifications found")
        else:
            print(f"✅ Found {pending_count} pending PSA verification(s)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error checking PSA verifications: {e}")
        return False

def check_products():
    """Check products collection for image URLs"""
    try:
        db = firestore.client()
        
        print("\n" + "="*60)
        print("🔍 CHECKING PRODUCTS (Image URLs)")
        print("="*60 + "\n")
        
        # Get first 5 products
        products_query = db.collection('products').limit(5).stream()
        
        product_count = 0
        for doc in products_query:
            product_count += 1
            data = doc.to_dict()
            images = data.get('images', [])
            
            print(f"Product ID: {doc.id}")
            print(f"  Name: {data.get('name', 'N/A')}")
            print(f"  Images Count: {len(images)}")
            
            if images:
                print(f"  First Image URL: {images[0][:80]}...")
                if not images[0].startswith('https://firebasestorage.googleapis.com'):
                    print(f"  ⚠️ WARNING: Image URL doesn't look like Firebase Storage URL")
            else:
                print(f"  ⚠️ WARNING: No images found for this product")
            print()
        
        if product_count == 0:
            print("ℹ️ No products found in database")
        else:
            print(f"✅ Checked {product_count} product(s)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error checking products: {e}")
        return False

def main():
    """Main diagnostic function"""
    print("\n" + "="*60)
    print("🔥 FIRESTORE DIAGNOSTIC SCRIPT")
    print("="*60 + "\n")
    
    # Step 1: Check credentials
    if not check_firebase_credentials():
        sys.exit(1)
    
    # Step 2: Initialize Firebase
    if not initialize_firebase():
        sys.exit(1)
    
    # Step 3: Check admin users
    admin_check = check_admin_users()
    
    # Step 4: Check PSA verifications
    psa_check = check_psa_verifications()
    
    # Step 5: Check products
    product_check = check_products()
    
    # Summary
    print("\n" + "="*60)
    print("📊 DIAGNOSTIC SUMMARY")
    print("="*60 + "\n")
    
    print(f"Admin Users Setup: {'✅ PASS' if admin_check else '❌ FAIL'}")
    print(f"PSA Verifications: {'✅ PASS' if psa_check else '❌ FAIL'}")
    print(f"Products/Images: {'✅ PASS' if product_check else '❌ FAIL'}")
    
    if not admin_check:
        print("\n⚠️ ACTION REQUIRED: Set up admin users in Firestore")
        print("   See output above for required structure")
    
    print("\n" + "="*60)

if __name__ == "__main__":
    main()
