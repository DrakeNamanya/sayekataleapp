#!/bin/bash

# Script to verify and redeploy all Firebase Functions including initiatePayment
# Run this in Google Cloud Shell

echo "=============================================="
echo "🔍 Checking for initiatePayment Function"
echo "=============================================="

# Check if initiatePayment exists in functions/index.js
if grep -q "exports.initiatePayment" functions/index.js; then
    echo "✅ initiatePayment function found in functions/index.js"
else
    echo "❌ initiatePayment function NOT found in functions/index.js"
    echo "❌ This means the code needs to be updated"
    exit 1
fi

echo ""
echo "=============================================="
echo "📦 Checking Firebase Functions Configuration"
echo "=============================================="

# Check current configuration
echo "Current configuration:"
npx firebase functions:config:get

echo ""
echo "=============================================="
echo "🚀 Deploying All Functions"
echo "=============================================="

# Deploy all functions
npx firebase deploy --only functions

echo ""
echo "=============================================="
echo "✅ Deployment Complete!"
echo "=============================================="

echo ""
echo "Checking deployed functions..."
npx firebase functions:list

echo ""
echo "=============================================="
echo "📋 Post-Deployment Checklist"
echo "=============================================="
echo ""
echo "Verify these 4 functions are deployed:"
echo "  1. initiatePayment"
echo "  2. pawaPayWebhook"
echo "  3. pawaPayWebhookHealth"
echo "  4. manualActivateSubscription"
echo ""
echo "Test initiatePayment endpoint:"
echo "  curl https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment"
echo ""
echo "Expected: 405 Method Not Allowed (proves function exists)"
echo ""
