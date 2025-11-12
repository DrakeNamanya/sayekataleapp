#!/usr/bin/env python3
"""
Check and Fix Orders - Update seller_id/farmer_id to Firebase UID
===================================================================

PROBLEM: Existing orders have old system IDs (SHG-00001, PSA-00001) instead of Firebase UIDs
SOLUTION: Update orders to use correct Firebase UIDs

This script:
1. Finds all orders with invalid seller_id/buyer_id (system ID pattern)
2. Maps old system IDs to correct Firebase UIDs using system_id field
3. Updates orders with correct Firebase UIDs

Usage:
    python3 check_and_fix_orders.py
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


def is_system_id(uid: str) -> bool:
    """Check if string looks like system ID (not Firebase UID)"""
    if not uid:
        return False
    # System IDs have patterns like "SHG-00001", "PSA-00001", "SME-00001"
    return '-' in uid and len(uid) < 20


def find_user_by_system_id(system_id: str):
    """Find user's Firebase UID using their system_id field"""
    try:
        users_ref = db.collection('users')
        query = users_ref.where('system_id', '==', system_id).limit(1)
        docs = query.get()
        
        if docs:
            for doc in docs:
                return doc.id  # Return Firebase UID (document ID)
        return None
    except Exception as e:
        print(f"❌ Error finding user by system_id '{system_id}': {e}")
        return None


def check_and_fix_orders():
    """Check all orders and fix seller_id/buyer_id if needed"""
    print("="*80)
    print("🔍 CHECKING ORDERS")
    print("="*80 + "\n")
    
    try:
        orders_ref = db.collection('orders')
        all_orders = orders_ref.get()
        
        if not all_orders:
            print("⚠️  No orders found in Firestore!\n")
            return
        
        print(f"📦 Found {len(all_orders)} orders\n")
        
        valid_orders = 0
        invalid_orders = []
        
        for doc in all_orders:
            data = doc.to_dict()
            order_id = doc.id
            
            seller_id = data.get('seller_id') or data.get('sellerId') or data.get('farmer_id') or data.get('farmerId', '')
            buyer_id = data.get('buyer_id') or data.get('buyerId', '')
            
            has_invalid_seller = is_system_id(seller_id)
            has_invalid_buyer = is_system_id(buyer_id)
            
            if has_invalid_seller or has_invalid_buyer:
                invalid_orders.append({
                    'id': order_id,
                    'order_number': data.get('order_number', 'N/A'),
                    'seller_id': seller_id,
                    'seller_name': data.get('seller_name') or data.get('sellerName') or data.get('farmer_name', 'Unknown'),
                    'buyer_id': buyer_id,
                    'buyer_name': data.get('buyer_name') or data.get('buyerName', 'Unknown'),
                    'status': data.get('status', 'N/A'),
                    'invalid_seller': has_invalid_seller,
                    'invalid_buyer': has_invalid_buyer,
                })
            else:
                valid_orders += 1
        
        # Print Results
        print("="*80)
        print("📊 ANALYSIS RESULTS")
        print("="*80 + "\n")
        
        print(f"✅ Valid Orders: {valid_orders}")
        print(f"❌ Invalid Orders: {len(invalid_orders)}")
        print()
        
        if not invalid_orders:
            print("✅ All orders have valid Firebase UIDs!")
            return
        
        # Show invalid orders
        print("="*80)
        print("❌ ORDERS WITH INVALID IDs")
        print("="*80 + "\n")
        
        for i, order in enumerate(invalid_orders, 1):
            print(f"{i}. Order #{order['order_number']}")
            print(f"   Order ID: {order['id']}")
            print(f"   Status: {order['status']}")
            
            if order['invalid_seller']:
                print(f"   ❌ seller_id: {order['seller_id']} (system ID)")
                print(f"      Seller: {order['seller_name']}")
            else:
                print(f"   ✅ seller_id: {order['seller_id']} (valid)")
            
            if order['invalid_buyer']:
                print(f"   ❌ buyer_id: {order['buyer_id']} (system ID)")
                print(f"      Buyer: {order['buyer_name']}")
            else:
                print(f"   ✅ buyer_id: {order['buyer_id']} (valid)")
            
            print()
        
        # Fix orders
        print("="*80)
        print("🔧 FIXING ORDERS")
        print("="*80 + "\n")
        
        response = input("Fix these orders? (yes/no): ").strip().lower()
        
        if response not in ['yes', 'y']:
            print("\n❌ Fix cancelled by user\n")
            return
        
        print()
        
        fixed_count = 0
        failed_count = 0
        
        for order in invalid_orders:
            print(f"📦 Processing Order #{order['order_number']}...")
            
            updates = {}
            
            # Fix seller_id
            if order['invalid_seller']:
                correct_seller_uid = find_user_by_system_id(order['seller_id'])
                if correct_seller_uid:
                    print(f"   ✅ Found seller Firebase UID: {correct_seller_uid}")
                    updates['seller_id'] = correct_seller_uid
                    updates['sellerId'] = correct_seller_uid
                    updates['farmer_id'] = correct_seller_uid
                    updates['farmerId'] = correct_seller_uid
                else:
                    print(f"   ❌ Cannot find user with system_id: {order['seller_id']}")
                    failed_count += 1
                    continue
            
            # Fix buyer_id
            if order['invalid_buyer']:
                correct_buyer_uid = find_user_by_system_id(order['buyer_id'])
                if correct_buyer_uid:
                    print(f"   ✅ Found buyer Firebase UID: {correct_buyer_uid}")
                    updates['buyer_id'] = correct_buyer_uid
                    updates['buyerId'] = correct_buyer_uid
                else:
                    print(f"   ❌ Cannot find user with system_id: {order['buyer_id']}")
                    failed_count += 1
                    continue
            
            # Update order
            if updates:
                try:
                    updates['updated_at'] = firestore.SERVER_TIMESTAMP
                    db.collection('orders').document(order['id']).update(updates)
                    print(f"   ✅ Order fixed successfully!")
                    fixed_count += 1
                except Exception as e:
                    print(f"   ❌ Error updating order: {e}")
                    failed_count += 1
            
            print()
        
        # Summary
        print("="*80)
        print("📊 SUMMARY")
        print("="*80 + "\n")
        print(f"Total invalid orders: {len(invalid_orders)}")
        print(f"✅ Fixed: {fixed_count}")
        print(f"❌ Failed: {failed_count}")
        print()
        
        if fixed_count > 0:
            print("✅ Orders updated successfully!")
            print("   - seller_id now uses Firebase UID")
            print("   - buyer_id now uses Firebase UID")
            print("   - Orders can now be accepted/confirmed")
            print()
        
    except Exception as e:
        print(f"❌ Error: {e}")


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🔧 ORDER SELLER_ID/BUYER_ID FIX")
    print("="*80 + "\n")
    
    check_and_fix_orders()
    
    print("="*80 + "\n")


if __name__ == "__main__":
    main()
