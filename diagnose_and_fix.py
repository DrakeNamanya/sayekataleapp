#!/usr/bin/env python3
"""
Diagnose and fix authentication and data issues
"""

import sys
import subprocess

# Check and install firebase-admin if needed
try:
    import firebase_admin
    from firebase_admin import credentials, firestore, auth
    print("✅ firebase-admin available")
except ImportError:
    print("📦 Installing firebase-admin...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "firebase-admin==7.1.0"])
    import firebase_admin
    from firebase_admin import credentials, firestore, auth

print("\n🔍 SAYE Katale App - Diagnostic Tool")
print("=" * 50)

# Initialize Firebase
try:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase connection successful")
except Exception as e:
    print(f"❌ Firebase connection failed: {e}")
    sys.exit(1)

print("\n1️⃣ Checking Firebase Authentication...")
try:
    # List users
    page = auth.list_users()
    users = list(page.users)
    print(f"   ✅ Found {len(users)} registered users:")
    for user in users[:10]:  # Show first 10
        print(f"      - {user.email} (UID: {user.uid[:8]}...)")
    if len(users) == 0:
        print("   ⚠️ No users found - you need to create accounts")
except Exception as e:
    print(f"   ❌ Error checking users: {e}")

print("\n2️⃣ Checking Firestore Collections...")
try:
    collections = list(db.collections())
    print(f"   ✅ Found {len(collections)} collections:")
    
    for collection in collections:
        docs = list(collection.limit(5).stream())
        print(f"      - {collection.id}: {len(docs)} documents (showing first 5)")
        
    # Check specific collections
    print("\n3️⃣ Checking Key Collections...")
    
    # Users collection
    users_ref = db.collection('users')
    users_count = len(list(users_ref.stream()))
    print(f"   👤 users: {users_count} documents")
    
    # Products collection
    products_ref = db.collection('products')
    products_count = len(list(products_ref.stream()))
    print(f"   📦 products: {products_count} documents")
    if products_count == 0:
        print("      ⚠️ No products found - dashboards will be empty!")
    
    # Cart items collection
    cart_ref = db.collection('cart_items')
    cart_count = len(list(cart_ref.stream()))
    print(f"   🛒 cart_items: {cart_count} documents")
    
    # Orders collection
    orders_ref = db.collection('orders')
    orders_count = len(list(orders_ref.stream()))
    print(f"   📋 orders: {orders_count} documents")
    
except Exception as e:
    print(f"   ❌ Error checking collections: {e}")

print("\n4️⃣ Diagnosis Summary...")
print("=" * 50)

issues_found = []

# Check for authentication issues
try:
    page = auth.list_users()
    if len(list(page.users)) == 0:
        issues_found.append("No users registered - create accounts first")
except:
    issues_found.append("Cannot access Firebase Authentication")

# Check for data issues
try:
    products_count = len(list(db.collection('products').stream()))
    if products_count == 0:
        issues_found.append("No products in database - dashboards will be blank")
except:
    issues_found.append("Cannot access products collection")

if len(issues_found) == 0:
    print("✅ All checks passed! App should work correctly.")
else:
    print("⚠️  Issues Found:")
    for i, issue in enumerate(issues_found, 1):
        print(f"   {i}. {issue}")

print("\n5️⃣ Recommended Actions...")
print("=" * 50)

if "No users registered" in str(issues_found):
    print("📝 Action 1: Create test accounts")
    print("   - Open app URL and create accounts")
    print("   - Use these test emails:")
    print("     * sarah.buyer@test.com (SME/Buyer)")
    print("     * john.nama@test.com (SHG/Farmer)")
    print("     * ngobi.peter@test.com (SHG/Farmer)")

if "No products" in str(issues_found):
    print("\n📝 Action 2: Add sample products")
    print("   Option A: Run create_test_data.py to add sample products")
    print("   Option B: Login as farmer and add products manually")
    
    response = input("\n❓ Create sample products now? (y/n): ")
    if response.lower() == 'y':
        print("\n📦 Creating sample products...")
        try:
            sample_products = [
                {
                    'name': 'Fresh Tomatoes',
                    'category': 'Vegetables',
                    'price': 5000.0,
                    'unit': 'kg',
                    'stock_quantity': 100,
                    'description': 'Fresh organic tomatoes',
                    'farmer_id': 'TEST-FARMER-001',
                    'farmer_name': 'Test Farmer',
                    'location': 'Kampala',
                    'rating': 4.5,
                    'images': ['https://via.placeholder.com/400x400?text=Tomatoes'],
                    'created_at': firestore.SERVER_TIMESTAMP,
                    'updated_at': firestore.SERVER_TIMESTAMP,
                    'is_available': True,
                },
                {
                    'name': 'Green Cabbage',
                    'category': 'Vegetables',
                    'price': 3000.0,
                    'unit': 'kg',
                    'stock_quantity': 50,
                    'description': 'Fresh green cabbage',
                    'farmer_id': 'TEST-FARMER-001',
                    'farmer_name': 'Test Farmer',
                    'location': 'Kampala',
                    'rating': 4.7,
                    'images': ['https://via.placeholder.com/400x400?text=Cabbage'],
                    'created_at': firestore.SERVER_TIMESTAMP,
                    'updated_at': firestore.SERVER_TIMESTAMP,
                    'is_available': True,
                },
                {
                    'name': 'Red Beans',
                    'category': 'Legumes',
                    'price': 8000.0,
                    'unit': 'kg',
                    'stock_quantity': 80,
                    'description': 'Quality red beans',
                    'farmer_id': 'TEST-FARMER-002',
                    'farmer_name': 'Another Farmer',
                    'location': 'Wakiso',
                    'rating': 4.8,
                    'images': ['https://via.placeholder.com/400x400?text=Beans'],
                    'created_at': firestore.SERVER_TIMESTAMP,
                    'updated_at': firestore.SERVER_TIMESTAMP,
                    'is_available': True,
                },
            ]
            
            for product in sample_products:
                doc_ref = db.collection('products').add(product)
                print(f"   ✅ Created: {product['name']}")
            
            print("\n✅ Sample products created successfully!")
            print("💡 Refresh your browser to see the products")
            
        except Exception as e:
            print(f"   ❌ Error creating products: {e}")

print("\n6️⃣ Next Steps...")
print("=" * 50)
print("1. Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)")
print("2. Try creating accounts again")
print("3. Check browser console (F12) for any JavaScript errors")
print("4. If authentication still fails, check Firebase Console:")
print("   https://console.firebase.google.com/")
print("\n🎉 Diagnostic complete!")
