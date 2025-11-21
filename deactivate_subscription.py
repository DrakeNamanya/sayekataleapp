#!/usr/bin/env python3
"""
Deactivate Premium SME Directory subscription for drnamanya@gmail.com
This script will set the subscription status to 'expired' or delete it entirely.
"""

import firebase_admin
from firebase_admin import credentials, firestore, auth
from datetime import datetime
import sys

def init_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialized successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return False

def get_user_id(email):
    """Get user ID from email"""
    try:
        user = auth.get_user_by_email(email)
        print(f"✅ Found user: {user.uid}")
        return user.uid
    except Exception as e:
        print(f"❌ Failed to get user: {e}")
        return None

def deactivate_subscription(user_id):
    """Deactivate all subscriptions for the user"""
    db = firestore.client()
    
    try:
        # Query all subscriptions for this user
        subscriptions_ref = db.collection('subscriptions')
        query = subscriptions_ref.where('user_id', '==', user_id)
        subscriptions = query.get()
        
        if not subscriptions:
            print(f"ℹ️  No subscriptions found for user {user_id}")
            return True
        
        print(f"📋 Found {len(subscriptions)} subscription(s)")
        
        # Deactivate each subscription
        for sub_doc in subscriptions:
            sub_id = sub_doc.id
            sub_data = sub_doc.to_dict()
            
            print(f"\n🔍 Subscription ID: {sub_id}")
            print(f"   Type: {sub_data.get('type', 'N/A')}")
            print(f"   Status: {sub_data.get('status', 'N/A')}")
            print(f"   Started: {sub_data.get('start_date', 'N/A')}")
            print(f"   Ends: {sub_data.get('end_date', 'N/A')}")
            
            # Update to expired status
            subscriptions_ref.document(sub_id).update({
                'status': 'expired',
                'is_active': False,
                'updated_at': firestore.SERVER_TIMESTAMP,
                'deactivated_by': 'admin',
                'deactivation_reason': 'Manual deactivation for testing',
                'deactivated_at': firestore.SERVER_TIMESTAMP
            })
            
            print(f"✅ Subscription {sub_id} deactivated")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to deactivate subscriptions: {e}")
        return False

def main():
    print("=" * 60)
    print("🔒 PREMIUM SUBSCRIPTION DEACTIVATION")
    print("=" * 60)
    print()
    
    # Initialize Firebase
    if not init_firebase():
        sys.exit(1)
    
    # Target email
    target_email = "drnamanya@gmail.com"
    print(f"🎯 Target: {target_email}\n")
    
    # Get user ID
    user_id = get_user_id(target_email)
    if not user_id:
        sys.exit(1)
    
    # Deactivate subscriptions
    if deactivate_subscription(user_id):
        print()
        print("=" * 60)
        print("✅ SUBSCRIPTION SUCCESSFULLY LOCKED")
        print("=" * 60)
        print()
        print(f"User {target_email} can now test the payment flow:")
        print("1. Open Sayekatale app")
        print("2. Navigate to SHG Dashboard")
        print("3. Click 'Unlock Premium' button")
        print("4. Enter phone number (e.g., 0744646069)")
        print("5. Complete payment with PIN")
        print("6. Verify subscription activation")
        print()
        print("📊 Monitor at:")
        print("- Firestore: https://console.firebase.google.com/project/sayekataleapp/firestore")
        print("- Logs: https://console.firebase.google.com/project/sayekataleapp/functions/logs")
        print()
    else:
        print("\n❌ DEACTIVATION FAILED")
        sys.exit(1)

if __name__ == "__main__":
    main()
