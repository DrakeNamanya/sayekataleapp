#!/usr/bin/env python3
"""
Script to create sample PSA verification requests for testing
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
    print("🔧 Creating Sample PSA Verification Requests")
    print("="*60)
    
    db = initialize_firebase()
    verifications_ref = db.collection('psa_verifications')
    
    sample_psas = [
        {
            'business_name': 'Kampala Agricultural Inputs Ltd',
            'contact_person': 'John Ssemakula',
            'email': 'john@kampalaagri.com',
            'phone_number': '+256 700 123 456',
            'business_address': 'Plot 45, Industrial Area, Kampala',
            'business_type': 'Input Supplier',
            'status': 'pending',
            'has_all_docs': True,
        },
        {
            'business_name': 'Quality Seeds & Fertilizers',
            'contact_person': 'Mary Nakato',
            'email': 'mary@qualityseeds.ug',
            'phone_number': '+256 700 789 012',
            'business_address': 'Mukono Town, Main Street',
            'business_type': 'Input Supplier',
            'status': 'pending',
            'has_all_docs': True,
        },
        {
            'business_name': 'Farm Equipment Rentals',
            'contact_person': 'David Okello',
            'email': 'david@farmequipment.ug',
            'phone_number': '+256 700 345 678',
            'business_address': 'Mbale District, Eastern Uganda',
            'business_type': 'Equipment Rental',
            'status': 'pending',
            'has_all_docs': False,
        },
        {
            'business_name': 'AgriTech Solutions Uganda',
            'contact_person': 'Sarah Nambi',
            'email': 'sarah@agritech.ug',
            'phone_number': '+256 700 901 234',
            'business_address': 'Nakawa, Kampala',
            'business_type': 'Input Supplier',
            'status': 'underReview',
            'has_all_docs': True,
        },
        {
            'business_name': 'Masaka Farm Supplies',
            'contact_person': 'Peter Mutumba',
            'email': 'peter@masakafarm.com',
            'phone_number': '+256 700 567 890',
            'business_address': 'Masaka Town Center',
            'business_type': 'Input Supplier',
            'status': 'pending',
            'has_all_docs': True,
        },
    ]
    
    created_count = 0
    
    for i, psa_data in enumerate(sample_psas):
        # Create PSA user first
        psa_id = f'psa_user_{i+1}'
        user_ref = db.collection('users').document(psa_id)
        user_data = {
            'email': psa_data['email'],
            'name': psa_data['contact_person'],
            'role': 'psa',
            'is_verified': False,
            'verification_status': 'pending',
            'created_at': (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat(),
        }
        user_ref.set(user_data)
        
        # Create verification request
        verification_data = {
            'psa_id': psa_id,
            'business_name': psa_data['business_name'],
            'contact_person': psa_data['contact_person'],
            'email': psa_data['email'],
            'phone_number': psa_data['phone_number'],
            'business_address': psa_data['business_address'],
            'business_type': psa_data['business_type'],
            'status': psa_data['status'],
            'created_at': (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        
        # Add document URLs for PSAs with all docs
        if psa_data['has_all_docs']:
            verification_data.update({
                'business_license_url': 'https://placeholder.com/business_license.pdf',
                'tax_id_document_url': 'https://placeholder.com/tax_id.pdf',
                'national_id_url': 'https://placeholder.com/national_id.jpg',
                'trade_license_url': 'https://placeholder.com/trade_license.pdf',
                'additional_documents': [],
            })
        else:
            verification_data.update({
                'business_license_url': 'https://placeholder.com/business_license.pdf',
                'tax_id_document_url': None,
                'national_id_url': 'https://placeholder.com/national_id.jpg',
                'trade_license_url': None,
                'additional_documents': [],
            })
        
        verification_ref = verifications_ref.document(f'psa_verification_{i+1}')
        verification_ref.set(verification_data)
        
        created_count += 1
        status_icon = '✅' if psa_data['has_all_docs'] else '⚠️'
        print(f"\n{status_icon} {psa_data['business_name']}")
        print(f"   Contact: {psa_data['contact_person']}")
        print(f"   Status: {psa_data['status']}")
        print(f"   Documents: {'Complete' if psa_data['has_all_docs'] else 'Incomplete'}")
    
    print("\n"+"="*60)
    print(f"✅ Created {created_count} PSA verification requests")
    print("="*60)
    print("\n📋 Summary:")
    pending = sum(1 for p in sample_psas if p['status'] == 'pending')
    complete_docs = sum(1 for p in sample_psas if p['has_all_docs'])
    print(f"  • Pending verification: {pending}")
    print(f"  • Complete documentation: {complete_docs}/{len(sample_psas)}")
    print("\n💡 Ready for admin review in PSA Verification screen!")

if __name__ == "__main__":
    main()
