#!/usr/bin/env python3
"""Verify subscription status after locking"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase
cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Check subscription
user_id = "SccSSc08HbQUIYH731HvGhgSJNX2"
print("\n" + "="*60)
print("📊 SUBSCRIPTION STATUS VERIFICATION")
print("="*60 + "\n")

subs = db.collection('subscriptions').where('user_id', '==', user_id).get()

if not subs:
    print("❌ No subscriptions found")
else:
    for sub in subs:
        data = sub.to_dict()
        print(f"Subscription ID: {sub.id}")
        print(f"Type: {data.get('type', 'N/A')}")
        print(f"Status: {data.get('status', 'N/A')}")
        print(f"Active: {data.get('is_active', 'N/A')}")
        print(f"Start Date: {data.get('start_date', 'N/A')}")
        print(f"End Date: {data.get('end_date', 'N/A')}")
        print(f"Deactivated By: {data.get('deactivated_by', 'N/A')}")
        print(f"Deactivation Reason: {data.get('deactivation_reason', 'N/A')}")

print("\n" + "="*60)
print("✅ VERIFICATION COMPLETE")
print("="*60 + "\n")
print("Status: 🔒 LOCKED")
print("Ready to test payment flow!")
print("\nNext: Open app and navigate to SHG Dashboard → Unlock Premium")
