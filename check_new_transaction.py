#!/usr/bin/env python3
"""Check for the transaction just created"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
from datetime import datetime, timedelta

cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("\n" + "="*60)
print("🔍 SEARCHING FOR NEW TRANSACTION")
print("="*60 + "\n")

# Search for the deposit ID we just created
deposit_id = "dep_1763760402341_sxqnhj"
print(f"Looking for deposit_id: {deposit_id}\n")

# Method 1: Search by document ID
print("Method 1: Searching by document ID...")
doc = db.collection('transactions').document(deposit_id).get()
if doc.exists:
    print(f"✅ FOUND by document ID!")
    print(f"\nDocument structure:")
    print(json.dumps(doc.to_dict(), indent=2, default=str))
else:
    print(f"❌ NOT FOUND by document ID")

# Method 2: Search in metadata
print("\nMethod 2: Searching all recent transactions...")
recent_time = datetime.utcnow() - timedelta(minutes=5)
all_transactions = db.collection('transactions').get()

found = False
for trans in all_transactions:
    data = trans.to_dict()
    
    # Check if deposit_id is in the document
    if data.get('deposit_id') == deposit_id:
        found = True
        print(f"✅ FOUND in field 'deposit_id'!")
        print(f"\nTransaction ID: {trans.id}")
        print(f"Document structure:")
        print(json.dumps(data, indent=2, default=str))
        break
    
    # Check in metadata
    metadata = data.get('metadata', {})
    if metadata.get('deposit_id') == deposit_id:
        found = True
        print(f"✅ FOUND in metadata.deposit_id!")
        print(f"\nTransaction ID: {trans.id}")
        print(f"Document structure:")
        print(json.dumps(data, indent=2, default=str))
        break

if not found:
    print("❌ NOT FOUND in any transaction document")
    
    print("\n" + "="*60)
    print("🔍 LISTING ALL RECENT TRANSACTIONS")
    print("="*60 + "\n")
    
    # List all transactions created in last 5 minutes
    count = 0
    for trans in all_transactions:
        data = trans.to_dict()
        created_at = data.get('createdAt') or data.get('created_at')
        
        if created_at:
            if isinstance(created_at, str):
                try:
                    created_at = datetime.fromisoformat(created_at.replace('+00:00', ''))
                except:
                    continue
            
            if created_at > recent_time:
                count += 1
                print(f"{count}. ID: {trans.id}")
                print(f"   Created: {created_at}")
                print(f"   Status: {data.get('status', 'N/A')}")
                print(f"   Amount: {data.get('amount', 'N/A')}")
                print(f"   Phone: {data.get('phone_number', metadata.get('phone_number', 'N/A'))}")
                print()
    
    if count == 0:
        print("❌ NO transactions created in the last 5 minutes")

print("\n" + "="*60)
print("📋 DIAGNOSIS")
print("="*60 + "\n")

if found:
    print("✅ Transaction WAS created by initiatePayment function")
    print("✅ Firestore rules are working correctly")
    print("\n💡 The issue is likely in the Flutter app:")
    print("   - App may not be calling the correct endpoint")
    print("   - App may have local caching issues")
    print("   - App build may be outdated")
else:
    print("❌ Transaction was NOT created despite API returning success")
    print("\n🔍 Possible causes:")
    print("   1. Function creates transaction with different ID format")
    print("   2. Function fails after returning success")
    print("   3. Firestore rules block writes (but Admin SDK test passed)")
    print("\n🔧 Next step: Check Firebase Functions logs")
    print("   https://console.firebase.google.com/project/sayekataleapp/functions/logs")
