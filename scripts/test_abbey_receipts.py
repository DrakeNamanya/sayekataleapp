#!/usr/bin/env python3
"""
Diagnostic script to check Abbey Rukundo's receipts
Helps identify why receipts aren't showing in "My Receipts" screen
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys

print("🔍 Abbey Rukundo Receipt Diagnostic Tool")
print("=" * 50)

# Initialize Firebase Admin
try:
    cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
    firebase_admin.initialize_app(cred)
    print("✅ Firebase initialized successfully")
except Exception as e:
    print(f"❌ Error initializing Firebase: {e}")
    sys.exit(1)

db = firestore.client()

# Find Abbey Rukundo's user ID
print("\n🔍 Step 1: Searching for Abbey Rukundo...")
print("-" * 50)

users = list(db.collection('users').where('name', '==', 'Abbey Rukundo').stream())

abbey_user = None
if users:
    abbey_user = users[0]
    user_data = abbey_user.to_dict()
    print(f"✅ Found user!")
    print(f"   User ID: {abbey_user.id}")
    print(f"   Name: {user_data.get('name')}")
    print(f"   Email: {user_data.get('email')}")
    print(f"   Role: {user_data.get('role')}")
else:
    print("❌ 'Abbey Rukundo' not found")
    print("\n🔍 Searching for similar names...")
    all_users = db.collection('users').stream()
    found_similar = False
    for user in all_users:
        user_data = user.to_dict()
        name = user_data.get('name', '').lower()
        if 'abbey' in name or 'rukundo' in name:
            print(f"   Found: {user.id} - {user_data.get('name')} ({user_data.get('email')})")
            found_similar = True
    
    if not found_similar:
        print("   No similar names found")
    sys.exit(1)

abbey_id = abbey_user.id

# Check orders
print(f"\n🔍 Step 2: Checking orders for Abbey...")
print("-" * 50)

orders_query = db.collection('orders').where('buyer_id', '==', abbey_id)
orders = list(orders_query.stream())

if not orders:
    print(f"❌ No orders found for buyer_id: {abbey_id}")
    print("   This might be the issue!")
else:
    print(f"✅ Found {len(orders)} order(s)")
    
    order_summary = {
        'pending': 0,
        'confirmed': 0,
        'delivered': 0,
        'completed': 0,
        'with_receipt': 0,
        'without_receipt': 0
    }
    
    for order in orders:
        order_data = order.to_dict()
        status = order_data.get('status', 'unknown')
        has_receipt = order_data.get('receipt_id') is not None
        
        print(f"\n   Order: {order.id[:12]}...")
        print(f"      Status: {status}")
        print(f"      Buyer ID: {order_data.get('buyer_id')}")
        print(f"      Buyer Name: {order_data.get('buyer_name')}")
        print(f"      Total Amount: UGX {order_data.get('total_amount', 0):,.0f}")
        print(f"      Receipt ID: {order_data.get('receipt_id', 'None')}")
        print(f"      Is Received: {order_data.get('is_received_by_buyer', False)}")
        
        # Update summary
        if status in order_summary:
            order_summary[status] += 1
        if has_receipt:
            order_summary['with_receipt'] += 1
        else:
            order_summary['without_receipt'] += 1
    
    print(f"\n📊 Order Summary:")
    for key, value in order_summary.items():
        if value > 0:
            print(f"      {key.title()}: {value}")

# Check receipts
print(f"\n🔍 Step 3: Checking receipts in Firestore...")
print("-" * 50)

receipts_query = db.collection('receipts').where('buyer_id', '==', abbey_id)
receipts = list(receipts_query.stream())

if not receipts:
    print(f"❌ NO RECEIPTS FOUND for buyer_id: {abbey_id}")
    print("\n   This is why 'My Receipts' shows 'No purchase receipts yet'!")
    
    print("\n🔧 Possible Causes:")
    print("   1. Delivery was not confirmed (check order status)")
    print("   2. Receipt generation failed silently")
    print("   3. Field name mismatch (buyer_id vs buyerId)")
    print("   4. Firestore security rules blocking receipt creation")
    
    # Check if there are ANY receipts in the system
    all_receipts = list(db.collection('receipts').limit(5).stream())
    if all_receipts:
        print(f"\n   ℹ️  Note: There are {len(all_receipts)} receipts in the system")
        print("      The issue is specific to Abbey's receipts")
        sample_receipt = all_receipts[0].to_dict()
        print(f"      Sample receipt buyer_id format: {sample_receipt.get('buyer_id')}")
    else:
        print("\n   ℹ️  Note: NO receipts exist in the entire system")
        print("      Receipt generation might not be working at all")
else:
    print(f"✅ Found {len(receipts)} receipt(s)!")
    
    for receipt in receipts:
        receipt_data = receipt.to_dict()
        print(f"\n   Receipt: {receipt.id}")
        print(f"      Order ID: {receipt_data.get('order_id')}")
        print(f"      Buyer ID: {receipt_data.get('buyer_id')}")
        print(f"      Buyer Name: {receipt_data.get('buyer_name')}")
        print(f"      Seller Name: {receipt_data.get('seller_name')}")
        print(f"      Total Amount: UGX {receipt_data.get('total_amount', 0):,.0f}")
        print(f"      Created: {receipt_data.get('created_at')}")
    
    print(f"\n✅ Receipts exist but user can't see them!")
    print("\n🔧 Possible Causes:")
    print("   1. Query in StreamBuilder not matching")
    print("   2. User ID mismatch in app vs Firestore")
    print("   3. Firestore security rules blocking reads")
    print("   4. Wrong receipts screen being opened (seller vs buyer view)")

# Final diagnosis
print("\n" + "=" * 50)
print("📋 DIAGNOSIS SUMMARY:")
print("=" * 50)
print(f"✅ User Exists: {'Yes' if abbey_user else 'No'}")
print(f"✅ Has Orders: {'Yes' if orders else 'No'} ({len(orders)} total)")
print(f"✅ Has Receipts: {'Yes' if receipts else 'No'} ({len(receipts)} total)")

if not receipts and orders:
    completed_orders = [o for o in orders if o.to_dict().get('status') == 'completed']
    if completed_orders:
        print(f"\n⚠️  ISSUE FOUND:")
        print(f"   - {len(completed_orders)} completed order(s) without receipts")
        print(f"   - Receipts should have been generated automatically")
        print(f"\n💡 RECOMMENDED ACTION:")
        print(f"   Run: python3 /home/user/generate_missing_receipts.py")
    else:
        print(f"\n⚠️  ISSUE FOUND:")
        print(f"   - No completed orders yet")
        print(f"   - Receipts are only generated when buyer confirms delivery")
        print(f"\n💡 RECOMMENDED ACTION:")
        print(f"   Have Abbey confirm a delivered order to test receipt generation")

print("\n" + "=" * 50)
