#!/usr/bin/env python3
"""
Script to create admin users in Firestore
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
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

def main():
    print("="*60)
    print("🔧 Creating Admin Users")
    print("="*60)
    
    db = initialize_firebase()
    admin_users_ref = db.collection('admin_users')
    
    # Create Super Admin
    super_admin = {
        'email': 'admin@sayekatale.com',
        'name': 'System Administrator',
        'role': 'superAdmin',
        'permissions': [
            'manage_users',
            'manage_admins',
            'verify_psa',
            'moderate_products',
            'manage_orders',
            'view_analytics',
            'system_settings',
        ],
        'is_active': True,
        'created_at': firestore.SERVER_TIMESTAMP,
    }
    
    super_admin_ref = admin_users_ref.document('super_admin_001')
    super_admin_ref.set(super_admin)
    print(f"\n✅ Created Super Admin: {super_admin['email']}")
    print(f"   Role: {super_admin['role']}")
    print(f"   Permissions: {len(super_admin['permissions'])}")
    
    # Create Regular Admin
    admin = {
        'email': 'moderator@sayekatale.com',
        'name': 'Content Moderator',
        'role': 'admin',
        'permissions': [
            'manage_users',
            'verify_psa',
            'moderate_products',
            'manage_orders',
            'view_analytics',
        ],
        'is_active': True,
        'created_at': firestore.SERVER_TIMESTAMP,
    }
    
    admin_ref = admin_users_ref.document('admin_001')
    admin_ref.set(admin)
    print(f"\n✅ Created Admin: {admin['email']}")
    print(f"   Role: {admin['role']}")
    print(f"   Permissions: {len(admin['permissions'])}")
    
    # Create Analyst
    analyst = {
        'email': 'analyst@sayekatale.com',
        'name': 'Data Analyst',
        'role': 'analyst',
        'permissions': ['view_analytics'],
        'is_active': True,
        'created_at': firestore.SERVER_TIMESTAMP,
    }
    
    analyst_ref = admin_users_ref.document('analyst_001')
    analyst_ref.set(analyst)
    print(f"\n✅ Created Analyst: {analyst['email']}")
    print(f"   Role: {analyst['role']}")
    print(f"   Permissions: {len(analyst['permissions'])}")
    
    print("\n"+"="*60)
    print("✅ Admin users created successfully!")
    print("="*60)
    print("\n📋 Login Credentials (use email to login):")
    print(f"  • Super Admin: {super_admin['email']}")
    print(f"  • Admin: {admin['email']}")
    print(f"  • Analyst: {analyst['email']}")
    print("\n💡 Use these emails in the admin login screen")

if __name__ == "__main__":
    main()
