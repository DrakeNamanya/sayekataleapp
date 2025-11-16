# GitHub Secrets Configuration Guide

This document contains all 8 GitHub Secrets values needed for CI/CD pipeline.

---

## 🔐 GitHub Secrets Values

### 1. ANDROID_KEYSTORE

**Description**: Base64-encoded release keystore file for signing Android APKs

**How to get the value**:
```bash
base64 -w 0 /home/user/flutter_app/android/release-key.jks
```

**Or on Windows**:
```bash
cd C:\Users\dnamanya\Documents\sayekataleapp\android
certutil -encode release-key.jks keystore.txt
# Then copy content from keystore.txt (remove BEGIN/END lines)
```

**Value**: 
```
Copy the FULL base64 output from the command above.
It will be a very long string (approximately 3700 characters).
```

**Storage location**: This is the same keystore at `android/release-key.jks`

---

### 2. ANDROID_KEY_PASSWORD

**Description**: Password for the release key alias

**Value**:
```
KAqjapekEJ6dXKY$Yh%U
```

**Source**: From `android/key.properties` file

---

### 3. ANDROID_STORE_PASSWORD

**Description**: Password for the keystore file

**Value**:
```
KAqjapekEJ6dXKY$Yh%U
```

**Source**: From `android/key.properties` file

---

### 4. API_BASE_URL

**Description**: Production webhook server base URL

**Value**:
```
https://pawapay-webhook-713040690605.us-central1.run.app
```

**Source**: Cloud Run deployment (Phase 1)

**Verify it's working**:
```bash
curl https://pawapay-webhook-713040690605.us-central1.run.app/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "PawaPay Webhook Handler",
  "timestamp": "2024-11-16T..."
}
```

---

### 5. GOOGLE_SERVICES_JSON

**Description**: Firebase Android configuration (entire JSON file content)

**Value**:
```json
{
  "project_info": {
    "project_number": "713040690605",
    "project_id": "sayekataleapp",
    "storage_bucket": "sayekataleapp.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:713040690605:android:060c649529abd85ccb7524",
        "android_client_info": {
          "package_name": "com.datacollectors.sayekatale"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyAR4WdX7MsctO7aSX_vfqKMZbIUOxrnMlg"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

**Source**: `/opt/flutter/google-services.json`

**Important**: Store the ENTIRE JSON as-is (with all formatting)

---

### 6. PAWAPAY_API_TOKEN

**Description**: PawaPay API authentication token (Updated November 16, 2024)

**Value**:
```
eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4ODY1ODk1LCJpYXQiOjE3NjMzMzMwOTUsInBtIjoiREFGLFBBRiIsImp0aSI6IjI3OWJlNGZlLTk1ZTgtNGYwMy1iNmU3LWNhZGQ0N2MwODQ0NCJ9.gEZrCzNiIsln3stFyfe6CGAcbdKCKBsbiA07yAalylNmRSupCdxek6DQWO_mOQGxAnP4CO7G-Rxzg-QkOdUb6Q
```

**Source**: PawaPay Dashboard

**Token Details**: 
- Issued: November 15, 2024
- Expires: December 31, 2035
- Permissions: Deposit, Payout, Refund

---

### 7. PAWAPAY_DEPOSIT_CALLBACK

**Description**: Webhook URL for deposit (payment) callbacks

**Value**:
```
https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook
```

**Source**: Cloud Run deployment + `/api/pawapay/webhook` endpoint

---

### 8. PAWAPAY_WITHDRAWAL_CALLBACK

**Description**: Webhook URL for withdrawal (payout) callbacks

**Value**:
```
https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook
```

**Source**: Cloud Run deployment + `/api/pawapay/webhook` endpoint

**Note**: Same URL as deposit callback (webhook handles both)

---

## 📝 How to Update GitHub Secrets

### Method 1: Via GitHub Web UI (Recommended)

1. **Go to your repository**: https://github.com/DrakeNamanya/sayekataleapp

2. **Navigate to Settings**:
   - Click "Settings" tab
   - Click "Secrets and variables" → "Actions"

3. **Update each secret**:
   - Click "New repository secret" or "Update" for existing secrets
   - Name: Enter the secret name exactly (e.g., `API_BASE_URL`)
   - Value: Paste the value from above
   - Click "Add secret" or "Update secret"

4. **Repeat for all 8 secrets**

### Method 2: Via GitHub CLI (Faster)

```bash
# Install GitHub CLI if not installed
# Windows: winget install --id GitHub.cli

# Login to GitHub
gh auth login

# Navigate to your repo
cd C:\Users\dnamanya\Documents\sayekataleapp

# Set secrets one by one
gh secret set API_BASE_URL -b "https://pawapay-webhook-713040690605.us-central1.run.app"

gh secret set PAWAPAY_API_TOKEN -b "eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4NTA5MjM2LCJpYXQiOjE3NjI5NzY0MzYsInBtIjoiREFGLFBBRiIsImp0aSI6ImE0NjQyZjUyLWYwODYtNGJjNy1hMGY3LTQ2MmJiNDgyYzM1MSJ9.zyFdgBTQ-dj_NiR15ChPjLM6kYjH3ZB4J9G8ye4TKiOjPgdXsJ53U08-WspwZ8JtjXua8FGuIf4VhQVcmVRjHQ"

gh secret set PAWAPAY_DEPOSIT_CALLBACK -b "https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook"

gh secret set PAWAPAY_WITHDRAWAL_CALLBACK -b "https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook"

gh secret set ANDROID_KEY_PASSWORD -b "KAqjapekEJ6dXKY$Yh%U"

gh secret set ANDROID_STORE_PASSWORD -b "KAqjapekEJ6dXKY$Yh%U"

# For GOOGLE_SERVICES_JSON (multiline)
gh secret set GOOGLE_SERVICES_JSON < android/app/google-services.json

# For ANDROID_KEYSTORE (base64 file)
base64 -w 0 android/release-key.jks | gh secret set ANDROID_KEYSTORE
```

---

## ✅ Verify Secrets are Set

After updating, verify all secrets are configured:

1. Go to: https://github.com/DrakeNamanya/sayekataleapp/settings/secrets/actions

2. You should see all 8 secrets listed:
   - ✅ ANDROID_KEYSTORE
   - ✅ ANDROID_KEY_PASSWORD
   - ✅ ANDROID_STORE_PASSWORD
   - ✅ API_BASE_URL
   - ✅ GOOGLE_SERVICES_JSON
   - ✅ PAWAPAY_API_TOKEN
   - ✅ PAWAPAY_DEPOSIT_CALLBACK
   - ✅ PAWAPAY_WITHDRAWAL_CALLBACK

3. Secrets show as "Updated X ago" with a green checkmark

---

## 🧪 Test CI/CD Pipeline

After updating secrets, trigger a build to test:

```bash
# Make a small change and push
cd C:\Users\dnamanya\Documents\sayekataleapp
git pull origin main
echo "# Test" >> README.md
git add README.md
git commit -m "test: Trigger CI/CD with updated secrets"
git push origin main
```

Then check:
- GitHub Actions: https://github.com/DrakeNamanya/sayekataleapp/actions
- Look for successful build with green checkmark

---

## 🔍 Common Issues

### Issue: "Invalid keystore format"
**Solution**: Ensure ANDROID_KEYSTORE is base64-encoded without newlines
```bash
base64 -w 0 android/release-key.jks
```

### Issue: "Invalid JSON" for GOOGLE_SERVICES_JSON
**Solution**: Copy the EXACT JSON content including all brackets and quotes

### Issue: Webhook not receiving callbacks
**Solution**: 
1. Verify webhook is running: `curl https://pawapay-webhook-713040690605.us-central1.run.app/health`
2. Check Cloud Run logs: `gcloud run services logs read pawapay-webhook --region us-central1`
3. Verify PawaPay dashboard has correct callback URL

### Issue: Build fails with "Signing key not found"
**Solution**: Verify all three signing secrets are set:
- ANDROID_KEYSTORE (base64 of .jks file)
- ANDROID_KEY_PASSWORD
- ANDROID_STORE_PASSWORD

---

## 📋 Checklist

Before marking complete, verify:

- [ ] All 8 secrets added to GitHub
- [ ] Webhook health check returns 200 OK
- [ ] PawaPay dashboard configured with webhook URL
- [ ] Test push triggers successful CI/CD build
- [ ] APK builds successfully in GitHub Actions
- [ ] User authentication tested (next step)

---

## 🔐 Security Best Practices

1. **Never commit secrets to Git**
   - Keep `.gitignore` updated
   - Use GitHub Secrets for CI/CD
   - Use environment variables at runtime

2. **Rotate credentials periodically**
   - Update PawaPay token every 6 months
   - Regenerate keystore only if compromised (breaks updates!)

3. **Limit access**
   - Only authorized team members can view secrets
   - Use separate tokens for dev/staging/prod

4. **Monitor usage**
   - Check GitHub Actions logs for failed auth attempts
   - Monitor webhook logs for suspicious activity

---

## 📞 Support

If you encounter issues:
- **GitHub Secrets**: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- **Firebase Console**: https://console.firebase.google.com/project/sayekataleapp
- **PawaPay Dashboard**: https://dashboard.pawapay.io/
- **Cloud Run Logs**: `gcloud run services logs read pawapay-webhook --region us-central1`

---

**Next Step**: After updating secrets, test user authentication to verify Firebase Auth is working correctly.
