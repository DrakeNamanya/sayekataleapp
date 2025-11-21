#!/bin/bash

# Firebase Functions Configuration Script
# Run this after rotating your PawaPay API key

echo "=============================================="
echo "Firebase Functions Setup for PawaPay"
echo "=============================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

echo "✅ Firebase CLI is installed"
echo ""

# Login to Firebase (if not already logged in)
echo "📝 Checking Firebase authentication..."
firebase login:list

echo ""
echo "=============================================="
echo "STEP 1: Set PawaPay API Token"
echo "=============================================="
echo ""
echo "⚠️  IMPORTANT: You need to provide your NEW PawaPay API token"
echo "   (after rotating the exposed key)"
echo ""
read -p "Enter your PawaPay API Token: " PAWAPAY_TOKEN

echo ""
echo "Setting PawaPay API token in Firebase Functions config..."
firebase functions:config:set pawapay.api_token="$PAWAPAY_TOKEN"

echo ""
echo "=============================================="
echo "STEP 2: Set Environment Mode"
echo "=============================================="
echo ""
echo "Choose deployment mode:"
echo "  1) Sandbox (for testing with test numbers)"
echo "  2) Production (for real transactions)"
echo ""
read -p "Enter your choice (1 or 2): " MODE_CHOICE

if [ "$MODE_CHOICE" = "1" ]; then
    echo "Setting mode to SANDBOX..."
    firebase functions:config:set pawapay.use_sandbox="true"
    echo "✅ Sandbox mode enabled"
elif [ "$MODE_CHOICE" = "2" ]; then
    echo "Setting mode to PRODUCTION..."
    firebase functions:config:set pawapay.use_sandbox="false"
    echo "✅ Production mode enabled"
else
    echo "❌ Invalid choice. Please run script again."
    exit 1
fi

echo ""
echo "=============================================="
echo "STEP 3: Verify Configuration"
echo "=============================================="
echo ""
firebase functions:config:get

echo ""
echo "=============================================="
echo "STEP 4: Deploy Cloud Functions"
echo "=============================================="
echo ""
read -p "Deploy Cloud Functions now? (y/n): " DEPLOY_CHOICE

if [ "$DEPLOY_CHOICE" = "y" ] || [ "$DEPLOY_CHOICE" = "Y" ]; then
    echo "Deploying Cloud Functions..."
    firebase deploy --only functions
    
    echo ""
    echo "=============================================="
    echo "✅ Deployment Complete!"
    echo "=============================================="
    echo ""
    echo "📝 Next Steps:"
    echo "1. Configure webhook URL in PawaPay Dashboard"
    echo "2. Test payment flow"
    echo "3. Monitor Firebase Functions logs"
    echo ""
else
    echo "Skipping deployment. Run 'firebase deploy --only functions' manually when ready."
fi

echo ""
echo "=============================================="
echo "Setup Complete!"
echo "=============================================="
