#!/usr/bin/env python3
"""
Create test orders in Firestore for comprehensive order system testing.
This script creates sample orders with different statuses to test the complete order workflow.
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random

def create_test_orders():
    """Create test orders in Firestore."""
    try:
        # Initialize Firebase Admin SDK
        if not firebase_admin._apps:
            cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        
        print("=" * 80)
        print("CREATING TEST ORDERS FOR ORDER SYSTEM TESTING")
        print("=" * 80)
        
        # Get some users to use as buyers and farmers
        users = list(db.collection('users').limit(10).stream())
        
        if len(users) < 2:
            print("❌ Error: Need at least 2 users in database to create test orders")
            print("Please register some users first")
            return
        
        # Separate into potential buyers (SME) and farmers (SHG)
        buyers = [u for u in users if u.to_dict().get('role') == 'sme']
        farmers = [u for u in users if u.to_dict().get('role') == 'shg']
        
        # If not enough role-specific users, use any users
        if len(buyers) == 0:
            buyers = users[:len(users)//2]
        if len(farmers) == 0:
            farmers = users[len(users)//2:]
        
        print(f"\n✅ Found {len(buyers)} potential buyers and {len(farmers)} potential farmers")
        
        # Get some products
        products = list(db.collection('products').limit(20).stream())
        
        if len(products) == 0:
            print("❌ Error: No products found in database")
            print("Please create some products first")
            return
        
        print(f"✅ Found {len(products)} products for orders")
        
        # Order statuses to test
        statuses = [
            'pending',
            'confirmed',
            'preparing',
            'ready',
            'inTransit',
            'delivered',
            'completed',
            'rejected',
            'cancelled'
        ]
        
        # Payment methods
        payment_methods = ['cash', 'mobileMoney', 'bankTransfer']
        
        # Create 15 test orders with different statuses
        print("\n📦 Creating test orders...")
        created_orders = []
        
        for i in range(15):
            buyer = random.choice(buyers)
            buyer_data = buyer.to_dict()
            
            farmer = random.choice(farmers)
            farmer_data = farmer.to_dict()
            
            # Select 1-3 random products for this order
            num_items = random.randint(1, 3)
            order_products = random.sample(products, min(num_items, len(products)))
            
            # Create order items
            items = []
            total_amount = 0.0
            
            for product_doc in order_products:
                product = product_doc.to_dict()
                quantity = random.randint(1, 5)
                price = product.get('price', 5000)
                subtotal = price * quantity
                
                items.append({
                    'product_id': product_doc.id,
                    'product_name': product.get('name', 'Product'),
                    'product_image': product.get('image_url', 'https://via.placeholder.com/200'),
                    'price': price,
                    'unit': product.get('unit', 'kg'),
                    'quantity': quantity,
                    'subtotal': subtotal
                })
                
                total_amount += subtotal
            
            # Generate order number
            timestamp = int((datetime.now() - timedelta(days=random.randint(0, 30))).timestamp() * 1000)
            order_number = f"ORD-2024-{timestamp % 100000:05d}"
            
            # Assign status (cycle through statuses for variety)
            status = statuses[i % len(statuses)]
            
            # Create order data
            order_data = {
                'order_number': order_number,
                'buyer_id': buyer.id,
                'buyer_name': buyer_data.get('name', 'Test Buyer'),
                'buyer_phone': buyer_data.get('phone', '+256700000000'),
                'buyer_system_id': buyer_data.get('national_id'),
                'farmer_id': farmer.id,
                'farmer_name': farmer_data.get('name', 'Test Farmer'),
                'farmer_phone': farmer_data.get('phone', '+256700000001'),
                'farmer_system_id': farmer_data.get('national_id'),
                'items': items,
                'total_amount': total_amount,
                'status': status,
                'payment_method': random.choice(payment_methods),
                'delivery_address': 'Test Address, Kampala, Uganda',
                'delivery_notes': 'Please call when arriving' if random.choice([True, False]) else None,
                'created_at': datetime.now() - timedelta(days=random.randint(0, 30)),
                'updated_at': datetime.now(),
                'is_received_by_buyer': False,
            }
            
            # Add timestamps based on status
            if status in ['confirmed', 'preparing', 'ready', 'inTransit', 'delivered', 'completed']:
                order_data['confirmed_at'] = order_data['created_at'] + timedelta(hours=1)
            
            if status == 'rejected':
                order_data['rejected_at'] = order_data['created_at'] + timedelta(hours=1)
                order_data['rejection_reason'] = random.choice([
                    'Out of stock',
                    'Cannot deliver to location',
                    'Product no longer available',
                    'Incorrect pricing'
                ])
            
            if status in ['delivered', 'completed']:
                order_data['delivered_at'] = order_data['created_at'] + timedelta(days=2)
                order_data['is_received_by_buyer'] = True
            
            if status == 'completed':
                order_data['received_at'] = order_data['created_at'] + timedelta(days=2, hours=1)
                order_data['rating'] = random.randint(3, 5)
                order_data['review'] = random.choice([
                    'Great quality products!',
                    'Fast delivery, thank you',
                    'Very fresh and good',
                    'Excellent service',
                    'Will order again'
                ])
                order_data['reviewed_at'] = order_data['received_at']
            
            # Save order to Firestore
            doc_ref = db.collection('orders').add(order_data)
            order_id = doc_ref[1].id
            
            created_orders.append({
                'id': order_id,
                'order_number': order_number,
                'buyer': buyer_data.get('name'),
                'farmer': farmer_data.get('name'),
                'items': len(items),
                'total': total_amount,
                'status': status
            })
            
            print(f"✅ Created order {i+1}/15: {order_number} - {status} - UGX {total_amount:,.0f}")
        
        print("\n" + "=" * 80)
        print("SUMMARY OF CREATED TEST ORDERS")
        print("=" * 80)
        
        for order in created_orders:
            print(f"\n📦 Order: {order['order_number']}")
            print(f"   Status: {order['status']}")
            print(f"   Buyer: {order['buyer']} → Farmer: {order['farmer']}")
            print(f"   Items: {order['items']} | Total: UGX {order['total']:,.0f}")
        
        # Count orders by status
        print("\n\n📊 ORDERS BY STATUS:")
        print("-" * 80)
        status_counts = {}
        for order in created_orders:
            status = order['status']
            status_counts[status] = status_counts.get(status, 0) + 1
        
        for status, count in sorted(status_counts.items()):
            print(f"   {status.ljust(15)}: {count} order(s)")
        
        print("\n" + "=" * 80)
        print(f"✅ SUCCESS: Created {len(created_orders)} test orders")
        print("=" * 80)
        
        print("\n\n🧪 TEST CASES COVERED:")
        print("-" * 80)
        print("✅ Pending orders (waiting for farmer confirmation)")
        print("✅ Confirmed orders (farmer accepted)")
        print("✅ Orders in preparation")
        print("✅ Orders ready for pickup/delivery")
        print("✅ Orders in transit")
        print("✅ Delivered orders")
        print("✅ Completed orders (with ratings/reviews)")
        print("✅ Rejected orders (with rejection reasons)")
        print("✅ Cancelled orders")
        print("\n✅ Multiple items per order")
        print("✅ Different payment methods")
        print("✅ Delivery addresses and notes")
        print("✅ Order timestamps (created, confirmed, delivered, etc.)")
        print("\n" + "=" * 80)
        
        print("\n\n📱 NEXT STEPS:")
        print("-" * 80)
        print("1. Open the Flutter app in your browser")
        print("2. Log in as a BUYER (SME) to view and track orders")
        print("3. Log in as a FARMER (SHG) to manage incoming orders")
        print("4. Test order status updates:")
        print("   - Accept/Reject pending orders")
        print("   - Update order status through workflow")
        print("   - Track deliveries")
        print("   - Submit ratings/reviews")
        print("\n" + "=" * 80)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    create_test_orders()
