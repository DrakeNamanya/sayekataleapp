#!/usr/bin/env python3
"""
Fix Order ID Field - Remove empty id field from orders
=======================================================

PROBLEM: Orders have empty 'id' field which prevents Order.fromFirestore() 
         from using document ID correctly

SOLUTION: Remove 'id' field from orders so fromFirestore uses docId parameter

Usage:
    python3 fix_order_id_field.py
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


def fix_orders():
    """Remove empty id field from all orders"""
    print("="*80)
    print("🔧 FIXING ORDER ID FIELDS")
    print("="*80 + "\n")
    
    try:
        orders_ref = db.collection('orders')
        all_orders = orders_ref.get()
        
        if not all_orders:
            print("⚠️  No orders found!\n")
            return
        
        print(f"📦 Found {len(all_orders)} orders\n")
        
        fixed_count = 0
        
        for doc in all_orders:
            data = doc.to_dict()
            order_id = doc.id
            stored_id = data.get('id', None)
            
            # Check if id field is empty or doesn't match document ID
            if stored_id == '' or (stored_id and stored_id != order_id):
                print(f"📦 Order: {data.get('order_number', order_id)}")
                print(f"   Document ID: {order_id}")
                print(f"   Stored 'id': {repr(stored_id)}")
                print(f"   🔧 Removing empty/incorrect 'id' field...")
                
                try:
                    # Remove the 'id' field from document
                    doc.reference.update({
                        'id': firestore.DELETE_FIELD,
                        'updated_at': firestore.SERVER_TIMESTAMP,
                    })
                    print(f"   ✅ Fixed!")
                    fixed_count += 1
                except Exception as e:
                    print(f"   ❌ Error: {e}")
                
                print()
        
        print("="*80)
        print("📊 SUMMARY")
        print("="*80 + "\n")
        print(f"Total orders checked: {len(all_orders)}")
        print(f"✅ Fixed: {fixed_count}")
        print()
        
        if fixed_count > 0:
            print("✅ Orders fixed successfully!")
            print("   - Removed empty/incorrect 'id' fields")
            print("   - Order.fromFirestore() will now use document ID correctly")
            print()
        else:
            print("✅ All orders already have correct structure")
            print()
        
    except Exception as e:
        print(f"❌ Error: {e}")


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🔧 ORDER ID FIELD FIX")
    print("="*80 + "\n")
    
    fix_orders()
    
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
