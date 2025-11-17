# 🚀 Sayekatale Production Deployment Guide

**Last Updated**: November 17, 2024  
**APK Version**: 1.0.0 (Build 1)  
**Status**: ✅ Ready for Testing → Google Play Store Submission

---

## 📋 Table of Contents
1. [What's Been Completed](#whats-been-completed)
2. [Critical Action Required](#critical-action-required)
3. [APK Download & Installation](#apk-download--installation)
4. [Testing Checklist](#testing-checklist)
5. [Google Play Store Submission](#google-play-store-submission)
6. [Troubleshooting](#troubleshooting)

---

## ✅ What's Been Completed

### 1. Firestore Security Rules - Fixed (6 Collections)
**Status**: ✅ Fixed in Code | 🔴 **REQUIRES DEPLOYMENT**

**Collections Updated**:
- `orders` - Split read permissions, fixed field names
- `cart_items` - Split read permissions  
- `favorite_products` - NEW rules added (was completely missing)
- `messages` - Split read permissions for sender/receiver
- `receipts` - Split read permissions for buyer/seller
- `transactions` - Split read permissions for user access

**What This Fixes**:
- ❌ "Permission Denied" errors in Orders screen
- ❌ "Permission Denied" errors in Favorites screen
- ❌ "Permission Denied" errors in Messages screen
- ❌ "Permission Denied" errors in Purchase Receipts screen

### 2. PawaPay Webhook Configuration - Updated ✅
**Status**: ✅ Complete

**Changes Made**:
- ✅ Updated deposit callback URL to Google Cloud Run service
- ✅ Updated refund callback URL to Google Cloud Run service
- ✅ Both endpoints now point to: `https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook`

**Before**:
```dart
defaultValue: 'https://api.sayekatale.com/webhooks/pawapay/deposit'
```

**After**:
```dart
defaultValue: 'https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook'
```

### 3. Production APK Built ✅
**Status**: ✅ Complete

**Build Configuration**:
- ✅ PawaPay API Token: Included via `--dart-define`
- ✅ Webhook URLs: Updated to Cloud Run service
- ✅ Signing: Production keystore applied
- ✅ AdMob: Production IDs included
- ✅ Firebase: Production project configured

**APK Details**:
- **File**: `app-release.apk`
- **Size**: 67 MB
- **MD5**: `0f2a7d7920653b4479a1bfb3711e55b8`
- **Package**: `com.datacollectors.sayekatale`
- **Version**: 1.0.0 (Build 1)

### 4. Version Control ✅
**Status**: ✅ Complete

- ✅ All changes committed to git
- ✅ Pushed to GitHub repository
- ✅ Comprehensive documentation created

---

## 🔴 CRITICAL ACTION REQUIRED

### Deploy Updated Firestore Security Rules

**⚠️ WARNING**: Users will continue to see "Permission Denied" errors until you deploy the updated security rules!

#### Option A: Firebase Console (Recommended - Easiest)

1. **Visit Firebase Console**:
   ```
   https://console.firebase.google.com/project/sayekataleapp/firestore/rules
   ```

2. **Copy Rules Content**:
   - Open local file: `firestore.rules` (in project root)
   - Copy entire content (all 215 lines)

3. **Paste & Publish**:
   - Paste into Firebase Console editor
   - Click **"Publish"** button
   - Wait for confirmation message

4. **Verify Deployment**:
   - Check for success message
   - Note deployment timestamp

#### Option B: Firebase CLI

```bash
# Ensure you're in the project directory
cd /path/to/sayekataleapp

# Login to Firebase (if not already logged in)
firebase login

# Deploy security rules
firebase deploy --only firestore:rules

# Expected output:
# ✔ Deploy complete!
# Firestore Rules: Released
```

#### Verification After Deployment

**Test in Firebase Console**:
1. Go to: Firestore Rules → **Rules Playground**
2. Test query: `orders` collection
3. Simulate authenticated user
4. Should return: ✅ **"Allowed"**

**Test in App**:
1. Open Orders screen → Should load without errors
2. Open Favorites screen → Should load without errors
3. Open Messages → Should load without errors
4. Open Purchase Receipts → Should load without errors

---

## 📥 APK Download & Installation

### Download APK

**Method 1: Direct Download Link**
```
[Download from Cloud Sandbox]
Location: /home/user/flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

**Method 2: Build Locally**
```bash
git clone https://github.com/DrakeNamanya/sayekataleapp.git
cd sayekataleapp
flutter build apk --release \
  --dart-define=PAWAPAY_API_TOKEN=eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJpc3MiOiJQYXdhUGF5IiwiYXVkIjoicGF3YXBheS1jb3JlIiwiaWF0IjoxNzMxNzY2OTQxLCJleHAiOjIwNDczMjY5NDF9.i3hkfkL08OiBPRXOm5WQHZN1Dz-WV7yApVXTCy7y2G4gzUVPcBYJ3s51c2d-jKrN24bHQkpGDLLH8DYMCfKNnQ
```

### Install on Android Device

**Requirements**:
- Android 5.0 (API 21) or higher
- 100 MB free storage space
- Unknown sources enabled (for non-Play Store APKs)

**Installation Steps**:
1. **Enable Unknown Sources**:
   - Go to: Settings → Security → Unknown Sources
   - Toggle **ON** (temporarily)

2. **Transfer APK**:
   - USB cable method: Copy APK to device
   - Cloud method: Upload to Google Drive, download on device
   - Direct method: Open download link on device

3. **Install**:
   - Tap `app-release.apk`
   - Click **"Install"**
   - Wait for completion
   - Click **"Open"**

4. **Re-disable Unknown Sources** (security best practice)

---

## ✅ Testing Checklist

### Pre-Testing Setup
- [ ] Firestore security rules deployed
- [ ] APK installed on test device
- [ ] Internet connection active
- [ ] Test user account created/available

### Core Functionality Testing

#### 1. Authentication & User Management
- [ ] User registration works
- [ ] Email verification sent
- [ ] Login successful
- [ ] Password reset functional
- [ ] Profile updates save correctly

#### 2. Product Browsing (Previously Fixed)
- [ ] Products list loads without errors
- [ ] Product details display correctly
- [ ] Images load properly
- [ ] Search functionality works
- [ ] Filters apply correctly

#### 3. Orders Screen (NEW FIX - Priority Testing)
- [ ] **Orders list loads WITHOUT "Permission Denied" error** ⭐
- [ ] Can view order details
- [ ] Order status displays correctly
- [ ] Can filter/sort orders

#### 4. Favorites Screen (NEW FIX - Priority Testing)
- [ ] **Favorites list loads WITHOUT "Permission Denied" error** ⭐
- [ ] Can add products to favorites
- [ ] Can remove from favorites
- [ ] Favorites sync across sessions

#### 5. Messages Screen (NEW FIX - Priority Testing)
- [ ] **Messages list loads WITHOUT "Permission Denied" error** ⭐
- [ ] Can send messages
- [ ] Can receive messages
- [ ] Message notifications work

#### 6. Purchase Receipts (NEW FIX - Priority Testing)
- [ ] **Receipts list loads WITHOUT "Permission Denied" error** ⭐
- [ ] Can view receipt details
- [ ] Receipt data accurate
- [ ] Can download/share receipts

#### 7. Wallet & Payments (CRITICAL - PawaPay Integration)
- [ ] Wallet balance displays correctly
- [ ] **Deposit via MTN Mobile Money** ⭐
  - [ ] Initiate deposit request
  - [ ] Receive MTN payment prompt on phone
  - [ ] Enter MTN PIN to confirm
  - [ ] Wait for webhook confirmation (check backend logs)
  - [ ] Wallet balance updates correctly
  - [ ] Transaction appears in history
- [ ] **Deposit via Airtel Money** ⭐
  - [ ] Initiate deposit request
  - [ ] Receive Airtel payment prompt
  - [ ] Enter Airtel PIN to confirm
  - [ ] Wait for webhook confirmation
  - [ ] Wallet balance updates correctly
  - [ ] Transaction appears in history
- [ ] Withdrawal request functional
- [ ] Transaction history accurate

#### 8. Shopping Cart & Checkout
- [ ] Add items to cart
- [ ] Update quantities
- [ ] Remove items
- [ ] Checkout process completes
- [ ] Payment options work
- [ ] Order confirmation received

#### 9. Seller Functionality (if applicable)
- [ ] List new products
- [ ] Update product details
- [ ] Manage inventory
- [ ] View sales analytics
- [ ] Process orders

#### 10. AdMob Integration
- [ ] Banner ads display (production IDs)
- [ ] Ads don't obstruct UI
- [ ] Ad revenue tracking works (check AdMob console)

### Performance Testing
- [ ] App launches in < 3 seconds
- [ ] Screen transitions smooth (60fps)
- [ ] Images load progressively
- [ ] No memory leaks during extended use
- [ ] Battery usage reasonable

### Edge Cases
- [ ] App handles poor network gracefully
- [ ] Offline functionality works (cached data)
- [ ] Large datasets load without crashing
- [ ] Concurrent operations don't conflict

---

## 🎯 Expected Test Results

### ✅ FIXED Issues (Should Work Now)
1. **Orders Screen**: Should load order history without errors
2. **Favorites Screen**: Should show favorite products without errors
3. **Messages Screen**: Should display conversations without errors
4. **Receipts Screen**: Should list purchase receipts without errors
5. **Wallet Deposits**: Should process MTN/Airtel payments successfully

### 🔍 What to Monitor

#### Backend Webhook Logs
Monitor your Google Cloud Run service for webhook callbacks:
```bash
# View recent webhook logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=pawapay-webhook" --limit 50 --format json

# Or visit Cloud Run console:
# https://console.cloud.google.com/run/detail/us-central1/pawapay-webhook/logs
```

**Expected Webhook Flow**:
1. User initiates deposit in app
2. App calls PawaPay API with callback URL
3. User completes payment on mobile money
4. PawaPay sends POST request to: `https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook`
5. Your webhook updates Firestore `transactions` and `wallets` collections
6. App displays updated balance

#### Firestore Console Monitoring
Watch real-time updates during testing:
```
https://console.firebase.google.com/project/sayekataleapp/firestore/data
```

**Collections to Monitor**:
- `transactions` - Should see new entries after deposits
- `wallets` - User balance should increase
- `orders` - Should see new orders after checkout
- `messages` - Should see message exchanges

---

## 📱 Google Play Store Submission

### Pre-Submission Checklist
- [ ] All critical bugs fixed
- [ ] Testing completed successfully
- [ ] Screenshots prepared (phone + tablet)
- [ ] App icon finalized (512x512px)
- [ ] Feature graphic created (1024x500px)
- [ ] Privacy policy URL ready
- [ ] Terms of service URL ready
- [ ] Content rating questionnaire completed

### Google Play Console Steps

#### 1. Create Application
1. Visit: https://play.google.com/console
2. Click **"Create app"**
3. Fill in details:
   - **App name**: Sayekatale
   - **Default language**: English (or primary language)
   - **App type**: App
   - **Free/Paid**: (Choose based on business model)

#### 2. Store Listing
**Required Assets**:
- App icon (512x512px)
- Feature graphic (1024x500px)
- Screenshots:
  - Phone: 2-8 screenshots (16:9 or 9:16)
  - 7-inch tablet: 2-8 screenshots
  - 10-inch tablet: 2-8 screenshots

**Description**:
```
Sayekatale - Agricultural Marketplace

Connect farmers, buyers, and sellers in one seamless platform. 
Buy fresh agricultural products, manage orders, and make secure 
payments via Mobile Money (MTN & Airtel Uganda).

Features:
✓ Browse agricultural products
✓ Secure wallet & Mobile Money payments
✓ Real-time messaging with sellers
✓ Order tracking & purchase receipts
✓ Favorite products for quick access
✓ Location-based product discovery

Trusted by Ugandan farmers and buyers for transparent, 
efficient agricultural trade.
```

#### 3. Content Rating
Complete the content rating questionnaire:
- Access category: General audience
- Violence: None
- Sexual content: None
- Language: Polite, no profanity
- Controlled substances: None
- Gambling: None

#### 4. App Content
**Privacy Policy**: Required! Must include:
- Data collection practices
- How user data is used
- Third-party integrations (Firebase, PawaPay, AdMob)
- User rights (access, deletion)

**Example Privacy Policy URL**:
```
https://sayekatale.com/privacy-policy
```

#### 5. Production Release
**APK/AAB Upload**:
1. Go to: Production → Releases
2. Click **"Create new release"**
3. Upload: `app-release.apk` (or build AAB: `flutter build appbundle --release`)
4. Release notes:
   ```
   Initial release of Sayekatale agricultural marketplace.
   
   Features:
   - Product browsing & search
   - Secure Mobile Money payments
   - Order management
   - Real-time messaging
   - Favorites & wishlists
   ```

5. Click **"Review release"**
6. **Save** → **Start rollout to production**

#### 6. Review Process
**Timeline**: 1-7 days (typically 2-3 days)

**What Google Reviews**:
- App functionality
- Privacy policy compliance
- Content rating accuracy
- Metadata accuracy
- Store listing assets

**Possible Outcomes**:
- ✅ **Approved**: App goes live automatically
- ⚠️ **Changes requested**: Address feedback and resubmit
- ❌ **Rejected**: Fix policy violations and appeal/resubmit

---

## 🔧 Troubleshooting

### Issue: "Permission Denied" Errors Persist

**Symptoms**:
- Orders screen shows "No permission to read"
- Favorites empty despite added products
- Messages won't load

**Solution**:
1. Verify security rules deployed:
   ```bash
   firebase firestore:rules:get
   ```
2. Check Firebase Console timestamp
3. Clear app data and re-login
4. Check Firestore Console → Rules tab

**If Still Failing**:
- Review Firestore Rules in console
- Check user authentication status
- Verify user document exists in `users` collection

---

### Issue: Wallet Deposits Not Completing

**Symptoms**:
- Deposit initiated but balance doesn't update
- "Processing" status never changes
- No transaction record

**Diagnostic Steps**:

1. **Check Webhook Logs**:
   ```bash
   gcloud logging read "resource.type=cloud_run_revision" --limit 20
   ```
   
   **Expected**: POST requests from PawaPay IPs
   **If Missing**: Webhook URL may be incorrect in PawaPay dashboard

2. **Check PawaPay API Token**:
   ```dart
   // Verify in app logs (debug mode only)
   debugPrint('PawaPay Token Set: ${Environment.pawaPayToken.isNotEmpty}');
   ```
   
   **Expected**: `true`
   **If False**: Rebuild APK with `--dart-define=PAWAPAY_API_TOKEN=...`

3. **Verify Callback URL**:
   ```dart
   // lib/config/environment.dart
   debugPrint('Callback URL: ${Environment.pawaPayDepositCallback}');
   ```
   
   **Expected**: `https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook`
   **If Different**: Update and rebuild APK

4. **Check Firestore Permissions**:
   - User must have write access to `transactions` collection
   - User must have write access to `wallets` collection

**Manual Webhook Test**:
```bash
curl -X POST https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "depositId": "test-123",
    "status": "COMPLETED",
    "amount": "1000",
    "currency": "UGX",
    "correspondent": "MTN_MOMO_UGA",
    "payer": {
      "msisdn": "+256700000000"
    },
    "metadata": {
      "userId": "test-user-id"
    }
  }'
```

**Expected Response**: `200 OK` with webhook confirmation

---

### Issue: AdMob Ads Not Showing

**Symptoms**:
- Banner ad slots empty
- No ads displayed in app

**Solutions**:

1. **Verify AdMob App Status**:
   - Visit: https://apps.admob.com/
   - Check app review status
   - New apps may take 24-48 hours for ads to start serving

2. **Check Ad Unit IDs**:
   ```dart
   // lib/config/environment.dart
   debugPrint('AdMob App ID: ${Environment.admobAppIdAndroid}');
   debugPrint('AdMob Banner ID: ${Environment.admobBannerIdAndroid}');
   ```
   
   **Expected**:
   - App ID: `ca-app-pub-6557386913540479~2174503706`
   - Banner ID: `ca-app-pub-6557386913540479/5529911893`

3. **Test with Test Ads**:
   ```dart
   // Temporarily use test ad unit for debugging
   static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
   ```

---

### Issue: App Crashes on Startup

**Symptoms**:
- App opens briefly then closes
- Black screen after splash
- "App keeps stopping" error

**Diagnostic Steps**:

1. **Check Logcat Logs**:
   ```bash
   adb logcat -s flutter,AndroidRuntime
   ```

2. **Common Causes**:
   - Firebase initialization failure
   - Missing google-services.json
   - Invalid API keys
   - Null pointer exceptions

3. **Verify Firebase Setup**:
   - Check `android/app/google-services.json` exists
   - Verify package name matches: `com.datacollectors.sayekatale`
   - Confirm SHA-1 fingerprint registered in Firebase Console

---

### Issue: Products/Data Not Loading

**Symptoms**:
- Empty product lists
- "No data available" messages
- Infinite loading spinners

**Solutions**:

1. **Check Internet Connection**:
   - Verify device has active internet
   - Test on different networks (WiFi, mobile data)

2. **Verify Firestore Data Exists**:
   - Open Firebase Console → Firestore Database
   - Check `products` collection has documents
   - Verify product fields are populated

3. **Check Security Rules**:
   - Ensure `products` collection has public read access:
   ```javascript
   match /products/{productId} {
     allow read: if true;  // Public read access
   }
   ```

4. **Clear App Cache**:
   - Go to: Settings → Apps → Sayekatale → Storage
   - Click **"Clear Cache"**
   - Click **"Clear Data"** (will require re-login)

---

## 📞 Support & Resources

### Documentation Files
- `SECURITY_AND_API_AUDIT.md` - Comprehensive security audit report
- `FIRESTORE_RULES_FIX_V2.md` - Detailed security rules documentation
- `AUDIT_SUMMARY_QUICK.txt` - Quick reference guide
- `APK_BUILD_SUCCESS.md` - Build documentation

### Key URLs
- **Firebase Console**: https://console.firebase.google.com/project/sayekataleapp
- **Google Play Console**: https://play.google.com/console
- **AdMob Console**: https://apps.admob.com/
- **PawaPay Webhook**: https://pawapay-webhook-713040690605.us-central1.run.app
- **GitHub Repository**: https://github.com/DrakeNamanya/sayekataleapp

### Technical Configuration
**Package Name**: `com.datacollectors.sayekatale`  
**Bundle ID**: `com.datacollectors.sayekatale`  
**Version Code**: 1  
**Version Name**: 1.0.0  
**Min SDK**: 21 (Android 5.0)  
**Target SDK**: 36 (Android 15)

---

## 🎉 Next Steps

### Immediate Actions (Today)
1. ✅ Download APK from build server
2. 🔴 **Deploy Firestore security rules** (CRITICAL)
3. ✅ Install APK on test device
4. ✅ Complete testing checklist

### This Week
1. ✅ Prepare Google Play Store assets
2. ✅ Create privacy policy & terms of service
3. ✅ Complete content rating questionnaire
4. ✅ Submit app to Google Play Store

### After Submission
1. Monitor Google Play Console for review status
2. Address any feedback from Google review team
3. Plan marketing strategy for app launch
4. Set up user feedback channels
5. Monitor analytics and crash reports

---

## 📊 Success Metrics to Track

### Day 1 (Testing Phase)
- [ ] All permission errors resolved
- [ ] At least 3 successful wallet deposits (MTN & Airtel)
- [ ] 10+ orders placed successfully
- [ ] No critical crashes

### Week 1 (After Play Store Approval)
- Target: 100+ downloads
- Monitor: Crash rate < 1%
- Track: Wallet deposit success rate > 95%
- Measure: Average session duration

### Month 1 (Growth Phase)
- Target: 1,000+ active users
- Monitor: User retention rate
- Track: Order completion rate
- Measure: Revenue metrics

---

**Document Version**: 1.0  
**Last Updated**: November 17, 2024  
**Maintained By**: Development Team

---

## ⚠️ REMINDER: Deploy Firestore Rules NOW!

**This is the ONLY remaining critical action before testing can begin!**

Visit: https://console.firebase.google.com/project/sayekataleapp/firestore/rules

Copy content from `firestore.rules` → Paste in console → Click "Publish"

✅ Without this step, users will continue seeing "Permission Denied" errors!
