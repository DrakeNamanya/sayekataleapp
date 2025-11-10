#!/usr/bin/env python3
"""
Clean up blob URLs from Firestore
Replace blob URLs with None so users can re-upload proper images
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys

def main():
    try:
        # Initialize Firebase Admin
        cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        
        print("=" * 80)
        print("🧹 CLEANING BLOB URLs FROM FIRESTORE")
        print("=" * 80)
        
        # Clean users collection
        print("\n📊 Checking USERS collection...")
        users = db.collection('users').stream()
        
        cleaned_count = 0
        for user in users:
            data = user.to_dict()
            updates = {}
            
            # Check profile_image
            profile_img = data.get('profile_image', '')
            if profile_img and profile_img.startswith('blob:'):
                updates['profile_image'] = None
                print(f"   Cleaning profile_image for user {user.id}")
            
            # Check national_id_photo
            natid_img = data.get('national_id_photo', '')
            if natid_img and natid_img.startswith('blob:'):
                updates['national_id_photo'] = None
                # Also mark profile as incomplete if national ID photo was required
                if data.get('is_profile_complete'):
                    updates['is_profile_complete'] = False
                print(f"   Cleaning national_id_photo for user {user.id}")
            
            # Apply updates if any
            if updates:
                db.collection('users').document(user.id).update(updates)
                cleaned_count += 1
                print(f"   ✅ Cleaned {len(updates)} field(s) for user {user.id}")
        
        print(f"\n✅ Cleaned {cleaned_count} users")
        
        # Clean products collection
        print("\n📦 Checking PRODUCTS collection...")
        products = db.collection('products').stream()
        
        product_cleaned = 0
        for product in products:
            data = product.to_dict()
            updates = {}
            
            # Check image_url
            image_url = data.get('image_url', '')
            if image_url and image_url.startswith('blob:'):
                updates['image_url'] = None
                print(f"   Cleaning image_url for product {product.id}")
            
            # Check images array
            images_list = data.get('images', [])
            cleaned_images = []
            has_blob = False
            for img in images_list:
                if img.startswith('blob:'):
                    has_blob = True
                else:
                    cleaned_images.append(img)
            
            if has_blob:
                updates['images'] = cleaned_images
                print(f"   Cleaning images array for product {product.id}")
            
            # Apply updates if any
            if updates:
                db.collection('products').document(product.id).update(updates)
                product_cleaned += 1
                print(f"   ✅ Cleaned {len(updates)} field(s) for product {product.id}")
        
        print(f"\n✅ Cleaned {product_cleaned} products")
        
        print("\n" + "=" * 80)
        print("✅ CLEANUP COMPLETE")
        print("=" * 80)
        print("\n💡 Users can now re-upload photos and they will be saved properly!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
