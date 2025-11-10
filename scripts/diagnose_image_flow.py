#!/usr/bin/env python3
"""
Diagnose the complete image upload and display flow
"""

import firebase_admin
from firebase_admin import credentials, firestore, storage
import sys

def main():
    try:
        # Initialize Firebase Admin
        cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'sayekataleapp.firebasestorage.app'
        })
        db = firestore.client()
        bucket = storage.bucket()
        
        print("=" * 80)
        print("🔍 COMPLETE IMAGE FLOW DIAGNOSIS")
        print("=" * 80)
        
        # Step 1: Check if images exist in Storage
        print("\n📦 STEP 1: Checking Cloud Storage...")
        print("-" * 80)
        
        folders = ['profiles', 'national_ids', 'products']
        storage_files = {}
        
        for folder in folders:
            blobs = list(bucket.list_blobs(prefix=f'{folder}/'))
            storage_files[folder] = blobs
            print(f"\n{folder.upper()} folder: {len(blobs)} files")
            if blobs:
                for i, blob in enumerate(blobs[:3]):  # Show first 3
                    print(f"   {i+1}. {blob.name}")
                    print(f"      URL: https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/{blob.name.replace('/', '%2F')}?alt=media")
                if len(blobs) > 3:
                    print(f"   ... and {len(blobs) - 3} more files")
        
        # Step 2: Check Firestore for URLs
        print("\n\n📊 STEP 2: Checking Firestore URLs...")
        print("-" * 80)
        
        users = db.collection('users').limit(3).stream()
        
        print("\n👤 USER PROFILES:")
        for user in users:
            data = user.to_dict()
            profile_img = data.get('profile_image')
            natid_img = data.get('national_id_photo')
            
            print(f"\nUser: {data.get('name', 'N/A')} ({user.id})")
            print(f"   profile_image field: {profile_img if profile_img else 'EMPTY/NULL'}")
            print(f"   national_id_photo field: {natid_img if natid_img else 'EMPTY/NULL'}")
            
            # Check if URL format is correct
            if profile_img:
                if profile_img.startswith('https://firebasestorage.googleapis.com'):
                    print(f"   ✅ profile_image URL format is CORRECT")
                elif profile_img.startswith('blob:'):
                    print(f"   ❌ profile_image is BLOB URL (should be https://)")
                elif profile_img.startswith('gs://'):
                    print(f"   ⚠️  profile_image is gs:// format (needs conversion to https://)")
                else:
                    print(f"   ❌ profile_image format is UNKNOWN")
            
            if natid_img:
                if natid_img.startswith('https://firebasestorage.googleapis.com'):
                    print(f"   ✅ national_id_photo URL format is CORRECT")
                elif natid_img.startswith('blob:'):
                    print(f"   ❌ national_id_photo is BLOB URL (should be https://)")
                elif natid_img.startswith('gs://'):
                    print(f"   ⚠️  national_id_photo is gs:// format (needs conversion to https://)")
                else:
                    print(f"   ❌ national_id_photo format is UNKNOWN")
        
        print("\n\n📦 PRODUCT IMAGES:")
        products = db.collection('products').limit(3).stream()
        
        for product in products:
            data = product.to_dict()
            image_url = data.get('image_url')
            images = data.get('images', [])
            
            print(f"\nProduct: {data.get('name', 'N/A')} ({product.id})")
            print(f"   image_url field: {image_url if image_url else 'EMPTY/NULL'}")
            print(f"   images field: {images if images else 'EMPTY/NULL'}")
            
            # Check URL formats
            if image_url and image_url.startswith('https://firebasestorage.googleapis.com'):
                print(f"   ✅ image_url format is CORRECT")
            elif image_url and image_url.startswith('https://via.placeholder.com'):
                print(f"   ⚠️  image_url is PLACEHOLDER (no real image uploaded)")
            elif image_url and image_url.startswith('gs://'):
                print(f"   ⚠️  image_url is gs:// format (needs conversion)")
            
            if images:
                for i, img in enumerate(images):
                    if img.startswith('https://firebasestorage.googleapis.com'):
                        print(f"   ✅ images[{i}] format is CORRECT")
                    else:
                        print(f"   ❌ images[{i}] format is WRONG: {img[:60]}...")
        
        # Step 3: Storage Rules Check
        print("\n\n🔐 STEP 3: Storage Access Check...")
        print("-" * 80)
        print("\n⚠️  Cannot check Storage Rules from script")
        print("You must manually verify in Firebase Console:")
        print("👉 https://console.firebase.google.com/project/sayekataleapp/storage/rules")
        print("\nRules should allow:")
        print("   - allow read: if true; (for public images like profiles/products)")
        print("   - allow write: if request.auth != null; (for authenticated uploads)")
        
        # Summary
        print("\n\n" + "=" * 80)
        print("📋 SUMMARY")
        print("=" * 80)
        
        total_storage_files = sum(len(files) for files in storage_files.values())
        print(f"\n✅ Total files in Cloud Storage: {total_storage_files}")
        
        if total_storage_files == 0:
            print("   ❌ NO FILES IN STORAGE! Images are not being uploaded.")
            print("   Action: Check upload code and console logs")
        else:
            print("   ✅ Files exist in storage")
        
        print("\n💡 NEXT STEPS:")
        print("   1. If files exist in Storage but URLs are NULL in Firestore:")
        print("      → Upload code isn't saving download URLs")
        print("   2. If URLs are blob:// or gs:// format:")
        print("      → Need to convert to https:// format")
        print("   3. If URLs are correct but images don't display:")
        print("      → Check Storage Rules (must allow read)")
        print("   4. If everything looks correct:")
        print("      → Check UI code (NetworkImage implementation)")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
