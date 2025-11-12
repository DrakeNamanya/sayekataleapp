#!/usr/bin/env python3
"""
Fix Existing User Profiles - Migrate id field to Firebase UID
==============================================================

PROBLEM: Existing user profiles have wrong 'id' field (system ID like "PSA-00001")
SOLUTION: Update 'id' field to Firebase UID, move old value to 'system_id'

This script:
1. Finds all users where id field != document ID (Firebase UID)
2. Moves current id value to system_id field
3. Sets id field to document ID (Firebase UID)

Usage:
    python3 fix_existing_user_profiles.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
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


def fix_user_profiles():
    """Fix all user profiles with wrong id field"""
    print("="*80)
    print("🔧 FIXING USER PROFILES")
    print("="*80 + "\n")
    
    try:
        users_ref = db.collection('users')
        all_users = users_ref.get()
        
        if not all_users:
            print("⚠️  No users found in Firestore!\n")
            return
        
        print(f"👥 Found {len(all_users)} user profiles\n")
        
        fixed_count = 0
        already_correct = 0
        
        for doc in all_users:
            firebase_uid = doc.id
            data = doc.to_dict()
            stored_id = data.get('id')
            
            print(f"📋 User: {data.get('name', 'Unknown')} ({data.get('email', 'N/A')})")
            print(f"   Document ID (Firebase UID): {firebase_uid}")
            print(f"   Stored 'id' field: {stored_id}")
            
            if stored_id == firebase_uid:
                print(f"   ✅ Already correct - id matches Firebase UID")
                already_correct += 1
            else:
                print(f"   🔧 Needs fix - id != Firebase UID")
                print(f"   Moving '{stored_id}' to system_id field...")
                
                try:
                    # Update the user profile
                    doc.reference.update({
                        'id': firebase_uid,  # Set to Firebase UID
                        'system_id': stored_id,  # Move old value to system_id
                        'updated_at': firestore.SERVER_TIMESTAMP,
                    })
                    
                    print(f"   ✅ Fixed successfully!")
                    fixed_count += 1
                    
                    # Verify the update
                    updated_doc = doc.reference.get()
                    updated_data = updated_doc.to_dict()
                    print(f"   ✅ Verified - id: {updated_data.get('id')}, system_id: {updated_data.get('system_id')}")
                    
                except Exception as e:
                    print(f"   ❌ Error updating: {e}")
            
            print()
        
        # Summary
        print("="*80)
        print("📊 SUMMARY")
        print("="*80 + "\n")
        print(f"Total users: {len(all_users)}")
        print(f"✅ Already correct: {already_correct}")
        print(f"🔧 Fixed: {fixed_count}")
        print()
        
        if fixed_count > 0:
            print("✅ All user profiles have been migrated!")
            print("   - id field now uses Firebase UID")
            print("   - Old ID value moved to system_id field")
            print("   - Products created by these users will now use correct Firebase UID")
            print()
        
    except Exception as e:
        print(f"❌ Error: {e}")


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🔧 USER PROFILE MIGRATION")
    print("="*80 + "\n")
    
    print("This script will fix user profiles where 'id' field doesn't match Firebase UID.\n")
    
    response = input("Continue with migration? (yes/no): ").strip().lower()
    
    if response not in ['yes', 'y']:
        print("\n❌ Migration cancelled by user\n")
        return
    
    print()
    fix_user_profiles()
    
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
