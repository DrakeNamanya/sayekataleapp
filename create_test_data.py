#!/usr/bin/env python3
"""
Create test data in Firestore for testing Phase 4
Adds sample products for farmers to enable testing
"""

import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 Installing firebase-admin...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "firebase-admin==7.1.0"])
    import firebase_admin
    from firebase_admin import credentials, firestore

from datetime import datetime

# Initialize Firebase Admin
try:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin initialized")
except Exception as e:
    print(f"❌ Firebase initialization error: {e}")
    sys.exit(1)

# Get Firestore client
db = firestore.client()

print("\n🔍 Checking existing data...")

# Check if products exist
products_ref = db.collection('products')
existing_products = list(products_ref.limit(1).stream())

if len(existing_products) > 0:
    print(f"✅ Found {len(list(products_ref.stream()))} existing products")
    print("💡 No need to create sample data")
else:
    print("📦 No products found. Creating sample data for testing...")
    
    # Sample products for testing
    sample_products = [
        {
            'id': 'PROD001',
            'name': 'Fresh Tomatoes',
            'category': 'Vegetables',
            'price': 5000,
            'unit': 'kg',
            'stock_quantity': 100,
            'description': 'Fresh organic tomatoes from local farm',
            'farmer_id': 'SHG-TEST001',
            'farmer_name': 'Test Farmer',
            'location': 'Kampala',
            'rating': 4.5,
            'images': ['https://via.placeholder.com/400x400?text=Tomatoes'],
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
            'is_available': True,
        },
        {
            'id': 'PROD002',
            'name': 'Green Cabbage',
            'category': 'Vegetables',
            'price': 3000,
            'unit': 'kg',
            'stock_quantity': 50,
            'description': 'Fresh green cabbage',
            'farmer_id': 'SHG-TEST001',
            'farmer_name': 'Test Farmer',
            'location': 'Kampala',
            'rating': 4.7,
            'images': ['https://via.placeholder.com/400x400?text=Cabbage'],
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
            'is_available': True,
        },
        {
            'id': 'PROD003',
            'name': 'Red Beans',
            'category': 'Legumes',
            'price': 8000,
            'unit': 'kg',
            'stock_quantity': 80,
            'description': 'Quality red beans',
            'farmer_id': 'SHG-TEST002',
            'farmer_name': 'Another Farmer',
            'location': 'Wakiso',
            'rating': 4.8,
            'images': ['https://via.placeholder.com/400x400?text=Beans'],
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
            'is_available': True,
        },
    ]
    
    print(f"📝 Creating {len(sample_products)} sample products...")
    for product in sample_products:
        try:
            products_ref.document(product['id']).set(product)
            print(f"  ✅ Created product: {product['name']}")
        except Exception as e:
            print(f"  ❌ Error creating {product['name']}: {e}")
    
    print("\n✅ Sample data created successfully!")

print("\n📊 Current Firestore Collections:")
collections = db.collections()
for collection in collections:
    count = len(list(collection.stream()))
    print(f"  - {collection.id}: {count} documents")

print("\n🎉 Done! You can now test the app.")
print("💡 Note: Products created with test farmer IDs.")
print("💡 Create real accounts (John Nama, Ngobi Peter) to add their own products.")
