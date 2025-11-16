# Phase 1: Webhook Server Deployment - Ready to Deploy! 🚀

## What's Been Prepared

Your PawaPay webhook server is **fully configured and ready for deployment** to Google Cloud Run.

## Files Created/Updated

### 📁 webhook_server/ Directory

1. ✅ **pawapay_webhook.py** (Updated)
   - Modified to support both local and Cloud Run environments
   - Uses environment variables for Firebase credentials
   - Configurable PORT for Cloud Run compatibility

2. ✅ **Dockerfile** (New)
   - Python 3.11 slim base image
   - Optimized for Cloud Run deployment
   - Production-ready with gunicorn

3. ✅ **.dockerignore** (New)
   - Excludes unnecessary files from Docker build
   - Reduces image size and build time

4. ✅ **deploy.sh** (New)
   - Automated deployment script
   - Handles authentication, API setup, and deployment
   - Provides webhook URLs after deployment

5. ✅ **README.md** (New)
   - Quick start guide
   - Deployment instructions
   - Monitoring commands

6. ✅ **DEPLOYMENT_GUIDE.md** (New)
   - Comprehensive deployment documentation
   - Step-by-step instructions
   - Troubleshooting guide
   - Cost estimates

7. ✅ **requirements.txt** (Already exists)
   - Flask==3.0.0
   - firebase-admin==7.1.0
   - gunicorn==21.2.0

## Prerequisites (Already Completed)

✅ Google Cloud CLI installed at `/home/user/google-cloud-sdk/`
✅ Firebase Admin SDK credentials at `/opt/flutter/firebase-admin-sdk.json`
✅ Firebase project: `sayekataleapp`
✅ PawaPay API sandbox token configured

## How to Deploy (Choose One Method)

### Method 1: Automated Deployment (Recommended) ⚡

This is the **fastest and easiest** way:

```bash
# Step 1: Add gcloud to PATH
export PATH="/home/user/google-cloud-sdk/bin:$PATH"

# Step 2: Authenticate with Google Cloud (opens browser)
gcloud auth login

# Step 3: Run deployment script
cd /home/user/flutter_app/webhook_server
./deploy.sh
```

**Time**: ~3-5 minutes

**What it does automatically**:
- Sets Google Cloud project to `sayekataleapp`
- Enables Cloud Run, Cloud Build, and Artifact Registry APIs
- Builds Docker container from source
- Deploys to Cloud Run with proper configuration
- Provides webhook URLs for next steps

### Method 2: Manual Step-by-Step Deployment

If you prefer more control, follow the detailed guide:

```bash
# See full instructions in:
/home/user/flutter_app/webhook_server/DEPLOYMENT_GUIDE.md
```

## What You'll Get After Deployment

1. **Production Webhook URL**: 
   ```
   https://pawapay-webhook-[random-id]-uc.a.run.app
   ```

2. **Two Important Endpoints**:
   - Health Check: `https://YOUR-URL/health`
   - PawaPay Webhook: `https://YOUR-URL/api/pawapay/webhook`

3. **Automatic Features**:
   - ✅ HTTPS encryption (enforced by Cloud Run)
   - ✅ Auto-scaling (scales to zero when not in use)
   - ✅ Firebase integration (uses project credentials)
   - ✅ Webhook signature verification
   - ✅ Comprehensive logging

## After Deployment - Next Steps

### Step 1: Test Your Webhook

```bash
# Test health endpoint
curl https://YOUR-CLOUD-RUN-URL/health

# Expected response:
# {
#   "status": "healthy",
#   "service": "PawaPay Webhook Handler",
#   "timestamp": "2024-11-16T21:30:00.123456"
# }
```

### Step 2: Configure PawaPay Dashboard

1. Go to **PawaPay Dashboard**: https://dashboard.pawapay.io/
2. Navigate to **Settings** → **Webhooks**
3. Add webhook URL: `https://YOUR-CLOUD-RUN-URL/api/pawapay/webhook`
4. Save configuration

### Step 3: Save URLs for Phase 2

You'll need these URLs when building your production APK:

```bash
# Save these values:
API_BASE_URL=https://YOUR-CLOUD-RUN-URL
PAWAPAY_CALLBACK=https://YOUR-CLOUD-RUN-URL/api/pawapay/webhook
```

### Step 4: Proceed to Phase 2

Once webhook is deployed and tested, move to **Phase 2: Get AdMob App ID**

## Monitoring Your Webhook

### View Real-Time Logs
```bash
export PATH="/home/user/google-cloud-sdk/bin:$PATH"
gcloud run services logs read pawapay-webhook --region us-central1 --follow
```

### Check Service Status
```bash
gcloud run services describe pawapay-webhook --region us-central1
```

### View Recent Activity
```bash
gcloud run services logs read pawapay-webhook --region us-central1 --limit 100
```

## Cost Estimate

**Google Cloud Run Free Tier** (More than enough for SayeKatale):
- ✅ 2 million requests per month
- ✅ 360,000 GB-seconds of memory
- ✅ 180,000 vCPU-seconds of compute time

**Expected cost**: $0/month (well within free tier)

Even with thousands of transactions:
- Each webhook call takes ~100-200ms
- ~1000 transactions/day = ~30,000/month
- Still within free tier!

## Troubleshooting

### Issue: "gcloud: command not found"
**Solution**: Add gcloud to PATH
```bash
export PATH="/home/user/google-cloud-sdk/bin:$PATH"
```

### Issue: Authentication fails
**Solution**: Make sure you're using the correct Google account
```bash
gcloud auth list
gcloud auth revoke  # If wrong account
gcloud auth login   # Login with correct account
```

### Issue: "Permission denied" during deployment
**Solution**: Verify project access in Firebase Console
- Go to: https://console.firebase.google.com/project/sayekataleapp
- Check that your Google account has "Owner" or "Editor" role

### Issue: Deployment succeeds but webhook doesn't work
**Solution**: Check Cloud Run logs for errors
```bash
gcloud run services logs read pawapay-webhook --region us-central1 --limit 50
```

## Security Features

✅ **HTTPS Only**: Cloud Run enforces HTTPS for all connections
✅ **Webhook Signature Verification**: Validates PawaPay requests
✅ **Environment Variables**: Sensitive data stored securely
✅ **Firebase Security**: Uses service account authentication
✅ **No Hard-Coded Secrets**: All tokens in environment variables

## Architecture Diagram

```
┌─────────────────────────┐
│   Android App (Flutter)  │
│   Package: com.datacol-  │
│   lectors.sayekatale     │
└────────────┬─────────────┘
             │ 1. Initiate payment
             ↓
┌─────────────────────────┐
│      PawaPay API         │
│   (Payment Gateway)      │
└────────────┬─────────────┘
             │ 2. Send callback
             ↓
┌─────────────────────────┐
│   Cloud Run Webhook      │ ← YOU ARE HERE (Phase 1)
│   (Python/Flask)         │
│   URL: pawapay-webhook-  │
│   xxx.a.run.app          │
└────────────┬─────────────┘
             │ 3. Update database
             ↓
┌─────────────────────────┐
│   Firebase Firestore     │
│   (Database)             │
│   Project: sayekataleapp │
└─────────────────────────┘
```

## Ready to Deploy?

**Run this command to start deployment**:

```bash
export PATH="/home/user/google-cloud-sdk/bin:$PATH" && \
gcloud auth login && \
cd /home/user/flutter_app/webhook_server && \
./deploy.sh
```

This single command will:
1. Add gcloud to your PATH
2. Open browser for Google authentication
3. Deploy webhook to Cloud Run
4. Provide your production webhook URL

**Estimated time**: 3-5 minutes

---

## Support & Documentation

📚 **Full Deployment Guide**: `webhook_server/DEPLOYMENT_GUIDE.md`
📖 **Quick Reference**: `webhook_server/README.md`
🔧 **Deployment Script**: `webhook_server/deploy.sh`

🌐 **External Resources**:
- Cloud Run Docs: https://cloud.google.com/run/docs
- PawaPay Docs: https://docs.pawapay.io/
- Firebase Docs: https://firebase.google.com/docs

---

**Status**: ✅ Ready for Deployment
**Next Phase**: Phase 2 - Get AdMob App ID (after webhook deployment)
