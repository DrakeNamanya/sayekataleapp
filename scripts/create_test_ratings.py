#!/usr/bin/env python3
"""
Generate comprehensive test ratings and reviews data for the agricultural marketplace.
This script creates:
- Farmer ratings statistics
- Product reviews with ratings
- Various rating distributions
- Reviews with and without photos/comments
"""

import os
import sys
import random
from datetime import datetime, timedelta

# Add the flutter sandbox directory to Python path
sys.path.insert(0, '/opt/flutter')

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 INSTALLATION REQUIRED:")
    print("pip install firebase-admin==7.1.0")
    exit(1)

# Initialize Firebase Admin SDK
def initialize_firebase():
    """Initialize Firebase Admin SDK with service account key"""
    # Check if already initialized
    if firebase_admin._apps:
        print("✅ Firebase already initialized")
        return firestore.client()
    
    # Find Firebase Admin SDK key
    firebase_key_paths = [
        '/opt/flutter/firebase-admin-sdk.json',
    ]
    
    # Also search for any JSON file with 'adminsdk' in the name
    flutter_dir = '/opt/flutter'
    if os.path.exists(flutter_dir):
        for filename in os.listdir(flutter_dir):
            if 'adminsdk' in filename.lower() and filename.endswith('.json'):
                firebase_key_paths.append(os.path.join(flutter_dir, filename))
    
    firebase_key = None
    for path in firebase_key_paths:
        if os.path.exists(path):
            firebase_key = path
            break
    
    if not firebase_key:
        print(f"❌ Firebase Admin SDK key not found in: {firebase_key_paths}")
        print("📝 Please upload your Firebase Admin SDK JSON file to /opt/flutter/")
        exit(1)
    
    print(f"✅ Found Firebase Admin SDK key: {firebase_key}")
    
    cred = credentials.Certificate(firebase_key)
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized successfully")
    
    return firestore.client()

# Sample review comments
REVIEW_COMMENTS = {
    5: [
        "Excellent quality! Fresh products and fast delivery. Highly recommended!",
        "Amazing service! The products exceeded my expectations. Will order again!",
        "Outstanding! Best quality products I've received. Very satisfied!",
        "Perfect! The farmer was very responsive and professional. Great experience!",
        "Exceptional quality and service. Everything was as described. Five stars!",
    ],
    4: [
        "Very good quality products. Delivery was on time. Satisfied with the purchase.",
        "Good experience overall. Products were fresh but packaging could be better.",
        "Great products! Minor delay in delivery but quality was worth the wait.",
        "Nice products and good communication. Would buy again.",
        "Satisfied with the order. Good quality and reasonable prices.",
    ],
    3: [
        "Decent products. Quality was okay but not exceptional.",
        "Average experience. Products were acceptable but room for improvement.",
        "Fair quality. Expected slightly better based on description.",
        "Okay experience. Products were fine but nothing special.",
        "Acceptable quality. Some items were better than others.",
    ],
    2: [
        "Below expectations. Quality was not as good as described.",
        "Disappointing. Products did not meet the standards shown in photos.",
        "Not very satisfied. Some products were not fresh enough.",
        "Could be better. Quality issues with some items.",
        "Not impressed. Expected better quality for the price.",
    ],
    1: [
        "Very disappointed. Products were not fresh and quality was poor.",
        "Terrible experience. Products were not as described at all.",
        "Not satisfied. Poor quality and late delivery.",
        "Would not recommend. Very poor quality products.",
        "Unacceptable quality. Products were damaged during delivery.",
    ],
}

# User names for reviews (mix of test users and realistic names)
REVIEWER_NAMES = [
    "Grace Namara", "Moses Mugabe", "Ngobi Peter", "Jolly Komuhendo", "Kiconco Debrah",
    "Sarah Nakato", "John Okello", "Mary Atim", "David Opio", "Rebecca Aber",
    "Patrick Okwir", "Jane Akello", "Samuel Odongo", "Lucy Auma", "Joseph Otim",
]

def get_existing_users(db):
    """Get existing users from Firestore"""
    users_ref = db.collection('users')
    users = users_ref.stream()
    
    user_list = []
    for user in users:
        user_data = user.to_dict()
        user_list.append({
            'id': user.id,
            'name': user_data.get('name', 'User'),
            'role': user_data.get('role', 'sme')
        })
    
    return user_list

def get_existing_farmers(users):
    """Filter users to get only farmers (SHG role)"""
    return [u for u in users if u['role'] == 'shg']

def get_existing_buyers(users):
    """Filter users to get only buyers (SME role)"""
    return [u for u in users if u['role'] == 'sme']

def get_existing_orders(db):
    """Get existing orders from Firestore"""
    orders_ref = db.collection('orders')
    orders = orders_ref.stream()
    
    order_list = []
    for order in orders:
        order_data = order.to_dict()
        order_list.append({
            'id': order.id,
            'buyer_id': order_data.get('buyer_id', ''),
            'buyer_name': order_data.get('buyer_name', ''),
            'farmer_id': order_data.get('farmer_id', ''),
            'farmer_name': order_data.get('farmer_name', ''),
            'status': order_data.get('status', ''),
            'created_at': order_data.get('created_at', ''),
        })
    
    return order_list

def create_farmer_rating(db, farmer_id, farmer_name, reviews):
    """Create or update farmer rating statistics"""
    if not reviews:
        return
    
    total_ratings = len(reviews)
    average_rating = sum(r['rating'] for r in reviews) / total_ratings
    
    # Calculate rating distribution
    rating_distribution = [0, 0, 0, 0, 0]
    for review in reviews:
        rating_index = int(review['rating']) - 1
        if 0 <= rating_index < 5:
            rating_distribution[rating_index] += 1
    
    rating_data = {
        'farmer_name': farmer_name,
        'average_rating': average_rating,
        'total_ratings': total_ratings,
        'total_orders': total_ratings,  # Assuming 1 review per order
        'total_deliveries': total_ratings,
        'rating_distribution': rating_distribution,
        'last_rated_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP,
    }
    
    db.collection('farmer_ratings').document(farmer_id).set(rating_data)
    print(f"  ✅ Created/updated rating for {farmer_name}: {average_rating:.1f}⭐ ({total_ratings} reviews)")

def create_review(db, order_id, buyer_id, buyer_name, farmer_id, farmer_name, rating, days_ago=0):
    """Create a single review"""
    review_id = f"review_{order_id}_{int(datetime.now().timestamp() * 1000)}"
    created_at = datetime.now() - timedelta(days=days_ago)
    
    # Select appropriate comment based on rating
    comment = random.choice(REVIEW_COMMENTS.get(rating, REVIEW_COMMENTS[3]))
    
    # 30% chance of having photos (only for ratings 4-5)
    has_photos = rating >= 4 and random.random() < 0.3
    photo_urls = []
    if has_photos:
        num_photos = random.randint(1, 3)
        photo_urls = [f"https://example.com/review_photo_{i}.jpg" for i in range(num_photos)]
    
    review_data = {
        'order_id': order_id,
        'user_id': buyer_id,
        'user_name': buyer_name,
        'farm_id': farmer_id,
        'product_id': None,  # Generic farmer review
        'rating': float(rating),
        'comment': comment if random.random() < 0.8 else None,  # 80% have comments
        'photo_urls': photo_urls,
        'created_at': created_at.isoformat(),
    }
    
    db.collection('reviews').document(review_id).set(review_data)
    return review_data

def main():
    print("================================================================================")
    print("🌟 CREATING TEST RATINGS & REVIEWS")
    print("================================================================================\n")
    
    # Initialize Firebase
    db = initialize_firebase()
    
    # Get existing data
    print("\n📊 Fetching existing data...")
    users = get_existing_users(db)
    farmers = get_existing_farmers(users)
    buyers = get_existing_buyers(users)
    orders = get_existing_orders(db)
    
    print(f"  📋 Found {len(users)} users ({len(farmers)} farmers, {len(buyers)} buyers)")
    print(f"  📋 Found {len(orders)} orders")
    
    if not farmers:
        print("\n❌ No farmers found. Please create farmers first.")
        return
    
    if not buyers:
        print("\n❌ No buyers found. Please create buyers first.")
        return
    
    # Create reviews for each farmer
    print("\n📝 Creating reviews for farmers...")
    total_reviews = 0
    
    for farmer in farmers:
        farmer_id = farmer['id']
        farmer_name = farmer['name']
        
        # Create 3-10 reviews per farmer
        num_reviews = random.randint(3, 10)
        print(f"\n  👨‍🌾 {farmer_name} ({num_reviews} reviews)")
        
        farmer_reviews = []
        
        for i in range(num_reviews):
            # Select random buyer
            buyer = random.choice(buyers)
            
            # Generate rating (weighted towards higher ratings)
            rating = random.choices(
                [5, 4, 3, 2, 1],
                weights=[50, 30, 15, 4, 1]  # 50% chance of 5 stars, etc.
            )[0]
            
            # Generate random order ID
            order_id = f"order_{int(datetime.now().timestamp() * 1000)}_{i}"
            
            # Create review with varied timestamps
            days_ago = random.randint(1, 60)
            review_data = create_review(
                db,
                order_id,
                buyer['id'],
                buyer['name'],
                farmer_id,
                farmer_name,
                rating,
                days_ago
            )
            
            farmer_reviews.append(review_data)
            total_reviews += 1
        
        # Create farmer rating statistics
        create_farmer_rating(db, farmer_id, farmer_name, farmer_reviews)
    
    print(f"\n================================================================================")
    print(f"SUMMARY")
    print(f"================================================================================\n")
    print(f"👨‍🌾 FARMERS WITH RATINGS: {len(farmers)}")
    print(f"⭐ TOTAL REVIEWS CREATED: {total_reviews}")
    print(f"📊 Average reviews per farmer: {total_reviews / len(farmers):.1f}")
    print(f"\n✅ Test ratings and reviews data created successfully!")
    print(f"\n================================================================================\n")

if __name__ == '__main__':
    main()
