# PawaPay Webhook Server - Cloud Run Deployment Guide

## Overview

This guide will help you deploy the PawaPay webhook server to Google Cloud Run. The webhook handles payment callbacks from PawaPay and updates your Firebase Firestore database.

## Prerequisites

✅ Google Cloud CLI installed (already done)
✅ Firebase Admin SDK credentials (already configured)
✅ Firebase project: `sayekataleapp`
✅ PawaPay API token

## Architecture

```
PawaPay API → Cloud Run Webhook → Firestore Database
```

## Deployment Steps

### Step 1: Authenticate with Google Cloud

Open your browser and authenticate:

```bash
# Add gcloud to PATH
export PATH="/home/user/google-cloud-sdk/bin:$PATH"

# Login to Google Cloud
gcloud auth login

# Set project
gcloud config set project sayekataleapp
```

### Step 2: Enable Required APIs

```bash
# Enable Cloud Run API
gcloud services enable run.googleapis.com

# Enable Cloud Build API (for building containers)
gcloud services enable cloudbuild.googleapis.com

# Enable Artifact Registry API
gcloud services enable artifactregistry.googleapis.com
```

### Step 3: Deploy to Cloud Run

```bash
cd /home/user/flutter_app/webhook_server

# Deploy with Firebase credentials from environment
gcloud run deploy pawapay-webhook \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --timeout 300 \
  --set-env-vars "PAWAPAY_API_TOKEN=eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4NTA5MjM2LCJpYXQiOjE3NjI5NzY0MzYsInBtIjoiREFGLFBBRiIsImp0aSI6ImE0NjQyZjUyLWYwODYtNGJjNy1hMGY3LTQ2MmJiNDgyYzM1MSJ9.zyFdgBTQ-dj_NiR15ChPjLM6kYjH3ZB4J9G8ye4TKiOjPgdXsJ53U08-WspwZ8JtjXua8FGuIf4VhQVcmVRjHQ"
```

**Note**: Cloud Run will automatically use the Firebase project's default credentials, so you don't need to manually upload the credentials file.

### Step 4: Get Your Webhook URL

After deployment completes, you'll see output like:

```
Service [pawapay-webhook] revision [pawapay-webhook-00001-xxx] has been deployed and is serving 100 percent of traffic.
Service URL: https://pawapay-webhook-xxxxxxxxx-uc.a.run.app
```

**Save this URL!** You'll need it for:
1. PawaPay Dashboard configuration
2. Building your production APK

### Step 5: Test the Webhook

```bash
# Test health check endpoint
curl https://YOUR-CLOUD-RUN-URL/health

# Expected response:
# {
#   "status": "healthy",
#   "service": "PawaPay Webhook Handler",
#   "timestamp": "2024-01-15T10:30:00.123456"
# }
```

### Step 6: Configure PawaPay Dashboard

1. Go to PawaPay Dashboard: https://dashboard.pawapay.io/
2. Navigate to **Settings** → **Webhooks**
3. Add webhook URL: `https://YOUR-CLOUD-RUN-URL/api/pawapay/webhook`
4. Save configuration

## Environment Variables

The webhook server uses these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PAWAPAY_API_TOKEN` | PawaPay API authentication token | Sandbox token |
| `PORT` | HTTP port (Cloud Run sets this automatically) | 8080 |
| `FIREBASE_CREDENTIALS_PATH` | Path to Firebase credentials | `/opt/flutter/firebase-admin-sdk.json` |

## Monitoring and Logs

### View Logs
```bash
# View real-time logs
gcloud run services logs read pawapay-webhook --region us-central1 --follow

# View recent logs
gcloud run services logs read pawapay-webhook --region us-central1 --limit 100
```

### Check Service Status
```bash
gcloud run services describe pawapay-webhook --region us-central1
```

## Production Webhook URLs

After deployment, your webhook endpoints will be:

- **Health Check**: `https://YOUR-CLOUD-RUN-URL/health`
- **PawaPay Webhook**: `https://YOUR-CLOUD-RUN-URL/api/pawapay/webhook`

## Updating the Webhook

To deploy updates:

```bash
cd /home/user/flutter_app/webhook_server
gcloud run deploy pawapay-webhook \
  --source . \
  --platform managed \
  --region us-central1
```

## Cost Considerations

Cloud Run pricing (Free tier includes):
- ✅ 2 million requests per month
- ✅ 360,000 GB-seconds of memory
- ✅ 180,000 vCPU-seconds of compute time

**Estimated cost for SayeKatale**: ~$0-5/month (well within free tier)

## Troubleshooting

### Issue: "Permission denied" errors
**Solution**: Ensure you're logged in with the correct Google account
```bash
gcloud auth list
gcloud auth login
```

### Issue: "Service account does not have permission"
**Solution**: Grant Cloud Run admin role
```bash
gcloud projects add-iam-policy-binding sayekataleapp \
  --member="user:YOUR_EMAIL@gmail.com" \
  --role="roles/run.admin"
```

### Issue: Firebase connection errors
**Solution**: Verify Firebase project permissions
- Go to Firebase Console: https://console.firebase.google.com/
- Check that your Google account has "Owner" or "Editor" role

### Issue: Webhook receiving but not updating Firestore
**Solution**: Check Cloud Run logs for errors
```bash
gcloud run services logs read pawapay-webhook --region us-central1 --limit 50
```

## Security Best Practices

1. ✅ **Webhook Signature Verification**: Already implemented in code
2. ✅ **HTTPS Only**: Cloud Run enforces HTTPS
3. ✅ **Environment Variables**: API tokens stored securely
4. ⚠️ **Production Token**: Replace sandbox token with production token before launch

## Next Steps

After webhook deployment:

1. ✅ Copy your Cloud Run URL
2. ✅ Configure PawaPay Dashboard with webhook URL
3. ✅ Test webhook with PawaPay sandbox
4. ⏭️ Proceed to Phase 2: Get AdMob App ID
5. ⏭️ Build production Android APK with webhook URL

## Support

For issues:
- Cloud Run: https://cloud.google.com/run/docs
- PawaPay: https://docs.pawapay.io/
- Firebase: https://firebase.google.com/support
