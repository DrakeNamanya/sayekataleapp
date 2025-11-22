#!/usr/bin/env python3
"""
Script to delete existing admin accounts and create fresh ones
Requires password change on first login
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

def delete_admin_auth_users():
    """Delete all existing admin auth users"""
    print("\n🗑️  Deleting existing admin Firebase Auth accounts...")
    
    emails = [
        'admin@sayekatale.com',
        'moderator@sayekatale.com', 
        'analyst@sayekatale.com'
    ]
    
    deleted_count = 0
    for email in emails:
        try:
            user = auth.get_user_by_email(email)
            auth.delete_user(user.uid)
            print(f"  ✅ Deleted: {email}")
            deleted_count += 1
        except auth.UserNotFoundError:
            print(f"  ℹ️  Not found: {email}")
        except Exception as e:
            print(f"  ❌ Error deleting {email}: {e}")
    
    return deleted_count

def delete_admin_firestore_docs(db):
    """Delete all admin documents from Firestore"""
    print("\n🗑️  Deleting admin Firestore documents...")
    
    admin_users_ref = db.collection('admin_users')
    docs = admin_users_ref.get()
    
    deleted_count = 0
    for doc in docs:
        try:
            doc.reference.delete()
            print(f"  ✅ Deleted Firestore doc: {doc.id}")
            deleted_count += 1
        except Exception as e:
            print(f"  ❌ Error deleting {doc.id}: {e}")
    
    return deleted_count

def create_admin_user(email, password, name, role, permissions, db):
    """Create new admin user in both Auth and Firestore"""
    try:
        # Create Firebase Auth user with force password change
        user = auth.create_user(
            email=email,
            password=password,
            display_name=name,
            email_verified=False,  # Require email verification
        )
        
        # Create Firestore document
        admin_data = {
            'email': email.lower(),
            'name': name,
            'role': role,
            'permissions': permissions,
            'is_active': True,
            'must_change_password': True,  # Flag for password change
            'created_at': firestore.SERVER_TIMESTAMP,
            'last_login_at': None,
        }
        
        db.collection('admin_users').document(user.uid).set(admin_data)
        
        print(f"  ✅ Created: {email} (UID: {user.uid})")
        return True
        
    except Exception as e:
        print(f"  ❌ Failed to create {email}: {e}")
        return False

def main():
    print("="*70)
    print("🔄 RESETTING ADMIN ACCOUNTS")
    print("="*70)
    
    db = initialize_firebase()
    
    # Step 1: Delete existing admin auth users
    auth_deleted = delete_admin_auth_users()
    print(f"\n📊 Deleted {auth_deleted} Firebase Auth accounts")
    
    # Step 2: Delete existing Firestore documents
    firestore_deleted = delete_admin_firestore_docs(db)
    print(f"📊 Deleted {firestore_deleted} Firestore documents")
    
    # Step 3: Create new admin accounts
    print("\n"+"="*70)
    print("✨ CREATING NEW ADMIN ACCOUNTS")
    print("="*70)
    
    # New password (stronger)
    new_password = "Admin@2024!"
    
    admins = [
        {
            'email': 'admin@sayekatale.com',
            'password': new_password,
            'name': 'System Administrator',
            'role': 'superAdmin',
            'permissions': [
                'view_dashboard',
                'manage_users',
                'manage_products',
                'manage_orders',
                'view_analytics',
                'manage_complaints',
                'manage_admins',
                'view_audit_logs',
                'manage_system_config',
            ],
        },
        {
            'email': 'moderator@sayekatale.com',
            'password': new_password,
            'name': 'Content Moderator',
            'role': 'admin',
            'permissions': [
                'view_dashboard',
                'manage_users',
                'manage_products',
                'manage_complaints',
                'view_analytics',
            ],
        },
        {
            'email': 'analyst@sayekatale.com',
            'password': new_password,
            'name': 'Data Analyst',
            'role': 'analyst',
            'permissions': [
                'view_dashboard',
                'view_analytics',
            ],
        },
    ]
    
    created_count = 0
    for admin in admins:
        print(f"\n👤 {admin['name']} ({admin['role']})")
        if create_admin_user(
            email=admin['email'],
            password=admin['password'],
            name=admin['name'],
            role=admin['role'],
            permissions=admin['permissions'],
            db=db,
        ):
            created_count += 1
    
    print("\n"+"="*70)
    print(f"✅ RESET COMPLETE: {created_count}/3 admin accounts created")
    print("="*70)
    
    print("\n📋 NEW LOGIN CREDENTIALS:")
    print("\n" + "="*70)
    print("  Email: admin@sayekatale.com")
    print(f"  Password: {new_password}")
    print("  Role: System Administrator (Super Admin)")
    print("="*70)
    print("\n  Email: moderator@sayekatale.com")
    print(f"  Password: {new_password}")
    print("  Role: Content Moderator")
    print("="*70)
    print("\n  Email: analyst@sayekatale.com")
    print(f"  Password: {new_password}")
    print("  Role: Data Analyst")
    print("="*70)
    
    print("\n⚠️  IMPORTANT:")
    print("  • You will be REQUIRED to change password on first login")
    print("  • Email verification may be required")
    print("  • Use these credentials in the Admin Login Screen")
    print("\n💡 The 'must_change_password' flag is set to TRUE")
    print("   The app will prompt for password change after login\n")

if __name__ == "__main__":
    main()
