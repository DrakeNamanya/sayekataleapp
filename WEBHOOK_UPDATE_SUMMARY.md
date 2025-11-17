# ✅ PawaPay Webhook Configuration Update - Complete

**Date**: November 17, 2024  
**Status**: ✅ Configuration Updated & APK Rebuilt

---

## 🎯 What Was Done

### 1. Updated Webhook URLs in Flutter App
**File**: `lib/config/environment.dart`

**Old Configuration**:
```dart
// Deposit Callback
defaultValue: 'https://api.sayekatale.com/webhooks/pawapay/deposit'

// Withdrawal Callback  
defaultValue: 'https://api.sayekatale.com/webhooks/pawapay/withdrawal'
```

**New Configuration**:
```dart
// Deposit Callback
defaultValue: 'https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook'

// Refund Callback
defaultValue: 'https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook'
```

### 2. Rebuilt Production APK
**Command Used**:
```bash
flutter build apk --release \
  --dart-define=PAWAPAY_API_TOKEN=eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJpc3MiOiJQYXdhUGF5IiwiYXVkIjoicGF3YXBheS1jb3JlIiwiaWF0IjoxNzMxNzY2OTQxLCJleHAiOjIwNDczMjY5NDF9.i3hkfkL08OiBPRXOm5WQHZN1Dz-WV7yApVXTCy7y2G4gzUVPcBYJ3s51c2d-jKrN24bHQkpGDLLH8DYMCfKNnQ
```

**APK Details**:
- **File**: `build/app/outputs/flutter-apk/app-release.apk`
- **Size**: 67 MB
- **MD5**: `0f2a7d7920653b4479a1bfb3711e55b8`
- **Version**: 1.0.0 (Build 1)
- **Built**: November 17, 2024

### 3. Committed to Version Control
**Git Commit**: `0f020e0`
**Message**: "Update PawaPay webhook URLs to Google Cloud Run service"
**Pushed to**: https://github.com/DrakeNamanya/sayekataleapp

---

## 🔄 Webhook Flow Verification

### Your Deployed Backend Webhook Service
**URL**: `https://pawapay-webhook-713040690605.us-central1.run.app`  
**Endpoint**: `/api/pawapay/webhook`  
**Status**: ✅ Healthy (verified via `/health` endpoint)  
**API Token**: ✅ Configured with production token  

**Health Check**:
```bash
curl https://pawapay-webhook-713040690605.us-central1.run.app/health

# Response:
{
  "service": "PawaPay Webhook Handler",
  "status": "healthy",
  "timestamp": "2025-11-16T23:01:46.956881"
}
```

### Expected Flow During Wallet Deposit

```
1. User initiates deposit in Flutter app
   ↓
2. Flutter app calls PawaPay API with:
   - API Token: eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ...
   - Callback URL: https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook
   ↓
3. PawaPay sends payment prompt to user's mobile number
   ↓
4. User enters PIN on mobile money (MTN/Airtel)
   ↓
5. PawaPay processes payment
   ↓
6. PawaPay sends POST request to YOUR webhook:
   POST https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook
   {
     "depositId": "uuid",
     "status": "COMPLETED",
     "amount": "10000",
     "currency": "UGX",
     "correspondent": "MTN_MOMO_UGA",
     "metadata": {
       "userId": "firebase-user-id"
     }
   }
   ↓
7. Your webhook updates Firestore:
   - transactions collection: Creates transaction record
   - wallets collection: Increases user balance
   ↓
8. Flutter app displays updated wallet balance
```

---

## 🧪 Testing the Webhook Integration

### Method 1: Manual Webhook Test (Without Mobile Money)
Test that your webhook is receiving and processing requests correctly:

```bash
curl -X POST https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "depositId": "test-deposit-001",
    "status": "COMPLETED",
    "amount": "5000",
    "currency": "UGX",
    "correspondent": "MTN_MOMO_UGA",
    "payer": {
      "msisdn": "+256700123456"
    },
    "metadata": {
      "userId": "YOUR_FIREBASE_USER_ID"
    },
    "created": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'
```

**Expected Response**: `200 OK` with confirmation JSON

**Verify in Firestore**:
1. Open: https://console.firebase.google.com/project/sayekataleapp/firestore/data
2. Check `transactions` collection → Should see new test transaction
3. Check `wallets` collection → Should see balance increase for test user

### Method 2: End-to-End Test (With Real Mobile Money)
**⚠️ Uses real money - Test with small amount (e.g., 1000 UGX)**

1. **Install New APK**:
   - Transfer `app-release.apk` to test device
   - Install and open app

2. **Create Test Account**:
   - Register with test email
   - Complete profile setup

3. **Initiate Deposit**:
   - Go to Wallet screen
   - Click "Add Money"
   - Enter amount: 1000 UGX
   - Select: MTN Mobile Money or Airtel Money
   - Enter mobile number
   - Click "Deposit"

4. **Complete Payment**:
   - Wait for prompt on mobile phone
   - Enter mobile money PIN
   - Confirm transaction

5. **Monitor Webhook Logs**:
   ```bash
   gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=pawapay-webhook" \
     --limit 10 --format json
   ```

6. **Verify in App**:
   - Wait 5-10 seconds
   - Check wallet balance updated
   - Check transaction history shows deposit

**If Deposit Fails**:
- Check webhook logs for errors
- Verify PawaPay API token is valid
- Confirm callback URL matches exactly
- Check Firestore security rules allow writes to `transactions` and `wallets`

---

## 📋 Configuration Summary

### Environment Variables (Build Time)
```bash
# Production build command with all environment variables:
flutter build apk --release \
  --dart-define=PAWAPAY_API_TOKEN=eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ... \
  --dart-define=PAWAPAY_DEPOSIT_CALLBACK=https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook \
  --dart-define=PAWAPAY_WITHDRAWAL_CALLBACK=https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook
```

**Note**: The default values in `environment.dart` have been updated, so you can now build without explicit `--dart-define` for callback URLs. However, `PAWAPAY_API_TOKEN` should always be provided for security.

### Backend Webhook Configuration
**Google Cloud Run Service**:
```bash
Service Name: pawapay-webhook
Region: us-central1
URL: https://pawapay-webhook-713040690605.us-central1.run.app
Environment Variables:
  - PAWAPAY_API_TOKEN: eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ...
  - (Other variables as configured)
```

---

## 🔍 Monitoring & Debugging

### View Webhook Logs in Real-Time
```bash
# Stream logs (updates live)
gcloud logging tail "resource.type=cloud_run_revision AND resource.labels.service_name=pawapay-webhook"

# Get recent logs (last 50 entries)
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=pawapay-webhook" \
  --limit 50 --format json

# Filter for errors only
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=pawapay-webhook AND severity>=ERROR" \
  --limit 20 --format json
```

### Cloud Run Console
**Direct Link**: https://console.cloud.google.com/run/detail/us-central1/pawapay-webhook/logs

**Useful Views**:
- **Logs**: See all incoming webhook requests
- **Metrics**: Monitor request rate, latency, error rate
- **Revisions**: View deployment history

### Firestore Real-Time Monitoring
**Console**: https://console.firebase.google.com/project/sayekataleapp/firestore/data

**Collections to Watch**:
- `transactions` - New entries after deposits
- `wallets` - Balance updates
- `users` - User activity tracking

---

## ✅ Verification Checklist

### Configuration Updates
- [x] Webhook URLs updated in `lib/config/environment.dart`
- [x] Production APK rebuilt with PawaPay API token
- [x] Changes committed to git
- [x] Changes pushed to GitHub

### Backend Verification
- [x] Google Cloud Run service deployed
- [x] Webhook health check passing
- [x] Production API token configured
- [x] Webhook endpoint accessible

### Ready for Testing
- [x] APK available for download (67 MB)
- [x] Documentation complete
- [ ] **Firestore security rules deployed** (USER ACTION REQUIRED)
- [ ] End-to-end wallet deposit test (PENDING)

---

## 🚨 IMPORTANT: Next Action Required

### Deploy Firestore Security Rules

**Why This Matters**:
- Without this, users see "Permission Denied" errors
- Affects: Orders, Favorites, Messages, Receipts screens
- Takes 2 minutes to deploy

**How to Deploy**:
1. Visit: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
2. Copy content from `firestore.rules` file
3. Paste into editor
4. Click **"Publish"**
5. Wait for confirmation

**After Deployment**:
- Test Orders screen → Should load without errors
- Test Favorites screen → Should load without errors
- Test Messages → Should load without errors
- Test Receipts → Should load without errors

---

## 📞 Support Information

### Key Files
- `PRODUCTION_DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `SECURITY_AND_API_AUDIT.md` - Security audit report
- `firestore.rules` - Updated security rules (NEEDS DEPLOYMENT)

### Contact
- **GitHub**: https://github.com/DrakeNamanya/sayekataleapp
- **Firebase Project**: sayekataleapp
- **Google Cloud Project**: (Your GCP project with Cloud Run)

---

**Status**: ✅ Webhook configuration complete - Ready for testing after Firestore rules deployment!
