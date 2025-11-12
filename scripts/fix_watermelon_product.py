#!/usr/bin/env python3
"""
Fix Watermelon Product - Update farmer_id to correct Firebase UID
==================================================================

PROBLEM: Watermelon product has farmer_id = "SHG-00001" (invalid)
CORRECT: farmer_id should be "SccSSc08HbQUIYH731HvGhgSJNX2" (Drake Namanya's UID)

This script directly fixes the watermelon product.

Usage:
    python3 fix_watermelon_product.py
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

# Drake Namanya's correct Firebase UID (from Firebase Authentication)
CORRECT_UID = "SccSSc08HbQUIYH731HvGhgSJNX2"


def fix_watermelon_product():
    """Find and fix the watermelon product"""
    print("="*80)
    print("🔧 FIXING WATERMELON PRODUCT")
    print("="*80 + "\n")
    
    # Find watermelon product
    print("🔍 Searching for watermelon product...")
    
    try:
        products_ref = db.collection('products')
        query = products_ref.where('name', '==', 'watermelon').limit(1)
        docs = query.get()
        
        if not docs:
            print("❌ Watermelon product not found!")
            return False
        
        for doc in docs:
            data = doc.to_dict()
            
            print(f"✅ Found watermelon product!\n")
            print(f"   Product ID: {doc.id}")
            print(f"   System ID: {data.get('system_id', 'N/A')}")
            print(f"   Name: {data.get('name', 'N/A')}")
            print(f"   Description: {data.get('description', 'N/A')}")
            print(f"   Price: {data.get('price', 'N/A')} UGX")
            print(f"   Category: {data.get('category', 'N/A')}")
            print(f"   Is Available: {data.get('is_available', 'N/A')}")
            print()
            print(f"   🔴 CURRENT farmer_id: {data.get('farmer_id', 'N/A')}")
            print(f"   🔴 CURRENT farm_id: {data.get('farm_id', 'N/A')}")
            print(f"   Farmer Name: {data.get('farmer_name', 'N/A')}")
            print()
            print(f"   🟢 CORRECT farmer_id: {CORRECT_UID}")
            print(f"   🟢 CORRECT farm_id: {CORRECT_UID}")
            print()
            
            # Check if already fixed
            if data.get('farmer_id') == CORRECT_UID:
                print("✅ Product already has correct farmer_id!")
                return True
            
            # Fix the product
            print("🔧 Updating product...")
            try:
                doc.reference.update({
                    'farmer_id': CORRECT_UID,
                    'farm_id': CORRECT_UID,
                    'updated_at': firestore.SERVER_TIMESTAMP,
                })
                
                print("✅ Product updated successfully!\n")
                
                # Verify the update
                updated_doc = doc.reference.get()
                updated_data = updated_doc.to_dict()
                
                print("📋 VERIFICATION:")
                print(f"   New farmer_id: {updated_data.get('farmer_id')}")
                print(f"   New farm_id: {updated_data.get('farm_id')}")
                
                if updated_data.get('farmer_id') == CORRECT_UID:
                    print("\n✅ UPDATE CONFIRMED!")
                    return True
                else:
                    print("\n❌ UPDATE FAILED - farmer_id still incorrect")
                    return False
                
            except Exception as e:
                print(f"❌ Error updating product: {e}")
                return False
        
    except Exception as e:
        print(f"❌ Error searching for product: {e}")
        return False


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🍉 WATERMELON PRODUCT FIX")
    print("="*80 + "\n")
    
    print("📍 Target User: Drake Namanya (drnamanya@gmail.com)")
    print(f"📍 Correct Firebase UID: {CORRECT_UID}")
    print()
    
    success = fix_watermelon_product()
    
    if success:
        print("\n" + "="*80)
        print("✅ SUCCESS - PRODUCT FIXED!")
        print("="*80 + "\n")
        print("🎯 What Was Changed:")
        print(f"   farmer_id: 'SHG-00001' → '{CORRECT_UID}'")
        print(f"   farm_id: 'SHG-00001' → '{CORRECT_UID}'")
        print()
        print("🎯 Next Steps:")
        print("   1. Log in to app as SME user: datacollectorslimited@gmail.com")
        print("   2. Navigate to Browse Products screen")
        print("   3. Hard refresh: Ctrl+Shift+R (or close and reopen app)")
        print("   4. ✅ Watermelon product should now be visible!")
        print()
        print("💡 Why This Fixes It:")
        print("   - Product now uses correct Firebase User UID")
        print("   - ProductWithFarmerService can find farmer profile in users collection")
        print("   - Product is no longer skipped when enriching with farmer details")
        print("   - SME user can see product in browse list")
        print()
    else:
        print("\n" + "="*80)
        print("❌ FIX FAILED")
        print("="*80 + "\n")
        print("💡 Manual Fix Required:")
        print("   1. Go to: https://console.firebase.google.com/")
        print("   2. Navigate to: Firestore Database → products collection")
        print("   3. Find product: watermelon (name field)")
        print("   4. Update these fields:")
        print(f"      farmer_id: {CORRECT_UID}")
        print(f"      farm_id: {CORRECT_UID}")
        print("   5. Save changes")
        print()
    
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
