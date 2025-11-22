#!/bin/bash
#
# Deploy Updated Firestore Security Rules to Firebase
# 
# This script deploys the updated rules that fix:
# - Edit Profile permission errors for SME/SHG users
# - More flexible profile update rules
#
# Usage:
#   bash deploy_firestore_rules.sh
#

set -e

echo "=========================================="
echo "🔥 FIRESTORE RULES DEPLOYMENT"
echo "=========================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found!"
    echo ""
    echo "📦 Installing Firebase CLI..."
    npm install -g firebase-tools
    echo "✅ Firebase CLI installed"
    echo ""
fi

# Check if we're in the right directory
if [ ! -f "FIRESTORE_RULES_FIX.txt" ]; then
    echo "❌ FIRESTORE_RULES_FIX.txt not found!"
    echo "   Make sure you're in the /home/user/flutter_app directory"
    exit 1
fi

echo "📁 Current directory: $(pwd)"
echo ""

# Check if firestore.rules exists, backup if it does
if [ -f "firestore.rules" ]; then
    echo "💾 Backing up existing firestore.rules..."
    cp firestore.rules firestore.rules.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup created"
    echo ""
fi

# Copy the new rules file
echo "📝 Preparing new Firestore rules..."
cp FIRESTORE_RULES_FIX.txt firestore.rules
echo "✅ Rules file ready"
echo ""

# Check if firebase.json exists
if [ ! -f "firebase.json" ]; then
    echo "📋 Creating firebase.json configuration..."
    cat > firebase.json << 'EOF'
{
  "firestore": {
    "rules": "firestore.rules"
  }
}
EOF
    echo "✅ firebase.json created"
    echo ""
fi

# Check if .firebaserc exists
if [ ! -f ".firebaserc" ]; then
    echo "📋 Creating .firebaserc configuration..."
    cat > .firebaserc << 'EOF'
{
  "projects": {
    "default": "sayekataleapp"
  }
}
EOF
    echo "✅ .firebaserc created"
    echo ""
fi

# Login to Firebase (if not already logged in)
echo "🔐 Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "⚠️ Not logged in to Firebase"
    echo ""
    echo "Please run: firebase login --no-localhost"
    echo "Then run this script again"
    exit 1
fi
echo "✅ Firebase authentication verified"
echo ""

# Show the project we're deploying to
echo "📊 Deployment target:"
firebase use sayekataleapp
echo ""

# Deploy the rules
echo "🚀 Deploying Firestore rules to sayekataleapp..."
echo ""
firebase deploy --only firestore:rules

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "🎉 Firestore rules successfully deployed!"
echo ""
echo "✅ Fixed Issues:"
echo "   - Edit Profile permission errors (SME/SHG users)"
echo "   - Profile field updates now allowed"
echo "   - id and role fields still protected"
echo ""
echo "🧪 Test Now:"
echo "   1. Login as Rita (SME user)"
echo "   2. Navigate to Profile → Edit Profile"
echo "   3. Update profile fields (name, phone, location, etc.)"
echo "   4. Upload profile image"
echo "   5. Click Save Profile"
echo "   6. ✅ Should work without permission errors!"
echo ""
echo "📊 Verify deployment:"
echo "   https://console.firebase.google.com/project/sayekataleapp/firestore/rules"
echo ""
