#!/usr/bin/env python3
"""
Script to apply Firestore security rules using Firebase Admin SDK
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    import firebase_admin
    from firebase_admin import credentials
    import json
    import requests
except ImportError:
    print("❌ Failed to import required modules")
    sys.exit(1)

def initialize_firebase():
    try:
        app = firebase_admin.get_app()
        return app
    except ValueError:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        app = firebase_admin.initialize_app(cred)
        return app

def get_project_id():
    """Extract project ID from firebase config"""
    try:
        with open("/opt/flutter/google-services.json", "r") as f:
            config = json.load(f)
            return config["project_info"]["project_id"]
    except Exception as e:
        print(f"❌ Failed to get project ID: {e}")
        return None

def apply_rules():
    print("="*70)
    print("🔧 APPLYING FIRESTORE SECURITY RULES VIA API")
    print("="*70)
    
    app = initialize_firebase()
    project_id = get_project_id()
    
    if not project_id:
        print("❌ Could not determine project ID")
        return False
    
    print(f"\n📋 Project ID: {project_id}")
    
    # Get access token
    try:
        access_token = app.credential.get_access_token().access_token
        print("✅ Got Firebase access token")
    except Exception as e:
        print(f"❌ Failed to get access token: {e}")
        return False
    
    # Define the rules
    rules_content = """rules_version = '2';

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
    
    # API endpoint
    url = f"https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents:ruleset"
    
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }
    
    payload = {
        "source": {
            "files": [
                {
                    "name": "firestore.rules",
                    "content": rules_content
                }
            ]
        }
    }
    
    print("\n🚀 Attempting to apply rules via Firebase API...")
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        
        if response.status_code in [200, 201]:
            print("✅ Rules applied successfully!")
            return True
        else:
            print(f"⚠️  API response: {response.status_code}")
            print(f"Response: {response.text}")
            print("\n❌ Could not apply rules via API")
            print("\n⚠️  MANUAL UPDATE REQUIRED:")
            print(f"\n1. Go to: https://console.firebase.google.com/project/{project_id}/firestore/rules")
            print("2. Copy rules from: /home/user/flutter_app/firestore.rules")
            print("3. Click 'Publish'\n")
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        print("\n⚠️  MANUAL UPDATE REQUIRED:")
        print(f"\n1. Go to: https://console.firebase.google.com/project/{project_id}/firestore/rules")
        print("2. Copy rules from: /home/user/flutter_app/firestore.rules")
        print("3. Click 'Publish'\n")
        return False

def main():
    result = apply_rules()
    
    print("\n" + "="*70)
    if result:
        print("✅ SUCCESS - Rules applied!")
        print("="*70)
        print("\nYou can now login with:")
        print("Email: admin@sayekatale.com")
        print("Password: Admin@2024!\n")
    else:
        print("⚠️  MANUAL ACTION NEEDED")
        print("="*70)
        print("\nPlease update Firestore rules manually (see instructions above)")
        print("Then try admin login again.\n")

if __name__ == "__main__":
    main()
