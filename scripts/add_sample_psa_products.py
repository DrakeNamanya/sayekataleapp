#!/usr/bin/env python3
"""
Add sample PSA products to Firestore for testing
"""

import sys
import os

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 INSTALLATION REQUIRED:")
    print("pip install firebase-admin==7.1.0")
    print("💡 This package is required for Firebase operations.")
    sys.exit(1)

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    # Check for Firebase Admin SDK key file
    admin_sdk_path = None
    
    # Search for admin SDK file in /opt/flutter/
    if os.path.exists('/opt/flutter/'):
        for file in os.listdir('/opt/flutter/'):
            if 'adminsdk' in file.lower() and file.endswith('.json'):
                admin_sdk_path = os.path.join('/opt/flutter/', file)
                break
    
    if not admin_sdk_path:
        print("❌ Firebase Admin SDK key file not found in /opt/flutter/")
        print("📁 Please upload your Firebase Admin SDK JSON file")
        sys.exit(1)
    
    try:
        cred = credentials.Certificate(admin_sdk_path)
        firebase_admin.initialize_app(cred)
        print(f"✅ Firebase initialized with: {os.path.basename(admin_sdk_path)}")
        return firestore.client()
    except Exception as e:
        print(f"❌ Error initializing Firebase: {e}")
        sys.exit(1)

def get_psa_user_id(db):
    """Get or create a PSA user for testing"""
    # Try to find existing PSA user
    users_ref = db.collection('users')
    psa_users = users_ref.where('role', '==', 'psa').limit(1).get()
    
    if psa_users:
        psa_id = psa_users[0].id
        psa_name = psa_users[0].to_dict().get('name', 'PSA Supplier')
        print(f"✅ Found existing PSA user: {psa_name} ({psa_id})")
        return psa_id, psa_name
    
    print("⚠️ No PSA user found in database")
    print("💡 Please create a PSA user account first through the app")
    print("   or run the create_users script")
    sys.exit(1)

def add_psa_products(db, psa_id, psa_name):
    """Add sample PSA products to Firestore"""
    
    products = [
        # Crop inputs
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Hybrid Maize Seeds (10kg)',
            'description': 'High-yield hybrid maize seeds suitable for Uganda climate',
            'category': 'fertilizers',  # Using fertilizers category for crop inputs
            'unit': 'bag',
            'unit_size': 10,
            'price': 450000.0,
            'stock_quantity': 120,
            'low_stock_threshold': 10,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Maize+Seeds',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'NPK Fertilizer (50kg)',
            'description': 'NPK 17-17-17 compound fertilizer for all crops',
            'category': 'fertilizers',
            'unit': 'bag',
            'unit_size': 50,
            'price': 180000.0,
            'stock_quantity': 85,
            'low_stock_threshold': 10,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=NPK+Fertilizer',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Pesticide Spray (5L)',
            'description': 'Broad-spectrum insecticide for pest control',
            'category': 'chemicals',
            'unit': 'bottle',
            'unit_size': 5,
            'price': 95000.0,
            'stock_quantity': 45,
            'low_stock_threshold': 5,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Pesticide',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Hand Hoe (Steel)',
            'description': 'Durable steel hand hoe with wooden handle',
            'category': 'hoes',
            'unit': 'piece',
            'unit_size': 1,
            'price': 25000.0,
            'stock_quantity': 200,
            'low_stock_threshold': 20,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Hand+Hoe',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        
        # Poultry inputs
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Day-Old Chicks (Broilers)',
            'description': 'Healthy broiler chicks, vaccinated and ready to raise',
            'category': 'dayOldChicks',
            'unit': 'piece',
            'unit_size': 1,
            'price': 3500.0,
            'stock_quantity': 500,
            'low_stock_threshold': 50,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Day+Old+Chicks',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Poultry Starter Feed (50kg)',
            'description': 'Complete starter feed for day-old to 3-week chicks',
            'category': 'feeds',
            'unit': 'bag',
            'unit_size': 50,
            'price': 125000.0,
            'stock_quantity': 75,
            'low_stock_threshold': 10,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Starter+Feed',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Poultry Grower Feed (50kg)',
            'description': 'Nutrient-rich grower feed for 3-week to market age',
            'category': 'feeds',
            'unit': 'bag',
            'unit_size': 50,
            'price': 115000.0,
            'stock_quantity': 60,
            'low_stock_threshold': 10,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Grower+Feed',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Poultry Vaccines Kit',
            'description': 'Complete vaccination kit for 100 birds',
            'category': 'chemicals',
            'unit': 'kit',
            'unit_size': 100,
            'price': 85000.0,
            'stock_quantity': 25,
            'low_stock_threshold': 5,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Vaccine+Kit',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        
        # Goat & Cow inputs
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Goat Feed Concentrate (25kg)',
            'description': 'High-protein concentrate for goats',
            'category': 'feeds',
            'unit': 'bag',
            'unit_size': 25,
            'price': 75000.0,
            'stock_quantity': 40,
            'low_stock_threshold': 5,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Goat+Feed',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Goat Mineral Supplements',
            'description': 'Essential mineral lick for goats, 5kg block',
            'category': 'chemicals',
            'unit': 'block',
            'unit_size': 5,
            'price': 15000.0,
            'stock_quantity': 80,
            'low_stock_threshold': 10,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Mineral+Block',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Dairy Cow Feed (50kg)',
            'description': 'High-energy dairy feed for lactating cows',
            'category': 'feeds',
            'unit': 'bag',
            'unit_size': 50,
            'price': 145000.0,
            'stock_quantity': 35,
            'low_stock_threshold': 5,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Dairy+Feed',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
        {
            'farmer_id': psa_id,
            'farmer_name': psa_name,
            'name': 'Cattle Dewormer (500ml)',
            'description': 'Broad-spectrum dewormer for cattle',
            'category': 'chemicals',
            'unit': 'bottle',
            'unit_size': 500,
            'price': 55000.0,
            'stock_quantity': 20,
            'low_stock_threshold': 5,
            'is_available': True,
            'image_url': 'https://via.placeholder.com/400x400?text=Dewormer',
            'location': '',
            'rating': 0.0,
            'total_reviews': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP,
        },
    ]
    
    print(f"\n📦 Adding {len(products)} PSA products to Firestore...")
    products_ref = db.collection('products')
    
    added_count = 0
    for product_data in products:
        try:
            doc_ref = products_ref.add(product_data)
            print(f"✅ Added: {product_data['name']} (ID: {doc_ref[1].id})")
            added_count += 1
        except Exception as e:
            print(f"❌ Error adding {product_data['name']}: {e}")
    
    print(f"\n🎉 Successfully added {added_count}/{len(products)} products!")
    return added_count

def main():
    print("=" * 60)
    print("PSA Sample Products Setup Script")
    print("=" * 60)
    
    # Initialize Firebase
    db = initialize_firebase()
    
    # Get PSA user
    psa_id, psa_name = get_psa_user_id(db)
    
    # Add sample products
    add_psa_products(db, psa_id, psa_name)
    
    print("\n" + "=" * 60)
    print("✅ Setup Complete!")
    print("=" * 60)
    print("\n💡 Next steps:")
    print("   1. Login to the app as an SHG user")
    print("   2. Navigate to 'Buy Inputs' tab")
    print("   3. Browse PSA products by category")
    print("   4. Add products to cart and place order")
    print("   5. Login as PSA to manage orders")
    print("\n")

if __name__ == '__main__':
    main()
