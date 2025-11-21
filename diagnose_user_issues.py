#!/usr/bin/env python3
"""
Comprehensive Diagnosis of User Issues for SayeKatale App

Issues to diagnose:
1. Grey dashboard on first login for new SME users
2. Purchase receipts not displaying for SME users
3. Edit Profile Firestore permission errors for SME/SHG
4. Product delete/update permissions for PSA/SHG

Root causes to check:
- Firestore security rules
- User profile initialization
- Dashboard state loading
- Receipt service query logic
"""

import firebase_admin
from firebase_admin import credentials, firestore, auth
import sys
from datetime import datetime

# Initialize Firebase Admin
try:
    cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase Admin SDK initialized successfully\n")
except Exception as e:
    print(f"❌ Failed to initialize Firebase Admin SDK: {e}")
    sys.exit(1)

print("="*80)
print("🔍 SAYEKATALE APP - USER ISSUES DIAGNOSIS")
print("="*80)
print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

# ============================================================================
# ISSUE #1: Grey Dashboard on First Login for New SME Users
# ============================================================================
print("="*80)
print("📋 ISSUE #1: Grey Dashboard on First Login")
print("="*80)
print("")

print("🔍 Hypothesis: Dashboard loads before user profile is fully initialized")
print("   - New users created with minimal profile data")
print("   - Dashboard queries fail due to missing fields")
print("   - After second login, cached data or re-initialization works")
print("")

# Check rita's account
print("🔎 Checking Rita's account (new SME user)...")
try:
    # Search for Rita in users collection
    users_ref = db.collection('users')
    rita_query = users_ref.where('role', '==', 'sme').where('name', '==', 'Rita').limit(1).get()
    
    if rita_query:
        for doc in rita_query:
            user_data = doc.to_dict()
            print(f"✅ Found Rita's account:")
            print(f"   - User ID: {doc.id}")
            print(f"   - Name: {user_data.get('name')}")
            print(f"   - Email: {user_data.get('email')}")
            print(f"   - Profile Complete: {user_data.get('is_profile_complete', False)}")
            print(f"   - Created At: {user_data.get('created_at')}")
            print("")
            
            # Check for missing required fields
            print("   🔍 Checking required fields for dashboard:")
            required_fields = ['id', 'name', 'email', 'phone', 'role']
            missing_fields = []
            for field in required_fields:
                if field not in user_data or user_data[field] is None:
                    missing_fields.append(field)
                    print(f"      ❌ Missing: {field}")
                else:
                    print(f"      ✅ Present: {field} = {user_data[field]}")
            
            if missing_fields:
                print(f"\n   ⚠️ PROBLEM FOUND: Missing {len(missing_fields)} required fields")
            else:
                print("\n   ✅ All required fields present")
    else:
        print("❌ Rita's account not found. Checking all recent SME users...")
        recent_smes = users_ref.where('role', '==', 'sme').order_by('created_at', direction=firestore.Query.DESCENDING).limit(5).get()
        print(f"\n📊 Last 5 SME registrations:")
        for doc in recent_smes:
            user_data = doc.to_dict()
            print(f"   - {user_data.get('name')} ({doc.id}): {user_data.get('email')}")
            print(f"     Profile Complete: {user_data.get('is_profile_complete', False)}")
except Exception as e:
    print(f"❌ Error checking Rita's account: {e}")

print("")

# ============================================================================
# ISSUE #2: Purchase Receipts Not Displaying for SME Users
# ============================================================================
print("="*80)
print("📋 ISSUE #2: Purchase Receipts Not Displaying for SME Users")
print("="*80)
print("")

print("🔍 Hypothesis: Receipts query uses wrong user ID field or wrong collection filter")
print("   - Working for datacollectorslimited@gmail.com but not for SME users")
print("   - Possible field name mismatch (buyer_id vs buyerId)")
print("   - Possible role-based permission issue")
print("")

# Check receipts for datacollectorslimited@gmail.com
print("🔎 Checking receipts for datacollectorslimited@gmail.com...")
try:
    dc_user_query = db.collection('users').where('email', '==', 'datacollectorslimited@gmail.com').limit(1).get()
    if dc_user_query:
        dc_user_id = None
        for doc in dc_user_query:
            dc_user_id = doc.id
            print(f"✅ Found datacollectorslimited@gmail.com account: {dc_user_id}")
        
        if dc_user_id:
            # Check receipts for this user
            receipts_buyer = db.collection('receipts').where('buyer_id', '==', dc_user_id).limit(5).get()
            print(f"\n📊 Receipts with buyer_id = {dc_user_id}: {len(receipts_buyer)}")
            
            receipts_seller = db.collection('receipts').where('seller_id', '==', dc_user_id).limit(5).get()
            print(f"📊 Receipts with seller_id = {dc_user_id}: {len(receipts_seller)}")
            
            if receipts_buyer:
                print("\n✅ Sample receipt (as buyer):")
                first_receipt = receipts_buyer[0].to_dict()
                print(f"   - Receipt ID: {receipts_buyer[0].id}")
                print(f"   - Buyer ID: {first_receipt.get('buyer_id')}")
                print(f"   - Buyer Name: {first_receipt.get('buyer_name')}")
                print(f"   - Seller ID: {first_receipt.get('seller_id')}")
                print(f"   - Seller Name: {first_receipt.get('seller_name')}")
                print(f"   - Total Amount: UGX {first_receipt.get('total_amount')}")
    else:
        print("❌ datacollectorslimited@gmail.com account not found")
except Exception as e:
    print(f"❌ Error checking receipts: {e}")

print("")

# Now check Rita's receipts
print("🔎 Checking Rita's receipts...")
try:
    rita_query = db.collection('users').where('role', '==', 'sme').where('name', '==', 'Rita').limit(1).get()
    if rita_query:
        rita_id = None
        for doc in rita_query:
            rita_id = doc.id
        
        if rita_id:
            receipts_buyer = db.collection('receipts').where('buyer_id', '==', rita_id).get()
            print(f"📊 Receipts for Rita (buyer_id = {rita_id}): {len(receipts_buyer)}")
            
            if not receipts_buyer:
                print("   ⚠️ PROBLEM FOUND: Rita has no purchase receipts")
                print("   ℹ️ This could be normal if no orders are completed")
    else:
        print("❌ Rita's account not found for receipt check")
except Exception as e:
    print(f"❌ Error checking Rita's receipts: {e}")

print("")

# ============================================================================
# ISSUE #3: Edit Profile Firestore Permission Errors
# ============================================================================
print("="*80)
print("📋 ISSUE #3: Edit Profile Firestore Permission Errors (SME/SHG)")
print("="*80)
print("")

print("🔍 Hypothesis: Firestore rules too restrictive or role mismatch")
print("   - Rules may require admin privileges for profile updates")
print("   - Rules may be checking wrong UID field")
print("   - Rules may not allow profile image updates")
print("")

print("📋 Current Firestore Security Rules (users collection):")
print("""
match /users/{userId} {
  // Read: Authenticated users can read their own profile + others
  allow read: if request.auth != null;
  
  // Update: Only owner can update their profile (with restrictions)
  allow update: if request.auth != null && 
                   request.auth.uid == userId &&
                   // Prevent changing UID or role
                   request.resource.data.id == resource.data.id &&
                   request.resource.data.role == resource.data.role;
  
  // Create: Only allow creating your own user document
  allow create: if request.auth != null && 
                   request.auth.uid == userId &&
                   request.resource.data.id == request.auth.uid;
  
  // Delete: Only admins can delete users
  allow delete: if isAdmin();
}
""")

print("✅ ANALYSIS:")
print("   - Rules allow users to update their own profile")
print("   - BUT: UID must match document ID")
print("   - BUT: Cannot change id or role fields")
print("")

# Test a sample user update
print("🔎 Checking if Rita's UID matches her document ID...")
try:
    rita_query = db.collection('users').where('role', '==', 'sme').where('name', '==', 'Rita').limit(1).get()
    if rita_query:
        for doc in rita_query:
            user_data = doc.to_dict()
            doc_id = doc.id
            user_id_field = user_data.get('id')
            
            print(f"   - Document ID: {doc_id}")
            print(f"   - User 'id' field: {user_id_field}")
            
            if doc_id == user_id_field:
                print("   ✅ IDs match - permission rule should work")
            else:
                print("   ❌ PROBLEM FOUND: Document ID doesn't match 'id' field")
                print("      This will cause permission errors!")
    else:
        print("❌ Rita's account not found")
except Exception as e:
    print(f"❌ Error checking UID: {e}")

print("")

# ============================================================================
# ISSUE #4: Product Delete/Update Permissions for PSA/SHG
# ============================================================================
print("="*80)
print("📋 ISSUE #4: Product Delete/Update Permissions (PSA/SHG)")
print("="*80)
print("")

print("🔍 Hypothesis: Products have wrong farmer_id or rules too restrictive")
print("   - Products may be owned by different user")
print("   - Rules may require admin for all deletes/updates")
print("   - Field mismatch (farmer_id vs farmerId)")
print("")

print("📋 Current Firestore Security Rules (products collection):")
print("""
match /products/{productId} {
  // Read: Anyone can read products
  allow read: if request.auth != null;
  
  // Create: Only farmers (SHG/PSA) can create
  allow create: if request.auth != null && 
                   request.resource.data.farmer_id == request.auth.uid;
  
  // Update/Delete: Only owner or admin
  allow update: if request.auth != null && 
                   (resource.data.farmer_id == request.auth.uid || isAdmin());
  allow delete: if request.auth != null && 
                   (resource.data.farmer_id == request.auth.uid || isAdmin());
}
""")

print("✅ ANALYSIS:")
print("   - Rules allow owner to update/delete their products")
print("   - Rules check farmer_id field against request.auth.uid")
print("")

# Check sample products
print("🔎 Checking sample products from PSA/SHG users...")
try:
    products_ref = db.collection('products')
    sample_products = products_ref.limit(5).get()
    
    print(f"📊 Sample of {len(sample_products)} products:\n")
    for doc in sample_products:
        product_data = doc.to_dict()
        product_id = doc.id
        farmer_id = product_data.get('farmer_id')
        farmer_name = product_data.get('farmer_name')
        
        print(f"   Product: {product_data.get('name')}")
        print(f"   - Product ID: {product_id}")
        print(f"   - Farmer ID: {farmer_id}")
        print(f"   - Farmer Name: {farmer_name}")
        
        # Check if farmer exists
        try:
            farmer_doc = db.collection('users').document(farmer_id).get()
            if farmer_doc.exists:
                farmer_data = farmer_doc.to_dict()
                print(f"   - Farmer Role: {farmer_data.get('role')}")
                print(f"   - ✅ Farmer document exists")
            else:
                print(f"   - ❌ PROBLEM: Farmer document doesn't exist!")
        except Exception as e:
            print(f"   - ❌ Error checking farmer: {e}")
        print("")
    
except Exception as e:
    print(f"❌ Error checking products: {e}")

print("")

# ============================================================================
# SUMMARY & RECOMMENDATIONS
# ============================================================================
print("="*80)
print("📊 SUMMARY & RECOMMENDATIONS")
print("="*80)
print("")

print("🔧 REQUIRED FIXES:")
print("")
print("1️⃣ Grey Dashboard Fix:")
print("   ✅ Add loading state to dashboard")
print("   ✅ Ensure user profile is fully loaded before rendering")
print("   ✅ Add retry mechanism if initial load fails")
print("")

print("2️⃣ Purchase Receipts Fix:")
print("   ✅ Verify query uses correct field name (buyer_id)")
print("   ✅ Add error handling and debug logging")
print("   ✅ Check if receipts are actually being created")
print("")

print("3️⃣ Edit Profile Permission Fix:")
print("   ✅ Ensure document ID matches user 'id' field")
print("   ✅ Verify updateProfile() doesn't try to change 'id' or 'role'")
print("   ✅ Add proper error messages for permission errors")
print("")

print("4️⃣ Product Update/Delete Permission Fix:")
print("   ✅ Verify farmer_id matches current user's UID")
print("   ✅ Add owner check before attempting update/delete")
print("   ✅ Provide clear error if user tries to modify others' products")
print("")

print("="*80)
print("✅ DIAGNOSIS COMPLETE")
print("="*80)
