#!/usr/bin/env python3
"""
Create sample user complaints for testing
"""

import sys
import os
from datetime import datetime, timedelta
import random

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("❌ Failed to import firebase-admin")
    sys.exit(1)

def initialize_firebase():
    try:
        firebase_admin.get_app()
    except ValueError:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        firebase_admin.initialize_app(cred)
    return firestore.client()

def main():
    print("="*60)
    print("📝 Creating Sample User Complaints")
    print("="*60)
    
    db = initialize_firebase()
    
    complaints = [
        {
            'user_id': 'user_001',
            'user_name': 'John Mugisha',
            'user_role': 'customer',
            'subject': 'Late delivery of eggs',
            'description': 'I ordered 2 trays of eggs last week but delivery is 3 days late. Please help.',
            'category': 'delivery',
            'status': 'pending',
            'priority': 'high',
            'created_at': (datetime.now() - timedelta(days=2)).isoformat(),
        },
        {
            'user_id': 'shg_002',
            'user_name': 'Mary Nakato SHG',
            'user_role': 'shg',
            'subject': 'Payment not received',
            'description': 'I delivered 50kg of tomatoes last week but payment has not been processed yet.',
            'category': 'payment',
            'status': 'pending',
            'priority': 'urgent',
            'created_at': (datetime.now() - timedelta(days=5)).isoformat(),
        },
        {
            'user_id': 'psa_001',
            'user_name': 'Kampala Agri Inputs',
            'user_role': 'psa',
            'subject': 'Account verification delay',
            'description': 'My account verification is taking too long. I submitted all documents 2 weeks ago.',
            'category': 'account',
            'status': 'inProgress',
            'priority': 'medium',
            'assigned_to': 'admin_001',
            'created_at': (datetime.now() - timedelta(days=14)).isoformat(),
        },
        {
            'user_id': 'user_003',
            'user_name': 'Sarah Nambi',
            'user_role': 'customer',
            'subject': 'Poor product quality',
            'description': 'The chickens I received were underweight. Expected 2kg but got 1.5kg each.',
            'category': 'product',
            'status': 'resolved',
            'priority': 'medium',
            'response': 'We apologize for the inconvenience. A refund has been processed and quality checks have been improved.',
            'responded_by': 'admin_001',
            'responded_at': (datetime.now() - timedelta(days=1)).isoformat(),
            'created_at': (datetime.now() - timedelta(days=7)).isoformat(),
        },
        {
            'user_id': 'shg_005',
            'user_name': 'Peter Okello SHG',
            'user_role': 'shg',
            'subject': 'Cannot upload product photos',
            'description': 'Getting error when trying to upload photos of my products. Please fix.',
            'category': 'technical',
            'status': 'pending',
            'priority': 'low',
            'created_at': (datetime.now() - timedelta(hours=6)).isoformat(),
        },
    ]
    
    complaints_ref = db.collection('user_complaints')
    
    for i, complaint in enumerate(complaints):
        complaint['updated_at'] = complaint['created_at']
        complaint['attachments'] = []
        
        doc_ref = complaints_ref.document(f'complaint_{i+1}')
        doc_ref.set(complaint)
        
        priority_icon = {'low': '🟢', 'medium': '🟡', 'high': '🟠', 'urgent': '🔴'}
        print(f"\n{priority_icon[complaint['priority']]} {complaint['subject']}")
        print(f"   User: {complaint['user_name']} ({complaint['user_role']})")
        print(f"   Status: {complaint['status']}")
    
    print("\n"+"="*60)
    print(f"✅ Created {len(complaints)} sample complaints")
    print("="*60)
    print("\n📋 Summary:")
    pending = sum(1 for c in complaints if c['status'] == 'pending')
    urgent = sum(1 for c in complaints if c['priority'] == 'urgent')
    print(f"  • Pending: {pending}")
    print(f"  • Urgent: {urgent}")
    print("\n💡 Ready for Customer Relations staff to handle!")

if __name__ == "__main__":
    main()
