#!/usr/bin/env python3
"""
PawaPay Webhook Handler for SayeKatale App

This webhook receives callbacks from PawaPay for:
- Deposit status updates (COMPLETED, FAILED, etc.)
- Payout/Refund status updates

Configure this URL in PawaPay Dashboard:
https://your-domain.com/api/pawapay/webhook

For local testing with ngrok:
ngrok http 5555
Then use: https://xxxx.ngrok.io/api/pawapay/webhook
"""

from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import hashlib
import hmac
import json
import os

app = Flask(__name__)

# Initialize Firebase Admin SDK
# Support both local development and Cloud Run deployment
cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', '/opt/flutter/firebase-admin-sdk.json')

if not firebase_admin._apps:
    # Try using credentials file first
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print(f'✅ Firebase initialized with credentials file: {cred_path}')
    else:
        # Fall back to default credentials (Cloud Run uses this)
        try:
            firebase_admin.initialize_app()
            print('✅ Firebase initialized with default credentials (Cloud Run)')
        except Exception as e:
            print(f'❌ Firebase initialization failed: {e}')
            raise

db = firestore.client()

# PawaPay API token for signature verification (optional but recommended)
PAWAPAY_API_TOKEN = os.getenv('PAWAPAY_API_TOKEN', 'eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4ODY1ODk1LCJpYXQiOjE3NjMzMzMwOTUsInBtIjoiREFGLFBBRiIsImp0aSI6IjI3OWJlNGZlLTk1ZTgtNGYwMy1iNmU3LWNhZGQ0N2MwODQ0NCJ9.gEZrCzNiIsln3stFyfe6CGAcbdKCKBsbiA07yAalylNmRSupCdxek6DQWO_mOQGxAnP4CO7G-Rxzg-QkOdUb6Q')


def verify_signature(payload, signature, token):
    """
    Verify PawaPay webhook signature (optional but recommended for production)
    """
    if not signature:
        return True  # Skip verification if no signature provided
    
    expected_signature = hmac.new(
        token.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(expected_signature, signature)


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'PawaPay Webhook Handler',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@app.route('/api/pawapay/webhook', methods=['POST'])
def pawapay_webhook():
    """
    PawaPay Webhook Handler
    
    Handles callbacks for:
    - Deposits (collections from customers)
    - Payouts (sending money to customers)
    - Refunds
    """
    try:
        # Get request data
        payload = request.get_data(as_text=True)
        data = request.get_json()
        
        # Optional: Verify signature for security
        signature = request.headers.get('X-PawaPay-Signature', '')
        if not verify_signature(payload, signature, PAWAPAY_API_TOKEN):
            print('❌ Invalid signature')
            return jsonify({'error': 'Invalid signature'}), 401
        
        print(f'📥 Webhook received: {json.dumps(data, indent=2)}')
        
        # Determine callback type
        if 'depositId' in data:
            return handle_deposit_callback(data)
        elif 'payoutId' in data:
            return handle_payout_callback(data)
        elif 'refundId' in data:
            return handle_refund_callback(data)
        else:
            print('⚠️ Unknown callback type')
            return jsonify({'error': 'Unknown callback type'}), 400
            
    except Exception as e:
        print(f'❌ Webhook error: {str(e)}')
        return jsonify({'error': str(e)}), 500


def handle_deposit_callback(data):
    """
    Handle deposit callback from PawaPay
    
    Expected data:
    {
        "depositId": "uuid",
        "status": "COMPLETED" | "FAILED" | "REJECTED",
        "amount": "10000.00",
        "currency": "UGX",
        "correspondent": "MTN_MOMO_UGA",
        "payer": {
            "type": "MSISDN",
            "address": {"value": "256712345678"}
        },
        "reason": "Optional failure reason"
    }
    """
    try:
        deposit_id = data.get('depositId')
        status = data.get('status')
        amount = float(data.get('amount', 0))
        reason = data.get('reason', '')
        
        print(f'💰 Deposit callback: {deposit_id} - Status: {status}')
        
        # Find transaction in Firestore by reference_id
        transactions_ref = db.collection('transactions')
        query = transactions_ref.where('reference_id', '==', deposit_id).limit(1)
        docs = query.stream()
        
        transaction_doc = None
        for doc in docs:
            transaction_doc = doc
            break
        
        if not transaction_doc:
            print(f'⚠️ Transaction not found for deposit: {deposit_id}')
            return jsonify({'warning': 'Transaction not found'}), 200
        
        transaction_data = transaction_doc.to_dict()
        wallet_id = transaction_data.get('wallet_id')
        
        # Update transaction status based on PawaPay status
        if status == 'COMPLETED':
            # Update transaction to completed
            transaction_doc.reference.update({
                'status': 'completed',
                'updated_at': firestore.SERVER_TIMESTAMP
            })
            
            # Update wallet balance
            wallet_ref = db.collection('wallets').document(wallet_id)
            wallet_doc = wallet_ref.get()
            
            if wallet_doc.exists:
                wallet_data = wallet_doc.to_dict()
                current_balance = wallet_data.get('balance', 0)
                current_pending = wallet_data.get('pending_balance', 0)
                
                # Add to balance, remove from pending
                new_balance = current_balance + amount
                new_pending = max(0, current_pending - amount)
                
                wallet_ref.update({
                    'balance': new_balance,
                    'pending_balance': new_pending,
                    'updated_at': firestore.SERVER_TIMESTAMP
                })
                
                print(f'✅ Deposit completed: UGX {amount} added to wallet {wallet_id}')
                print(f'   New balance: UGX {new_balance}')
            
        elif status in ['FAILED', 'REJECTED']:
            # Update transaction to failed
            transaction_doc.reference.update({
                'status': 'failed',
                'description': reason or f'Deposit {status.lower()}',
                'updated_at': firestore.SERVER_TIMESTAMP
            })
            
            # Remove from pending balance
            wallet_ref = db.collection('wallets').document(wallet_id)
            wallet_doc = wallet_ref.get()
            
            if wallet_doc.exists:
                wallet_data = wallet_doc.to_dict()
                current_pending = wallet_data.get('pending_balance', 0)
                new_pending = max(0, current_pending - amount)
                
                wallet_ref.update({
                    'pending_balance': new_pending,
                    'updated_at': firestore.SERVER_TIMESTAMP
                })
                
                print(f'❌ Deposit failed: {reason}')
        
        return jsonify({'success': True, 'message': f'Deposit {status.lower()} processed'}), 200
        
    except Exception as e:
        print(f'❌ Deposit callback error: {str(e)}')
        return jsonify({'error': str(e)}), 500


def handle_payout_callback(data):
    """
    Handle payout/withdrawal callback from PawaPay
    """
    try:
        payout_id = data.get('payoutId')
        status = data.get('status')
        amount = float(data.get('amount', 0))
        reason = data.get('reason', '')
        
        print(f'💸 Payout callback: {payout_id} - Status: {status}')
        
        # Find transaction
        transactions_ref = db.collection('transactions')
        query = transactions_ref.where('reference_id', '==', payout_id).limit(1)
        docs = query.stream()
        
        transaction_doc = None
        for doc in docs:
            transaction_doc = doc
            break
        
        if not transaction_doc:
            print(f'⚠️ Transaction not found for payout: {payout_id}')
            return jsonify({'warning': 'Transaction not found'}), 200
        
        transaction_data = transaction_doc.to_dict()
        wallet_id = transaction_data.get('wallet_id')
        
        # Update transaction status
        if status == 'COMPLETED':
            transaction_doc.reference.update({
                'status': 'completed',
                'updated_at': firestore.SERVER_TIMESTAMP
            })
            print(f'✅ Payout completed: UGX {amount} sent to user')
            
        elif status in ['FAILED', 'REJECTED']:
            # Refund the amount back to wallet
            transaction_doc.reference.update({
                'status': 'failed',
                'description': reason or f'Payout {status.lower()}',
                'updated_at': firestore.SERVER_TIMESTAMP
            })
            
            wallet_ref = db.collection('wallets').document(wallet_id)
            wallet_doc = wallet_ref.get()
            
            if wallet_doc.exists:
                wallet_data = wallet_doc.to_dict()
                current_balance = wallet_data.get('balance', 0)
                
                # Refund amount back to wallet
                new_balance = current_balance + amount
                
                wallet_ref.update({
                    'balance': new_balance,
                    'updated_at': firestore.SERVER_TIMESTAMP
                })
                
                print(f'♻️ Payout failed, refunded UGX {amount} to wallet')
        
        return jsonify({'success': True, 'message': f'Payout {status.lower()} processed'}), 200
        
    except Exception as e:
        print(f'❌ Payout callback error: {str(e)}')
        return jsonify({'error': str(e)}), 500


def handle_refund_callback(data):
    """
    Handle refund callback from PawaPay
    """
    try:
        refund_id = data.get('refundId')
        status = data.get('status')
        amount = float(data.get('amount', 0))
        deposit_id = data.get('depositId', '')
        
        print(f'♻️ Refund callback: {refund_id} - Status: {status}')
        
        if status == 'COMPLETED':
            # Create refund transaction record
            # Find original deposit transaction
            transactions_ref = db.collection('transactions')
            query = transactions_ref.where('reference_id', '==', deposit_id).limit(1)
            docs = query.stream()
            
            original_transaction = None
            for doc in docs:
                original_transaction = doc.to_dict()
                break
            
            if original_transaction:
                wallet_id = original_transaction.get('wallet_id')
                
                # Create refund transaction
                refund_transaction = {
                    'wallet_id': wallet_id,
                    'type': 'refund',
                    'amount': amount,
                    'status': 'completed',
                    'reference_id': refund_id,
                    'description': f'Refund for deposit {deposit_id}',
                    'created_at': firestore.SERVER_TIMESTAMP,
                    'updated_at': firestore.SERVER_TIMESTAMP
                }
                
                db.collection('transactions').add(refund_transaction)
                print(f'✅ Refund completed: UGX {amount}')
        
        return jsonify({'success': True, 'message': f'Refund {status.lower()} processed'}), 200
        
    except Exception as e:
        print(f'❌ Refund callback error: {str(e)}')
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # Support both local and Cloud Run deployment
    port = int(os.getenv('PORT', 5555))
    
    print('🚀 Starting PawaPay Webhook Server...')
    print(f'📍 Webhook URL: http://localhost:{port}/api/pawapay/webhook')
    print(f'🏥 Health check: http://localhost:{port}/health')
    print('')
    print('⚠️ For production, configure this URL in PawaPay Dashboard:')
    print('   Settings → Webhooks → Add URL')
    print('')
    
    # Run on specified port (5555 for local, 8080 for Cloud Run)
    app.run(host='0.0.0.0', port=port, debug=False)
