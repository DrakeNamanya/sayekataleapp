#!/bin/bash

# ========================================
# PawaPay Integration - Cloud Shell Deployment Script
# ========================================
# This script deploys the complete PawaPay integration including
# the initiatePayment function that was missing.
#
# Run this in Google Cloud Shell:
# bash <(curl -s https://raw.githubusercontent.com/DrakeNamanya/sayekataleapp/main/DEPLOY_IN_CLOUD_SHELL.sh)
# ========================================

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   PawaPay Integration - Complete Deployment                   ║"
echo "║   Including Missing initiatePayment Function                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Clean up old repository
echo "📦 Step 1/7: Cleaning up old repository..."
cd ~
if [ -d "sayekataleapp" ]; then
    echo "   Removing old sayekataleapp directory..."
    rm -rf sayekataleapp
fi

# Step 2: Clone fresh from GitHub
echo ""
echo "📥 Step 2/7: Cloning latest code from GitHub..."
git clone https://github.com/DrakeNamanya/sayekataleapp.git
cd sayekataleapp

# Step 3: Verify initiatePayment function exists
echo ""
echo "🔍 Step 3/7: Verifying initiatePayment function..."
if grep -q "exports.initiatePayment" functions/index.js; then
    echo "   ✅ initiatePayment function found!"
else
    echo "   ❌ ERROR: initiatePayment function not found!"
    echo "   The latest code may not have been pulled correctly."
    exit 1
fi

# Step 4: Check all exported functions
echo ""
echo "📋 Step 4/7: Listing all exported functions..."
echo "   Functions found:"
grep "exports\." functions/index.js | grep -o "exports\.[a-zA-Z]*" | sort | uniq | sed 's/^/      - /'

# Expected output:
# - exports.initiatePayment          ← THIS WAS MISSING!
# - exports.manualActivateSubscription
# - exports.pawaPayWebhook
# - exports.pawaPayWebhookHealth

# Step 5: Check Firebase configuration
echo ""
echo "⚙️  Step 5/7: Checking Firebase configuration..."
firebase functions:config:get || {
    echo ""
    echo "❌ ERROR: Firebase configuration not found!"
    echo ""
    echo "You need to configure PawaPay settings first:"
    echo ""
    echo "   firebase functions:config:set pawapay.api_token=\"YOUR_API_TOKEN\""
    echo "   firebase functions:config:set pawapay.use_sandbox=\"false\""
    echo ""
    echo "After configuring, run this script again."
    exit 1
}

# Step 6: Install dependencies
echo ""
echo "📦 Step 6/7: Installing Node.js dependencies..."
cd functions
npm install
cd ..

# Step 7: Deploy functions
echo ""
echo "🚀 Step 7/7: Deploying all functions to Firebase..."
echo ""
echo "   This will deploy 4 functions:"
echo "      1. initiatePayment          ← The missing function!"
echo "      2. pawaPayWebhook"
echo "      3. pawaPayWebhookHealth"
echo "      4. manualActivateSubscription"
echo ""

firebase deploy --only functions

# Verify deployment
echo ""
echo "✅ Deployment completed!"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Verifying Deployed Functions                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

firebase functions:list

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Testing Endpoints                                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Test webhook health endpoint
echo "1️⃣ Testing pawaPayWebhookHealth..."
HEALTH_URL="https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth"
curl -s "$HEALTH_URL" | head -3
echo ""

# Test initiatePayment endpoint (should return method not allowed for GET)
echo ""
echo "2️⃣ Testing initiatePayment (should reject GET requests)..."
INITIATE_URL="https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment"
curl -s -X GET "$INITIATE_URL"
echo ""

# Show function URLs
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Deployment Successful! 🎉                                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Function URLs:"
echo ""
echo "   initiatePayment:          $INITIATE_URL"
echo "   pawaPayWebhook:           https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook"
echo "   pawaPayWebhookHealth:     $HEALTH_URL"
echo "   manualActivateSubscription: https://us-central1-sayekataleapp.cloudfunctions.net/manualActivateSubscription"
echo ""
echo "Next steps:"
echo ""
echo "1. Install app-release.apk on your phone"
echo "2. Log in with: drnamanya@gmail.com"
echo "3. Navigate to Premium Subscription"
echo "4. Enter your Uganda mobile number (MTN/Airtel)"
echo "5. You should receive a mobile money PIN prompt!"
echo ""
echo "Monitor Firebase Console Logs for payment processing:"
echo "   https://console.firebase.google.com/project/sayekataleapp/functions/logs"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Troubleshooting                                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "If payment doesn't work:"
echo ""
echo "1. Check Firebase logs:"
echo "   firebase functions:log --only initiatePayment"
echo ""
echo "2. Verify PawaPay webhook configuration:"
echo "   URL: https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook"
echo "   Event: deposit.status.updated"
echo ""
echo "3. Check Firestore transactions collection for error details"
echo ""
echo "Documentation:"
echo "   - DEPLOYMENT_INSTRUCTIONS.md"
echo "   - PRODUCTION_CONFIG.md"
echo "   - PAWAPAY_COMPARISON_ANALYSIS.md"
echo "   - MISSING_FUNCTION_FIX.md"
echo ""
