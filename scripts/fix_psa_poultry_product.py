#!/usr/bin/env python3
"""
Fix PSA Poultry Product - Update farmer_id to correct Firebase UID
===================================================================

PROBLEM: "Old day Chicks" product has farmer_id = "PSA-00001" (invalid)
CORRECT: farmer_id should be "3tUQ06RgrlcYnsjkvkUeoqwraxu1" (PSA user's Firebase UID)

This script directly fixes the PSA poultry product.

Usage:
    python3 fix_psa_poultry_product.py
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

# PSA user's correct Firebase UID (from Firebase Authentication)
PSA_CORRECT_UID = "3tUQ06RgrlcYnsjkvkUeoqwraxu1"


def fix_psa_poultry_product():
    """Find and fix the PSA poultry product"""
    print("="*80)
    print("🔧 FIXING PSA POULTRY PRODUCT")
    print("="*80 + "\n")
    
    # Find PSA products with invalid farmer_id
    print("🔍 Searching for products with farmer_id = 'PSA-00001'...")
    
    try:
        products_ref = db.collection('products')
        query = products_ref.where('farmer_id', '==', 'PSA-00001')
        docs = query.get()
        
        if not docs:
            print("❌ No products found with farmer_id = 'PSA-00001'!")
            return False
        
        fixed_count = 0
        
        for doc in docs:
            data = doc.to_dict()
            
            print(f"✅ Found product!\n")
            print(f"   Product ID: {doc.id}")
            print(f"   System ID: {data.get('system_id', 'N/A')}")
            print(f"   Name: {data.get('name', 'N/A')}")
            print(f"   Description: {data.get('description', 'N/A')}")
            print(f"   Price: {data.get('price', 'N/A')} UGX")
            print(f"   Category: {data.get('category', 'N/A')}")
            print(f"   Main Category: {data.get('main_category', 'N/A')}")
            print(f"   Subcategory: {data.get('subcategory', 'N/A')}")
            print(f"   Is Available: {data.get('is_available', 'N/A')}")
            print()
            print(f"   🔴 CURRENT farmer_id: {data.get('farmer_id', 'N/A')}")
            print(f"   🔴 CURRENT farm_id: {data.get('farm_id', 'N/A')}")
            print(f"   Farmer Name: {data.get('farmer_name', 'N/A')}")
            print()
            print(f"   🟢 CORRECT farmer_id: {PSA_CORRECT_UID}")
            print(f"   🟢 CORRECT farm_id: {PSA_CORRECT_UID}")
            print()
            
            # Check if already fixed
            if data.get('farmer_id') == PSA_CORRECT_UID:
                print("✅ Product already has correct farmer_id!")
                continue
            
            # Fix the product
            print("🔧 Updating product...")
            try:
                doc.reference.update({
                    'farmer_id': PSA_CORRECT_UID,
                    'farm_id': PSA_CORRECT_UID,
                    'updated_at': firestore.SERVER_TIMESTAMP,
                })
                
                print("✅ Product updated successfully!\n")
                
                # Verify the update
                updated_doc = doc.reference.get()
                updated_data = updated_doc.to_dict()
                
                print("📋 VERIFICATION:")
                print(f"   New farmer_id: {updated_data.get('farmer_id')}")
                print(f"   New farm_id: {updated_data.get('farm_id')}")
                
                if updated_data.get('farmer_id') == PSA_CORRECT_UID:
                    print("\n✅ UPDATE CONFIRMED!")
                    fixed_count += 1
                else:
                    print("\n❌ UPDATE FAILED - farmer_id still incorrect")
                
                print()
                
            except Exception as e:
                print(f"❌ Error updating product: {e}")
                print()
        
        return fixed_count > 0
        
    except Exception as e:
        print(f"❌ Error searching for products: {e}")
        return False


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🐔 PSA POULTRY PRODUCT FIX")
    print("="*80 + "\n")
    
    print("📍 Target User: kiconco psa (kiconcodebrah@gmail.com)")
    print(f"📍 Correct Firebase UID: {PSA_CORRECT_UID}")
    print()
    
    success = fix_psa_poultry_product()
    
    if success:
        print("\n" + "="*80)
        print("✅ SUCCESS - PRODUCT(S) FIXED!")
        print("="*80 + "\n")
        print("🎯 What Was Changed:")
        print(f"   farmer_id: 'PSA-00001' → '{PSA_CORRECT_UID}'")
        print(f"   farm_id: 'PSA-00001' → '{PSA_CORRECT_UID}'")
        print()
        print("🎯 Next Steps:")
        print("   1. Log in to app as SHG user: drnamanya@gmail.com")
        print("   2. Navigate to Buy Inputs screen")
        print("   3. Hard refresh: Ctrl+Shift+R (or close and reopen app)")
        print("   4. ✅ PSA poultry product should now be visible!")
        print()
        print("💡 Why This Fixes It:")
        print("   - Product now uses correct Firebase User UID")
        print("   - ProductWithFarmerService can find PSA user profile")
        print("   - Product is no longer skipped when enriching with supplier details")
        print("   - SHG users can see PSA products in Buy Inputs")
        print()
        print("🚨 ROOT CAUSE:")
        print("   The PSA user profile may have a 'system_id' field that is being")
        print("   incorrectly used as farmer_id. We need to investigate why the")
        print("   PSA product creation screen is using system_id instead of Firebase UID.")
        print()
    else:
        print("\n" + "="*80)
        print("❌ FIX FAILED OR NO PRODUCTS FOUND")
        print("="*80 + "\n")
        print("💡 Manual Fix Required:")
        print("   1. Go to: https://console.firebase.google.com/")
        print("   2. Navigate to: Firestore Database → products collection")
        print("   3. Find product: Old day Chicks (or search by farmer_id = 'PSA-00001')")
        print("   4. Update these fields:")
        print(f"      farmer_id: {PSA_CORRECT_UID}")
        print(f"      farm_id: {PSA_CORRECT_UID}")
        print("   5. Save changes")
        print()
    
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
