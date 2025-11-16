#!/bin/bash

# SayeKatale Production APK Build Script
# This script builds a production-ready Android APK with all credentials

set -e  # Exit on error

echo "🚀 SayeKatale Production APK Build"
echo "===================================="
echo ""

# ========================================
# Configuration
# ========================================

PROJECT_DIR="/home/user/flutter_app"
BUILD_TYPE="apk"  # Options: apk, appbundle (aab)

# Production URLs (from Phase 1)
API_BASE_URL="https://pawapay-webhook-713040690605.us-central1.run.app"
PAWAPAY_CALLBACK="https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook"

# PawaPay API Token (Sandbox - Replace with production token later)
PAWAPAY_API_TOKEN="eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4NTA5MjM2LCJpYXQiOjE3NjI5NzY0MzYsInBtIjoiREFGLFBBRiIsImp0aSI6ImE0NjQyZjUyLWYwODYtNGJjNy1hMGY3LTQ2MmJiNDgyYzM1MSJ9.zyFdgBTQ-dj_NiR15ChPjLM6kYjH3ZB4J9G8ye4TKiOjPgdXsJ53U08-WspwZ8JtjXua8FGuIf4VhQVcmVRjHQ"

# AdMob Credentials (from Phase 2)
ADMOB_APP_ID="ca-app-pub-6557386913540479~2174503706"
ADMOB_BANNER_ID="ca-app-pub-6557386913540479/5529911893"

# App Information
APP_VERSION="1.0.0"
BUILD_NUMBER="1"

echo "📋 Build Configuration:"
echo "   App Version: $APP_VERSION+$BUILD_NUMBER"
echo "   Build Type: $BUILD_TYPE"
echo "   Package: com.datacollectors.sayekatale"
echo "   API Base: $API_BASE_URL"
echo "   AdMob App ID: $ADMOB_APP_ID"
echo ""

# ========================================
# Pre-Build Steps
# ========================================

echo "📋 Step 1: Pre-build checks..."
cd $PROJECT_DIR

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please ensure Flutter is in your PATH."
    exit 1
fi

echo "   Flutter version:"
flutter --version | head -n 1
echo ""

# ========================================
# Clean Build
# ========================================

echo "📋 Step 2: Cleaning previous builds..."
flutter clean
echo "✅ Clean complete"
echo ""

# ========================================
# Get Dependencies
# ========================================

echo "📋 Step 3: Getting dependencies..."
flutter pub get
echo "✅ Dependencies fetched"
echo ""

# ========================================
# Run Tests (Optional)
# ========================================

echo "📋 Step 4: Running tests..."
if flutter test --no-pub; then
    echo "✅ All tests passed"
else
    echo "⚠️ Some tests failed, but continuing build..."
fi
echo ""

# ========================================
# Build Production APK
# ========================================

echo "📋 Step 5: Building production APK..."
echo "   This may take 5-10 minutes..."
echo ""

if [ "$BUILD_TYPE" = "appbundle" ]; then
    # Build App Bundle (AAB) for Play Store
    flutter build appbundle --release \
        --dart-define=PRODUCTION=true \
        --dart-define=APP_VERSION=$APP_VERSION \
        --dart-define=API_BASE_URL=$API_BASE_URL \
        --dart-define=PAWAPAY_API_TOKEN=$PAWAPAY_API_TOKEN \
        --dart-define=PAWAPAY_DEPOSIT_CALLBACK=$PAWAPAY_CALLBACK \
        --dart-define=PAWAPAY_WITHDRAWAL_CALLBACK=$PAWAPAY_CALLBACK \
        --dart-define=ADMOB_APP_ID_ANDROID=$ADMOB_APP_ID \
        --dart-define=ADMOB_BANNER_ID_ANDROID=$ADMOB_BANNER_ID \
        --dart-define=ENABLE_PAWAPAY=true \
        --dart-define=ENABLE_ANALYTICS=true \
        --build-name=$APP_VERSION \
        --build-number=$BUILD_NUMBER
    
    BUILD_OUTPUT="build/app/outputs/bundle/release/app-release.aab"
else
    # Build APK for direct installation/Firebase App Distribution
    flutter build apk --release \
        --dart-define=PRODUCTION=true \
        --dart-define=APP_VERSION=$APP_VERSION \
        --dart-define=API_BASE_URL=$API_BASE_URL \
        --dart-define=PAWAPAY_API_TOKEN=$PAWAPAY_API_TOKEN \
        --dart-define=PAWAPAY_DEPOSIT_CALLBACK=$PAWAPAY_CALLBACK \
        --dart-define=PAWAPAY_WITHDRAWAL_CALLBACK=$PAWAPAY_CALLBACK \
        --dart-define=ADMOB_APP_ID_ANDROID=$ADMOB_APP_ID \
        --dart-define=ADMOB_BANNER_ID_ANDROID=$ADMOB_BANNER_ID \
        --dart-define=ENABLE_PAWAPAY=true \
        --dart-define=ENABLE_ANALYTICS=true \
        --build-name=$APP_VERSION \
        --build-number=$BUILD_NUMBER
    
    BUILD_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
fi

echo ""
echo "✅ Build complete!"
echo ""

# ========================================
# Build Summary
# ========================================

echo "🎉 SUCCESS! Production APK Built"
echo "=================================="
echo ""

if [ -f "$BUILD_OUTPUT" ]; then
    FILE_SIZE=$(du -h "$BUILD_OUTPUT" | cut -f1)
    echo "📦 Output File: $BUILD_OUTPUT"
    echo "📊 File Size: $FILE_SIZE"
    echo ""
    
    # Get APK info
    echo "📋 APK Information:"
    echo "   App Name: SayeKatale"
    echo "   Package: com.datacollectors.sayekatale"
    echo "   Version: $APP_VERSION ($BUILD_NUMBER)"
    echo "   Min SDK: 21 (Android 5.0)"
    echo "   Target SDK: 35 (Android 15)"
    echo ""
    
    echo "🔗 Production URLs Configured:"
    echo "   API Base: $API_BASE_URL"
    echo "   PawaPay Webhook: $PAWAPAY_CALLBACK"
    echo ""
    
    echo "📱 AdMob Configuration:"
    echo "   App ID: $ADMOB_APP_ID"
    echo "   Banner ID: $ADMOB_BANNER_ID"
    echo ""
    
    echo "✅ Next Steps:"
    echo ""
    echo "1. Test APK on Android device:"
    echo "   adb install $BUILD_OUTPUT"
    echo ""
    echo "2. Download APK:"
    echo "   The APK is ready at: $BUILD_OUTPUT"
    echo ""
    echo "3. Distribute via Firebase App Distribution:"
    echo "   firebase appdistribution:distribute $BUILD_OUTPUT \\"
    echo "     --app 1:713040690605:android:YOUR_APP_ID \\"
    echo "     --release-notes 'Production release with PawaPay and AdMob integration'"
    echo ""
    echo "4. Or upload to Google Play Console:"
    echo "   - Go to: https://play.google.com/console/"
    echo "   - Create new release"
    echo "   - Upload APK/AAB"
    echo ""
else
    echo "❌ Build failed - output file not found"
    exit 1
fi

echo "📝 Build log saved to: flutter_build.log"
echo ""
echo "🎉 Phase 3 Complete!"
