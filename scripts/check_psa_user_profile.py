#!/usr/bin/env python3
"""
Check PSA User Profile - Investigate system_id field
=====================================================

This script checks the PSA user's Firestore profile to see if
there's a system_id field being stored incorrectly.

Usage:
    python3 check_psa_user_profile.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys
import json

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized successfully\n")
except Exception as e:
    print(f"❌ Failed to initialize Firebase Admin SDK: {e}")
    sys.exit(1)

db = firestore.client()

PSA_UID = "3tUQ06RgrlcYnsjkvkUeoqwraxu1"
PSA_EMAIL = "kiconcodebrah@gmail.com"


def check_psa_user_profile():
    """Check PSA user profile in detail"""
    print("="*80)
    print("🔍 PSA USER PROFILE INVESTIGATION")
    print("="*80 + "\n")
    
    print(f"Target User: {PSA_EMAIL}")
    print(f"Firebase UID: {PSA_UID}\n")
    
    try:
        # Get user profile from Firestore
        user_ref = db.collection('users').document(PSA_UID)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            print(f"❌ User profile NOT found in Firestore!")
            print(f"   Expected document ID: {PSA_UID}")
            return
        
        data = user_doc.to_dict()
        
        print("✅ User Profile Found!\n")
        print("="*80)
        print("📋 COMPLETE PROFILE DATA")
        print("="*80 + "\n")
        
        # Print all fields
        for key, value in sorted(data.items()):
            print(f"{key}: {value}")
        
        print("\n" + "="*80)
        print("🔑 KEY FIELDS ANALYSIS")
        print("="*80 + "\n")
        
        # Check critical fields
        id_field = data.get('id')
        system_id_field = data.get('system_id')
        email = data.get('email')
        name = data.get('name')
        role = data.get('role')
        
        print(f"id field: {id_field}")
        print(f"system_id field: {system_id_field}")
        print(f"email: {email}")
        print(f"name: {name}")
        print(f"role: {role}")
        print()
        
        # Identify the problem
        if system_id_field and system_id_field == "PSA-00001":
            print("🚨 PROBLEM IDENTIFIED!")
            print("="*80 + "\n")
            print("The user profile HAS a 'system_id' field with value: 'PSA-00001'")
            print()
            print("This suggests the PSA product creation code is incorrectly using:")
            print("   ❌ psaUser.systemId  (returns 'PSA-00001')")
            print()
            print("Instead of:")
            print("   ✅ psaUser.id  (returns Firebase UID)")
            print()
            print("ACTION REQUIRED:")
            print("   Check psa_add_edit_product_screen.dart")
            print("   Verify it's using psaUser.id, not psaUser.systemId")
            print()
        elif id_field == "PSA-00001":
            print("🚨 CRITICAL PROBLEM IDENTIFIED!")
            print("="*80 + "\n")
            print("The user profile's 'id' field is WRONG!")
            print(f"   Current id: {id_field}")
            print(f"   Should be: {PSA_UID}")
            print()
            print("This means the user profile was created incorrectly.")
            print()
        elif not system_id_field:
            print("✅ No system_id field found")
            print()
            print("This suggests the product was created through a different method")
            print("or the user profile was updated after product creation.")
            print()
        else:
            print(f"⚠️  system_id field exists but has different value: {system_id_field}")
            print()
        
    except Exception as e:
        print(f"❌ Error checking user profile: {e}")


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🔍 PSA USER PROFILE DIAGNOSTIC")
    print("="*80 + "\n")
    
    check_psa_user_profile()
    
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
