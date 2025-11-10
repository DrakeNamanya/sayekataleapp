#!/usr/bin/env python3
"""
Script to create Firebase Auth accounts for admin users
This enables admin login with email/password
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    import firebase_admin
    from firebase_admin import credentials, auth, firestore
except ImportError:
    print("❌ Failed to import firebase-admin")
    sys.exit(1)

def initialize_firebase():
    try:
        firebase_admin.get_app()
    except ValueError:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        firebase_admin.initialize_app(cred)
    return firestore.client()

def create_or_update_admin_auth(email, password, display_name, admin_id):
    """Create or update Firebase Auth user for admin"""
    try:
        # Try to get existing user
        try:
            user = auth.get_user_by_email(email)
            print(f"  ℹ️  User exists: {email}")
            
            # Update user
            auth.update_user(
                user.uid,
                password=password,
                display_name=display_name,
            )
            print(f"  ✅ Updated password for: {email}")
            return user.uid
            
        except auth.UserNotFoundError:
            # Create new user
            user = auth.create_user(
                uid=admin_id,
                email=email,
                password=password,
                display_name=display_name,
                email_verified=True,
            )
            print(f"  ✅ Created auth user: {email}")
            return user.uid
            
    except Exception as e:
        print(f"  ❌ Failed to create/update {email}: {e}")
        return None

def main():
    print("="*60)
    print("🔐 Setting Up Admin Authentication")
    print("="*60)
    
    db = initialize_firebase()
    
    # Get admin users from Firestore
    admin_users_ref = db.collection('admin_users')
    admin_docs = admin_users_ref.get()
    
    if not admin_docs:
        print("\n❌ No admin users found in Firestore!")
        print("Run create_admin_users.py first")
        return
    
    # Default password for testing
    default_password = "password123"
    
    print(f"\n🔑 Creating Firebase Auth accounts...")
    print(f"   Default password: {default_password}")
    print()
    
    created_count = 0
    
    for doc in admin_docs:
        admin_data = doc.to_dict()
        admin_id = doc.id
        email = admin_data.get('email')
        name = admin_data.get('name', 'Admin')
        role = admin_data.get('role', 'admin')
        
        if not email:
            print(f"  ⚠️  Skipping {admin_id}: No email found")
            continue
        
        print(f"\n👤 {name} ({role})")
        print(f"   Email: {email}")
        
        # Create/update auth user
        uid = create_or_update_admin_auth(
            email=email,
            password=default_password,
            display_name=name,
            admin_id=admin_id,
        )
        
        if uid:
            created_count += 1
    
    print("\n"+"="*60)
    print(f"✅ Setup complete: {created_count} admin auth accounts")
    print("="*60)
    print(f"\n📋 Login Credentials:")
    print(f"\n  Email: admin@sayekatale.com")
    print(f"  Password: {default_password}")
    print(f"\n  Email: moderator@sayekatale.com")
    print(f"  Password: {default_password}")
    print(f"\n  Email: analyst@sayekatale.com")
    print(f"  Password: {default_password}")
    print(f"\n⚠️  IMPORTANT: Change passwords after first login!")
    print(f"\n💡 Use these credentials in the Admin Login Screen")

if __name__ == "__main__":
    main()
