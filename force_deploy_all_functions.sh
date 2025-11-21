#!/bin/bash

echo "=============================================="
echo "🔧 Force Deploy All Firebase Functions"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "This script will:"
echo "  1. Clean local cache"
echo "  2. Pull latest code from GitHub"
echo "  3. Verify all 4 functions exist"
echo "  4. Force redeploy all functions"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "Step 1: Cleaning local Firebase cache..."
cd ~/sayekataleapp
rm -rf functions/node_modules
rm -rf functions/.firebase
rm -f .firebase/*/cache/*
echo -e "${GREEN}✅ Cache cleaned${NC}"

echo ""
echo "Step 2: Pulling latest code from GitHub..."
git pull origin main
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Code updated${NC}"
else
    echo -e "${RED}❌ Failed to pull code${NC}"
    exit 1
fi

echo ""
echo "Step 3: Verifying function exports..."
cd ~/sayekataleapp

# Check for all 4 functions
FUNCTIONS=(
    "initiatePayment"
    "pawaPayWebhook"
    "pawaPayWebhookHealth"
    "manualActivateSubscription"
)

echo "Checking functions/index.js for exports:"
for func in "${FUNCTIONS[@]}"; do
    if grep -q "exports.$func" functions/index.js; then
        echo -e "  ${GREEN}✅ $func${NC}"
    else
        echo -e "  ${RED}❌ $func MISSING${NC}"
        exit 1
    fi
done

echo ""
echo "Step 4: Installing dependencies..."
cd functions
npm install
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi
cd ..

echo ""
echo "Step 5: Force deploying all functions..."
npx firebase deploy --only functions --force

echo ""
echo "=============================================="
echo "🔍 Verification"
echo "=============================================="
echo ""

echo "Deployed functions:"
npx firebase functions:list

echo ""
echo "Testing endpoints:"
echo ""

# Test each endpoint
echo "1. Testing pawaPayWebhookHealth..."
HEALTH_RESPONSE=$(curl -s https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo -e "   ${GREEN}✅ pawaPayWebhookHealth working${NC}"
else
    echo -e "   ${RED}❌ pawaPayWebhookHealth not responding${NC}"
fi

echo ""
echo "2. Testing initiatePayment (should return 405 for GET)..."
INITIATE_RESPONSE=$(curl -s -w "%{http_code}" https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment)
if echo "$INITIATE_RESPONSE" | grep -q "405"; then
    echo -e "   ${GREEN}✅ initiatePayment exists (405 Method Not Allowed is expected)${NC}"
else
    echo -e "   ${RED}❌ initiatePayment not responding correctly${NC}"
    echo "   Response: $INITIATE_RESPONSE"
fi

echo ""
echo "=============================================="
echo "📋 Summary"
echo "=============================================="
echo ""
echo "Check Firebase Console to verify all 4 functions are listed:"
echo "  https://console.firebase.google.com/project/sayekataleapp/functions"
echo ""
echo "Expected functions:"
echo "  1. ✅ initiatePayment"
echo "  2. ✅ pawaPayWebhook"
echo "  3. ✅ pawaPayWebhookHealth"
echo "  4. ✅ manualActivateSubscription"
echo ""
echo "If all functions are deployed, test the payment flow:"
echo "  1. Install APK on Android device"
echo "  2. Login: drnamanya@gmail.com"
echo "  3. Go to: SME Directory → Upgrade to Premium"
echo "  4. Enter mobile number and pay"
echo "  5. Check if mobile money prompt appears"
echo ""
