#!/usr/bin/env python3
"""
Check actual Firestore data to diagnose profile and product issues
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
        print("🔍 FIRESTORE DATA INSPECTION")
        print("=" * 80)
        
        # Check users collection
        print("\n📊 USERS COLLECTION:")
        print("-" * 80)
        users = db.collection('users').limit(5).stream()
        
        user_count = 0
        for user in users:
            user_count += 1
            data = user.to_dict()
            print(f"\n👤 User ID: {user.id}")
            print(f"   Name: {data.get('name', 'N/A')}")
            print(f"   Role: {data.get('role', 'N/A')}")
            print(f"   Email: {data.get('email', 'N/A')}")
            print(f"   Profile Complete: {data.get('is_profile_complete', 'N/A')}")
            print(f"   Profile Image: {data.get('profile_image', 'NOT SET')}")
            print(f"   National ID: {data.get('national_id', 'NOT SET')}")
            print(f"   National ID Photo: {data.get('national_id_photo', 'NOT SET')}")
            print(f"   Name on ID: {data.get('name_on_id_photo', 'NOT SET')}")
            print(f"   Sex: {data.get('sex', 'NOT SET')}")
            print(f"   Location: {data.get('location', 'NOT SET')}")
            
            # Check if profile SHOULD be complete
            has_all_fields = all([
                data.get('national_id'),
                data.get('national_id_photo'),
                data.get('name_on_id_photo'),
                data.get('sex'),
                data.get('location')
            ])
            
            if has_all_fields and not data.get('is_profile_complete'):
                print("   ⚠️ WARNING: Has all required fields but marked incomplete!")
            elif not has_all_fields and data.get('is_profile_complete'):
                print("   ⚠️ WARNING: Missing fields but marked complete!")
            
            # Check image URL format
            profile_img = data.get('profile_image', '')
            if profile_img and not profile_img.startswith('http'):
                print(f"   ❌ PROBLEM: profile_image is not a URL: {profile_img[:100]}")
            
            natid_img = data.get('national_id_photo', '')
            if natid_img and not natid_img.startswith('http'):
                print(f"   ❌ PROBLEM: national_id_photo is not a URL: {natid_img[:100]}")
        
        if user_count == 0:
            print("   ⚠️ No users found in database")
        
        # Check products collection
        print("\n\n📦 PRODUCTS COLLECTION:")
        print("-" * 80)
        products = db.collection('products').limit(5).stream()
        
        product_count = 0
        for product in products:
            product_count += 1
            data = product.to_dict()
            print(f"\n📦 Product ID: {product.id}")
            print(f"   Name: {data.get('name', 'N/A')}")
            print(f"   Farmer ID: {data.get('farmer_id', 'N/A')}")
            print(f"   Farmer Name: {data.get('farmer_name', 'N/A')}")
            print(f"   Price: {data.get('price', 'N/A')}")
            
            # Check image fields
            image_url = data.get('image_url', 'NOT SET')
            images_list = data.get('images', [])
            
            print(f"   image_url field: {image_url}")
            print(f"   images field: {images_list if images_list else 'NOT SET OR EMPTY'}")
            
            # Check if images are valid URLs
            if image_url and image_url != 'NOT SET' and not image_url.startswith('http'):
                print(f"   ❌ PROBLEM: image_url is not a URL: {image_url[:100]}")
            
            if images_list:
                for idx, img_url in enumerate(images_list):
                    if not img_url.startswith('http'):
                        print(f"   ❌ PROBLEM: images[{idx}] is not a URL: {img_url[:100]}")
            elif data.get('name'):  # Product exists but no images
                print("   ⚠️ WARNING: Product has no images")
        
        if product_count == 0:
            print("   ⚠️ No products found in database")
        
        print("\n" + "=" * 80)
        print("✅ INSPECTION COMPLETE")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
