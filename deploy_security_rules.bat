@echo off
REM ========================================
REM SayeKatale - Deploy Firebase Security Rules
REM ========================================
REM
REM This script deploys secure Firestore and Storage rules
REM to fix the "public access" security warning
REM
REM Run this from: C:\Users\dnamanya\Documents\sayekataleapp
REM ========================================

echo.
echo ========================================
echo SayeKatale - Deploy Security Rules
echo ========================================
echo.

REM Check if firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI not found!
    echo.
    echo Please install Firebase CLI:
    echo npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

echo Step 1: Checking Firebase login status...
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo You need to login to Firebase first.
    echo Opening browser for authentication...
    echo.
    firebase login
    if %errorlevel% neq 0 (
        echo ERROR: Firebase login failed!
        pause
        exit /b 1
    )
)

echo ✓ Firebase authentication verified
echo.

echo Step 2: Deploying Firestore security rules...
firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo ERROR: Failed to deploy Firestore rules!
    pause
    exit /b 1
)

echo ✓ Firestore rules deployed
echo.

echo Step 3: Deploying Storage security rules...
firebase deploy --only storage:rules
if %errorlevel% neq 0 (
    echo ERROR: Failed to deploy Storage rules!
    pause
    exit /b 1
)

echo ✓ Storage rules deployed
echo.

echo ========================================
echo SUCCESS! Security Rules Deployed
echo ========================================
echo.
echo Your database is now protected with proper security rules!
echo.
echo Next steps:
echo 1. Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
echo 2. Verify the warning is gone
echo 3. Test app functionality to ensure rules work correctly
echo.
echo Press any key to open Firebase Console...
pause >nul

start https://console.firebase.google.com/project/sayekataleapp/firestore/rules

echo.
echo Done!
pause
