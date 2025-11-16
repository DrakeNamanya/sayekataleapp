#!/usr/bin/env python3
"""
Firebase Authentication Test Script
Tests if Firebase Auth is properly configured and working
"""

import sys
import requests
import json
from datetime import datetime

# Firebase Configuration
FIREBASE_PROJECT_ID = "sayekataleapp"
FIREBASE_API_KEY = "AIzaSyAR4WdX7MsctO7aSX_vfqKMZbIUOxrnMlg"

# Firebase Auth REST API endpoints
AUTH_SIGNUP_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_API_KEY}"
AUTH_SIGNIN_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
AUTH_REFRESH_URL = f"https://securetoken.googleapis.com/v1/token?key={FIREBASE_API_KEY}"

def print_section(title):
    """Print formatted section header"""
    print("\n" + "=" * 60)
    print(f"  {title}")
    print("=" * 60)

def test_firebase_auth_enabled():
    """Test if Firebase Auth API is enabled"""
    print_section("TEST 1: Firebase Auth API Status")
    
    try:
        # Try to sign in with invalid credentials (just to test API is enabled)
        response = requests.post(
            AUTH_SIGNIN_URL,
            json={
                "email": "test@example.com",
                "password": "test123",
                "returnSecureToken": True
            },
            timeout=10
        )
        
        # Even if credentials are wrong, if we get a response, API is enabled
        if response.status_code in [200, 400]:
            print("✅ Firebase Auth API is ENABLED and responding")
            print(f"   Status Code: {response.status_code}")
            
            if response.status_code == 400:
                error_data = response.json()
                if 'error' in error_data:
                    error_message = error_data['error'].get('message', '')
                    print(f"   Response: {error_message}")
                    
                    if error_message in ['EMAIL_NOT_FOUND', 'INVALID_PASSWORD', 'INVALID_EMAIL']:
                        print("   ✅ This is expected - just testing API availability")
                        return True
            return True
        else:
            print(f"❌ Firebase Auth API returned unexpected status: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Firebase Auth API connection failed: {e}")
        return False

def test_create_test_user():
    """Test creating a new test user"""
    print_section("TEST 2: Create Test User")
    
    # Generate unique test email
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    test_email = f"test_{timestamp}@sayekatale.test"
    test_password = "TestPassword123!"
    
    print(f"📧 Creating test user: {test_email}")
    
    try:
        response = requests.post(
            AUTH_SIGNUP_URL,
            json={
                "email": test_email,
                "password": test_password,
                "returnSecureToken": True
            },
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Test user created successfully!")
            print(f"   User ID: {data.get('localId', 'N/A')}")
            print(f"   Email: {data.get('email', 'N/A')}")
            print(f"   ID Token: {data.get('idToken', 'N/A')[:50]}...")
            
            return {
                'email': test_email,
                'password': test_password,
                'uid': data.get('localId'),
                'idToken': data.get('idToken'),
                'refreshToken': data.get('refreshToken')
            }
        else:
            print(f"❌ Failed to create test user")
            print(f"   Status: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
        return None

def test_sign_in_user(email, password):
    """Test signing in with existing credentials"""
    print_section("TEST 3: Sign In Test User")
    
    print(f"🔐 Signing in as: {email}")
    
    try:
        response = requests.post(
            AUTH_SIGNIN_URL,
            json={
                "email": email,
                "password": password,
                "returnSecureToken": True
            },
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Sign in successful!")
            print(f"   User ID: {data.get('localId', 'N/A')}")
            print(f"   Email: {data.get('email', 'N/A')}")
            print(f"   Email Verified: {data.get('emailVerified', False)}")
            print(f"   ID Token: {data.get('idToken', 'N/A')[:50]}...")
            return True
        else:
            print(f"❌ Sign in failed")
            print(f"   Status: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
        return False

def main():
    """Run all Firebase Auth tests"""
    print("\n🔥 Firebase Authentication Test Suite")
    print(f"📋 Project: {FIREBASE_PROJECT_ID}")
    print(f"🔑 API Key: {FIREBASE_API_KEY[:20]}...")
    
    # Test 1: Check if Auth API is enabled
    auth_enabled = test_firebase_auth_enabled()
    
    if not auth_enabled:
        print("\n❌ Firebase Auth is not enabled or not configured correctly")
        print("\n📝 To enable Firebase Auth:")
        print("   1. Go to: https://console.firebase.google.com/project/sayekataleapp")
        print("   2. Navigate to: Build → Authentication")
        print("   3. Click 'Get Started'")
        print("   4. Enable 'Email/Password' sign-in method")
        sys.exit(1)
    
    # Test 2: Create a test user
    test_user = test_create_test_user()
    
    if not test_user:
        print("\n⚠️ Could not create test user")
        print("   This might mean:")
        print("   - Email/Password provider is not enabled")
        print("   - Firebase Auth quota exceeded")
        print("   - Network/API issues")
        sys.exit(1)
    
    # Test 3: Sign in with test user
    sign_in_success = test_sign_in_user(test_user['email'], test_user['password'])
    
    # Final Summary
    print_section("TEST SUMMARY")
    
    if auth_enabled and test_user and sign_in_success:
        print("✅ ALL TESTS PASSED!")
        print("\n📊 Results:")
        print("   ✅ Firebase Auth API is enabled")
        print("   ✅ User registration works")
        print("   ✅ User sign-in works")
        print("\n🎉 Firebase Authentication is LIVE and working correctly!")
        print("\n📱 Your Flutter app can now:")
        print("   - Register new users")
        print("   - Sign in existing users")
        print("   - Authenticate API requests")
        print("\n🔐 Test User Created:")
        print(f"   Email: {test_user['email']}")
        print(f"   Password: {test_user['password']}")
        print(f"   UID: {test_user['uid']}")
        print("\n💡 You can use this account to test your app!")
    else:
        print("❌ SOME TESTS FAILED")
        print("\n📋 Failed Tests:")
        if not auth_enabled:
            print("   ❌ Firebase Auth API not responding")
        if not test_user:
            print("   ❌ User registration failed")
        if not sign_in_success:
            print("   ❌ User sign-in failed")
        
        print("\n🔧 Next Steps:")
        print("   1. Check Firebase Console: https://console.firebase.google.com/project/sayekataleapp")
        print("   2. Verify Authentication is enabled")
        print("   3. Check billing status (if on Spark plan)")
        print("   4. Review Firebase Auth logs")
        sys.exit(1)
    
    print("\n" + "=" * 60)

if __name__ == '__main__':
    main()
