#!/bin/bash

# Firebase Cloud Functions Deployment Script
# SayeKatale App - Push Notifications

echo "============================================"
echo "🚀 Firebase Cloud Functions Deployment"
echo "============================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed"
    echo "📦 Installing Firebase CLI..."
    npm install -g firebase-tools
    echo "✅ Firebase CLI installed"
fi

# Check Firebase login status
echo "🔐 Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "⚠️  Not logged in to Firebase"
    echo "🔑 Opening browser for Firebase login..."
    firebase login
else
    echo "✅ Already logged in to Firebase"
fi

# Navigate to project directory
cd "$(dirname "$0")"
echo "📂 Working directory: $(pwd)"
echo ""

# Install function dependencies
echo "📦 Installing function dependencies..."
cd functions
npm install
echo "✅ Dependencies installed"
echo ""

# Go back to project root
cd ..

# Deploy functions
echo "============================================"
echo "🚀 Deploying Cloud Functions to Firebase..."
echo "============================================"
echo ""

firebase deploy --only functions

echo ""
echo "============================================"
echo "✅ Deployment Complete!"
echo "============================================"
echo ""
echo "📋 Deployed Functions:"
echo "   ✅ onNewOrder - New order notifications"
echo "   ✅ onOrderStatusUpdate - Order status change notifications"
echo "   ✅ onNewMessage - New message notifications"
echo "   ✅ onPSAVerificationSubmitted - PSA verification admin alerts"
echo "   ✅ onPSAVerificationStatusUpdate - PSA approval/rejection notifications"
echo "   ✅ onLowStockAlert - Low stock inventory alerts"
echo "   ✅ onReceiptGenerated - Receipt ready notifications"
echo ""
echo "🔗 View functions in Firebase Console:"
echo "   https://console.firebase.google.com/project/_/functions"
echo ""
echo "📊 View function logs:"
echo "   firebase functions:log"
echo ""
echo "🧪 Test notifications by creating test data in Firestore"
echo ""
