# PawaPay Webhook Server

This webhook server handles payment callbacks from PawaPay and updates Firebase Firestore with transaction statuses.

## Quick Deploy (Automated)

```bash
# 1. Authenticate with Google Cloud
export PATH="/home/user/google-cloud-sdk/bin:$PATH"
gcloud auth login

# 2. Run deployment script
cd /home/user/flutter_app/webhook_server
./deploy.sh
```

That's it! The script will:
- ✅ Set up your Google Cloud project
- ✅ Enable required APIs
- ✅ Build and deploy the Docker container
- ✅ Provide your webhook URL

## Manual Deploy

If you prefer step-by-step control, see [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

## After Deployment

1. **Test the health endpoint**:
   ```bash
   curl https://YOUR-URL/health
   ```

2. **Configure PawaPay Dashboard**:
   - Go to https://dashboard.pawapay.io/
   - Settings → Webhooks
   - Add: `https://YOUR-URL/api/pawapay/webhook`

3. **Save webhook URL for APK build**:
   - You'll need this URL when building your production Android APK

## Files

- `pawapay_webhook.py` - Main webhook handler
- `requirements.txt` - Python dependencies
- `Dockerfile` - Container configuration
- `deploy.sh` - Automated deployment script
- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions

## Monitoring

View real-time logs:
```bash
gcloud run services logs read pawapay-webhook --region us-central1 --follow
```

## Architecture

```
Android App (Flutter)
    ↓ Initiates payment
PawaPay API
    ↓ Sends callback
Cloud Run Webhook (This service)
    ↓ Updates database
Firebase Firestore
```

## Environment Variables

- `PAWAPAY_API_TOKEN` - PawaPay authentication token
- `PORT` - HTTP port (set by Cloud Run)
- `FIREBASE_CREDENTIALS_PATH` - Firebase credentials file path

## Support

- Cloud Run: https://cloud.google.com/run/docs
- PawaPay: https://docs.pawapay.io/
- Firebase: https://firebase.google.com/docs
