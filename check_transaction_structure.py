#!/usr/bin/env python3
"""Check the actual structure of transaction documents"""

import firebase_admin
from firebase_admin import credentials, firestore
import json

cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("\n" + "="*60)
print("🔍 TRANSACTION DOCUMENT STRUCTURE ANALYSIS")
print("="*60 + "\n")

# Get one transaction
transactions = db.collection('transactions').limit(1).get()

if transactions:
    for trans in transactions:
        print(f"Transaction ID: {trans.id}\n")
        data = trans.to_dict()
        print("Full document structure:")
        print(json.dumps(data, indent=2, default=str))
        print("\n" + "="*60)
        print("🔍 FIELD ANALYSIS")
        print("="*60 + "\n")
        
        print("Fields present:")
        for key, value in data.items():
            print(f"  - {key}: {type(value).__name__} = {value}")
        
        print("\n" + "="*60)
        print("❓ MISSING FIELDS CHECK")
        print("="*60 + "\n")
        
        expected_fields = [
            'phone_number', 'phoneNumber', 'msisdn',
            'deposit_id', 'depositId',
            'created_at', 'createdAt', 'timestamp'
        ]
        
        for field in expected_fields:
            if field in data:
                print(f"✅ {field}: {data[field]}")
            else:
                print(f"❌ {field}: MISSING")
else:
    print("No transactions found")
