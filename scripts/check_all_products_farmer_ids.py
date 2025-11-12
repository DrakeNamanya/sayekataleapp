#!/usr/bin/env python3
"""
Check All Products for Invalid farmer_id Values
================================================

This script checks ALL products in Firestore to identify:
1. Products with invalid farmer_id (system_id pattern instead of Firebase UID)
2. Products where farmer profile doesn't exist in users collection
3. Summary by user/farmer

Usage:
    python3 check_all_products_farmer_ids.py
"""

import firebase_admin
from firebase_admin import credentials, firestore, auth
import sys
from collections import defaultdict

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized successfully\n")
except Exception as e:
    print(f"❌ Failed to initialize Firebase Admin SDK: {e}")
    sys.exit(1)

db = firestore.client()


def is_valid_firebase_uid(uid: str) -> bool:
    """Check if string looks like a valid Firebase UID"""
    if not uid:
        return False
    
    # Firebase UIDs are typically 28 characters, alphanumeric, no dashes
    # System IDs have patterns like "SHG-00001", "PROD-2025-123"
    if '-' in uid:
        return False  # Has dashes - likely system_id
    
    if len(uid) < 20:
        return False  # Too short
    
    return True


def check_user_exists(user_id: str) -> dict:
    """Check if user profile exists in Firestore users collection"""
    try:
        user_doc = db.collection('users').document(user_id).get()
        if user_doc.exists:
            data = user_doc.to_dict()
            return {
                'exists': True,
                'email': data.get('email', 'N/A'),
                'name': data.get('name', 'N/A'),
                'role': data.get('role', 'N/A'),
                'system_id': data.get('system_id', 'N/A'),
            }
        return {'exists': False}
    except Exception as e:
        return {'exists': False, 'error': str(e)}


def analyze_all_products():
    """Analyze all products for farmer_id issues"""
    print("="*80)
    print("🔍 ANALYZING ALL PRODUCTS")
    print("="*80 + "\n")
    
    try:
        products_ref = db.collection('products')
        all_products = products_ref.get()
        
        if not all_products:
            print("⚠️  No products found in Firestore!\n")
            return
        
        print(f"📦 Found {len(all_products)} total products\n")
        
        # Categorize products
        valid_products = []
        invalid_uid_products = []
        missing_farmer_products = []
        
        farmer_stats = defaultdict(lambda: {'valid': 0, 'invalid': 0, 'products': []})
        
        for doc in all_products:
            data = doc.to_dict()
            product_info = {
                'id': doc.id,
                'name': data.get('name', 'Unknown'),
                'farmer_id': data.get('farmer_id', ''),
                'farm_id': data.get('farm_id', ''),
                'farmer_name': data.get('farmer_name', 'Unknown'),
                'system_id': data.get('system_id', ''),
                'is_available': data.get('is_available', False),
                'category': data.get('category', 'N/A'),
            }
            
            farmer_id = product_info['farmer_id']
            
            # Check if farmer_id looks valid
            if not is_valid_firebase_uid(farmer_id):
                invalid_uid_products.append(product_info)
                farmer_stats[farmer_id]['invalid'] += 1
                farmer_stats[farmer_id]['products'].append(product_info['name'])
            else:
                # Check if farmer profile exists
                user_info = check_user_exists(farmer_id)
                if user_info['exists']:
                    valid_products.append(product_info)
                    farmer_stats[farmer_id]['valid'] += 1
                    farmer_stats[farmer_id]['user_info'] = user_info
                else:
                    missing_farmer_products.append(product_info)
                    farmer_stats[farmer_id]['invalid'] += 1
                    farmer_stats[farmer_id]['products'].append(product_info['name'])
        
        # Print Results
        print("="*80)
        print("📊 ANALYSIS RESULTS")
        print("="*80 + "\n")
        
        print(f"✅ Valid Products: {len(valid_products)}")
        print(f"❌ Invalid farmer_id (system_id pattern): {len(invalid_uid_products)}")
        print(f"⚠️  Valid UID but farmer profile missing: {len(missing_farmer_products)}")
        print()
        
        # Show invalid UID products
        if invalid_uid_products:
            print("="*80)
            print("❌ PRODUCTS WITH INVALID farmer_id (System ID Pattern)")
            print("="*80 + "\n")
            
            for i, product in enumerate(invalid_uid_products, 1):
                print(f"{i}. Product: {product['name']}")
                print(f"   Product ID: {product['id']}")
                print(f"   System ID: {product['system_id']}")
                print(f"   Category: {product['category']}")
                print(f"   Is Available: {product['is_available']}")
                print(f"   ❌ farmer_id: {product['farmer_id']}")
                print(f"   ❌ farm_id: {product['farm_id']}")
                print(f"   Farmer Name: {product['farmer_name']}")
                print()
        
        # Show missing farmer profile products
        if missing_farmer_products:
            print("="*80)
            print("⚠️  PRODUCTS WITH VALID UID BUT MISSING FARMER PROFILE")
            print("="*80 + "\n")
            
            for i, product in enumerate(missing_farmer_products, 1):
                print(f"{i}. Product: {product['name']}")
                print(f"   Product ID: {product['id']}")
                print(f"   farmer_id: {product['farmer_id']} (looks valid but user not found)")
                print(f"   Farmer Name: {product['farmer_name']}")
                print()
        
        # Show farmer statistics
        print("="*80)
        print("👥 FARMER STATISTICS")
        print("="*80 + "\n")
        
        for farmer_id, stats in farmer_stats.items():
            user_info = stats.get('user_info')
            
            if user_info:
                print(f"✅ Farmer: {user_info['name']} ({user_info['email']})")
                print(f"   Firebase UID: {farmer_id}")
                print(f"   Role: {user_info['role']}")
                print(f"   Valid Products: {stats['valid']}")
            else:
                print(f"❌ Invalid farmer_id: {farmer_id}")
                print(f"   Invalid Products: {stats['invalid']}")
                if stats['products']:
                    print(f"   Products affected: {', '.join(stats['products'][:3])}")
                    if len(stats['products']) > 3:
                        print(f"                      ... and {len(stats['products']) - 3} more")
            
            print()
        
        # Action Items
        if invalid_uid_products or missing_farmer_products:
            print("="*80)
            print("🔧 ACTION ITEMS")
            print("="*80 + "\n")
            
            if invalid_uid_products:
                print("1️⃣ Fix products with invalid farmer_id:")
                print("   Run: python3 scripts/fix_product_farmer_ids.py")
                print()
            
            if missing_farmer_products:
                print("2️⃣ Create missing farmer profiles:")
                print("   - Check Firebase Authentication for these users")
                print("   - Create user profile documents in Firestore users collection")
                print("   - Document ID should match Firebase Auth UID")
                print()
        else:
            print("="*80)
            print("✅ ALL PRODUCTS ARE VALID!")
            print("="*80 + "\n")
            print("No issues found. All products have:")
            print("✅ Valid Firebase UID as farmer_id")
            print("✅ Matching farmer profile in users collection")
            print()
        
    except Exception as e:
        print(f"❌ Error analyzing products: {e}\n")


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🔍 PRODUCT FARMER_ID INTEGRITY CHECK")
    print("="*80 + "\n")
    
    analyze_all_products()
    
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
