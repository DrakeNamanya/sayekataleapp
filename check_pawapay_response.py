#!/usr/bin/env python3
"""
Check what PawaPay actually returned for this transaction
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json

cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

deposit_id = "dep_1763761474192_nlaf2i"

print("\n" + "="*80)
print(f"🔍 INVESTIGATING TRANSACTION: {deposit_id}")
print("="*80 + "\n")

# Get the transaction
doc = db.collection('transactions').document(deposit_id).get()

if doc.exists:
    data = doc.to_dict()
    
    print("📄 TRANSACTION DETAILS")
    print("─"*80)
    print(json.dumps(data, indent=2, default=str))
    
    print("\n" + "="*80)
    print("🔍 KEY INFORMATION")
    print("="*80 + "\n")
    
    print(f"Status: {data.get('status')}")
    print(f"Phone: {data.get('metadata', {}).get('phone_number')}")
    print(f"MSISDN: {data.get('metadata', {}).get('msisdn')}")
    print(f"Correspondent: {data.get('metadata', {}).get('correspondent')}")
    print(f"Created: {data.get('createdAt')}")
    
    # Check for error information
    error = data.get('error')
    pawapay_response = data.get('pawapay_response')
    
    print("\n" + "="*80)
    print("❓ WHY NO PIN PROMPT?")
    print("="*80 + "\n")
    
    if error:
        print(f"❌ ERROR FOUND: {error}")
    elif pawapay_response:
        print(f"📨 PawaPay Response: {pawapay_response}")
    else:
        print("⚠️  No error or PawaPay response stored in transaction")
        print("\nPossible reasons:")
        print("1. PawaPay is in SANDBOX mode")
        print("2. Phone number not registered for mobile money")
        print("3. Network/connectivity issues")
        print("4. PawaPay API configuration issue")
        print("5. Daily transaction limits reached")
    
    print("\n" + "="*80)
    print("🔧 NEXT STEPS TO DEBUG")
    print("="*80 + "\n")
    
    print("1. Check Firebase Functions logs for this transaction:")
    print("   https://console.firebase.google.com/project/sayekataleapp/functions/logs")
    print(f"   Search for: {deposit_id}")
    print()
    print("2. Check PawaPay Dashboard:")
    print("   https://dashboard.pawapay.io/")
    print(f"   Search for deposit ID: {deposit_id}")
    print()
    print("3. Verify PawaPay configuration:")
    print("   - Is API in Production mode?")
    print("   - Is API token valid?")
    print("   - Is phone number format correct?")
    print()
    print("4. Test with PawaPay API directly:")
    print("   curl https://api.pawapay.io/deposits/{deposit_id}")
    
else:
    print(f"❌ Transaction {deposit_id} not found")

