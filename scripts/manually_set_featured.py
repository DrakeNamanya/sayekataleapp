#!/usr/bin/env python3
"""
Manually set featured products and configure realistic sales/ratings data
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
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

def main():
    print("="*60)
    print("🎯 Manually Configuring Featured Products")
    print("="*60)
    
    db = initialize_firebase()
    products_ref = db.collection('products')
    
    # Get all products
    products = list(products_ref.get())
    
    if not products:
        print("❌ No products found!")
        return
    
    print(f"\n📦 Found {len(products)} products")
    
    # Set featured products (top 3 based on existing data)
    featured_indices = [0, 1, 2]  # First 3 products
    top_products_count = 0
    featured_count = 0
    
    import random
    
    for i, product in enumerate(products):
        product_id = product.id
        product_data = product.to_dict()
        product_name = product_data.get('name', 'Unknown')
        
        # Set featured status for first 3 products
        is_featured = i in featured_indices
        
        # Set realistic ratings and sales
        if is_featured:
            # Featured products have higher ratings and sales
            rating = random.uniform(4.5, 5.0)
            sales = random.randint(15, 50)
            featured_count += 1
        else:
            # Regular products have varied ratings and sales
            rating = random.uniform(3.0, 4.8)
            sales = random.randint(0, 30)
        
        # Check if qualifies for Top badge
        is_top = sales >= 10 and rating >= 4.0
        
        # Update product
        products_ref.document(product_id).update({
            'is_featured': is_featured,
            'average_rating': round(rating, 1),
            'total_sales': sales
        })
        
        badge = ""
        if is_featured:
            badge += "⭐ FEATURED"
        if is_top:
            badge += " 🏆 TOP"
            top_products_count += 1
        
        print(f"\n  {'✨' if is_featured else '  '} {product_name}")
        print(f"     Rating: {rating:.1f} | Sales: {sales} units")
        if badge:
            print(f"     {badge}")
    
    print("\n"+"="*60)
    print("✅ Configuration Complete!")
    print("="*60)
    print(f"\n📋 Summary:")
    print(f"  • Featured Products: {featured_count}")
    print(f"  • Top Badge Products: {top_products_count}")
    print(f"\n💡 Browse Products screen ready to showcase!")

if __name__ == "__main__":
    main()
