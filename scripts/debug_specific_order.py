#!/usr/bin/env python3
"""
Debug Specific Order - Show ALL fields and identify empty values
=================================================================

This script will show complete order data to find which field is empty.

Usage:
    python3 debug_specific_order.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys
import json

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized successfully\n")
except Exception as e:
    print(f"❌ Failed to initialize Firebase Admin SDK: {e}")
    sys.exit(1)

db = firestore.client()


def debug_order(order_number="ORD-2025-242062"):
    """Debug specific order and show all fields"""
    print("="*80)
    print(f"🔍 DEBUGGING ORDER: {order_number}")
    print("="*80 + "\n")
    
    try:
        # Find order by order_number
        orders_ref = db.collection('orders')
        query = orders_ref.where('order_number', '==', order_number).limit(1)
        docs = query.get()
        
        if not docs:
            print(f"❌ Order {order_number} not found!")
            return
        
        for doc in docs:
            data = doc.to_dict()
            
            print(f"📦 Order ID: {doc.id}\n")
            print("="*80)
            print("📋 COMPLETE ORDER DATA")
            print("="*80 + "\n")
            
            # Print all fields in sorted order
            for key in sorted(data.keys()):
                value = data[key]
                
                # Check if value is empty, None, or empty string
                is_empty = value is None or value == '' or value == []
                marker = "❌ EMPTY" if is_empty else "✅"
                
                print(f"{marker} {key}: {repr(value)}")
            
            print("\n" + "="*80)
            print("🔍 CRITICAL FIELDS FOR DELIVERY TRACKING")
            print("="*80 + "\n")
            
            # Check critical fields
            critical_fields = [
                'buyer_id', 'buyerId',
                'seller_id', 'sellerId', 
                'farmer_id', 'farmerId',
                'order_id', 'orderId',
            ]
            
            print("Fields used in confirmOrder() and _createDeliveryTracking():\n")
            
            for field in critical_fields:
                value = data.get(field)
                if value is None or value == '':
                    print(f"❌ {field}: MISSING OR EMPTY")
                elif '-' in str(value) and len(str(value)) < 20:
                    print(f"⚠️  {field}: {value} (looks like system ID, not Firebase UID)")
                else:
                    print(f"✅ {field}: {value}")
            
            print("\n" + "="*80)
            print("👥 USER PROFILE CHECK")
            print("="*80 + "\n")
            
            # Check if users exist
            seller_id = data.get('seller_id') or data.get('sellerId') or data.get('farmer_id') or data.get('farmerId')
            buyer_id = data.get('buyer_id') or data.get('buyerId')
            
            if seller_id:
                print(f"Checking seller: {seller_id}")
                try:
                    seller_doc = db.collection('users').document(seller_id).get()
                    if seller_doc.exists:
                        seller_data = seller_doc.to_dict()
                        print(f"  ✅ Seller found: {seller_data.get('name', 'N/A')}")
                        print(f"     Email: {seller_data.get('email', 'N/A')}")
                        print(f"     Location: {seller_data.get('location', 'N/A')}")
                    else:
                        print(f"  ❌ Seller document NOT FOUND!")
                except Exception as e:
                    print(f"  ❌ Error checking seller: {e}")
            else:
                print("❌ No seller_id found in order!")
            
            print()
            
            if buyer_id:
                print(f"Checking buyer: {buyer_id}")
                try:
                    buyer_doc = db.collection('users').document(buyer_id).get()
                    if buyer_doc.exists:
                        buyer_data = buyer_doc.to_dict()
                        print(f"  ✅ Buyer found: {buyer_data.get('name', 'N/A')}")
                        print(f"     Email: {buyer_data.get('email', 'N/A')}")
                        print(f"     Location: {buyer_data.get('location', 'N/A')}")
                    else:
                        print(f"  ❌ Buyer document NOT FOUND!")
                except Exception as e:
                    print(f"  ❌ Error checking buyer: {e}")
            else:
                print("❌ No buyer_id found in order!")
            
            print("\n" + "="*80)
            print("🎯 LIKELY CAUSE OF ERROR")
            print("="*80 + "\n")
            
            # Identify the issue
            empty_fields = []
            for field in critical_fields:
                value = data.get(field)
                if value is None or value == '':
                    empty_fields.append(field)
            
            if empty_fields:
                print(f"❌ FOUND EMPTY FIELDS: {', '.join(empty_fields)}")
                print()
                print("The error 'Function doc() cannot be called with an empty path'")
                print("is likely caused by one of these empty fields being used in:")
                print("  - await _firestore.collection('users').doc(order.farmerId).get()")
                print("  - await _firestore.collection('users').doc(order.buyerId).get()")
                print()
            else:
                print("✅ No empty critical fields found")
                print()
                print("If error still occurs, check:")
                print("  1. Order.fromFirestore() might be setting fields to null")
                print("  2. Dart code might be using wrong field name")
                print("  3. Field might exist in Firestore but null in Dart object")
    
    except Exception as e:
        print(f"❌ Error: {e}")


def main():
    """Main execution flow"""
    print("\n" + "="*80)
    print("🐛 ORDER DEBUG TOOL")
    print("="*80 + "\n")
    
    debug_order()
    
    print("\n" + "="*80 + "\n")


if __name__ == "__main__":
    main()
