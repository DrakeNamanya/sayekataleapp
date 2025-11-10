#!/usr/bin/env python3
"""
List all users who have uploaded photos to Firebase Storage.
This helps identify which users should see photos in the UI.
"""

import firebase_admin
from firebase_admin import credentials, firestore, storage
import sys

def list_users_with_photos():
    """List all users who have uploaded photos."""
    try:
        # Initialize Firebase Admin SDK
        if not firebase_admin._apps:
            cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
            firebase_admin.initialize_app(cred, {
                'storageBucket': 'sayekataleapp.firebasestorage.app'
            })
        
        db = firestore.client()
        bucket = storage.bucket()
        
        print("=" * 80)
        print("USERS WITH PHOTOS IN FIRESTORE")
        print("=" * 80)
        
        # Get all users from Firestore
        users_ref = db.collection('users')
        users = users_ref.stream()
        
        users_with_photos = []
        users_without_photos = []
        
        for user_doc in users:
            user_data = user_doc.to_dict()
            user_id = user_doc.id
            name = user_data.get('name', 'Unknown')
            profile_image = user_data.get('profile_image')
            national_id_photo = user_data.get('national_id_photo')
            
            has_photos = bool(profile_image and profile_image.startswith('http')) or \
                        bool(national_id_photo and national_id_photo.startswith('http'))
            
            if has_photos:
                users_with_photos.append({
                    'id': user_id,
                    'name': name,
                    'profile_image': profile_image,
                    'national_id_photo': national_id_photo
                })
            else:
                users_without_photos.append({
                    'id': user_id,
                    'name': name,
                    'profile_image': profile_image,
                    'national_id_photo': national_id_photo
                })
        
        # Display users WITH photos
        print(f"\n✅ USERS WITH PHOTOS ({len(users_with_photos)}):")
        print("-" * 80)
        for user in users_with_photos:
            print(f"\nUser ID: {user['id']}")
            print(f"Name: {user['name']}")
            print(f"Profile Image: {user['profile_image'][:80] if user['profile_image'] else 'NULL'}{'...' if user['profile_image'] and len(user['profile_image']) > 80 else ''}")
            print(f"National ID: {user['national_id_photo'][:80] if user['national_id_photo'] else 'NULL'}{'...' if user['national_id_photo'] and len(user['national_id_photo']) > 80 else ''}")
        
        # Display users WITHOUT photos
        print(f"\n\n❌ USERS WITHOUT PHOTOS ({len(users_without_photos)}):")
        print("-" * 80)
        for user in users_without_photos:
            print(f"\nUser ID: {user['id']}")
            print(f"Name: {user['name']}")
            print(f"Profile Image: {user['profile_image'] if user['profile_image'] else 'NULL'}")
            print(f"National ID: {user['national_id_photo'] if user['national_id_photo'] else 'NULL'}")
        
        print("\n" + "=" * 80)
        print(f"SUMMARY: {len(users_with_photos)} with photos, {len(users_without_photos)} without photos")
        print("=" * 80)
        
        # List files in Firebase Storage
        print("\n\nFIRES IN FIREBASE STORAGE:")
        print("-" * 80)
        blobs = bucket.list_blobs()
        file_count = 0
        for blob in blobs:
            file_count += 1
            print(f"{file_count}. {blob.name}")
        
        print(f"\nTotal files in storage: {file_count}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    list_users_with_photos()
