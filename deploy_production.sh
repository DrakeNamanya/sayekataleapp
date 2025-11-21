#!/bin/bash

# Production Deployment Script
# Automated deployment with new PawaPay API key

set -e  # Exit on error

echo "=============================================="
echo "🚀 PawaPay Production Deployment"
echo "=============================================="
echo ""

# Configuration
PAWAPAY_TOKEN="eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc5MjQxMTE4LCJpYXQiOjE3NjM3MDgzMTgsInBtIjoiREFGLFBBRiIsImp0aSI6Ijk3YmJjM2Y2LTFiY2MtNDBlMS05ZTA1LWZkNjYyODRiODAzMSJ9.85FNrfBkh_RqiTR8sD-Ey7FWdPX3Ul56E7n2VixllH8c-qTu8JxeR-KB4rbcnVTyXXsr92Ph_0fZP4ju7rF8dg"
WEBHOOK_URL="https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook"
PROJECT_ID="sayekataleapp"

echo "✅ New API Key: ${PAWAPAY_TOKEN:0:50}..."
echo "✅ Webhook URL: $WEBHOOK_URL"
echo "✅ Project ID: $PROJECT_ID"
echo ""

# Step 1: Check Firebase CLI
echo "=============================================="
echo "Step 1: Checking Firebase CLI"
echo "=============================================="

if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found"
    echo "Installing Firebase CLI..."
    npm install -g firebase-tools
else
    echo "✅ Firebase CLI found"
fi
echo ""

# Step 2: Set Firebase project
echo "=============================================="
echo "Step 2: Setting Firebase Project"
echo "=============================================="

firebase use $PROJECT_ID
echo "✅ Project set to: $PROJECT_ID"
echo ""

# Step 3: Configure PawaPay API Token
echo "=============================================="
echo "Step 3: Configuring PawaPay API Token"
echo "=============================================="

firebase functions:config:set pawapay.api_token="$PAWAPAY_TOKEN"
echo "✅ PawaPay API token configured"
echo ""

# Step 4: Set Production Mode
echo "=============================================="
echo "Step 4: Setting Production Mode"
echo "=============================================="

firebase functions:config:set pawapay.use_sandbox="false"
echo "✅ Production mode enabled"
echo ""

# Step 5: Verify Configuration
echo "=============================================="
echo "Step 5: Verifying Configuration"
echo "=============================================="

echo "Current Firebase Functions config:"
firebase functions:config:get
echo ""

# Step 6: Deploy Cloud Functions
echo "=============================================="
echo "Step 6: Deploying Cloud Functions"
echo "=============================================="

cd /home/user/flutter_app
firebase deploy --only functions

echo ""
echo "=============================================="
echo "✅ Deployment Complete!"
echo "=============================================="
echo ""

# Step 7: Test Deployment
echo "=============================================="
echo "Step 7: Testing Deployment"
echo "=============================================="

echo "Testing webhook health endpoint..."
curl -s https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth | python3 -m json.tool

echo ""
echo "=============================================="
echo "📋 Post-Deployment Checklist"
echo "=============================================="
echo ""
echo "✅ API Token: Configured"
echo "✅ Production Mode: Enabled"
echo "✅ Cloud Functions: Deployed"
echo "✅ Webhook URL: $WEBHOOK_URL"
echo ""
echo "📝 Next Steps:"
echo "1. ✅ Verify webhook is configured in PawaPay Dashboard"
echo "2. ⏳ Build and install production APK"
echo "3. ⏳ Test payment with real mobile money number"
echo "4. ⏳ Monitor Firebase Functions logs"
echo ""
echo "🔗 Important Links:"
echo "   Firebase Logs: https://console.firebase.google.com/project/sayekataleapp/functions/logs"
echo "   Firestore: https://console.firebase.google.com/project/sayekataleapp/firestore"
echo "   PawaPay Dashboard: https://dashboard.pawapay.io/"
echo ""
echo "=============================================="
echo "🎉 Ready for Production Testing!"
echo "=============================================="
