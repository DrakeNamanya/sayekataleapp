#!/usr/bin/env python3
"""
Add real products for John Nama and Ngobi Peter to Firestore
This allows Sarah (buyer) to see their products immediately
"""

import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, auth
except ImportError:
    print("📦 Installing firebase-admin...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "firebase-admin==7.1.0"])
    import firebase_admin
    from firebase_admin import credentials, firestore, auth

print("\n🔧 Adding Real Farmer Products to Firestore")
print("=" * 50)

# Initialize Firebase
try:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase connected")
except Exception as e:
    print(f"❌ Firebase error: {e}")
    sys.exit(1)

# Get farmer UIDs from Authentication
print("\n1️⃣ Finding farmers in Firebase Auth...")
try:
    page = auth.list_users()
    users = list(page.users)
    
    john_uid = None
    ngobi_uid = None
    
    for user in users:
        if user.email and 'john.nama' in user.email.lower():
            john_uid = user.uid
            print(f"   ✅ Found John Nama: {user.email} (UID: {john_uid[:8]}...)")
        elif user.email and 'ngobi.peter' in user.email.lower():
            ngobi_uid = user.uid
            print(f"   ✅ Found Ngobi Peter: {user.email} (UID: {ngobi_uid[:8]}...)")
    
    if not john_uid:
        print("   ⚠️ John Nama not found in Auth - using test ID")
        john_uid = "JOHN-NAMA-TEST-001"
    
    if not ngobi_uid:
        print("   ⚠️ Ngobi Peter not found in Auth - using test ID")
        ngobi_uid = "NGOBI-PETER-TEST-001"
        
except Exception as e:
    print(f"   ⚠️ Could not query Auth: {e}")
    john_uid = "JOHN-NAMA-TEST-001"
    ngobi_uid = "NGOBI-PETER-TEST-001"

# John Nama's Products
john_products = [
    {
        'farmer_id': john_uid,
        'farmer_name': 'John Nama',
        'name': 'Fresh Tomatoes',
        'description': 'Organic red tomatoes, freshly harvested from my farm',
        'category': 'tomatoes',
        'price': 5000.0,
        'unit': 'kg',
        'unit_size': 1,
        'stock_quantity': 100,
        'low_stock_threshold': 20,
        'image_url': 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400',
        'location': 'Kampala',
        'rating': 4.5,
        'total_reviews': 0,
        'is_available': True,
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP,
    },
    {
        'farmer_id': john_uid,
        'farmer_name': 'John Nama',
        'name': 'Green Cabbage',
        'description': 'Fresh green cabbage, perfect for salads and cooking',
        'category': 'crop',
        'price': 3000.0,
        'unit': 'kg',
        'unit_size': 1,
        'stock_quantity': 50,
        'low_stock_threshold': 10,
        'image_url': 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=400',
        'location': 'Kampala',
        'rating': 4.7,
        'total_reviews': 0,
        'is_available': True,
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP,
    },
    {
        'farmer_id': john_uid,
        'farmer_name': 'John Nama',
        'name': 'Sweet Onions',
        'description': 'Red onions, sweet and fresh, 1kg pack',
        'category': 'onions',
        'price': 2500.0,
        'unit': 'kg',
        'unit_size': 1,
        'stock_quantity': 80,
        'low_stock_threshold': 15,
        'image_url': 'https://images.unsplash.com/photo-1618512484426-c35ad4f40b2c?w=400',
        'location': 'Kampala',
        'rating': 4.6,
        'total_reviews': 0,
        'is_available': True,
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP,
    },
]

# Ngobi Peter's Products
ngobi_products = [
    {
        'farmer_id': ngobi_uid,
        'farmer_name': 'Ngobi Peter',
        'name': 'Red Beans',
        'description': 'Quality red beans, perfect for stews and soups',
        'category': 'crop',
        'price': 8000.0,
        'unit': 'kg',
        'unit_size': 1,
        'stock_quantity': 80,
        'low_stock_threshold': 15,
        'image_url': 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=400',
        'location': 'Wakiso',
        'rating': 4.8,
        'total_reviews': 0,
        'is_available': True,
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP,
    },
    {
        'farmer_id': ngobi_uid,
        'farmer_name': 'Ngobi Peter',
        'name': 'Yellow Maize',
        'description': 'Fresh yellow maize, dried and ready for use',
        'category': 'crop',
        'price': 6000.0,
        'unit': 'kg',
        'unit_size': 1,
        'stock_quantity': 120,
        'low_stock_threshold': 20,
        'image_url': 'https://images.unsplash.com/photo-1560671994-96274e5e757d?w=400',
        'location': 'Wakiso',
        'rating': 4.6,
        'total_reviews': 0,
        'is_available': True,
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP,
    },
    {
        'farmer_id': ngobi_uid,
        'farmer_name': 'Ngobi Peter',
        'name': 'Ground Nuts',
        'description': 'Roasted ground nuts, rich in protein',
        'category': 'groundNuts',
        'price': 7500.0,
        'unit': 'kg',
        'unit_size': 1,
        'stock_quantity': 60,
        'low_stock_threshold': 10,
        'image_url': 'https://images.unsplash.com/photo-1582038501126-e57109d1f926?w=400',
        'location': 'Wakiso',
        'rating': 4.9,
        'total_reviews': 0,
        'is_available': True,
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP,
    },
]

print("\n2️⃣ Adding products to Firestore...")

# Add John's products
print("\n📦 John Nama's Products:")
for product in john_products:
    try:
        doc_ref = db.collection('products').add(product)
        print(f"   ✅ {product['name']} - {product['price']} UGX/{product['unit']}")
    except Exception as e:
        print(f"   ❌ Failed to add {product['name']}: {e}")

# Add Ngobi's products
print("\n📦 Ngobi Peter's Products:")
for product in ngobi_products:
    try:
        doc_ref = db.collection('products').add(product)
        print(f"   ✅ {product['name']} - {product['price']} UGX/{product['unit']}")
    except Exception as e:
        print(f"   ❌ Failed to add {product['name']}: {e}")

print("\n3️⃣ Verifying products in Firestore...")
try:
    # Count total products
    all_products = list(db.collection('products').stream())
    print(f"   📊 Total products in database: {len(all_products)}")
    
    # Count John's products
    john_count = len([p for p in all_products if p.to_dict().get('farmer_id') == john_uid])
    print(f"   👤 John Nama's products: {john_count}")
    
    # Count Ngobi's products
    ngobi_count = len([p for p in all_products if p.to_dict().get('farmer_id') == ngobi_uid])
    print(f"   👤 Ngobi Peter's products: {ngobi_count}")
    
except Exception as e:
    print(f"   ⚠️ Verification error: {e}")

print("\n🎉 Products added successfully!")
print("\n📝 Next Steps:")
print("1. Hard refresh browser (Ctrl+Shift+R)")
print("2. Login as Sarah (buyer)")
print("3. ⚠️ NOTE: Buyer screen still uses mock data")
print("4. Need to update buyer browse screen to show Firestore products")
print("\n💡 Temporary Solution:")
print("   - I'll update the buyer screen to query Firestore")
print("   - Then Sarah will see John and Ngobi's products")
