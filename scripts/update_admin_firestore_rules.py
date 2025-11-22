#!/usr/bin/env python3
"""
Script to update Firestore security rules to allow admin authentication
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    import json
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

def get_project_id():
    """Extract project ID from firebase config"""
    try:
        with open("/opt/flutter/google-services.json", "r") as f:
            config = json.load(f)
            return config["project_info"]["project_id"]
    except Exception as e:
        print(f"❌ Failed to get project ID: {e}")
        return None

def update_firestore_rules():
    """Update Firestore security rules to allow admin access"""
    
    print("="*70)
    print("🔧 UPDATING FIRESTORE SECURITY RULES")
    print("="*70)
    
    project_id = get_project_id()
    
    if not project_id:
        print("❌ Could not determine project ID")
        return False
    
    print(f"\n📋 Project ID: {project_id}")
    
    # Define security rules that allow admin authentication
    rules = """rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/admin_users/$(request.auth.uid));
    }
    
    // Admin users collection - allow authenticated users to read their own admin doc
    match /admin_users/{adminId} {
      // Allow any authenticated user to read admin documents (needed for login)
      allow read: if isAuthenticated();
      
      // Only admins can write
      allow write: if isAdmin();
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && 
                      (request.auth.uid == userId || isAdmin());
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if true; // Public read
      allow write: if isAuthenticated();
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Messages collection
    match /messages/{messageId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Complaints collection
    match /complaints/{complaintId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Subscriptions collection
    match /subscriptions/{subscriptionId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // SME Directory collection
    match /sme_directory/{smeId} {
      allow read: if true; // Public read
      allow write: if isAuthenticated();
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      allow read: if true; // Public read
      allow write: if isAuthenticated();
    }
    
    // Wallet transactions
    match /wallet_transactions/{transactionId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Payment records
    match /payments/{paymentId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Allow all other collections (for development)
    match /{document=**} {
      allow read, write: if isAuthenticated();
    }
  }
}
"""
    
    print("\n📝 Security Rules to be applied:")
    print("-" * 70)
    print("✅ Admin users: Authenticated users can read (for login)")
    print("✅ Users: Authenticated users can read, admins can write")
    print("✅ Products: Public read, authenticated write")
    print("✅ Orders/Messages/etc: Authenticated users only")
    print("-" * 70)
    
    print("\n⚠️  MANUAL ACTION REQUIRED:")
    print("\nFirestore Security Rules cannot be updated programmatically.")
    print("Please follow these steps:\n")
    
    print("1️⃣  Go to Firebase Console:")
    print(f"   https://console.firebase.google.com/project/{project_id}/firestore/rules\n")
    
    print("2️⃣  Click 'Edit Rules'\n")
    
    print("3️⃣  Replace all existing rules with the rules below:\n")
    
    print("="*70)
    print(rules)
    print("="*70)
    
    print("\n4️⃣  Click 'Publish'\n")
    
    print("✅ After publishing, admin login will work correctly!\n")
    
    # Save rules to file for reference
    rules_file = "/home/user/flutter_app/firestore.rules"
    try:
        with open(rules_file, "w") as f:
            f.write(rules)
        print(f"💾 Rules saved to: {rules_file}")
        print("   (You can copy from this file if needed)\n")
    except Exception as e:
        print(f"⚠️  Could not save rules file: {e}\n")
    
    return True

def main():
    initialize_firebase()
    update_firestore_rules()
    
    print("="*70)
    print("🎯 NEXT STEPS")
    print("="*70)
    print("\n1. Update Firestore Security Rules (see instructions above)")
    print("2. Try admin login again with: admin@sayekatale.com / Admin@2024!")
    print("3. You should be able to login and change password\n")

if __name__ == "__main__":
    main()
