#!/usr/bin/env python3
"""
Create test messages and notifications for testing messaging + notifications system.
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random

def create_test_data():
    """Create test messages and notifications."""
    try:
        # Initialize Firebase Admin SDK
        if not firebase_admin._apps:
            cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        
        print("=" * 80)
        print("CREATING TEST MESSAGES & NOTIFICATIONS")
        print("=" * 80)
        
        # Get some users for testing
        users = list(db.collection('users').limit(10).stream())
        
        if len(users) < 2:
            print("❌ Error: Need at least 2 users in database")
            return
        
        print(f"\n✅ Found {len(users)} users")
        
        #==================================================================
        # CREATE TEST CONVERSATIONS & MESSAGES
        #==================================================================
        print("\n\n📱 CREATING TEST CONVERSATIONS & MESSAGES...")
        print("-" * 80)
        
        conversations_created = []
        messages_created = 0
        
        # Create 5 conversations with messages
        for i in range(min(5, len(users) - 1)):
            user1 = users[i]
            user2 = users[i + 1]
            
            user1_data = user1.to_dict()
            user2_data = user2.to_dict()
            
            # Create conversation
            conversation_data = {
                'participant_ids': [user1.id, user2.id],
                'participant_names': {
                    user1.id: user1_data.get('name', 'User 1'),
                    user2.id: user2_data.get('name', 'User 2'),
                },
                'last_message': None,
                'last_message_time': None,
                'unread_count': {
                    user1.id: 0,
                    user2.id: 0,
                },
                'created_at': (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat(),
                'updated_at': datetime.now().isoformat(),
            }
            
            conv_ref = db.collection('conversations').add(conversation_data)
            conversation_id = conv_ref[1].id
            
            conversations_created.append({
                'id': conversation_id,
                'user1': user1_data.get('name'),
                'user2': user2_data.get('name'),
            })
            
            # Create 5-10 messages in this conversation
            num_messages = random.randint(5, 10)
            last_message_content = ''
            last_message_time = None
            unread_by_user2 = 0
            
            for j in range(num_messages):
                # Alternate between users
                is_user1_sender = (j % 2 == 0)
                sender_id = user1.id if is_user1_sender else user2.id
                sender_name = user1_data.get('name') if is_user1_sender else user2_data.get('name')
                
                message_texts = [
                    "Hi! How are you?",
                    "I'm interested in your products",
                    "Can you deliver to my location?",
                    "What's your best price?",
                    "Thank you for your order!",
                    "When can I expect delivery?",
                    "The products look great",
                    "I'll take 5kg please",
                    "Payment sent via mobile money",
                    "Order received. Thanks!",
                ]
                
                content = random.choice(message_texts)
                is_last_message = (j == num_messages - 1)
                message_time = datetime.now() - timedelta(hours=num_messages - j)
                
                # Mark last 2 messages as unread for user2
                is_read = not (is_last_message or j == num_messages - 2) if is_user1_sender else True
                
                if not is_read and not is_user1_sender:
                    unread_by_user2 += 1
                
                message_data = {
                    'conversation_id': conversation_id,
                    'sender_id': sender_id,
                    'sender_name': sender_name,
                    'content': content,
                    'type': 'text',
                    'attachment_url': None,
                    'is_read': is_read,
                    'created_at': message_time.isoformat(),
                }
                
                db.collection('messages').add(message_data)
                messages_created += 1
                
                if is_last_message:
                    last_message_content = content
                    last_message_time = message_time.isoformat()
            
            # Update conversation with last message
            db.collection('conversations').document(conversation_id).update({
                'last_message': last_message_content,
                'last_message_time': last_message_time,
                'unread_count': {
                    user1.id: 0,
                    user2.id: unread_by_user2,
                },
                'updated_at': datetime.now().isoformat(),
            })
            
            print(f"✅ Conversation {i+1}: {user1_data.get('name')} ↔ {user2_data.get('name')} ({num_messages} messages)")
        
        #==================================================================
        # CREATE TEST NOTIFICATIONS
        #==================================================================
        print("\n\n🔔 CREATING TEST NOTIFICATIONS...")
        print("-" * 80)
        
        notification_types = [
            ('order', 'New Order', 'You have received a new order for UGX 50,000'),
            ('order', 'Order Confirmed', 'Your order #ORD-2024-12345 has been confirmed'),
            ('payment', 'Payment Received', 'Payment of UGX 75,000 received successfully'),
            ('message', 'New Message', 'You have a new message from John Doe'),
            ('delivery', 'Order Shipped', 'Your order is on the way'),
            ('delivery', 'Order Delivered', 'Your order has been delivered successfully'),
            ('alert', 'Profile Incomplete', 'Complete your profile to start selling'),
            ('promotion', 'Special Offer', '20% off on all seeds this week!'),
            ('general', 'Welcome!', 'Welcome to SAYÉ KATALE marketplace'),
        ]
        
        notifications_created = 0
        
        # Create notifications for each user
        for user in users[:5]:  # First 5 users
            user_data = user.to_dict()
            
            # Create 3-5 random notifications per user
            num_notifications = random.randint(3, 5)
            
            for i in range(num_notifications):
                notif_type, title, message = random.choice(notification_types)
                
                # Make some notifications unread
                is_read = random.choice([True, True, False])  # 66% read, 33% unread
                
                notification_data = {
                    'user_id': user.id,
                    'type': notif_type,
                    'title': title,
                    'message': message,
                    'action_url': None,
                    'related_id': None,
                    'is_read': is_read,
                    'created_at': (datetime.now() - timedelta(hours=random.randint(1, 72))).isoformat(),
                }
                
                db.collection('notifications').add(notification_data)
                notifications_created += 1
            
            print(f"✅ Created {num_notifications} notifications for {user_data.get('name')}")
        
        #==================================================================
        # SUMMARY
        #==================================================================
        print("\n" + "=" * 80)
        print("SUMMARY")
        print("=" * 80)
        
        print(f"\n📱 CONVERSATIONS: {len(conversations_created)} created")
        for conv in conversations_created:
            print(f"   - {conv['user1']} ↔ {conv['user2']}")
        
        print(f"\n💬 MESSAGES: {messages_created} total messages created")
        print(f"🔔 NOTIFICATIONS: {notifications_created} total notifications created")
        
        print("\n\n🧪 TEST FEATURES:")
        print("-" * 80)
        print("✅ Conversation list with last message preview")
        print("✅ Unread message badges")
        print("✅ Message timestamps (relative)")
        print("✅ Real-time message updates (StreamBuilder)")
        print("✅ Message read/unread status")
        print("✅ Notification list with icons and colors")
        print("✅ Unread notification indicators")
        print("✅ Notification types (order, payment, message, delivery, etc.)")
        print("✅ Dismissible notifications")
        print("✅ Mark all as read functionality")
        
        print("\n\n📱 NEXT STEPS:")
        print("-" * 80)
        print("1. Open the Flutter app")
        print("2. Log in as any user")
        print("3. Go to Messages tab - see test conversations")
        print("4. Open a conversation - see message history")
        print("5. Send a test message - see real-time updates")
        print("6. Go to Notifications tab - see test notifications")
        print("7. Tap notification to mark as read")
        print("8. Swipe to dismiss notifications")
        print("9. Test unread badges on tabs")
        
        print("\n" + "=" * 80)
        print("✅ TEST DATA CREATED SUCCESSFULLY")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    create_test_data()
