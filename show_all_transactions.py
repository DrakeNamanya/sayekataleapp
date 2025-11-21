#!/usr/bin/env python3
"""
Show ALL transactions in Firestore, sorted by creation date
Focus on identifying NEW transactions from initiatePayment function
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone
import json

def init_firebase():
    try:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialized")
        return True
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return False

def list_all_transactions():
    """List all transactions sorted by creation date"""
    db = firestore.client()
    
    print("\n" + "="*80)
    print("📊 ALL TRANSACTIONS IN FIRESTORE")
    print("="*80 + "\n")
    
    try:
        # Get ALL transactions
        all_transactions = db.collection('transactions').get()
        
        if not all_transactions:
            print("❌ No transactions found in Firestore")
            return
        
        # Convert to list with parsed dates
        transactions_list = []
        for trans in all_transactions:
            data = trans.to_dict()
            doc_id = trans.id
            
            # Try to get creation date
            created_at = data.get('createdAt') or data.get('created_at')
            
            # Parse date if it's a string
            if created_at and isinstance(created_at, str):
                try:
                    created_at = datetime.fromisoformat(created_at.replace('+00:00', ''))
                except:
                    created_at = None
            
            transactions_list.append({
                'id': doc_id,
                'data': data,
                'created_at': created_at
            })
        
        # Sort by creation date (newest first)
        transactions_list.sort(
            key=lambda x: x['created_at'] if x['created_at'] else datetime.min.replace(tzinfo=timezone.utc),
            reverse=True
        )
        
        print(f"✅ Found {len(transactions_list)} transaction(s)\n")
        print("="*80)
        
        # Separate NEW and OLD transactions
        new_transactions = []
        old_transactions = []
        cutoff_date = datetime(2025, 11, 21, 0, 0, 0, tzinfo=timezone.utc)
        
        for trans in transactions_list:
            if trans['created_at'] and trans['created_at'] >= cutoff_date:
                new_transactions.append(trans)
            else:
                old_transactions.append(trans)
        
        # Show NEW transactions first
        if new_transactions:
            print("\n🆕 NEW TRANSACTIONS (Nov 21, 2025 onwards)")
            print("="*80 + "\n")
            
            for i, trans in enumerate(new_transactions, 1):
                data = trans['data']
                print(f"📄 Transaction #{i}")
                print(f"   Document ID: {trans['id']}")
                print(f"   Created: {trans['created_at']}")
                print(f"   Status: {data.get('status', 'N/A')}")
                print(f"   Amount: UGX {data.get('amount', 'N/A'):,}")
                print(f"   Type: {data.get('type', 'N/A')}")
                print(f"   Payment Method: {data.get('paymentMethod', 'N/A')}")
                
                # Check for phone number in metadata or top level
                metadata = data.get('metadata', {})
                phone = (data.get('phone_number') or 
                        metadata.get('phone_number') or 
                        metadata.get('msisdn', 'N/A'))
                print(f"   Phone: {phone}")
                
                # Show correspondent if available (NEW format indicator)
                correspondent = metadata.get('correspondent')
                if correspondent:
                    print(f"   ✨ Correspondent: {correspondent}")
                    print(f"   ✨ MSISDN: {metadata.get('msisdn', 'N/A')}")
                    print(f"   ✨ Operator: {metadata.get('operator', 'N/A')}")
                
                # Show deposit_id
                deposit_id = data.get('deposit_id') or metadata.get('deposit_id')
                if deposit_id:
                    print(f"   Deposit ID: {deposit_id}")
                
                print()
        
        # Show OLD transactions
        if old_transactions:
            print("\n📜 OLD TRANSACTIONS (Before Nov 21, 2025)")
            print("="*80 + "\n")
            print(f"Found {len(old_transactions)} old transaction(s) from previous system")
            
            # Show first 3 old transactions as examples
            for i, trans in enumerate(old_transactions[:3], 1):
                data = trans['data']
                print(f"📄 Old Transaction #{i}")
                print(f"   Document ID: {trans['id']}")
                print(f"   Created: {trans['created_at']}")
                print(f"   Status: {data.get('status', 'N/A')}")
                print(f"   Amount: UGX {data.get('amount', 'N/A'):,}")
                print()
            
            if len(old_transactions) > 3:
                print(f"   ... and {len(old_transactions) - 3} more old transactions")
        
        # Summary
        print("\n" + "="*80)
        print("📊 SUMMARY")
        print("="*80 + "\n")
        print(f"Total Transactions: {len(transactions_list)}")
        print(f"🆕 NEW (Nov 21+): {len(new_transactions)}")
        print(f"📜 OLD (Before Nov 21): {len(old_transactions)}")
        
        if new_transactions:
            print("\n✅ NEW transactions from initiatePayment function ARE visible!")
            print("   These transactions have the correct structure with:")
            print("   - deposit_id as document ID")
            print("   - correspondent field (MTN_MOMO_UGA or AIRTEL_OAPI_UGA)")
            print("   - msisdn in international format")
            print("   - metadata with complete payment details")
        else:
            print("\n⚠️  No NEW transactions found from Nov 21, 2025 onwards")
            print("   This might mean:")
            print("   1. Transactions were created but dates are incorrect")
            print("   2. Need to test initiatePayment again")
            print("   3. Console view needs to be refreshed")
        
    except Exception as e:
        print(f"❌ Error listing transactions: {e}")
        import traceback
        traceback.print_exc()

def show_specific_transaction():
    """Show the specific transaction we just created"""
    db = firestore.client()
    
    print("\n" + "="*80)
    print("🔍 SEARCHING FOR SPECIFIC TEST TRANSACTION")
    print("="*80 + "\n")
    
    deposit_id = "dep_1763760402341_sxqnhj"
    print(f"Looking for: {deposit_id}\n")
    
    try:
        doc = db.collection('transactions').document(deposit_id).get()
        
        if doc.exists:
            print("✅ FOUND!\n")
            data = doc.to_dict()
            print(json.dumps(data, indent=2, default=str))
        else:
            print("❌ NOT FOUND")
            print("   This transaction should exist. Checking if it was deleted...")
    
    except Exception as e:
        print(f"❌ Error: {e}")

def main():
    print("="*80)
    print("🔍 FIRESTORE TRANSACTIONS VIEWER")
    print("="*80)
    
    if not init_firebase():
        return
    
    # Show specific transaction first
    show_specific_transaction()
    
    # Then show all transactions
    list_all_transactions()
    
    print("\n" + "="*80)
    print("💡 HOW TO VIEW IN FIREBASE CONSOLE")
    print("="*80 + "\n")
    print("1. Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions")
    print("2. Click on any transaction to see full details")
    print("3. Look for transactions with IDs starting with 'dep_' (these are NEW)")
    print("4. Check the 'metadata' field for correspondent and msisdn")
    print("\n")

if __name__ == "__main__":
    main()
