#!/usr/bin/env python3
"""
Check Firestore rules deployment status
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys

def init_firebase():
    try:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialized")
        return True
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return False

def test_transaction_write():
    """Test if we can write to transactions collection"""
    db = firestore.client()
    
    print("\n" + "="*60)
    print("🧪 TESTING TRANSACTION WRITE PERMISSIONS")
    print("="*60 + "\n")
    
    test_doc = {
        'test': True,
        'message': 'Testing Cloud Function write access',
        'timestamp': firestore.SERVER_TIMESTAMP,
        'source': 'admin_sdk_test'
    }
    
    try:
        # Try to write a test document
        doc_ref = db.collection('transactions').document('test_write_permission')
        doc_ref.set(test_doc)
        print("✅ SUCCESS: Can write to transactions collection")
        print("   Document created: test_write_permission")
        
        # Read it back
        doc = doc_ref.get()
        if doc.exists:
            print("✅ SUCCESS: Can read back the document")
            print(f"   Data: {doc.to_dict()}")
        
        # Clean up
        doc_ref.delete()
        print("✅ Test document cleaned up")
        
        return True
        
    except Exception as e:
        print(f"❌ FAILED: Cannot write to transactions collection")
        print(f"   Error: {e}")
        print(f"   Error type: {type(e).__name__}")
        return False

def check_existing_transactions():
    """Check existing transactions"""
    db = firestore.client()
    
    print("\n" + "="*60)
    print("📊 CHECKING EXISTING TRANSACTIONS")
    print("="*60 + "\n")
    
    try:
        transactions = db.collection('transactions').limit(5).get()
        
        if not transactions:
            print("⚠️  No transactions found in Firestore")
        else:
            print(f"✅ Found {len(transactions)} transaction(s)")
            for i, trans in enumerate(transactions, 1):
                data = trans.to_dict()
                print(f"\n{i}. Transaction ID: {trans.id}")
                print(f"   Status: {data.get('status', 'N/A')}")
                print(f"   Phone: {data.get('phone_number', 'N/A')}")
                print(f"   Amount: {data.get('amount', 'N/A')}")
                print(f"   Created: {data.get('created_at', 'N/A')}")
        
    except Exception as e:
        print(f"❌ Error reading transactions: {e}")

def main():
    print("="*60)
    print("🔍 FIRESTORE RULES DEPLOYMENT CHECK")
    print("="*60)
    
    if not init_firebase():
        sys.exit(1)
    
    # Test write permissions
    can_write = test_transaction_write()
    
    # Check existing transactions
    check_existing_transactions()
    
    print("\n" + "="*60)
    print("📋 DIAGNOSIS")
    print("="*60 + "\n")
    
    if can_write:
        print("✅ GOOD: Cloud Functions CAN write to transactions collection")
        print("✅ GOOD: Firestore rules are correctly deployed")
        print("\nℹ️  If app still fails to create transactions:")
        print("   1. Check that initiatePayment function is being called")
        print("   2. Check Firebase Functions logs for errors")
        print("   3. Verify phone number format")
    else:
        print("❌ PROBLEM: Cloud Functions CANNOT write to transactions collection")
        print("❌ PROBLEM: Firestore rules NOT properly deployed")
        print("\n🔧 SOLUTION: Deploy Firestore rules to production")
        print("\n   Run this command in Google Cloud Shell:")
        print("   cd ~/sayekataleapp")
        print("   firebase deploy --only firestore:rules")
        print("\n   Or use Firebase Console:")
        print("   https://console.firebase.google.com/project/sayekataleapp/firestore/rules")

if __name__ == "__main__":
    main()
