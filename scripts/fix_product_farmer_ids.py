#!/usr/bin/env python3
"""
Fix Product Farmer IDs - Convert system_id to Firebase UID
============================================================

PROBLEM: Products have farmer_id = "SHG-00001" (system_id) instead of Firebase UID
SOLUTION: Update all products to use correct Firebase UID

This script:
1. Finds user's real Firebase UID using email
2. Finds all products with incorrect farmer_id (looks like system_id pattern)
3. Updates farmer_id and farm_id to correct Firebase UID
4. Reports changes made

Usage:
    python3 fix_product_farmer_ids.py
"""

import firebase_admin
from firebase_admin import credentials, firestore, auth
import sys
from datetime import datetime

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized successfully")
except Exception as e:
    print(f"❌ Failed to initialize Firebase Admin SDK: {e}")
    sys.exit(1)

db = firestore.client()


def find_user_uid_by_email(email: str) -> str:
    """Find Firebase User UID using email address"""
    try:
        user = auth.get_user_by_email(email)
        return user.uid
    except Exception as e:
        print(f"❌ Error finding user by email '{email}': {e}")
        return None


def find_users_with_system_id(system_id: str):
    """Find user documents in Firestore that have this system_id"""
    users_ref = db.collection('users')
    query = users_ref.where('system_id', '==', system_id).limit(1)
    docs = query.get()
    
    if docs:
        for doc in docs:
            return doc.id, doc.to_dict()
    return None, None


def find_products_with_invalid_farmer_id():
    """Find products with farmer_id that looks like system_id pattern (e.g., SHG-00001)"""
    products_ref = db.collection('products')
    all_products = products_ref.get()
    
    invalid_products = []
    
    for doc in all_products:
        data = doc.to_dict()
        farmer_id = data.get('farmer_id', '')
        
        # Check if farmer_id matches system_id pattern (starts with prefix like SHG-, PROD-, etc.)
        if farmer_id and ('-' in farmer_id or len(farmer_id) < 20):
            # Firebase UIDs are typically 28 characters, no dashes
            invalid_products.append({
                'id': doc.id,
                'name': data.get('name', 'Unknown'),
                'farmer_id': farmer_id,
                'farm_id': data.get('farm_id', ''),
                'farmer_name': data.get('farmer_name', 'Unknown'),
                'system_id': data.get('system_id', ''),
            })
    
    return invalid_products


def fix_product_farmer_id(product_id: str, correct_uid: str):
    """Update product's farmer_id and farm_id to correct Firebase UID"""
    try:
        product_ref = db.collection('products').document(product_id)
        product_ref.update({
            'farmer_id': correct_uid,
            'farm_id': correct_uid,
            'updated_at': firestore.SERVER_TIMESTAMP,
        })
        return True
    except Exception as e:
        print(f"❌ Error updating product {product_id}: {e}")
        return False


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🔧 PRODUCT FARMER ID FIX SCRIPT")
    print("="*80 + "\n")
    
    # Step 1: Find products with invalid farmer_id
    print("🔍 Step 1: Finding products with invalid farmer_id...\n")
    invalid_products = find_products_with_invalid_farmer_id()
    
    if not invalid_products:
        print("✅ No products found with invalid farmer_id!")
        print("   All products are already using correct Firebase UIDs.\n")
        return
    
    print(f"⚠️  Found {len(invalid_products)} products with invalid farmer_id:\n")
    
    for i, product in enumerate(invalid_products, 1):
        print(f"{i}. Product: {product['name']}")
        print(f"   System ID: {product['system_id']}")
        print(f"   Current farmer_id: {product['farmer_id']}")
        print(f"   Farmer Name: {product['farmer_name']}")
        print()
    
    # Step 2: Process each product
    print("\n" + "="*80)
    print("🔧 Step 2: Fixing farmer_id for each product...\n")
    
    fixed_count = 0
    failed_count = 0
    
    for product in invalid_products:
        print(f"📦 Processing: {product['name']}")
        print(f"   Current farmer_id: {product['farmer_id']}")
        
        # Try to find correct UID by system_id
        correct_uid, user_data = find_users_with_system_id(product['farmer_id'])
        
        if not correct_uid:
            print(f"   ❌ Cannot find user with system_id: {product['farmer_id']}")
            print(f"   💡 MANUAL ACTION REQUIRED:")
            print(f"      1. Find user '{product['farmer_name']}' in Firebase Auth")
            print(f"      2. Copy their UID")
            print(f"      3. Update product '{product['name']}' in Firestore:")
            print(f"         - farmer_id: <correct UID>")
            print(f"         - farm_id: <correct UID>")
            failed_count += 1
            print()
            continue
        
        print(f"   ✅ Found correct UID: {correct_uid}")
        print(f"   📧 User email: {user_data.get('email', 'N/A')}")
        print(f"   👤 User name: {user_data.get('name', 'N/A')}")
        
        # Fix the product
        if fix_product_farmer_id(product['id'], correct_uid):
            print(f"   ✅ Updated product successfully!")
            fixed_count += 1
        else:
            print(f"   ❌ Failed to update product")
            failed_count += 1
        
        print()
    
    # Final Summary
    print("\n" + "="*80)
    print("📊 SUMMARY")
    print("="*80 + "\n")
    print(f"Total products processed: {len(invalid_products)}")
    print(f"✅ Successfully fixed: {fixed_count}")
    print(f"❌ Failed to fix: {failed_count}")
    
    if fixed_count > 0:
        print("\n✅ Products updated successfully!")
        print("   - farmer_id now uses correct Firebase UID")
        print("   - farm_id now uses correct Firebase UID")
        print("   - Products should now be visible to SME users")
        print("\n🎯 Next Steps:")
        print("   1. Test app: Log in as SME user")
        print("   2. Go to Browse Products")
        print("   3. Hard refresh: Ctrl+Shift+R")
        print("   4. Verify products appear correctly")
    
    if failed_count > 0:
        print("\n⚠️  Some products need manual fixing:")
        print("   1. Go to Firebase Console → Authentication")
        print("   2. Find the user by name or email")
        print("   3. Copy their User UID")
        print("   4. Go to Firestore Database → products collection")
        print("   5. Update the product's farmer_id and farm_id fields")
    
    print("\n" + "="*80 + "\n")


if __name__ == "__main__":
    main()
