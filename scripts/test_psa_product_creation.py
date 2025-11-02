#!/usr/bin/env python3
"""
Test script to verify PSA product creation in Firestore
This script checks if products are being saved correctly to Firebase
"""

import sys
import os

# Add the parent directory to the path to import firebase_admin
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 This script requires Firebase Admin SDK")
    print("💡 Install with: pip install firebase-admin==7.1.0")
    sys.exit(1)

def test_psa_product_creation():
    """Test if PSA products are being saved to Firestore"""
    
    # Check if Firebase Admin SDK key exists
    admin_sdk_path = '/opt/flutter/firebase-admin-sdk.json'
    if not os.path.exists(admin_sdk_path):
        print(f"❌ Firebase Admin SDK key not found at {admin_sdk_path}")
        print("💡 This script requires the Firebase Admin SDK key file")
        return False
    
    # Initialize Firebase Admin SDK
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(admin_sdk_path)
            firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialized")
    except Exception as e:
        print(f"❌ Error initializing Firebase: {e}")
        return False
    
    # Get Firestore client
    db = firestore.client()
    
    print("\n" + "="*70)
    print("🧪 TESTING PSA PRODUCT CREATION")
    print("="*70)
    
    # Test 1: Check if any PSA users exist
    print("\n📋 Test 1: Checking PSA users...")
    try:
        psa_users = db.collection('users').where('role', '==', 'psa').get()
        psa_count = len(psa_users)
        
        if psa_count > 0:
            print(f"✅ Found {psa_count} PSA user(s)")
            for user in psa_users[:3]:  # Show first 3
                user_data = user.to_dict()
                print(f"   • {user_data.get('name', 'Unknown')} (ID: {user.id})")
        else:
            print("⚠️  No PSA users found in database")
            print("💡 Create a PSA user account first before adding products")
            return False
    except Exception as e:
        print(f"❌ Error fetching PSA users: {e}")
        return False
    
    # Test 2: Check if products collection exists and has PSA products
    print("\n📋 Test 2: Checking PSA products...")
    try:
        psa_ids = [user.id for user in psa_users]
        
        # Query products from PSA sellers
        products = []
        for psa_id in psa_ids[:10]:  # Limit to first 10 PSA users (Firestore 'in' limit)
            psa_products = db.collection('products').where('farmer_id', '==', psa_id).get()
            products.extend(psa_products)
        
        if products:
            print(f"✅ Found {len(products)} PSA product(s)")
            print("\n📦 Sample Products:")
            for product in products[:5]:  # Show first 5
                product_data = product.to_dict()
                print(f"\n   Product: {product_data.get('name', 'Unknown')}")
                print(f"   Category: {product_data.get('category', 'N/A')}")
                print(f"   Price: UGX {product_data.get('price', 0):,.0f}")
                print(f"   Stock: {product_data.get('stock_quantity', 0)} {product_data.get('unit', 'units')}")
                print(f"   PSA: {product_data.get('farmer_name', 'Unknown')}")
                print(f"   Available: {product_data.get('is_available', False)}")
        else:
            print("⚠️  No PSA products found")
            print("💡 Add products through the PSA app interface")
            print("💡 Or use the sample product script: scripts/add_sample_psa_products.py")
            
    except Exception as e:
        print(f"❌ Error fetching PSA products: {e}")
        return False
    
    # Test 3: Verify product structure
    print("\n📋 Test 3: Verifying product data structure...")
    if products:
        sample_product = products[0].to_dict()
        required_fields = [
            'farmer_id', 'farmer_name', 'name', 'description', 'category',
            'price', 'unit', 'unit_size', 'stock_quantity', 'is_available',
            'created_at', 'updated_at'
        ]
        
        missing_fields = []
        for field in required_fields:
            if field not in sample_product:
                missing_fields.append(field)
        
        if not missing_fields:
            print("✅ Product structure is correct")
            print("   All required fields present:")
            for field in required_fields:
                value = sample_product.get(field)
                if isinstance(value, (int, float)):
                    print(f"   • {field}: {value}")
                elif isinstance(value, str):
                    print(f"   • {field}: {value[:50]}..." if len(str(value)) > 50 else f"   • {field}: {value}")
                else:
                    print(f"   • {field}: {type(value).__name__}")
        else:
            print(f"⚠️  Missing fields in product structure: {missing_fields}")
            print("💡 Update product creation code to include these fields")
    
    # Test 4: Check if products are available for SHG buyers
    print("\n📋 Test 4: Checking product availability for SHG buyers...")
    try:
        available_products = [p for p in products if p.to_dict().get('is_available', False)]
        
        if available_products:
            print(f"✅ {len(available_products)} product(s) available for purchase")
            
            # Count by category
            categories = {}
            for product in available_products:
                cat = product.to_dict().get('category', 'unknown')
                categories[cat] = categories.get(cat, 0) + 1
            
            print("\n   Products by category:")
            for category, count in sorted(categories.items()):
                print(f"   • {category}: {count} product(s)")
        else:
            print("⚠️  No available products (all marked as unavailable)")
            print("💡 Set is_available to true for products to appear in SHG Buy Inputs screen")
            
    except Exception as e:
        print(f"❌ Error checking product availability: {e}")
        return False
    
    print("\n" + "="*70)
    print("📊 TEST SUMMARY")
    print("="*70)
    
    if psa_count > 0 and len(products) > 0 and len(available_products) > 0:
        print("✅ All tests passed!")
        print(f"   • PSA Users: {psa_count}")
        print(f"   • Total Products: {len(products)}")
        print(f"   • Available Products: {len(available_products)}")
        print("\n🎉 PSA product creation is working correctly!")
        print("💡 SHG users can now see these products in the 'Buy Inputs' screen")
        return True
    else:
        print("⚠️  Some tests failed or no data found")
        print("💡 Recommendations:")
        if psa_count == 0:
            print("   1. Create PSA user accounts in the app")
        if len(products) == 0:
            print("   2. Add products through PSA Products screen in the app")
        if len(available_products) == 0 and len(products) > 0:
            print("   3. Mark products as available (is_available = true)")
        return False

if __name__ == '__main__':
    try:
        success = test_psa_product_creation()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
