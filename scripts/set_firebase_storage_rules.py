#!/usr/bin/env python3
"""
Firebase Storage Security Rules Setup Script
===========================================

This script helps you set up Firebase Storage security rules for the Fresh Water Fish app.

BEFORE RUNNING:
1. Ensure Firebase Storage is enabled in Firebase Console
2. Have your Firebase Admin SDK key file ready (/opt/flutter/firebase-admin-sdk.json)

WHAT IT DOES:
- Reads your Firebase project configuration
- Provides the security rules to copy/paste into Firebase Console
- Cannot directly set rules (requires Firebase CLI or manual setup)

WHY MANUAL SETUP:
Firebase Storage security rules can only be set via:
1. Firebase Console (easiest - recommended)
2. Firebase CLI (requires npm + firebase-tools)

This script provides the exact rules to use.
"""

import json
import sys
import os

def load_firebase_config():
    """Load Firebase Admin SDK configuration"""
    config_paths = [
        '/opt/flutter/firebase-admin-sdk.json',
        '/opt/flutter/google-services.json'
    ]
    
    for config_path in config_paths:
        if os.path.exists(config_path):
            print(f"✅ Found Firebase config: {config_path}")
            with open(config_path, 'r') as f:
                return json.load(f), config_path
    
    print("❌ Firebase configuration file not found!")
    print("Expected locations:")
    for path in config_paths:
        print(f"  - {path}")
    return None, None

def get_storage_rules():
    """Get Firebase Storage security rules"""
    return '''rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // ============================================
    // PROFILE PHOTOS (Public Read)
    // ============================================
    match /profiles/{userId}/{fileName} {
      // Anyone can view profile photos (for customer browsing)
      allow read: if true;
      
      // Only authenticated users can upload their own photos
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024  // Max 5MB
                   && request.resource.contentType.matches('image/.*');  // Only images
    }
    
    // ============================================
    // NATIONAL ID PHOTOS (Private)
    // ============================================
    match /national_ids/{userId}/{fileName} {
      // Only the owner can view their own ID photos (sensitive!)
      allow read: if request.auth != null 
                  && request.auth.uid == userId;
      
      // Only the owner can upload their ID photos
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024  // Max 10MB (needs clarity)
                   && request.resource.contentType.matches('image/.*');
    }
    
    // ============================================
    // PRODUCT PHOTOS (Public Read)
    // ============================================
    match /products/{userId}/{fileName} {
      // Anyone can view product photos (for customers)
      allow read: if true;
      
      // Only authenticated users can upload their product photos
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024  // Max 5MB
                   && request.resource.contentType.matches('image/.*');
    }
    
    // ============================================
    // THUMBNAILS (Same permissions as parent)
    // ============================================
    match /profiles/thumbnails/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /products/thumbnails/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ============================================
    // DENY ALL OTHER ACCESS
    // ============================================
    match /{document=**} {
      allow read, write: if false;
    }
  }
}'''

def print_instructions(project_id, storage_bucket):
    """Print setup instructions"""
    print("\n" + "="*70)
    print("🔥 FIREBASE STORAGE SECURITY RULES SETUP")
    print("="*70)
    
    print(f"\n📋 Project Information:")
    print(f"   Project ID: {project_id}")
    print(f"   Storage Bucket: {storage_bucket}")
    
    print(f"\n🔗 Firebase Console URL:")
    print(f"   https://console.firebase.google.com/project/{project_id}/storage")
    
    print("\n" + "="*70)
    print("📝 SETUP INSTRUCTIONS (5 MINUTES)")
    print("="*70)
    
    print("\n1️⃣  ENABLE FIREBASE STORAGE (If not already enabled)")
    print("   ────────────────────────────────────────────────")
    print("   a) Go to: https://console.firebase.google.com/")
    print("   b) Select your project")
    print("   c) Click 'Build' → 'Storage' in left menu")
    print("   d) If you see 'Get started' button:")
    print("      - Click it")
    print("      - Choose 'Start in production mode'")
    print("      - Select storage location (closest to your users)")
    print("      - Click 'Done'")
    print("   e) If you see 'Files | Rules | Usage' tabs:")
    print("      ✅ Storage is already enabled! Skip to step 2.")
    
    print("\n2️⃣  CONFIGURE SECURITY RULES")
    print("   ────────────────────────────────────────────────")
    print("   a) In Firebase Console → Storage → Click 'Rules' tab")
    print("   b) You'll see default rules (denies all access)")
    print("   c) DELETE all existing rules")
    print("   d) COPY the rules below and PASTE into the editor")
    print("   e) Click 'Publish' button")
    print("   f) Wait for confirmation: 'Rules published successfully'")
    
    print("\n3️⃣  TEST YOUR SETUP")
    print("   ────────────────────────────────────────────────")
    print("   a) Open your Flutter app")
    print("   b) Login as any user")
    print("   c) Go to Edit Profile")
    print("   d) Upload a profile photo")
    print("   e) Check browser console (F12) for:")
    print("      '✅ Image uploaded successfully'")
    print("   f) Check Firebase Console → Storage → Files")
    print("      You should see: profiles/[user_id]/[photo].jpg")
    
    print("\n" + "="*70)
    print("📋 COPY THESE SECURITY RULES:")
    print("="*70)
    print("\n👇 Copy everything from 'rules_version' to the last closing brace 👇\n")
    print(get_storage_rules())
    print("\n👆 Copy until here (including the last closing brace) 👆\n")
    
    print("="*70)
    print("💡 IMPORTANT NOTES:")
    print("="*70)
    print("✅ Profile photos: Anyone can VIEW, only owner can UPLOAD")
    print("🔒 National ID photos: Only owner can VIEW and UPLOAD (private!)")
    print("✅ Product photos: Anyone can VIEW, only owner can UPLOAD")
    print("📏 File size limits: 5MB for photos, 10MB for ID photos")
    print("🖼️  Only image files allowed (jpg, png, gif, etc.)")
    
    print("\n" + "="*70)
    print("🆘 TROUBLESHOOTING:")
    print("="*70)
    print("❌ 'Permission denied' error?")
    print("   → Security rules not published. Follow step 2 again.")
    print("\n❌ 'Storage bucket not configured' error?")
    print("   → Firebase Storage not enabled. Follow step 1.")
    print("\n❌ Upload timeout?")
    print("   → Normal for first upload. Try again or check internet.")
    
    print("\n" + "="*70)
    print("✅ AFTER SETUP:")
    print("="*70)
    print("Your app will automatically:")
    print("  • Upload profile photos to Firebase Storage")
    print("  • Upload national ID photos (private)")
    print("  • Upload product photos (up to 3 per product)")
    print("  • Compress images (save 50-80% bandwidth)")
    print("  • Display photos from Firebase CDN (fast loading)")
    print("\n🎉 No coding required, no app rebuild needed!")
    print("="*70 + "\n")

def main():
    print("\n🔥 Firebase Storage Security Rules Setup Helper")
    print("="*70 + "\n")
    
    # Load Firebase config
    config, config_path = load_firebase_config()
    
    if not config:
        print("\n❌ Cannot proceed without Firebase configuration.")
        print("\nℹ️  To fix this:")
        print("   1. Download firebase-admin-sdk.json from Firebase Console")
        print("   2. Place it in: /opt/flutter/firebase-admin-sdk.json")
        print("   3. Run this script again")
        sys.exit(1)
    
    # Extract project information
    project_id = config.get('project_id') or config.get('projectId')
    storage_bucket = config.get('storageBucket') or f"{project_id}.appspot.com"
    
    if not project_id:
        print("❌ Could not find project_id in Firebase configuration!")
        print(f"Config file: {config_path}")
        sys.exit(1)
    
    # Print instructions
    print_instructions(project_id, storage_bucket)
    
    # Save rules to file for reference
    rules_file = '/home/user/flutter_app/storage.rules'
    with open(rules_file, 'w') as f:
        f.write(get_storage_rules())
    
    print(f"💾 Security rules also saved to: {rules_file}")
    print("   (You can use this file with Firebase CLI if you prefer)\n")
    
    print("="*70)
    print("🚀 NEXT STEPS:")
    print("="*70)
    print("1. Go to Firebase Console (URL above)")
    print("2. Copy the security rules (printed above)")
    print("3. Paste into Storage → Rules tab")
    print("4. Click 'Publish'")
    print("5. Test by uploading a photo in your app")
    print("="*70 + "\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Setup cancelled by user.")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
