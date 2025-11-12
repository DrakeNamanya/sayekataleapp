#!/usr/bin/env python3
"""
================================================================================
FIREBASE ORDERS MIGRATION: Add Participants Array
================================================================================
Purpose: Add 'participants' array to all existing orders for proper access control

This script:
1. Finds all orders (using collection_group for root and subcollections)
2. Extracts buyer_id/buyerId, seller_id/sellerId, farmer_id/farmerId
3. Creates a participants array with all unique user IDs
4. Updates each order with the participants field

Run this AFTER applying new Firestore rules to fix "permission-denied" errors
on existing orders that don't have the participants field.
================================================================================
"""

import sys
import os

# Check if Firebase Admin SDK is available
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 INSTALLATION REQUIRED:")
    print("pip install firebase-admin==7.1.0")
    print("💡 This package is required for Firebase operations.")
    sys.exit(1)

# ===================================================================
# CONFIGURATION
# ===================================================================

# Firebase Admin SDK key file path
ADMIN_SDK_PATH = '/opt/flutter/firebase-admin-sdk.json'

# Verify the key file exists
if not os.path.exists(ADMIN_SDK_PATH):
    print(f"❌ Firebase Admin SDK key not found at: {ADMIN_SDK_PATH}")
    print("📋 Please ensure you have uploaded the firebase-admin-sdk.json file")
    print("   to /opt/flutter/ directory in your sandbox")
    sys.exit(1)

# ===================================================================
# INITIALIZE FIREBASE
# ===================================================================

try:
    # Check if already initialized
    firebase_admin.get_app()
    print("✅ Firebase already initialized")
except ValueError:
    # Initialize if not already done
    cred = credentials.Certificate(ADMIN_SDK_PATH)
    firebase_admin.initialize_app(cred)
    print("✅ Firebase initialized successfully")

db = firestore.client()

# ===================================================================
# MIGRATION FUNCTION
# ===================================================================

def migrate_orders_add_participants():
    """
    Add participants array to all orders in Firestore
    """
    print("\n" + "="*80)
    print("STARTING MIGRATION: Add Participants Array to Orders")
    print("="*80)
    
    # Use collection_group to find ALL orders (root + subcollections)
    orders_ref = db.collection_group('orders')
    orders = orders_ref.stream()
    
    updated_count = 0
    skipped_count = 0
    error_count = 0
    
    print("\n🔍 Scanning all orders...")
    
    for order in orders:
        try:
            data = order.to_dict()
            order_id = order.id
            
            # Check if participants field already exists
            if 'participants' in data and data['participants']:
                print(f"⏭️  Order {order_id}: Already has participants, skipping")
                skipped_count += 1
                continue
            
            participants = []
            
            # Extract buyer ID (support both snake_case and camelCase)
            if 'buyer_id' in data and data['buyer_id']:
                participants.append(data['buyer_id'])
            elif 'buyerId' in data and data['buyerId']:
                participants.append(data['buyerId'])
            
            # Extract seller ID
            if 'seller_id' in data and data['seller_id']:
                participants.append(data['seller_id'])
            elif 'sellerId' in data and data['sellerId']:
                participants.append(data['sellerId'])
            
            # Extract farmer ID
            if 'farmer_id' in data and data['farmer_id']:
                participants.append(data['farmer_id'])
            elif 'farmerId' in data and data['farmerId']:
                participants.append(data['farmerId'])
            
            # Remove duplicates (in case same user is buyer and seller)
            participants = list(set(participants))
            
            # Update document only if we found participants
            if participants:
                order.reference.update({'participants': participants})
                print(f"✅ Order {order_id}: Added participants {participants}")
                updated_count += 1
            else:
                print(f"⚠️  Order {order_id}: No valid user IDs found, skipping")
                skipped_count += 1
                
        except Exception as e:
            print(f"❌ Order {order_id}: Error - {e}")
            error_count += 1
    
    # ===================================================================
    # MIGRATION SUMMARY
    # ===================================================================
    
    print("\n" + "="*80)
    print("MIGRATION COMPLETE")
    print("="*80)
    print(f"✅ Updated: {updated_count} orders")
    print(f"⏭️  Skipped: {skipped_count} orders (already had participants)")
    print(f"❌ Errors: {error_count} orders")
    print(f"📊 Total Processed: {updated_count + skipped_count + error_count} orders")
    print("="*80)
    
    if updated_count > 0:
        print("\n🎉 Migration successful!")
        print("📋 Next steps:")
        print("   1. Verify the participants field in Firebase Console")
        print("   2. Test Orders page in your app")
        print("   3. Confirm no more 'permission-denied' errors")
    
    if error_count > 0:
        print("\n⚠️  Some orders had errors. Please review the error messages above.")
    
    return {
        'updated': updated_count,
        'skipped': skipped_count,
        'errors': error_count,
        'total': updated_count + skipped_count + error_count
    }

# ===================================================================
# MAIN EXECUTION
# ===================================================================

if __name__ == '__main__':
    print("🚀 Orders Migration Script")
    print("📋 This will add 'participants' array to all existing orders")
    print("⚠️  WARNING: This will modify your Firebase Firestore database")
    print()
    
    # Safety confirmation
    confirm = input("❓ Do you want to proceed with the migration? (yes/no): ")
    
    if confirm.lower() in ['yes', 'y']:
        result = migrate_orders_add_participants()
        
        print("\n✅ Script completed successfully")
        sys.exit(0)
    else:
        print("❌ Migration cancelled by user")
        sys.exit(0)
