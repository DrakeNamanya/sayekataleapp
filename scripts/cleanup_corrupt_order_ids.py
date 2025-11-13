#!/usr/bin/env python3
"""
Cleanup script for corrupt order IDs in Firestore
This script removes the 'id' field from all order documents in Firestore
to prevent conflicts with Firestore document IDs.

Usage:
    python3 cleanup_corrupt_order_ids.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

def cleanup_corrupt_order_ids():
    """Remove 'id' field from all order documents"""
    
    # Initialize Firebase Admin SDK
    try:
        cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialized")
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return
    
    db = firestore.client()
    
    try:
        # Get all orders
        orders_ref = db.collection('orders')
        orders = orders_ref.stream()
        
        fixed_count = 0
        error_count = 0
        total_count = 0
        
        print("\n🔍 Scanning orders collection...")
        
        for order_doc in orders:
            total_count += 1
            order_id = order_doc.id
            order_data = order_doc.to_dict()
            
            # Check if 'id' field exists
            if 'id' in order_data:
                stored_id = order_data.get('id')
                
                # Check if stored id is corrupt (different from document ID)
                if stored_id != order_id:
                    print(f"\n⚠️  Order {order_id}")
                    print(f"   Stored 'id' field: {stored_id}")
                    print(f"   Actual document ID: {order_id}")
                    print(f"   → Removing corrupt 'id' field...")
                    
                    try:
                        # Remove the 'id' field from document
                        orders_ref.document(order_id).update({
                            'id': firestore.DELETE_FIELD
                        })
                        fixed_count += 1
                        print(f"   ✅ Fixed!")
                    except Exception as e:
                        print(f"   ❌ Error: {e}")
                        error_count += 1
                elif stored_id == order_id:
                    # ID matches but redundant, still remove it
                    print(f"\n📝 Order {order_id}: Removing redundant 'id' field...")
                    try:
                        orders_ref.document(order_id).update({
                            'id': firestore.DELETE_FIELD
                        })
                        fixed_count += 1
                        print(f"   ✅ Removed")
                    except Exception as e:
                        print(f"   ❌ Error: {e}")
                        error_count += 1
        
        # Summary
        print("\n" + "="*60)
        print("📊 CLEANUP SUMMARY")
        print("="*60)
        print(f"Total orders scanned: {total_count}")
        print(f"Orders fixed: {fixed_count}")
        print(f"Errors: {error_count}")
        print(f"Clean orders: {total_count - fixed_count - error_count}")
        print("="*60)
        
        if fixed_count > 0:
            print("\n✅ Cleanup completed successfully!")
            print("   All orders now use Firestore document IDs only.")
            print("   You can now test the order screens - they should work!")
        else:
            print("\n✅ No corrupt data found - all orders are clean!")
            
    except Exception as e:
        print(f"\n❌ Fatal error during cleanup: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    print("="*60)
    print("🔧 FIRESTORE ORDER ID CLEANUP SCRIPT")
    print("="*60)
    print("This script will remove corrupt 'id' fields from orders")
    print("to fix the 'invalid document reference' errors.")
    print("="*60)
    
    # Confirm before proceeding
    response = input("\n⚠️  Proceed with cleanup? (yes/no): ")
    
    if response.lower() in ['yes', 'y']:
        print("\n🚀 Starting cleanup...\n")
        cleanup_corrupt_order_ids()
    else:
        print("\n❌ Cleanup cancelled.")
