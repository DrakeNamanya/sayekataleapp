#!/usr/bin/env python3
"""
Script to set featured products and configure sales/ratings data for "Top" badge display
"""

import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("❌ Failed to import firebase-admin")
    print("📦 Installation required: pip install firebase-admin==7.1.0")
    sys.exit(1)

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        firebase_admin.get_app()
    except ValueError:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        firebase_admin.initialize_app(cred)
    return firestore.client()

def set_featured_products(db):
    """
    Set featured status on products (Manual selection based on ratings)
    Criteria: Products with average_rating >= 4.5 are marked as featured
    """
    print("\n🌟 Setting Featured Products...")
    
    products_ref = db.collection('products')
    products = products_ref.get()
    
    featured_count = 0
    total_count = 0
    
    for product in products:
        total_count += 1
        product_data = product.to_dict()
        product_id = product.id
        
        # Get current average rating (0.0 if not set)
        avg_rating = product_data.get('average_rating', 0.0)
        
        # Featured criteria: rating >= 4.5
        is_featured = avg_rating >= 4.5
        
        if is_featured:
            # Update product as featured
            products_ref.document(product_id).update({
                'is_featured': True
            })
            featured_count += 1
            print(f"  ⭐ {product_data.get('name', 'Unknown')} (Rating: {avg_rating:.1f}) - FEATURED")
    
    print(f"\n✅ Set {featured_count} / {total_count} products as featured")
    return featured_count

def calculate_product_ratings_and_sales(db):
    """
    Calculate and update product ratings and sales from reviews/orders
    """
    print("\n📊 Calculating Product Ratings & Sales...")
    
    products_ref = db.collection('products')
    reviews_ref = db.collection('reviews')
    orders_ref = db.collection('orders')
    
    products = products_ref.get()
    updated_count = 0
    
    for product in products:
        product_id = product.id
        product_data = product.to_dict()
        product_name = product_data.get('name', 'Unknown')
        
        # Calculate average rating from reviews
        product_reviews = reviews_ref.where('product_id', '==', product_id).get()
        
        if product_reviews:
            total_rating = sum(r.to_dict().get('rating', 0) for r in product_reviews)
            review_count = len(product_reviews)
            average_rating = total_rating / review_count
        else:
            average_rating = 0.0
            review_count = 0
        
        # Calculate total sales from completed orders
        completed_orders = orders_ref.where('status', '==', 'delivered').get()
        total_sales = 0
        
        for order in completed_orders:
            order_data = order.to_dict()
            items = order_data.get('items', [])
            for item in items:
                if item.get('productId') == product_id:
                    total_sales += item.get('quantity', 0)
        
        # Update product with calculated values
        products_ref.document(product_id).update({
            'average_rating': round(average_rating, 1),
            'total_sales': total_sales
        })
        
        # Check if qualifies for "Top" badge (sales >= 10 AND rating >= 4.0)
        is_top = total_sales >= 10 and average_rating >= 4.0
        
        if is_top:
            print(f"  🏆 {product_name}")
            print(f"     Rating: {average_rating:.1f} ({review_count} reviews)")
            print(f"     Sales: {total_sales} units")
            print(f"     Status: TOP BADGE ✨")
        
        updated_count += 1
    
    print(f"\n✅ Updated ratings and sales for {updated_count} products")

def add_sample_ratings_for_testing(db):
    """
    Add sample ratings and sales data for testing purposes
    Only if no ratings exist yet
    """
    print("\n🧪 Checking if sample data is needed...")
    
    reviews_ref = db.collection('reviews')
    existing_reviews = list(reviews_ref.limit(1).get())
    
    if existing_reviews:
        print("  ℹ️  Reviews already exist, skipping sample data")
        return
    
    print("  📝 Adding sample ratings and sales data...")
    
    products_ref = db.collection('products')
    products = list(products_ref.get())
    
    if not products:
        print("  ❌ No products found!")
        return
    
    import random
    from datetime import datetime, timedelta
    
    # Assign ratings and sales to products
    for i, product in enumerate(products):
        product_id = product.id
        product_data = product.to_dict()
        
        # Random rating between 3.5 and 5.0
        rating = random.uniform(3.5, 5.0)
        # Random sales between 0 and 50
        sales = random.randint(0, 50)
        
        products_ref.document(product_id).update({
            'average_rating': round(rating, 1),
            'total_sales': sales
        })
    
    print(f"  ✅ Added sample data to {len(products)} products")

def main():
    """Main execution function"""
    print("="*60)
    print("🔧 Featured Products & Top Badge Configuration")
    print("="*60)
    
    try:
        db = initialize_firebase()
        
        # Step 1: Add sample data if needed (for testing)
        add_sample_ratings_for_testing(db)
        
        # Step 2: Calculate real ratings and sales from reviews/orders
        calculate_product_ratings_and_sales(db)
        
        # Step 3: Set featured products based on ratings
        featured_count = set_featured_products(db)
        
        print("\n"+"="*60)
        print("✅ Configuration Complete!")
        print("="*60)
        print(f"\n📋 Summary:")
        print(f"  • Featured Products: {featured_count}")
        print(f"  • Criteria:")
        print(f"    - Featured: Rating >= 4.5")
        print(f"    - Top Badge: Sales >= 10 AND Rating >= 4.0")
        print("\n💡 Products are now ready for the new Browse Products screen!")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
