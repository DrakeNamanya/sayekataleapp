#!/usr/bin/env python3
"""List all transactions - fixed version"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import json

cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("\n" + "="*80)
print("📊 ALL TRANSACTIONS IN FIRESTORE (SORTED BY DATE)")
print("="*80 + "\n")

# Get all transactions
all_transactions = db.collection('transactions').get()

transactions_data = []
for trans in all_transactions:
    data = trans.to_dict()
    doc_id = trans.id
    
    # Get creation date
    created_at = data.get('createdAt') or data.get('created_at')
    
    # Convert to datetime if needed
    if created_at and isinstance(created_at, str):
        try:
            created_at = datetime.fromisoformat(created_at.replace('+00:00', ''))
        except:
            created_at = datetime.min
    elif not created_at:
        created_at = datetime.min
    
    transactions_data.append({
        'id': doc_id,
        'data': data,
        'created': created_at
    })

# Sort by date (newest first)
transactions_data.sort(key=lambda x: x['created'], reverse=True)

print(f"✅ Total Transactions Found: {len(transactions_data)}\n")
print("="*80 + "\n")

# Show ALL transactions
for i, trans in enumerate(transactions_data, 1):
    data = trans['data']
    metadata = data.get('metadata', {})
    
    # Determine if it's NEW or OLD
    is_new = trans['id'].startswith('dep_')
    label = "🆕 NEW" if is_new else "📜 OLD"
    
    print(f"{label} Transaction #{i}")
    print(f"{'─'*80}")
    print(f"Document ID: {trans['id']}")
    print(f"Created: {trans['created']}")
    print(f"Status: {data.get('status', 'N/A')}")
    print(f"Amount: UGX {data.get('amount', 0):,}")
    print(f"Type: {data.get('type', 'N/A')}")
    print(f"Payment Method: {data.get('paymentMethod', 'N/A')}")
    
    # Phone number
    phone = (data.get('phone_number') or 
            metadata.get('phone_number') or 
            'N/A')
    print(f"Phone: {phone}")
    
    # Show NEW transaction features
    if is_new:
        print(f"✨ MSISDN: {metadata.get('msisdn', 'N/A')}")
        print(f"✨ Correspondent: {metadata.get('correspondent', 'N/A')}")
        print(f"✨ Operator: {metadata.get('operator', 'N/A')}")
        print(f"✨ Deposit ID: {metadata.get('deposit_id', 'N/A')}")
    
    print()

# Summary
print("="*80)
print("📊 SUMMARY")
print("="*80 + "\n")

new_count = sum(1 for t in transactions_data if t['id'].startswith('dep_'))
old_count = len(transactions_data) - new_count

print(f"Total: {len(transactions_data)}")
print(f"🆕 NEW (from initiatePayment): {new_count}")
print(f"📜 OLD (from previous system): {old_count}")

print("\n" + "="*80)
print("💡 FINDING NEW TRANSACTIONS IN FIREBASE CONSOLE")
print("="*80 + "\n")
print("1. Open: https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions")
print("2. Look for document IDs starting with 'dep_' - these are NEW")
print("3. Click on any 'dep_...' document to see full details")
print("4. New transactions have 'correspondent' in metadata")
print()
print("Example NEW transaction ID: dep_1763760402341_sxqnhj")
print("Direct link: https://console.firebase.google.com/project/sayekataleapp/firestore/data/~2Ftransactions~2Fdep_1763760402341_sxqnhj")
print()
