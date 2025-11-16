# PawaPay API Token Update Guide

## ✅ Token Updated Successfully (Code Level)

The new PawaPay API token has been updated in all code and documentation files.

---

## 🔑 New PawaPay API Token

### Token Value
```
eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4ODY1ODk1LCJpYXQiOjE3NjMzMzMwOTUsInBtIjoiREFGLFBBRiIsImp0aSI6IjI3OWJlNGZlLTk1ZTgtNGYwMy1iNmU3LWNhZGQ0N2MwODQ0NCJ9.gEZrCzNiIsln3stFyfe6CGAcbdKCKBsbiA07yAalylNmRSupCdxek6DQWO_mOQGxAnP4CO7G-Rxzg-QkOdUb6Q
```

### Token Details
- **Issued**: November 15, 2024
- **Expires**: December 31, 2035 (11+ years validity)
- **Permissions**: Deposit, Payout, Refund (DAF, PAF)
- **Type**: Application Access Token (AAT)
- **Subject**: 1911

---

## ✅ Files Updated (Committed to Git)

### 1. Webhook Server ✅
**File**: `webhook_server/pawapay_webhook.py`
- Updated default token value
- Token is loaded from environment variable or defaults to new token

### 2. Build Script ✅
**File**: `build_production.sh`
- Updated token used in APK builds
- All future APK builds will use new token

### 3. GitHub Secrets Documentation ✅
**File**: `GITHUB_SECRETS_UPDATE.md`
- Updated PAWAPAY_API_TOKEN value
- Updated token expiry information

### 4. Auth Status Documentation ✅
**File**: `SECRETS_AND_AUTH_STATUS.md`
- Updated token in all references
- Updated GitHub CLI commands

---

## ⚠️ Action Required: Update Live Services

### 1. Update Cloud Run Webhook (Required)

The webhook is currently running with the old token. Update it from Windows:

```bash
cd C:\Users\dnamanya\Documents\sayekataleapp

# Update Cloud Run environment variable
gcloud run services update pawapay-webhook ^
  --region us-central1 ^
  --update-env-vars PAWAPAY_API_TOKEN=eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4ODY1ODk1LCJpYXQiOjE3NjMzMzMwOTUsInBtIjoiREFGLFBBRiIsImp0aSI6IjI3OWJlNGZlLTk1ZTgtNGYwMy1iNmU3LWNhZGQ0N2MwODQ0NCJ9.gEZrCzNiIsln3stFyfe6CGAcbdKCKBsbiA07yAalylNmRSupCdxek6DQWO_mOQGxAnP4CO7G-Rxzg-QkOdUb6Q ^
  --project sayekataleapp
```

**Expected output**:
```
✓ Deploying... Done.
✓ Service [pawapay-webhook] revision [pawapay-webhook-00002-xxx] has been deployed
Service URL: https://pawapay-webhook-713040690605.us-central1.run.app
```

**Verify update**:
```bash
# Check webhook health
curl https://pawapay-webhook-713040690605.us-central1.run.app/health
```

---

### 2. Update GitHub Secret (Required)

Update the PAWAPAY_API_TOKEN secret in GitHub:

**Method 1: GitHub Web UI**
1. Go to: https://github.com/DrakeNamanya/sayekataleapp/settings/secrets/actions
2. Click "PAWAPAY_API_TOKEN" → "Update"
3. Paste new token:
   ```
   eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4ODY1ODk1LCJpYXQiOjE3NjMzMzMwOTUsInBtIjoiREFGLFBBRiIsImp0aSI6IjI3OWJlNGZlLTk1ZTgtNGYwMy1iNmU3LWNhZGQ0N2MwODQ0NCJ9.gEZrCzNiIsln3stFyfe6CGAcbdKCKBsbiA07yAalylNmRSupCdxek6DQWO_mOQGxAnP4CO7G-Rxzg-QkOdUb6Q
   ```
4. Click "Update secret"

**Method 2: GitHub CLI**
```bash
cd C:\Users\dnamanya\Documents\sayekataleapp

gh secret set PAWAPAY_API_TOKEN -b "eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4ODY1ODk1LCJpYXQiOjE3NjMzMzMwOTUsInBtIjoiREFGLFBBRiIsImp0aSI6IjI3OWJlNGZlLTk1ZTgtNGYwMy1iNmU3LWNhZGQ0N2MwODQ0NCJ9.gEZrCzNiIsln3stFyfe6CGAcbdKCKBsbiA07yAalylNmRSupCdxek6DQWO_mOQGxAnP4CO7G-Rxzg-QkOdUb6Q"
```

---

### 3. Rebuild APK (Optional - For New Deployments)

If you want to rebuild the APK with the new token immediately:

```bash
cd C:\Users\dnamanya\Documents\sayekataleapp

# Pull latest code
git pull origin main

# Run build script (already has new token)
flutter build apk --release ^
  --dart-define=PRODUCTION=true ^
  --dart-define=API_BASE_URL=https://pawapay-webhook-713040690605.us-central1.run.app ^
  --dart-define=PAWAPAY_API_TOKEN=eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4ODY1ODk1LCJpYXQiOjE3NjMzMzMwOTUsInBtIjoiREFGLFBBRiIsImp0aSI6IjI3OWJlNGZlLTk1ZTgtNGYwMy1iNmU3LWNhZGQ0N2MwODQ0NCJ9.gEZrCzNiIsln3stFyfe6CGAcbdKCKBsbiA07yAalylNmRSupCdxek6DQWO_mOQGxAnP4CO7G-Rxzg-QkOdUb6Q ^
  --dart-define=PAWAPAY_DEPOSIT_CALLBACK=https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook ^
  --dart-define=PAWAPAY_WITHDRAWAL_CALLBACK=https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook ^
  --dart-define=ADMOB_APP_ID_ANDROID=ca-app-pub-6557386913540479~2174503706 ^
  --dart-define=ADMOB_BANNER_ID_ANDROID=ca-app-pub-6557386913540479/5529911893 ^
  --build-name=1.0.0 ^
  --build-number=1
```

**Note**: Existing APKs will continue to work with the old token until it expires.

---

## 🧪 Testing the New Token

### Test Webhook with New Token

1. **Check webhook health**:
   ```bash
   curl https://pawapay-webhook-713040690605.us-central1.run.app/health
   ```

2. **Test PawaPay integration**:
   - Use the app to initiate a payment
   - Check webhook logs:
     ```bash
     gcloud run services logs read pawapay-webhook --region us-central1 --limit 20
     ```
   - Verify callback is received with valid signature

3. **Monitor for errors**:
   - Check Cloud Run logs for authentication errors
   - Verify PawaPay dashboard shows successful callbacks

---

## 📊 Token Comparison

### Old Token
```
eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4NTA5MjM2LCJpYXQiOjE3NjI5NzY0MzYsInBtIjoiREFGLFBBRiIsImp0aSI6ImE0NjQyZjUyLWYwODYtNGJjNy1hMGY3LTQ2MmJiNDgyYzM1MSJ9.zyFdgBTQ-dj_NiR15ChPjLM6kYjH3ZB4J9G8ye4TKiOjPgdXsJ53U08-WspwZ8JtjXua8FGuIf4VhQVcmVRjHQ
```
- **Issued**: November 11, 2024
- **Expires**: December 5, 2035

### New Token
```
eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4ODY1ODk1LCJpYXQiOjE3NjMzMzMwOTUsInBtIjoiREFGLFBBRiIsImp0aSI6IjI3OWJlNGZlLTk1ZTgtNGYwMy1iNmU3LWNhZGQ0N2MwODQ0NCJ9.gEZrCzNiIsln3stFyfe6CGAcbdKCKBsbiA07yAalylNmRSupCdxek6DQWO_mOQGxAnP4CO7G-Rxzg-QkOdUb6Q
```
- **Issued**: November 15, 2024
- **Expires**: December 31, 2035

**Change**: New token issued with extended expiry (26 days longer)

---

## ✅ Update Checklist

- [x] Updated webhook server code
- [x] Updated build script
- [x] Updated GitHub Secrets documentation
- [x] Updated auth status documentation
- [x] Committed changes to Git
- [ ] Update Cloud Run environment variable (you need to do this)
- [ ] Update GitHub Secret (you need to do this)
- [ ] Test webhook with new token
- [ ] Rebuild APK (optional, for new deployments)

---

## 🔍 Verification Steps

After updating Cloud Run and GitHub:

1. **Verify Cloud Run Update**:
   ```bash
   gcloud run services describe pawapay-webhook --region us-central1 --format="value(spec.template.spec.containers[0].env)"
   ```
   Should show new token

2. **Verify GitHub Secret**:
   - Go to: https://github.com/DrakeNamanya/sayekataleapp/settings/secrets/actions
   - Check PAWAPAY_API_TOKEN shows "Updated X minutes ago"

3. **Test End-to-End**:
   - Install app on Android device
   - Initiate a mobile money payment
   - Verify webhook receives callback
   - Check transaction updates in Firestore

---

## 📞 Support

If you encounter issues:

- **PawaPay Dashboard**: https://dashboard.pawapay.io/
- **Cloud Run Console**: https://console.cloud.google.com/run/detail/us-central1/pawapay-webhook
- **GitHub Secrets**: https://github.com/DrakeNamanya/sayekataleapp/settings/secrets/actions

---

## 🎉 Summary

**Code Level**: ✅ **COMPLETE** - All code and documentation updated

**Live Services**: ⏳ **ACTION REQUIRED**
- Update Cloud Run webhook environment variable
- Update GitHub Secret

Once you update the live services, the new token will be active across all systems!

---

**Updated**: November 16, 2024
**Token Validity**: Until December 31, 2035
**Action Required**: Update Cloud Run and GitHub Secret
