#!/usr/bin/env python3
"""
Check User Profiles - Diagnose User Data Issues
================================================

This script checks:
1. Firebase Authentication users
2. Firestore users collection documents
3. Identifies mismatches between Auth and Firestore

Usage:
    python3 check_user_profiles.py
"""

import firebase_admin
from firebase_admin import credentials, firestore, auth
import sys

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized successfully\n")
except Exception as e:
    print(f"❌ Failed to initialize Firebase Admin SDK: {e}")
    sys.exit(1)

db = firestore.client()


def list_firebase_auth_users():
    """List all users in Firebase Authentication"""
    print("="*80)
    print("🔐 FIREBASE AUTHENTICATION USERS")
    print("="*80 + "\n")
    
    try:
        page = auth.list_users()
        users = list(page.users)
        
        if not users:
            print("⚠️  No users found in Firebase Authentication\n")
            return []
        
        print(f"Found {len(users)} users:\n")
        
        auth_users = []
        for i, user in enumerate(users, 1):
            print(f"{i}. Email: {user.email}")
            print(f"   UID: {user.uid}")
            print(f"   Display Name: {user.display_name or 'N/A'}")
            print(f"   Created: {user.user_metadata.creation_timestamp}")
            print()
            
            auth_users.append({
                'email': user.email,
                'uid': user.uid,
                'display_name': user.display_name,
            })
        
        return auth_users
        
    except Exception as e:
        print(f"❌ Error listing auth users: {e}\n")
        return []


def list_firestore_users():
    """List all users in Firestore users collection"""
    print("="*80)
    print("📄 FIRESTORE USERS COLLECTION")
    print("="*80 + "\n")
    
    try:
        users_ref = db.collection('users')
        docs = users_ref.get()
        
        if not docs:
            print("⚠️  No users found in Firestore users collection\n")
            return []
        
        print(f"Found {len(docs)} user documents:\n")
        
        firestore_users = []
        for i, doc in enumerate(docs, 1):
            data = doc.to_dict()
            print(f"{i}. Document ID: {doc.id}")
            print(f"   Email: {data.get('email', 'N/A')}")
            print(f"   Name: {data.get('name', 'N/A')}")
            print(f"   Role: {data.get('role', 'N/A')}")
            print(f"   System ID: {data.get('system_id', 'N/A')}")
            print()
            
            firestore_users.append({
                'doc_id': doc.id,
                'email': data.get('email'),
                'name': data.get('name'),
                'role': data.get('role'),
                'system_id': data.get('system_id'),
            })
        
        return firestore_users
        
    except Exception as e:
        print(f"❌ Error listing Firestore users: {e}\n")
        return []


def check_drnamanya_user():
    """Specifically check for Drake Namanya's user profile"""
    print("="*80)
    print("🎯 CHECKING DRAKE NAMANYA (drnamanya@gmail.com)")
    print("="*80 + "\n")
    
    email = "drnamanya@gmail.com"
    
    # Check Firebase Auth
    print("1️⃣ Checking Firebase Authentication...")
    try:
        auth_user = auth.get_user_by_email(email)
        print(f"   ✅ Found in Firebase Auth")
        print(f"      UID: {auth_user.uid}")
        print(f"      Display Name: {auth_user.display_name or 'N/A'}")
        auth_uid = auth_user.uid
    except Exception as e:
        print(f"   ❌ Not found in Firebase Auth: {e}")
        auth_uid = None
    
    print()
    
    # Check Firestore users collection
    print("2️⃣ Checking Firestore users collection...")
    try:
        # First, try to find by document ID (should match Auth UID)
        if auth_uid:
            user_doc = db.collection('users').document(auth_uid).get()
            if user_doc.exists:
                data = user_doc.to_dict()
                print(f"   ✅ Found user profile with document ID = Auth UID")
                print(f"      Document ID: {user_doc.id}")
                print(f"      Email: {data.get('email', 'N/A')}")
                print(f"      Name: {data.get('name', 'N/A')}")
                print(f"      Role: {data.get('role', 'N/A')}")
                print(f"      System ID: {data.get('system_id', 'N/A')}")
                print()
                print("   ✅ PROFILE STRUCTURE IS CORRECT!")
                return auth_uid, data
        
        # Try to find by email field
        users_ref = db.collection('users')
        query = users_ref.where('email', '==', email).limit(1)
        docs = query.get()
        
        if docs:
            for doc in docs:
                data = doc.to_dict()
                print(f"   ⚠️  Found user profile with different document ID")
                print(f"      Document ID: {doc.id}")
                print(f"      Email: {data.get('email', 'N/A')}")
                print(f"      Name: {data.get('name', 'N/A')}")
                print(f"      Role: {data.get('role', 'N/A')}")
                print(f"      System ID: {data.get('system_id', 'N/A')}")
                print()
                print(f"   🚨 PROBLEM: Document ID ({doc.id}) does NOT match Auth UID ({auth_uid})")
                print(f"   💡 SOLUTION: User profile document ID should be: {auth_uid}")
                return auth_uid, data
        
        print(f"   ❌ No user profile found in Firestore")
        print(f"   💡 SOLUTION: Create user profile with document ID: {auth_uid}")
        return auth_uid, None
        
    except Exception as e:
        print(f"   ❌ Error checking Firestore: {e}")
        return auth_uid, None


def create_user_profile_if_needed(auth_uid, email):
    """Create user profile in Firestore if it doesn't exist"""
    print("\n3️⃣ Creating user profile in Firestore...")
    
    try:
        user_ref = db.collection('users').document(auth_uid)
        
        # Generate system_id for the user
        import random
        system_id = f"SHG-{random.randint(10000, 99999):05d}"
        
        user_data = {
            'id': auth_uid,
            'email': email,
            'name': 'Drake Namanya',
            'role': 'shg',  # Assuming SHG role
            'system_id': system_id,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        }
        
        user_ref.set(user_data)
        
        print(f"   ✅ Created user profile successfully!")
        print(f"      Document ID: {auth_uid}")
        print(f"      Email: {email}")
        print(f"      System ID: {system_id}")
        return True
        
    except Exception as e:
        print(f"   ❌ Error creating user profile: {e}")
        return False


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🔍 USER PROFILE DIAGNOSTIC TOOL")
    print("="*80 + "\n")
    
    # Step 1: List all Firebase Auth users
    auth_users = list_firebase_auth_users()
    
    # Step 2: List all Firestore user documents
    firestore_users = list_firestore_users()
    
    # Step 3: Check Drake Namanya specifically
    auth_uid, user_data = check_drnamanya_user()
    
    # Step 4: Offer to create profile if missing
    if auth_uid and not user_data:
        print("\n" + "="*80)
        print("💡 SOLUTION AVAILABLE")
        print("="*80 + "\n")
        print("Would you like to create a Firestore user profile for Drake Namanya?")
        print(f"This will create a document in users collection with ID: {auth_uid}")
        print()
        
        response = input("Create user profile? (yes/no): ").strip().lower()
        
        if response in ['yes', 'y']:
            if create_user_profile_if_needed(auth_uid, "drnamanya@gmail.com"):
                print("\n✅ User profile created!")
                print("   Now you can re-run fix_product_farmer_ids.py")
    
    print("\n" + "="*80 + "\n")


if __name__ == "__main__":
    main()
