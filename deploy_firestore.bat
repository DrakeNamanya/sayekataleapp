@echo off
REM ============================================================================
REM Firestore Configuration Deployment Script
REM For SayeKatale App (sayekataleapp)
REM ============================================================================

echo.
echo ============================================
echo   Firestore Deployment Script
echo   SayeKatale App (sayekataleapp)
echo ============================================
echo.

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Firebase CLI not found!
    echo.
    echo Please install Firebase CLI first:
    echo   npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

echo [OK] Firebase CLI detected
echo.

REM Check if firebase.json exists
if not exist "firebase.json" (
    echo [WARNING] firebase.json not found!
    echo.
    echo Please run: firebase init
    echo Then select Firestore and configure the project.
    echo.
    pause
    exit /b 1
)

echo [OK] Firebase project configured
echo.

REM ============================================================================
REM STEP 1: Deploy Security Rules
REM ============================================================================

echo ============================================
echo   STEP 1: Deploying Security Rules
echo ============================================
echo.

firebase deploy --only firestore:rules
if errorlevel 1 (
    echo.
    echo [ERROR] Security rules deployment failed!
    echo Please check error messages above.
    echo.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Security rules deployed!
echo.

REM ============================================================================
REM STEP 2: Deploy Composite Indexes
REM ============================================================================

echo ============================================
echo   STEP 2: Deploying Composite Indexes
echo ============================================
echo.

firebase deploy --only firestore:indexes
if errorlevel 1 (
    echo.
    echo [ERROR] Index deployment failed!
    echo Please check error messages above.
    echo.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Indexes deployment started!
echo.

REM ============================================================================
REM COMPLETION
REM ============================================================================

echo ============================================
echo   DEPLOYMENT COMPLETE
echo ============================================
echo.
echo [1] Security rules: DEPLOYED
echo [2] Composite indexes: BUILDING (2-15 minutes)
echo.
echo Next steps:
echo   1. Monitor index building progress:
echo      https://console.firebase.google.com/project/sayekataleapp/firestore/indexes
echo.
echo   2. Wait for all indexes to show "Enabled" status (green checkmark)
echo.
echo   3. Test the app:
echo      - Open receipts screen
echo      - Send/receive messages
echo      - Check notifications
echo.
echo [TIP] Indexes typically take 2-15 minutes to build.
echo       You can close this window and check Firebase Console for progress.
echo.
pause
